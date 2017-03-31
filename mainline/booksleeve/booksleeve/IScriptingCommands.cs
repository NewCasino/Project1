using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Commands that apply to Redis scripting (Lua).
    /// </summary>
    /// <remarks>http://redis.io/commands#scripting</remarks>
    public interface IScriptingCommands
    {
        /// <summary>
        /// Execute a Lua 5.1 script. The script does not need to define a Lua function (and should not). It is just a Lua program that will run in the context of the Redis server.
        /// All key-names should be passed via the keyArgs parameter, which allows necessary checks by Redis. Note that Lua scripts in Redis have a range of features and
        /// limitations - be sure to review the documentation.
        /// </summary>
        /// <remarks>http://redis.io/commands/eval</remarks>
        Task<object> Eval(int db, string script, string[] keyArgs, object[] valueArgs, bool useCache = true, bool inferStrings = true, bool queueJump = false);

        /// <summary>
        /// Ensures that the given script exists
        /// </summary>
        /// <remarks>http://redis.io/commands/script-exists and http://redis.io/commands/script-load</remarks>
        Task Prepare(params string[] script);
    }

    partial class RedisConnection : IScriptingCommands
    {
        /// <summary>
        /// Commands that apply to Redis scripting (Lua).
        /// </summary>
        /// <remarks>http://redis.io/commands#scripting</remarks>
        public IScriptingCommands Scripting { get { return this; } }

        Task IScriptingCommands.Prepare(string[] scripts)
        {
            return Prepare(scripts);
        }
        internal virtual Task Prepare(string[] scripts)
        {
            if (scripts == null) throw new ArgumentNullException();
            var seenHashes = new HashSet<string>();
            List<Tuple<string,string>> fetch = new List<Tuple<string,string>>(scripts.Length);
            for (int i = 0; i < scripts.Length; i++)
            {
                string script = scripts[i];
                if (!scriptCache.ContainsKey(script)) {
                    string hash = ComputeHash(script);
                    seenHashes.Add(hash);
                    fetch.Add(Tuple.Create(hash, script));
                }
            }
            if (fetch.Count == 0)
            {
                // no point checking, since we'd still be at the mercy of ad-hoc SCRIPT FLUSH timing    
                return AlwaysTrue;
            }
            
            RedisMessage.RedisParameter[] args = new RedisMessage.RedisParameter[1 + fetch.Count];
            args[0] = RedisLiteral.EXISTS;
            int idx = 1;
            foreach (var pair in fetch)
            {
                args[idx++] = pair.Item1; // hash
            }

            TaskCompletionSource<bool> result = new TaskCompletionSource<bool>();

            var state = Tuple.Create(result, this, fetch);
            ExecuteRaw(RedisMessage.Create(-1, RedisLiteral.SCRIPT, args), false, state).ContinueWith(scriptCompletionCallback);

            return result.Task;
        }
        static readonly Action<Task<RedisResult>> scriptCompletionCallback = queryTask =>
            {
                var tuple = (Tuple<TaskCompletionSource<bool>, RedisConnection, List<Tuple<string,string>>>)queryTask.AsyncState;
                var result = tuple.Item1;
                var @this = tuple.Item2;
                var fetch = tuple.Item3;

                if (queryTask.ShouldSetResult(result))
                {
                    var existResults = queryTask.Result.ValueItems;
                    Task last = null;
                    for (int i = 0; i < existResults.Length; i++)
                    {
                        string hash = fetch[i].Item1, script = fetch[i].Item2;
                        if (existResults[i].ValueInt64 == 0)
                        {   // didn't exist
                            last = @this.ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.SCRIPT, RedisLiteral.LOAD, script), true, result);
                        }
                        // at this point, either it *already* existed, or we've issued a queue-jumping LOAD command,
                        // so all *subsequent* calles can reliably assume that it will exist on the server from now on
                        lock (@this.scriptCache)
                        {
                            @this.scriptCache[script] = hash;
                        }
                    }
                    if (last == null)
                    {
                        // nothing needed
                        result.TrySetResult(true);
                    }
                    else
                    {
                        last.ContinueWith(loadScriptCallback);
                    }
                }
            };
        static readonly Action<Task> loadScriptCallback = loadTask =>
        {
            var result = (TaskCompletionSource<bool>)loadTask.AsyncState;
            if (loadTask.ShouldSetResult(result)) result.TrySetResult(true);
        };

        Task<object> IScriptingCommands.Eval(int db, string script, string[] keyArgs, object[] valueArgs, bool useCache, bool inferStrings, bool queueJump)
        {
            if (string.IsNullOrEmpty(script)) throw new ArgumentNullException("script");
            var args = new RedisMessage.RedisParameter[2 + (keyArgs == null ? 0 : keyArgs.Length) + (valueArgs == null ? 0 : valueArgs.Length)];
            args[1] = keyArgs == null ? 0 : keyArgs.Length;
            int idx = 2;
            if (keyArgs != null)
            {
                for (int i = 0; i < keyArgs.Length; i++)
                {
                    args[idx++] = keyArgs[i];
                }
            }
            if (valueArgs != null)
            {
                for (int i = 0; i < valueArgs.Length; i++)
                {
                    args[idx++] = RedisMessage.RedisParameter.Create(valueArgs[i]);
                }
            }
            if (!useCache)
            {
                args[0] = script;
                return ExecuteScript(RedisMessage.Create(db, RedisLiteral.EVAL, args), inferStrings, queueJump);
            }

            // note this does a SCRIPT LOAD if it is the first time it is seen on this connection
            args[0] = GetScriptHash(script);
            return ExecuteScript(RedisMessage.Create(db, RedisLiteral.EVALSHA, args), inferStrings, queueJump);
        }
        internal void ResetScriptCache()
        {
            lock (scriptCache) { scriptCache.Clear(); }
        }
        internal Task<object> ExecuteScript(RedisMessage message, bool inferStrings, bool queueJump)
        {
            var msgResult = new MessageResultScript(this, inferStrings);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        static string ComputeHash(string script)
        {
            using (var sha1 = SHA1.Create())
            {

                var bytes = sha1.ComputeHash(Encoding.UTF8.GetBytes(script));
                var sb = new StringBuilder(bytes.Length * 2);
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }
        internal virtual string GetScriptHash(string script)
        {
            var hash = (string)scriptCache[script];

            if (hash == null)
            {   // double-checked
                lock (scriptCache)
                {
                    hash = (string)scriptCache[script];
                    if (hash == null)
                    {
                        // compute the hash and ensure it is loaded
                        hash = ComputeHash(script);
                        ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.SCRIPT, RedisLiteral.LOAD, script), queueJump: true);
                        scriptCache[script] = hash;
                    }
                }
            }
            return hash;
        }
        // unlike Dictionary, Hashtable has lock-free read semantics
        readonly Hashtable scriptCache = new Hashtable();
    }
}
