
using System.Threading.Tasks;
using System.Collections.Generic;
using System;
using System.ComponentModel;
namespace BookSleeve
{
    /// <summary>
    /// Commands that apply to key/sub-key/value tuples, i.e. where
    /// the item is a dictionary of inner values. This can be useful for
    /// modelling members of an entity, for example.
    /// </summary>
    /// <remarks>http://redis.io/commands#hash</remarks>
    public interface IHashCommands
    {
        /// <summary>
        /// Removes the specified fields from the hash stored at key. Non-existing fields are ignored. Non-existing keys are treated as empty hashes and this command returns 0.
        /// </summary>
        /// <remarks>http://redis.io/commands/hdel</remarks>
        /// <returns>The number of fields that were removed.</returns>
        Task<bool> Remove(int db, string key, string field, bool queueJump = false);
        /// <summary>
        /// Removes the specified fields from the hash stored at key. Non-existing fields are ignored. Non-existing keys are treated as empty hashes and this command returns 0.
        /// </summary>
        /// <remarks>http://redis.io/commands/hdel</remarks>
        /// <returns>The number of fields that were removed.</returns>
        Task<long> Remove(int db, string key, string[] fields, bool queueJump = false);
        /// <summary>
        /// Returns if field is an existing field in the hash stored at key.
        /// </summary>
        /// <returns>1 if the hash contains field. 0 if the hash does not contain field, or key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hexists</remarks>
        Task<bool> Exists(int db, string key, string field, bool queueJump = false);

        /// <summary>
        /// Returns the value associated with field in the hash stored at key.
        /// </summary>
        /// <returns>the value associated with field, or nil when field is not present in the hash or key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hget</remarks>
        Task<string> GetString(int db, string key, string field, bool queueJump = false);
        /// <summary>
        /// Returns the value associated with field in the hash stored at key.
        /// </summary>
        /// <returns>the value associated with field, or nil when field is not present in the hash or key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hget</remarks>
        Task<long?> GetInt64(int db, string key, string field, bool queueJump = false);
        /// <summary>
        /// Returns the value associated with field in the hash stored at key.
        /// </summary>
        /// <returns>the value associated with field, or nil when field is not present in the hash or key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hget</remarks>
        Task<byte[]> Get(int db, string key, string field, bool queueJump = false);
        /// <summary>
        /// Returns the values associated with the specified fields in the hash stored at key. For every field that does not exist in the hash, a nil value is returned.
        /// </summary>
        /// <returns>list of values associated with the given fields, in the same order as they are requested.</returns>
        /// <remarks>http://redis.io/commands/hmget</remarks>
        Task<string[]> GetString(int db, string key, string[] fields, bool queueJump = false);
        /// <summary>
        /// Returns the values associated with the specified fields in the hash stored at key. For every field that does not exist in the hash, a nil value is returned.
        /// </summary>
        /// <returns>list of values associated with the given fields, in the same order as they are requested.</returns>
        /// <remarks>http://redis.io/commands/hmget</remarks>
        Task<byte[][]> Get(int db, string key, string[] fields, bool queueJump = false);

        /// <summary>
        /// Returns all fields and values of the hash stored at key. 
        /// </summary>
        /// <returns>list of fields and their values stored in the hash, or an empty list when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hgetall</remarks>
        Task<Dictionary<string, byte[]>> GetAll(int db, string key, bool queueJump = false);

        /// <summary>
        /// Increments the number stored at field in the hash stored at key by increment. If key does not exist, a new key holding a hash is created. If field does not exist or holds a string that cannot be interpreted as integer, the value is set to 0 before the operation is performed.
        /// </summary>
        /// <remarks>The range of values supported by HINCRBY is limited to 64 bit signed integers.</remarks>
        /// <returns>the value at field after the increment operation.</returns>
        /// <remarks>http://redis.io/commands/hincrby</remarks>
        Task<long> Increment(int db, string key, string field, int value = 1, bool queueJump = false);
        /// <summary>
        /// Increments the number stored at field in the hash stored at key by increment. If key does not exist, a new key holding a hash is created. If field does not exist or holds a string that cannot be interpreted as integer, the value is set to 0 before the operation is performed.
        /// </summary>
        /// <remarks>The range of values supported by HINCRBY is limited to 64 bit signed integers.</remarks>
        /// <returns>the value at field after the increment operation.</returns>
        /// <remarks>http://redis.io/commands/hincrby</remarks>
        Task<double> Increment(int db, string key, string field, double value, bool queueJump = false);

        /// <summary>
        /// Returns all field names in the hash stored at key.
        /// </summary>
        /// <returns>list of fields in the hash, or an empty list when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hkeys</remarks>
        Task<string[]> GetKeys(int db, string key, bool queueJump = false);
        /// <summary>
        /// Returns all values in the hash stored at key.
        /// </summary>
        /// <returns>list of values in the hash, or an empty list when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hvals</remarks>
        Task<byte[][]> GetValues(int db, string key, bool queueJump = false);

        /// <summary>
        /// Returns the number of fields contained in the hash stored at key.
        /// </summary>
        /// <returns>number of fields in the hash, or 0 when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/hlen</remarks>
        Task<long> GetLength(int db, string key, bool queueJump = false);

        /// <summary>
        /// Sets field in the hash stored at key to value. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and the value was updated.</returns>
        /// <remarks>http://redis.io/commands/hset</remarks>
        Task<bool> Set(int db, string key, string field, string value, bool queueJump = false);
        /// <summary>
        /// Sets field in the hash stored at key to value. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and the value was updated.</returns>
        /// <remarks>http://redis.io/commands/hset</remarks>
        Task<bool> Set(int db, string key, string field, byte[] value, bool queueJump = false);
        /// <summary>
        /// Sets the specified fields to their respective values in the hash stored at key. This command overwrites any existing fields in the hash. If key does not exist, a new key holding a hash is created.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and the value was updated.</returns>
        /// <remarks>http://redis.io/commands/hmset</remarks>
        Task Set(int db, string key, Dictionary<string, byte[]> values, bool queueJump = false);
        /// <summary>
        /// Sets field in the hash stored at key to value, only if field does not yet exist. If key does not exist, a new key holding a hash is created. If field already exists, this operation has no effect.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and no operation was performed.</returns>
        /// <remarks>http://redis.io/commands/hsetnx</remarks>
        Task<bool> SetIfNotExists(int db, string key, string field, string value, bool queueJump = false);
        /// <summary>
        /// Sets field in the hash stored at key to value, only if field does not yet exist. If key does not exist, a new key holding a hash is created. If field already exists, this operation has no effect.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and no operation was performed.</returns>
        /// <remarks>http://redis.io/commands/hsetnx</remarks>
        Task<bool> SetIfNotExists(int db, string key, string field, byte[] value, bool queueJump = false);
    }

    partial class RedisConnection : IHashCommands
    {
        /// <summary>
        /// Enumerate all keys in a hash.
        /// </summary>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[][]> GetHash(int db, string key, bool queueJump = false)
        {
            
            return ExecuteMultiBytes(RedisMessage.Create(db, RedisLiteral.HGETALL, key), queueJump);
        }

        /// <summary>
        /// Returns all fields and values of the hash stored at key.
        /// </summary>
        /// <returns>list of fields and their values stored in the hash, or an empty list when key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<Dictionary<string, byte[]>> GetHashPairs(int db, string key, bool queueJump = false)
        {
            return Hashes.GetAll(db, key, queueJump);
        }
        Task<Dictionary<string, byte[]>> IHashCommands.GetAll(int db, string key, bool queueJump)
        {
            

            return ExecuteHashPairs(RedisMessage.Create(db, RedisLiteral.HGETALL, key), queueJump);
        }

        /// <summary>
        /// Increment a field on a hash by an amount (1 by default)
        /// </summary>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> IncrementHash(int db, string key, string field, int value = 1, bool queueJump = false)
        {
            return Hashes.Increment(db, key, field, value, queueJump);
        }
        Task<long> IHashCommands.Increment(int db, string key, string field, int value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.HINCRBY, key, field, value), queueJump);
        }
        Task<double> IHashCommands.Increment(int db, string key, string field, double value, bool queueJump)
        {
            return ExecuteDouble(RedisMessage.Create(db, RedisLiteral.HINCRBYFLOAT, key, field, value), queueJump);
        }

        /// <summary>
        /// Sets field in the hash stored at key to value. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and the value was updated.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> SetHash(int db, string key, string field, string value, bool queueJump = false)
        {
            return Hashes.Set(db, key, field, value, queueJump);
        }
        Task<bool> IHashCommands.Set(int db, string key, string field, string value, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.HSET, key, field, value), queueJump);
        }
        /// <summary>
        /// Sets the specified fields to their respective values in the hash stored at key. This command overwrites any existing fields in the hash. If key does not exist, a new key holding a hash is created.
        /// </summary>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task SetHash(int db, string key, Dictionary<string, byte[]> values, bool queueJump = false)
        {
            return Hashes.Set(db, key, values, queueJump);
        }
        Task IHashCommands.Set(int db, string key, Dictionary<string, byte[]> values, bool queueJump)
        {
            
            var keyAndFields = new RedisMessage.RedisParameter[(values.Count * 2) + 1];
            int index = 0;
            keyAndFields[index++] = key;
            foreach (var pair in values)
            {
                keyAndFields[index++] = pair.Key;
                keyAndFields[index++] = pair.Value;
            }
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.HMSET, keyAndFields), queueJump);
        }
        /// <summary>
        /// Sets field in the hash stored at key to value. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and the value was updated.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> SetHash(int db, string key, string field, byte[] value, bool queueJump = false)
        {
            return Hashes.Set(db, key, field, value, queueJump);
        }
        Task<bool> IHashCommands.Set(int db, string key, string field, byte[] value, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.HSET, key, field, value), queueJump);
        }
        /// <summary>
        /// Sets field in the hash stored at key to value, only if field does not yet exist. If key does not exist, a new key holding a hash is created. If field already exists, this operation has no effect.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and no operation was performed.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> SetHashIfNotExists(int db, string key, string field, string value, bool queueJump = false)
        {
            return Hashes.SetIfNotExists(db, key, field, value, queueJump);
        }
        Task<bool> IHashCommands.SetIfNotExists(int db, string key, string field, string value, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.HSETNX, key, field, value), queueJump);
        }
        /// <summary>
        /// Sets field in the hash stored at key to value, only if field does not yet exist. If key does not exist, a new key holding a hash is created. If field already exists, this operation has no effect.
        /// </summary>
        /// <returns>1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and no operation was performed.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> SetHashIfNotExists(int db, string key, string field, byte[] value, bool queueJump = false)
        {
            return Hashes.SetIfNotExists(db, key, field, value, queueJump);
        }
        Task<bool> IHashCommands.SetIfNotExists(int db, string key, string field, byte[] value, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.HSETNX, key, field, value), queueJump);
        }
        /// <summary>
        /// Returns the value associated with field in the hash stored at key.
        /// </summary>
        /// <returns>the value associated with field, or nil when field is not present in the hash or key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string> GetFromHashString(int db, string key, string field, bool queueJump = false)
        {
            return Hashes.GetString(db, key, field, queueJump);
        }
        Task<string> IHashCommands.GetString(int db, string key, string field, bool queueJump)
        {
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.HGET, key, field), queueJump);
        }
        Task<long?> IHashCommands.GetInt64(int db, string key, string field, bool queueJump)
        {
            return ExecuteNullableInt64(RedisMessage.Create(db, RedisLiteral.HGET, key, field), queueJump);
        }
        /// <summary>
        /// Returns the value associated with field in the hash stored at key.
        /// </summary>
        /// <returns>the value associated with field, or nil when field is not present in the hash or key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[]> GetFromHash(int db, string key, string field, bool queueJump = false)
        {
            return Hashes.Get(db, key, field, queueJump);
        }
        Task<byte[]> IHashCommands.Get(int db, string key, string field, bool queueJump)
        {
            
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.HGET, key, field), queueJump);
        }

        /// <summary>
        /// Returns the values associated with the specified fields in the hash stored at key. For every field that does not exist in the hash, a nil value is returned.
        /// </summary>
        /// <returns>list of values associated with the given fields, in the same order as they are requested.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string[]> GetFromHashString(int db, string key, string[] fields, bool queueJump = false)
        {
            return Hashes.GetString(db, key, fields, queueJump);
        }
        Task<string[]> IHashCommands.GetString(int db, string key, string[] fields, bool queueJump)
        {
            
            return ExecuteMultiString(RedisMessage.Create(db, RedisLiteral.HMGET, key, fields), queueJump);
        }
        /// <summary>
        /// Returns the values associated with the specified fields in the hash stored at key. For every field that does not exist in the hash, a nil value is returned.
        /// </summary>
        /// <returns>list of values associated with the given fields, in the same order as they are requested.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[][]> GetFromHash(int db, string key, string[] fields, bool queueJump = false)
        {
            return Hashes.Get(db, key, fields, queueJump);
        }
        Task<byte[][]> IHashCommands.Get(int db, string key, string[] fields, bool queueJump)
        {
            
            return ExecuteMultiBytes(RedisMessage.Create(db, RedisLiteral.HMGET, key, fields), queueJump);
        }

        /// <summary>
        /// Removes the specified field from the hash stored at key. Non-existing fields are ignored. Non-existing keys are treated as empty hashes and this command returns 0.
        /// </summary>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> RemoveHash(int db, string key, string field, bool queueJump = false)
        {
            return Hashes.Remove(db, key, field, queueJump);
        }
        Task<bool> IHashCommands.Remove(int db, string key, string field, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.HDEL, key, field), queueJump);
        }
        /// <summary>
        /// Removes the specified fields from the hash stored at key. Non-existing fields are ignored. Non-existing keys are treated as empty hashes and this command returns 0.
        /// </summary>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> RemoveHash(int db, string key, string[] fields, bool queueJump = false)
        {
            return Hashes.Remove(db, key, fields, queueJump);
        }
        Task<long> IHashCommands.Remove(int db, string key, string[] fields, bool queueJump)
        {
            

            RedisFeatures features;
            if (fields.Length > 1 && ((features = Features) == null || !features.HashVaradicDelete))
            {
                RedisTransaction tran = this as RedisTransaction;
                bool execute = false;
                if (tran == null)
                {
                    tran = CreateTransaction();
                    execute = true;
                }
                Task<bool>[] tasks = new Task<bool>[fields.Length];

                var hashes = tran.Hashes;
                for (int i = 0; i < fields.Length; i++)
                {
                    tasks[i] = hashes.Remove(db, key, fields[i], queueJump);
                }
                TaskCompletionSource<long> final = new TaskCompletionSource<long>();
                tasks[fields.Length - 1].ContinueWith(t =>
                {
                    
                    try
                    {
                        if (t.ShouldSetResult(final))
                        {
                            long count = 0;
                            for (int i = 0; i < tasks.Length; i++)
                            {
                                if (tran.Wait(tasks[i]))
                                {
                                    count++;
                                }
                            }
                            final.TrySetResult(count);
                        }
                    }
                    catch (Exception ex)
                    {
                        final.SafeSetException(ex);
                    }
                });
                if (execute) tran.Execute(queueJump);
                return final.Task;
            }
            else
            {
                return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.HDEL, key, fields), queueJump);
            }
        }

        /// <summary>
        /// Returns if field is an existing field in the hash stored at key.
        /// </summary>
        /// <returns>1 if the hash contains field. 0 if the hash does not contain field, or key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> ContainsHash(int db, string key, string field, bool queueJump = false)
        {
            return Hashes.Exists(db, key, field, queueJump);
        }
        Task<bool> IHashCommands.Exists(int db, string key, string field, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.HEXISTS, key, field), queueJump);
        }

        /// <summary>
        /// Returns all field names in the hash stored at key.
        /// </summary>
        /// <returns>list of fields in the hash, or an empty list when key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string[]> GetHashKeys(int db, string key, bool queueJump = false)
        {
            return Hashes.GetKeys(db, key, queueJump);
        }
        Task<string[]> IHashCommands.GetKeys(int db, string key, bool queueJump)
        {
            
            return ExecuteMultiString(RedisMessage.Create(db, RedisLiteral.HKEYS, key), queueJump);
        }

        /// <summary>
        /// Returns all values in the hash stored at key.
        /// </summary>
        /// <returns> list of values in the hash, or an empty list when key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[][]> GetHashValues(int db, string key, bool queueJump = false)
        {
            return Hashes.GetValues(db, key, queueJump);
        }
        Task<byte[][]> IHashCommands.GetValues(int db, string key, bool queueJump)
        {
            
            return ExecuteMultiBytes(RedisMessage.Create(db, RedisLiteral.HVALS, key), queueJump);
        }
        /// <summary>
        /// Returns the number of fields contained in the hash stored at key.
        /// </summary>
        /// <returns>number of fields in the hash, or 0 when key does not exist.</returns>
        [Obsolete("Please use the Hashes API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> GetHashLength(int db, string key, bool queueJump = false)
        {
            return Hashes.GetLength(db, key, queueJump);
        }
        Task<long> IHashCommands.GetLength(int db, string key, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.HLEN, key), queueJump);
        }


        /// <summary>
        /// Commands that apply to key/sub-key/value tuples, i.e. where
        /// the item is a dictionary of inner values. This can be useful for
        /// modelling members of an entity, for example.
        /// </summary>
        /// <remarks>http://redis.io/commands#hash</remarks>
        public IHashCommands Hashes
        {
            get { return this; }
        }
    }
}
