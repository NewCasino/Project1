
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.Net;
using System.Threading.Tasks;
namespace BookSleeve
{
    /// <summary>
    /// Commands related to server operation and configuration, rather than data.
    /// </summary>
    /// <remarks>http://redis.io/commands#server</remarks>
    public interface IServerCommands
    {
        /// <summary>
        /// Delete all the keys of the currently selected DB.
        /// </summary>
        /// <remarks>http://redis.io/commands/flushdb</remarks>
        Task FlushDb(int db);

        /// <summary>
        /// Delete all the keys of all the existing databases, not just the currently selected one.
        /// </summary>
        /// <remarks>http://redis.io/commands/flushall</remarks>
        Task FlushAll();

        /// <summary>
        /// This command is often used to test if a connection is still alive, or to measure latency.
        /// </summary>
        /// <returns>The latency in milliseconds.</returns>
        /// <remarks>http://redis.io/commands/ping</remarks>
        Task Ping(bool queueJump = false);

        /// <summary>
        /// The TIME command returns the current server time.
        /// </summary>
        /// <returns>The server's current time.</returns>
        /// <remarks>http://redis.io/commands/time</remarks>
        Task<DateTime> Time(bool queueJump = false);

        /// <summary>
        /// Get all configuration parameters matching the specified pattern.
        /// </summary>
        /// <param name="pattern">All the configuration parameters matching this parameter are reported as a list of key-value pairs.</param>
        /// <returns>All matching configuration parameters.</returns>
        /// <remarks>http://redis.io/commands/config-get</remarks>
        Task<Dictionary<string,string>> GetConfig(string pattern);

        /// <summary>
        /// The CONFIG SET command is used in order to reconfigure the server at runtime without the need to restart Redis. You can change both trivial parameters or switch from one to another persistence option using this command.
        /// </summary>
        /// <remarks>http://redis.io/commands/config-set</remarks>
        Task SetConfig(string parameter, string value);

        /// <summary>
        /// The SLAVEOF command can change the replication settings of a slave on the fly. In the proper form SLAVEOF hostname port will make the server a slave of another server listening at the specified hostname and port.
        /// If a server is already a slave of some master, SLAVEOF hostname port will stop the replication against the old server and start the synchronization against the new one, discarding the old dataset.
        /// </summary>
        /// <remarks>http://redis.io/commands/slaveof</remarks>
        Task MakeSlave(string host, int port);
        /// <summary>
        /// The SLAVEOF command can change the replication settings of a slave on the fly. 
        /// If a Redis server is already acting as slave, the command SLAVEOF NO ONE will turn off the replication, turning the Redis server into a MASTER.
        /// The form SLAVEOF NO ONE will stop replication, turning the server into a MASTER, but will not discard the replication. So, if the old master stops working, it is possible to turn the slave into a master and set the application to use this new master in read/write. Later when the other Redis server is fixed, it can be reconfigured to work as a slave.
        /// </summary>
        Task MakeMaster();

        /// <summary>
        /// Flush the Lua scripts cache; this can damage existing connections that expect the flush to behave normally, and should be used with caution.
        /// </summary>
        /// <remarks>http://redis.io/commands/script-flush</remarks>
        Task FlushScriptCache();
        /// <summary>
        /// The CLIENT LIST command returns information and statistics about the client connections server in a mostly human readable format.
        /// </summary>
        /// <remarks>http://redis.io/commands/client-list</remarks>
        Task<ClientInfo[]> ListClients();

        /// <summary>
        /// The CLIENT KILL command closes a given client connection identified by ip:port.
        /// </summary>
        /// <remarks>http://redis.io/commands/client-kill</remarks>
        Task KillClient(string address);

        /// <summary>
        /// The INFO command returns information and statistics about the server in a format that is simple to parse by computers and easy to read by humans.
        /// </summary>
        /// <remarks>http://redis.io/commands/info</remarks>
        Task<Dictionary<string, string>> GetInfo(string section = null, bool queueJump = false);

        /// <summary>
        /// Serialize the value stored at key in a Redis-specific format and return it to the user. The returned value can be synthesized back into a Redis key using the RESTORE command.
        /// The serialization format is opaque and non-standard. The serialized value does NOT contain expire information. In order to capture the time to live of the current value the PTTL command should be used.
        /// </summary>
        /// <remarks>http://redis.io/commands/dump</remarks>
        Task<byte[]> Export(int db, string key);

        /// <summary>
        /// Create a key associated with a value that is obtained by deserializing the provided serialized value (obtained via Export).
        /// </summary>
        /// <remarks>http://redis.io/commands/restore</remarks>
        Task Import(int db, string key, byte[] exportedData, int? timeoutMilliseconds = null);
    }
    partial class RedisConnection : IServerCommands
    {
        /// <summary>
        /// Commands related to server operation and configuration, rather than data.
        /// </summary>
        /// <remarks>http://redis.io/commands#server</remarks>
        public IServerCommands Server
        {
            get { return this; }
        }

        void CheckAdmin()
        {
            if (!allowAdmin) throw new InvalidOperationException("This command is not available unless the connection is created with admin-commands enabled");
        }

        /// <summary>
        /// Delete all the keys of the currently selected DB.
        /// </summary>
        [Obsolete("Please use the Server API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task FlushDb(int db)
        {
            return Server.FlushDb(db);
        }
        Task IServerCommands.FlushDb(int db)
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.FLUSHDB).ExpectOk().Critical(), false);
        }

        Task<Dictionary<string, string>> IServerCommands.GetInfo(string section, bool queueJump)
        {
            var msg = string.IsNullOrEmpty(section) ? RedisMessage.Create(-1, RedisLiteral.INFO) : RedisMessage.Create(-1, RedisLiteral.INFO, section);
            var source = new TaskCompletionSource<Dictionary<string, string>>();
            ExecuteString(msg, queueJump, source).ContinueWith(getInfoCallback);
            return source.Task;
        }
        static readonly Action<Task<string>> getInfoCallback = task =>
        {
            var state = (TaskCompletionSource<Dictionary<string, string>>)task.AsyncState;
            if (task.ShouldSetResult(state)) state.TrySetResult(RedisConnectionBase.ParseInfo(task.Result));
        };

        Task IServerCommands.FlushScriptCache()
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.SCRIPT, RedisLiteral.FLUSH).ExpectOk(), false);
        }

        Task IServerCommands.KillClient(string address)
        {
            if (string.IsNullOrEmpty(address)) throw new ArgumentNullException("address");
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.CLIENT, RedisLiteral.KILL, address).ExpectOk(), false);
        }
        Task<ClientInfo[]> IServerCommands.ListClients()
        {
            CheckAdmin();
            TaskCompletionSource<ClientInfo[]> result = new TaskCompletionSource<ClientInfo[]>();
            ExecuteString(RedisMessage.Create(-1, RedisLiteral.CLIENT, RedisLiteral.LIST), false, result).ContinueWith(listClientsCallback);
            return result.Task;
        }
        static readonly Action<Task<string>> listClientsCallback = task =>
        {
            var result = (TaskCompletionSource<ClientInfo[]>)task.AsyncState;
            if (task.ShouldSetResult(result)) try
            {
                result.TrySetResult(ClientInfo.Parse(task.Result));
            }
            catch (Exception ex) { result.SafeSetException(ex); }
        };

        /// <summary>
        /// Delete all the keys of all the existing databases, not just the currently selected one.
        /// </summary>
        [Obsolete("Please use the Server API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task FlushAll()
        {
            return Server.FlushAll();
        }

        Task IServerCommands.FlushAll()
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.FLUSHALL).ExpectOk().Critical(), false);
        }

        Task IServerCommands.MakeMaster()
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.SLAVEOF, RedisLiteral.NO, RedisLiteral.ONE).ExpectOk().Critical(), false);
        }
        Task IServerCommands.MakeSlave(string host, int port)
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.SLAVEOF, host, port).ExpectOk().Critical(), false);
        }

        Task<byte[]> IServerCommands.Export(int db, string key)
        {
            CheckAdmin();
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.DUMP, key), false);
        }


        Task IServerCommands.Import(int db, string key, byte[] exportedData, int? timeoutMilliseconds)
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.RESTORE, key, timeoutMilliseconds.GetValueOrDefault(), exportedData).ExpectOk(), false);
        }

        /// <summary>
        /// This command is often used to test if a connection is still alive, or to measure latency.
        /// </summary>
        /// <returns>The latency in milliseconds.</returns>
        /// <remarks>http://redis.io/commands/ping</remarks>
        [Obsolete("Please use the Server API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task Ping(bool queueJump = false)
        {
            return Server.Ping(queueJump);
        }

        Task IServerCommands.Ping(bool queueJump)
        {
            return base.PingImpl(queueJump, duringInit: false);
        }

        Task<DateTime> IServerCommands.Time(bool queueJump)
        {
            var source = new TaskCompletionSource<DateTime>();
            ExecuteMultiString(RedisMessage.Create(-1, RedisLiteral.TIME), queueJump, source).ContinueWith(timeCallback);
            return source.Task;
        }
        static readonly Action<Task<string[]>> timeCallback = task =>
        {
            var state = (TaskCompletionSource<DateTime>)task.AsyncState;
            if (task.ShouldSetResult(state))
            {
                long timestamp = int.Parse(task.Result[0], CultureInfo.InvariantCulture),
                    micros = int.Parse(task.Result[1], CultureInfo.InvariantCulture);

                // unix timestamp is in UTC time
                var time = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddSeconds(timestamp).AddTicks(micros * 10); // datetime ticks are 100ns

                state.TrySetResult(time);
            }
        };

        Task<Dictionary<string, string>> IServerCommands.GetConfig(string pattern)
        {
            return GetConfigImpl(pattern, false);
        }

        internal Task<Dictionary<string, string>> GetConfigImpl(string pattern, bool isInit)
        {
            if (string.IsNullOrEmpty(pattern)) pattern = "*";
            var msg = RedisMessage.Create(-1, RedisLiteral.CONFIG, RedisLiteral.GET, pattern);
            if (isInit) msg.DuringInit();
            return ExecuteStringPairs(msg, false);
        }

        Task IServerCommands.SetConfig(string name, string value)
        {
            CheckAdmin();
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.CONFIG, RedisLiteral.SET, name, value).ExpectOk(), false);
        }
    }
}
