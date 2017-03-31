using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Generic commands that apply to all/most data structures
    /// </summary>
    /// <remarks>http://redis.io/commands#generic</remarks>
    public interface IKeyCommands
    {
        /// <summary>
        /// Removes the specified key. A key is ignored if it does not exist.
        /// </summary>
        /// <returns>True if the key was removed.</returns>
        /// <remarks>http://redis.io/commands/del</remarks>
        Task<bool> Remove(int db, string key, bool queueJump = false);
        /// <summary>
        /// Removes the specified keys. A key is ignored if it does not exist.
        /// </summary>
        /// <returns>The number of keys that were removed.</returns>
        /// <remarks>http://redis.io/commands/del</remarks>
        Task<long> Remove(int db, string[] keys, bool queueJump = false);
        /// <summary>
        /// Returns if key exists.
        /// </summary>
        /// <returns>1 if the key exists. 0 if the key does not exist.</returns>
        /// <remarks>http://redis.io/commands/exists</remarks>
        Task<bool> Exists(int db, string key, bool queueJump = false);
        /// <summary>
        /// Set a timeout on key. After the timeout has expired, the key will automatically be deleted. A key with an associated timeout is said to be volatile in Redis terminology.
        /// </summary>
        /// <remarks>If key is updated before the timeout has expired, then the timeout is removed as if the PERSIST command was invoked on key.
        /// For Redis versions &lt; 2.1.3, existing timeouts cannot be overwritten. So, if key already has an associated timeout, it will do nothing and return 0. Since Redis 2.1.3, you can update the timeout of a key. It is also possible to remove the timeout using the PERSIST command. See the page on key expiry for more information.</remarks>
        /// <returns>1 if the timeout was set. 0 if key does not exist or the timeout could not be set.</returns>
        /// <remarks>http://redis.io/commands/expire</remarks>
        Task<bool> Expire(int db, string key, int seconds, bool queueJump = false);
        /// <summary>
        /// Remove the existing timeout on key.
        /// </summary>
        /// <returns>1 if the timeout was removed. 0 if key does not exist or does not have an associated timeout.</returns>
        /// <remarks>Available with 2.1.2 and above only</remarks>
        /// <remarks>http://redis.io/commands/persist</remarks>
        Task<bool> Persist(int db, string key, bool queueJump = false);
        /// <summary>
        /// Returns all keys matching pattern.
        /// </summary>
        /// <remarks>Warning: consider KEYS as a command that should only be used in production environments with extreme care. It may ruin performance when it is executed against large databases. This command is intended for debugging and special operations, such as changing your keyspace layout. Don't use KEYS in your regular application code. If you're looking for a way to find keys in a subset of your keyspace, consider using sets.</remarks>
        /// <remarks>http://redis.io/commands/keys</remarks>
        Task<string[]> Find(int db, string pattern, bool queueJump = false);
        /// <summary>
        /// Move key from the currently selected database (see SELECT) to the specified destination database. When key already exists in the destination database, or it does not exist in the source database, it does nothing. It is possible to use MOVE as a locking primitive because of this.
        /// </summary>
        /// <returns>1 if key was moved. 0 if key was not moved.</returns>
        /// <remarks>http://redis.io/commands/move</remarks>
        Task<bool> Move(int db, string key, int targetDb, bool queueJump = false);
        /// <summary>
        /// Return a random key from the currently selected database.
        /// </summary>
        /// <returns>the random key, or nil when the database is empty.</returns>
        /// <remarks>http://redis.io/commands/randomkey</remarks>
        Task<string> Random(int db, bool queueJump = false);

        /// <summary>
        /// Renames key to newkey. It returns an error when the source and destination names are the same, or when key does not exist. If newkey already exists it is overwritten.
        /// </summary>
        /// <remarks>http://redis.io/commands/rename</remarks>
        Task Rename(int db, string fromKey, string toKey, bool queueJump = false);


        /// <summary>
        /// Renames key to newkey if newkey does not yet exist. It returns an error under the same conditions as RENAME.
        /// </summary>
        /// <returns>1 if key was renamed to newkey. 0 if newkey already exists.</returns>
        /// <remarks>http://redis.io/commands/renamenx</remarks>
        Task<bool> RenameIfNotExists(int db, string fromKey, string toKey, bool queueJump = false);

        /// <summary>
        /// Returns the remaining time to live (seconds) of a key that has a timeout.  This introspection capability allows a Redis client to check how many seconds a given key will continue to be part of the dataset.
        /// </summary>
        /// <returns>TTL in seconds or -1 when key does not exist or does not have a timeout.</returns>
        /// <remarks>http://redis.io/commands/ttl</remarks>
        Task<long> TimeToLive(int db, string key, bool queueJump = false);

        /// <summary>
        /// Returns the string representation of the type of the value stored at key. The different types that can be returned are: string, list, set, zset and hash.
        /// </summary>
        /// <returns> type of key, or none when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/type</remarks>
        Task<string> Type(int db, string key, bool queueJump = false);

        /// <summary>
        /// Return the number of keys in the currently selected database.
        /// </summary>
        /// <remarks>http://redis.io/commands/dbsize</remarks>
        Task<long> GetLength(int db, bool queueJump = false);

        /// <summary>
        /// Returns or stores the elements contained in the list, set or sorted set at key. By default, sorting is numeric and elements are compared by their value interpreted as double precision floating point number. 
        /// </summary>
        /// <remarks>http://redis.io/commands/sort</remarks>
        Task<string[]> SortString(int db, string key, string byPattern = null, string[] getPattern = null,
                    long offset = 0, long count = -1, bool alpha = false, bool ascending = true, bool queueJump = false);

        /// <summary>
        /// Returns or stores the elements contained in the list, set or sorted set at key. By default, sorting is numeric and elements are compared by their value interpreted as double precision floating point number. 
        /// </summary>
        /// <remarks>http://redis.io/commands/sort</remarks>
        Task<long> SortAndStore(int db, string destination, string key, string byPattern = null, string[] getPattern = null,
                    long offset = 0, long count = -1, bool alpha = false, bool ascending = true, bool queueJump = false);


        /// <summary>
        /// Returns the raw DEBUG OBJECT output for a key; this command is not fully documented and should be avoided unless you have good reason, and then avoided anyway.
        /// </summary>
        /// <remarks>http://redis.io/commands/debug-object</remarks>
        Task<string> DebugObject(int db, string key);
    }

    partial class RedisConnection : IKeyCommands
    {
        /// <summary>
        /// Generic commands that apply to all/most data structures
        /// </summary>
        /// <remarks>http://redis.io/commands#generic</remarks>
        public IKeyCommands Keys
        {
            get { return this; }
        }

        /// <summary>
        /// Removes a key from the database.</summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> Remove(int db, string key, bool queueJump = false)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.DEL, key), queueJump);
        }
        /// <summary>
        /// Removes multiple keys from the database.</summary>
        [Obsolete("Please use the Keys API",false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> Remove(int db, string[] keys, bool queueJump = false)
        {
            
            return ExecuteInt64((keys.Length == 1 ? RedisMessage.Create(db, RedisLiteral.DEL, keys[0]) : RedisMessage.Create(db, RedisLiteral.DEL, keys)), queueJump);
        }
        /// <summary>
        /// Returns if key exists.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> ContainsKey(int db, string key, bool queueJump = false)
        {
            return Keys.Exists(db, key, queueJump);
        }
        Task<bool> IKeyCommands.Exists(int db, string key, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.EXISTS, key), queueJump);
        }

        /// <summary>
        /// Set a timeout on key. After the timeout has expired, the key will automatically be deleted. A key with an associated timeout is said to be volatile in Redis terminology.
        /// </summary>
        [Obsolete("Please use the Keys API",false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> Expire(int db, string key, int seconds, bool queueJump = false)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.EXPIRE, key, seconds), queueJump);
        }

        /// <summary>
        /// Remove the existing timeout on key.
        /// </summary>
        [Obsolete("Please use the Keys API",false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> Persist(int db, string key, bool queueJump = false)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.PERSIST, key), queueJump);
        }
        /// <summary>
        /// Returns all keys matching pattern.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string[]> GetKeysSync(int db, string pattern, bool queueJump = false)
        {
            return Keys.Find(db, pattern, queueJump);
        }
        /// <summary>
        /// Returns all keys matching pattern.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string[]> GetKeys(int db, string pattern, bool queueJump = false)
        {
            return Keys.Find(db, pattern, queueJump);
        }
        Task<string[]> IKeyCommands.Find(int db, string pattern, bool queueJump)
        {
            
            return ExecuteMultiString(RedisMessage.Create(db, RedisLiteral.KEYS, pattern), queueJump);
        }

        /// <summary>
        /// Move key from the currently selected database to the specified destination database.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> Move(int db, string key, int targetDb, bool queueJump = false)
        {
            if (targetDb < 0) throw new ArgumentOutOfRangeException("targetDb");
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.MOVE, key, targetDb), queueJump);
        }


        /// <summary>
        /// Return a random key from the currently selected database.
        /// </summary>
        /// <returns>the random key, or nil when the database is empty.</returns>
        /// <remarks>http://redis.io/commands/randomkey</remarks>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string> RandomKey(int db, bool queueJump = false)
        {
            return Keys.Random(db, queueJump);
        }
        Task<string> IKeyCommands.Random(int db, bool queueJump)
        {
            
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.RANDOMKEY), queueJump);
        }

        /// <summary>
        /// Renames a key in the database, overwriting any existing value; the source key must exist and be different to the destination.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task Rename(int db, string fromKey, string toKey, bool queueJump = false)
        {
            
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.RENAME, fromKey, toKey).ExpectOk(), queueJump);
        }


        /// <summary>
        /// Renames a key in the database, overwriting any existing value; the source key must exist and be different to the destination.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> RenameIfNotExists(int db, string fromKey, string toKey, bool queueJump = false)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.RENAMENX, fromKey, toKey), queueJump);
        }
        /// <summary>
        /// Returns the remaining time to live (seconds) of a key that has a timeout.
        /// </summary>
        [Obsolete("Please use the Keys API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> TimeToLive(int db, string key, bool queueJump = false)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.TTL, key), queueJump);
        }

        Task<string> IKeyCommands.Type(int db, string key, bool queueJump)
        {
            
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.TYPE, key), queueJump);
        }

        Task<long> IKeyCommands.GetLength(int db, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.DBSIZE), queueJump);
        }

        Task<string> IKeyCommands.DebugObject(int db, string key)
        {
            CheckAdmin();
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.DEBUG, RedisLiteral.OBJECT, key), false);
        }

        static RedisMessage CreateSortMessage(int db, string key, string byPattern, string[] getPattern,
                    long offset, long count, bool alpha, bool ascending, string storeKey)
        {
            var items = new List<RedisMessage.RedisParameter> { key };

            if (!string.IsNullOrEmpty(byPattern))
            {
                items.Add(RedisLiteral.BY);
                items.Add(byPattern);
            }

            if (offset != 0 || (count != -1 && count != long.MaxValue))
            {
                items.Add(RedisLiteral.LIMIT);
                items.Add(offset);
                items.Add(count);
            }

            if (getPattern != null)
            {
                foreach (var pattern in getPattern)
                {
                    if (!string.IsNullOrEmpty(pattern))
                    {
                        items.Add(RedisLiteral.GET);
                        items.Add(pattern);
                    }
                }
            }

            if (!ascending) items.Add(RedisLiteral.DESC);
            if (alpha) items.Add(RedisLiteral.ALPHA);

            if (!string.IsNullOrEmpty(storeKey))
            {
                items.Add(RedisLiteral.STORE);
                items.Add(storeKey);
            }
            return RedisMessage.Create(db, RedisLiteral.SORT, items.ToArray());
        }

        Task<string[]> IKeyCommands.SortString(int db, string key, string byPattern, string[] getPattern,
                    long offset, long count, bool alpha, bool ascending, bool queueJump)
        {
            var msg = CreateSortMessage(db, key, byPattern, getPattern, offset, count, alpha, ascending, null);
            return ExecuteMultiString(msg, queueJump);
        }
        Task<long> IKeyCommands.SortAndStore(int db, string destination, string key, string byPattern, string[] getPattern,
                    long offset, long count, bool alpha, bool ascending, bool queueJump)
        {
            var msg = CreateSortMessage(db, key, byPattern, getPattern, offset, count, alpha, ascending, destination);
            return ExecuteInt64(msg, queueJump);
        }
    }
}
