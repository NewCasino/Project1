
using System.Threading.Tasks;
using System.Collections.Generic;
using System.ComponentModel;
using System;
namespace BookSleeve
{
    /// <summary>
    /// Commands that apply to key/value pairs, where the value
    /// can be a string, a BLOB, or interpreted as a number
    /// </summary>
    /// <remarks>http://redis.io/commands#string</remarks>
    public interface IStringCommands
    {
        /// <summary>
        /// If key already exists and is a string, this command appends the value at the end of the string. If key does not exist it is created and set as an empty string, so APPEND will be similar to SET in this special case.
        /// </summary>
        /// <returns>the length of the string after the append operation.</returns>
        /// <remarks>http://redis.io/commands/append</remarks>
        Task<long> Append(int db, string key, string value, bool queueJump = false);

        /// <summary>
        /// If key already exists and is a string, this command appends the value at the end of the string. If key does not exist it is created and set as an empty string, so APPEND will be similar to SET in this special case.
        /// </summary>
        /// <returns>the length of the string after the append operation.</returns>
        /// <remarks>http://redis.io/commands/append</remarks>
        Task<long> Append(int db, string key, byte[] value, bool queueJump = false);

        /// <summary>
        /// Decrements the number stored at key by decrement. If the key does not exist, it is set to 0 before performing the operation. An error is returned if the key contains a value of the wrong type or contains a string that is not representable as integer. This operation is limited to 64 bit signed integers.
        /// </summary>
        /// <returns> the value of key after the increment</returns>
        /// <remarks>http://redis.io/commands/decrby</remarks>
        /// <remarks>http://redis.io/commands/decr</remarks>
        Task<long> Decrement(int db, string key, long value = 1, bool queueJump = false);

        /// <summary>
        /// Increments the number stored at key by increment. If the key does not exist, it is set to 0 before performing the operation. An error is returned if the key contains a value of the wrong type or contains a string that is not representable as integer. This operation is limited to 64 bit signed integers.
        /// </summary>
        /// <returns> the value of key after the increment</returns>
        /// <remarks>http://redis.io/commands/incrby</remarks>
        /// <remarks>http://redis.io/commands/incr</remarks>
        Task<long> Increment(int db, string key, long value = 1, bool queueJump = false);

        /// <summary>
        /// Increments the number stored at key by increment. If the key does not exist, it is set to 0 before performing the operation. An error is returned if the key contains a value of the wrong type or contains a string that is not representable as integer. This operation is limited to 64 bit signed integers.
        /// </summary>
        /// <returns> the value of key after the increment</returns>
        /// <remarks>http://redis.io/commands/incrbyfloat</remarks>
        Task<double> Increment(int db, string key, double value, bool queueJump = false);

        /// <summary>
        /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
        /// </summary>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/get</remarks>
        Task<byte[]> Get(int db, string key, bool queueJump = false);

        /// <summary>
        /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
        /// </summary>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/get</remarks>
        Task<string> GetString(int db, string key, bool queueJump = false);

        /// <summary>
        /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
        /// </summary>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/get</remarks>
        Task<long?> GetInt64(int db, string key, bool queueJump = false);

        /// <summary>
        /// Returns the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
        /// </summary>
        /// <remarks>Negative offsets can be used in order to provide an offset starting from the end of the string. So -1 means the last character, -2 the penultimate and so forth. The function handles out of range requests by limiting the resulting range to the actual length of the string.</remarks>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/getrange</remarks>
        Task<byte[]> Get(int db, string key, int start, int end, bool queueJump = false);

        /// <summary>
        /// Returns the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
        /// </summary>
        /// <remarks>Negative offsets can be used in order to provide an offset starting from the end of the string. So -1 means the last character, -2 the penultimate and so forth. The function handles out of range requests by limiting the resulting range to the actual length of the string.</remarks>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/getrange</remarks>
        Task<string> GetString(int db, string key, int start, int end, bool queueJump = false);

        /// <summary>
        /// Returns the values of all specified keys. For every key that does not hold a string value or does not exist, the special value nil is returned. Because of this, the operation never fails.
        /// </summary>
        /// <returns>list of values at the specified keys.</returns>
        /// <remarks>http://redis.io/commands/mget</remarks>
        Task<byte[][]> Get(int db, string[] keys, bool queueJump = false);

        /// <summary>
        /// Returns the values of all specified keys. For every key that does not hold a string value or does not exist, the special value nil is returned. Because of this, the operation never fails.
        /// </summary>
        /// <returns>list of values at the specified keys.</returns>
        /// <remarks>http://redis.io/commands/mget</remarks>
        Task<string[]> GetString(int db, string[] keys, bool queueJump = false);

        /// <summary>
        /// Atomically sets key to value and returns the old value stored at key. Returns an error when key exists but does not hold a string value.
        /// </summary>
        /// <returns>the old value stored at key, or nil when key did not exist.</returns>
        /// <remarks>http://redis.io/commands/getset</remarks>
        Task<string> GetSet(int db, string key, string value, bool queueJump = false);

        /// <summary>
        /// Atomically sets key to value and returns the old value stored at key. Returns an error when key exists but does not hold a string value.
        /// </summary>
        /// <returns>the old value stored at key, or nil when key did not exist.</returns>
        /// <remarks>http://redis.io/commands/getset</remarks>
        Task<byte[]> GetSet(int db, string key, byte[] value, bool queueJump = false);

        /// <summary>
        /// Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type.
        /// </summary>
        /// <remarks>http://redis.io/commands/set</remarks>
        Task Set(int db, string key, string value, bool queueJump = false);

        /// <summary>
        /// Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type.
        /// </summary>
        /// <remarks>http://redis.io/commands/set</remarks>
        Task Set(int db, string key, long value, bool queueJump = false);

        /// <summary>
        /// Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type.
        /// </summary>
        /// <remarks>http://redis.io/commands/set</remarks>
        Task Set(int db, string key, byte[] value, bool queueJump = false);

        /// <summary>
        /// Set key to hold the string value and set key to timeout after a given number of seconds.
        /// </summary>
        /// <remarks>http://redis.io/commands/setex</remarks>
        Task Set(int db, string key, string value, long expirySeconds, bool queueJump = false);

        /// <summary>
        /// Set key to hold the string value and set key to timeout after a given number of seconds.
        /// </summary>
        /// <remarks>http://redis.io/commands/setex</remarks>
        Task Set(int db, string key, byte[] value, long expirySeconds, bool queueJump = false);

        /// <summary>
        /// Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value. If the offset is larger than the current length of the string at key, the string is padded with zero-bytes to make offset fit. Non-existing keys are considered as empty strings, so this command will make sure it holds a string large enough to be able to set value at offset.
        /// </summary>
        /// <remarks>Note that the maximum offset that you can set is 229 -1 (536870911), as Redis Strings are limited to 512 megabytes. If you need to grow beyond this size, you can use multiple keys.
        /// Warning: When setting the last possible byte and the string value stored at key does not yet hold a string value, or holds a small string value, Redis needs to allocate all intermediate memory which can block the server for some time. On a 2010 MacBook Pro, setting byte number 536870911 (512MB allocation) takes ~300ms, setting byte number 134217728 (128MB allocation) takes ~80ms, setting bit number 33554432 (32MB allocation) takes ~30ms and setting bit number 8388608 (8MB allocation) takes ~8ms. Note that once this first allocation is done, subsequent calls to SETRANGE for the same key will not have the allocation overhead.</remarks>
        /// <remarks>http://redis.io/commands/setrange</remarks>
        /// <returns>the length of the string after it was modified by the command.</returns>
        Task<long> Set(int db, string key, long offset, string value, bool queueJump = false);

        /// <summary>
        /// Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value. If the offset is larger than the current length of the string at key, the string is padded with zero-bytes to make offset fit. Non-existing keys are considered as empty strings, so this command will make sure it holds a string large enough to be able to set value at offset.
        /// </summary>
        /// <remarks>Note that the maximum offset that you can set is 229 -1 (536870911), as Redis Strings are limited to 512 megabytes. If you need to grow beyond this size, you can use multiple keys.
        /// Warning: When setting the last possible byte and the string value stored at key does not yet hold a string value, or holds a small string value, Redis needs to allocate all intermediate memory which can block the server for some time. On a 2010 MacBook Pro, setting byte number 536870911 (512MB allocation) takes ~300ms, setting byte number 134217728 (128MB allocation) takes ~80ms, setting bit number 33554432 (32MB allocation) takes ~30ms and setting bit number 8388608 (8MB allocation) takes ~8ms. Note that once this first allocation is done, subsequent calls to SETRANGE for the same key will not have the allocation overhead.</remarks>
        /// <remarks>http://redis.io/commands/setrange</remarks>
        /// <returns>the length of the string after it was modified by the command.</returns>
        Task<long> Set(int db, string key, long offset, byte[] value, bool queueJump = false);

        /// <summary>
        /// Sets the given keys to their respective values. MSET replaces existing values with new values, just as regular SET. See MSETNX if you don't want to overwrite existing values.
        /// </summary>
        /// <remarks>MSET is atomic, so all given keys are set at once. It is not possible for clients to see that some of the keys were updated while others are unchanged.</remarks>
        /// <remarks>http://redis.io/commands/mset</remarks>
        Task Set(int db, Dictionary<string,string> values, bool queueJump = false);

        /// <summary>
        /// Sets the given keys to their respective values. MSET replaces existing values with new values, just as regular SET. See MSETNX if you don't want to overwrite existing values.
        /// </summary>
        /// <remarks>MSET is atomic, so all given keys are set at once. It is not possible for clients to see that some of the keys were updated while others are unchanged.</remarks>
        /// <remarks>http://redis.io/commands/mset</remarks>
        Task Set(int db, Dictionary<string, byte[]> values, bool queueJump = false);

        /// <summary>
        /// Sets the given keys to their respective values. MSETNX will not perform any operation at all even if just a single key already exists.
        /// </summary>
        /// <remarks>Because of this semantic MSETNX can be used in order to set different keys representing different fields of an unique logic object in a way that ensures that either all the fields or none at all are set.
        /// MSETNX is atomic, so all given keys are set at once. It is not possible for clients to see that some of the keys were updated while others are unchanged.</remarks>
        /// <returns>1 if the all the keys were set, 0 if no key was set (at least one key already existed).</returns>
        /// <remarks>http://redis.io/commands/msetnx</remarks>
        Task<bool> SetIfNotExists(int db, Dictionary<string, string> values, bool queueJump = false);

        /// <summary>
        /// Sets the given keys to their respective values. MSETNX will not perform any operation at all even if just a single key already exists.
        /// </summary>
        /// <remarks>Because of this semantic MSETNX can be used in order to set different keys representing different fields of an unique logic object in a way that ensures that either all the fields or none at all are set.
        /// MSETNX is atomic, so all given keys are set at once. It is not possible for clients to see that some of the keys were updated while others are unchanged.</remarks>
        /// <returns>1 if the all the keys were set, 0 if no key was set (at least one key already existed).</returns>
        /// <remarks>http://redis.io/commands/msetnx</remarks>
        Task<bool> SetIfNotExists(int db, Dictionary<string, byte[]> values, bool queueJump = false);

        /// <summary>
        /// Set key to hold string value if key does not exist. In that case, it is equal to SET. When key already holds a value, no operation is performed. 
        /// </summary>
        /// <returns>1 if the key was set, 0 if the key was not set</returns>
        /// <remarks>http://redis.io/commands/setnx</remarks>
        Task<bool> SetIfNotExists(int db, string key, string value, bool queueJump = false);

        /// <summary>
        /// Set key to hold string value if key does not exist. In that case, it is equal to SET. When key already holds a value, no operation is performed. 
        /// </summary>
        /// <returns>1 if the key was set, 0 if the key was not set</returns>
        /// <remarks>http://redis.io/commands/setnx</remarks>
        Task<bool> SetIfNotExists(int db, string key, byte[] value, bool queueJump = false);

        /// <summary>
        /// Returns the bit value at offset in the string value stored at key.
        /// </summary>
        /// <remarks>When offset is beyond the string length, the string is assumed to be a contiguous space with 0 bits. When key does not exist it is assumed to be an empty string, so offset is always out of range and the value is also assumed to be a contiguous space with 0 bits.</remarks>
        /// <returns>the bit value stored at offset.</returns>
        /// <remarks>http://redis.io/commands/getbit</remarks>
        Task<bool> GetBit(int db, string key, long offset, bool queueJump = false);

        /// <summary>
        /// Returns the length of the string value stored at key. An error is returned when key holds a non-string value.
        /// </summary>
        /// <returns>the length of the string at key, or 0 when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/strlen</remarks>
        Task<long> GetLength(int db, string key, bool queueJump = false);


        /// <summary>
        /// Sets or clears the bit at offset in the string value stored at key.
        /// </summary>
        /// <remarks>The bit is either set or cleared depending on value, which can be either 0 or 1. When key does not exist, a new string value is created. The string is grown to make sure it can hold a bit at offset. The offset argument is required to be greater than or equal to 0, and smaller than 232 (this limits bitmaps to 512MB). When the string at key is grown, added bits are set to 0.
        /// 
        /// Warning: When setting the last possible bit (offset equal to 232 -1) and the string value stored at key does not yet hold a string value, or holds a small string value, Redis needs to allocate all intermediate memory which can block the server for some time. On a 2010 MacBook Pro, setting bit number 232 -1 (512MB allocation) takes ~300ms, setting bit number 230 -1 (128MB allocation) takes ~80ms, setting bit number 228 -1 (32MB allocation) takes ~30ms and setting bit number 226 -1 (8MB allocation) takes ~8ms. Note that once this first allocation is done, subsequent calls to SETBIT for the same key will not have the allocation overhead.
        /// </remarks>
        /// <returns>the original bit value stored at offset.</returns>
        /// <remarks>http://redis.io/commands/setbit</remarks>
        Task<bool> SetBit(int db, string key, long offset, bool value, bool queueJump = false);

        /// <summary>
        /// Count the number of set bits (population counting) in a string.
        /// By default all the bytes contained in the string are examined. It is possible to specify the counting operation only in an interval passing the additional arguments start and end.
        /// Like for the GETRANGE command start and end can contain negative values in order to index bytes starting from the end of the string, where -1 is the last byte, -2 is the penultimate, and so forth.
        /// </summary>
        /// <remarks>http://redis.io/commands/bitcount</remarks>
        Task<long> CountSetBits(int db, string key, long start = 0, long count = -1, bool queueJump = false);

        /// <summary>
        /// Perform a bitwise AND operation between multiple keys (containing string values) and store the result in the destination key.
        /// </summary>
        /// <returns>The size of the string stored in the destination key, that is equal to the size of the longest input string.</returns>
        /// <remarks>http://redis.io/commands/bitop</remarks>
        Task<long> BitwiseAnd(int db, string destination, string[] keys, bool queueJump = false);
        /// <summary>
        /// Perform a bitwise OR operation between multiple keys (containing string values) and store the result in the destination key.
        /// </summary>
        /// <returns>The size of the string stored in the destination key, that is equal to the size of the longest input string.</returns>
        /// <remarks>http://redis.io/commands/bitop</remarks>
        Task<long> BitwiseOr(int db, string destination, string[] keys, bool queueJump = false);
        /// <summary>
        /// Perform a bitwise XOR operation between multiple keys (containing string values) and store the result in the destination key.
        /// </summary>
        /// <returns>The size of the string stored in the destination key, that is equal to the size of the longest input string.</returns>
        /// <remarks>http://redis.io/commands/bitop</remarks>
        Task<long> BitwiseXOr(int db, string destination, string[] keys, bool queueJump = false);
        /// <summary>
        /// Perform a bitwise NOT operation on a key (containing a string value) and store the result in the destination key.
        /// </summary>
        /// <returns>The size of the string stored in the destination key, that is equal to the size of the longest input string.</returns>
        /// <remarks>http://redis.io/commands/bitop</remarks>
        Task<long> BitwiseNot(int db, string destination, string key, bool queueJump = false);

        /// <summary>
        /// This is a composite helper command, to help with using redis as a lock provider. This is achieved
        /// as a string key/value pair with timeout. If the lock does not exist (or has expired), then a new string key is
        /// created (with the supplied duration), and <c>true</c> is returned to indicate success. If the lock
        /// already exists, then no lock is taken, and <c>false</c> is returned. The value may be fetched separately, but the meaning is
        /// implementation-defined). No change is made if the
        /// lock was not successfully taken. In this case, the client should delay and retry.
        /// 
        /// It is expected that a well-behaved client will also release the lock in a timely fashion via <c>ReleaseLock</c>.
        /// </summary>
        /// <returns><c>null</c> if the lock was successfully taken; the competing value otherwise</returns>
        /// <remarks>It transpires that robust locking in redis is actually remarkably hard, and most
        /// implementations are broken in one way or another (most commonly: thread-race, or extending the
        /// lock duration when failing to take the lock).</remarks>
        Task<bool> TakeLock(int db, string key, string value, int expirySeconds, bool queueJump = false);

        /// <summary>
        /// Releases a lock that was taken successfully via TakeLock. You should not release a lock that you did
        /// not take, as this will cause problems.
        /// </summary>
        Task ReleaseLock(int db, string key, bool queueJump = false);
    }

    partial class RedisConnection : IStringCommands
    {
        /// <summary>
        /// Commands that apply to key/value pairs, where the value
        /// can be a string, a BLOB, or interpreted as a number
        /// </summary>
        /// <remarks>http://redis.io/commands#string</remarks>
        public IStringCommands Strings
        {
            get { return this; }
        }

        Task<long> IStringCommands.Append(int db, string key, string value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.APPEND, key, value), queueJump);
        }

        Task<long> IStringCommands.Append(int db, string key, byte[] value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.APPEND, key, value), queueJump);
        }

        Task<long> IStringCommands.Decrement(int db, string key, long value, bool queueJump)
        {
            return IncrementImpl(db, key, -value, queueJump);
        }

        Task<long> IStringCommands.Increment(int db, string key, long value, bool queueJump)
        {
            return IncrementImpl(db, key, value, queueJump);
        }
        Task<double> IStringCommands.Increment(int db, string key, double value, bool queueJump)
        {
            return ExecuteDouble(RedisMessage.Create(db, RedisLiteral.INCRBYFLOAT, key, value), queueJump);            
        }

        Task<long> IncrementImpl(int db, string key, long value, bool queueJump)
        {
            switch(value)
            {
                case 1:
                    return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.INCR, key), queueJump);
                case -1:
                    return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.DECR, key), queueJump);
            }
            if(value >= 0)
            {
                return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.INCRBY, key, value), queueJump);
            }
            else
            {
                return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.DECRBY, key, -value), queueJump);
            }
        }

        Task<byte[]> IStringCommands.Get(int db, string key, bool queueJump)
        {
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.GET, key), queueJump);
        }

        Task<string> IStringCommands.GetString(int db, string key, bool queueJump)
        {
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.GET, key), queueJump);
        }
        Task<long?> IStringCommands.GetInt64(int db, string key, bool queueJump)
        {
            return ExecuteNullableInt64(RedisMessage.Create(db, RedisLiteral.GET, key), queueJump);
        }

        Task<byte[]> IStringCommands.Get(int db, string key, int start, int end, bool queueJump)
        {
            var features = this.Features;
            RedisLiteral cmd = features != null && features.Version < RedisFeatures.v2_1_0
                                   ? RedisLiteral.SUBSTR
                                   : RedisLiteral.GETRANGE;
            return ExecuteBytes(RedisMessage.Create(db, cmd, key, start, end), queueJump);
        }
        
        Task<string> IStringCommands.GetString(int db, string key, int start, int end, bool queueJump)
        {
            var features = this.Features;
            RedisLiteral cmd = features != null && features.Version < RedisFeatures.v2_1_0
                                   ? RedisLiteral.SUBSTR
                                   : RedisLiteral.GETRANGE;
            return ExecuteString(RedisMessage.Create(db, cmd, key, start, end), queueJump);
        }

        Task<byte[][]> IStringCommands.Get(int db, string[] keys, bool queueJump)
        {
            return ExecuteMultiBytes(RedisMessage.Create(db, RedisLiteral.MGET, keys), queueJump);
        }

        Task<string[]> IStringCommands.GetString(int db, string[] keys, bool queueJump)
        {
            return ExecuteMultiString(RedisMessage.Create(db, RedisLiteral.MGET, keys), queueJump);
        }

        Task<string> IStringCommands.GetSet(int db, string key, string value, bool queueJump)
        {
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.GETSET, key, value), queueJump);
        }

        Task<byte[]> IStringCommands.GetSet(int db, string key, byte[] value, bool queueJump)
        {
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.GETSET, key, value), queueJump);
        }

        Task IStringCommands.Set(int db, string key, string value, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.SET, key, value), queueJump);
        }
        Task IStringCommands.Set(int db, string key, long value, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.SET, key, value), queueJump);
        }

        Task IStringCommands.Set(int db, string key, byte[] value, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.SET, key, value), queueJump);
        }

        Task IStringCommands.Set(int db, string key, string value, long expirySeconds, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.SETEX, key, expirySeconds, value).ExpectOk(), queueJump);
        }

        Task IStringCommands.Set(int db, string key, byte[] value, long expirySeconds, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.SETEX, key, expirySeconds, value).ExpectOk(), queueJump);
        }

        Task<long> IStringCommands.Set(int db, string key, long offset, string value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.SETRANGE, key, offset, value), queueJump);
        }

        Task<long> IStringCommands.Set(int db, string key, long offset, byte[] value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.SETRANGE, key, offset, value), queueJump);
        }
        static RedisMessage.RedisParameter[] Parse(Dictionary<string, string> values)
        {
            if (values == null) return new RedisMessage.RedisParameter[0];
            var arr = new RedisMessage.RedisParameter[values.Count * 2];
            int index = 0;
            foreach (var pair in values)
            {
                arr[index++] = pair.Key;
                arr[index++] = pair.Value;
            }
            return arr;
        }
        static RedisMessage.RedisParameter[] Parse(Dictionary<string, byte[]> values)
        {
            if (values == null) return new RedisMessage.RedisParameter[0];
            var arr = new RedisMessage.RedisParameter[values.Count * 2];
            int index = 0;
            foreach (var pair in values)
            {
                arr[index++] = pair.Key;
                arr[index++] = pair.Value;
            }
            return arr;
        }
        Task IStringCommands.Set(int db, Dictionary<string, string> values, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.MSET, Parse(values)), queueJump);
        }
        Task IStringCommands.Set(int db, Dictionary<string, byte[]> values, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.MSET, Parse(values)), queueJump);
        }

        Task<bool> IStringCommands.SetIfNotExists(int db, Dictionary<string, string> values, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.MSETNX, Parse(values)), queueJump);
        }

        Task<bool> IStringCommands.SetIfNotExists(int db, Dictionary<string, byte[]> values, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.MSETNX, Parse(values)), queueJump);
        }

        Task<bool> IStringCommands.SetIfNotExists(int db, string key, string value, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.SETNX, key, value), queueJump);
        }

        Task<bool> IStringCommands.SetIfNotExists(int db, string key, byte[] value, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.SETNX, key, value), queueJump);
        }

        Task<bool> IStringCommands.GetBit(int db, string key, long offset, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.GETBIT, key, offset), queueJump);
        }

        Task<long> IStringCommands.GetLength(int db, string key, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.STRLEN, key), queueJump);
        }

        Task<bool> IStringCommands.SetBit(int db, string key, long offset, bool value, bool queueJump)
        {
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.SETBIT, key, offset, value ? 1L : 0L), queueJump);
        }
        Task<long> IStringCommands.CountSetBits(int db, string key, long start, long end, bool queueJump)
        {
            return ExecuteInt64(start == 0 && end == -1
                ? RedisMessage.Create(db, RedisLiteral.BITCOUNT, key) 
                : RedisMessage.Create(db, RedisLiteral.BITCOUNT, key, start, end), queueJump);
        }

        Task<long> IStringCommands.BitwiseAnd(int db, string destination, string[] keys, bool queueJump)
        {
            return BitOp(db, RedisLiteral.AND, destination, keys, queueJump);
        }
        Task<long> IStringCommands.BitwiseOr(int db, string destination, string[] keys, bool queueJump)
        {
            return BitOp(db, RedisLiteral.OR, destination, keys, queueJump);
        }
        Task<long> IStringCommands.BitwiseXOr(int db, string destination, string[] keys, bool queueJump)
        {
            return BitOp(db, RedisLiteral.XOR, destination, keys, queueJump);
        }
        private Task<long> BitOp(int db, RedisLiteral operation, string destination, string[] keys, bool queueJump)
        {
            if (keys == null) throw new ArgumentNullException("keys");
            if (keys.Length == 0) throw new ArgumentException("keys");
            var args = new RedisMessage.RedisParameter[keys.Length + 2];
            args[0] = operation;
            args[1] = destination;
            for (int i = 0; i < keys.Length; i++)
            {
                args[i + 2] = keys[i];
            }
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.BITOP, args), queueJump);
        }
        Task<long> IStringCommands.BitwiseNot(int db, string destination, string key, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.BITOP, RedisLiteral.NOT, destination, key), queueJump);
        }

        // minimise delegate creations via a single static delegate instance
        static readonly Action<Task<bool>> takeLockContinuation =
            task =>
            {
                var result = (TaskCompletionSource<bool>)task.AsyncState;
                if (task.ShouldSetResult(result)) result.TrySetResult(task.Result);
            };
        static readonly Action<Task<RedisResult>> takeLockConditionalContinuation =
            task =>
            {
                var result = (TaskCompletionSource<bool>)task.AsyncState;
                if (task.ShouldSetResult(result))
                {
                    var x = task.Result;
                    if (x.IsNil) result.TrySetResult(false);
                    else if (x.IsOk) result.TrySetResult(true);
                    else result.SafeSetException(new RedisException("Unexpected reply: " + x.ToString()));
                }
            };

        Task<bool> IStringCommands.TakeLock(int db, string key, string value, int expirySeconds, bool queueJump)
        {
            TaskCompletionSource<bool> result = new TaskCompletionSource<bool>();

            var features = Features;
            if (features != null && features.SetConditional)
            {
                var raw = ExecuteRaw(RedisMessage.Create(db, RedisLiteral.SET, key, value,
                    RedisLiteral.EX, expirySeconds, RedisLiteral.NX), queueJump, result);
                raw.ContinueWith(takeLockConditionalContinuation);
            }
            else
            {
                using (var tran = CreateTransaction())
                {
                    tran.AddCondition(Condition.KeyNotExists(db, key));
                    tran.Strings.Set(db, key, value, expirySeconds);
                    tran.Execute(queueJump, state: result).ContinueWith(takeLockContinuation);
                }
            }
            return result.Task;
        }
        Task IStringCommands.ReleaseLock(int db, string key, bool queueJump)
        {
            return Keys.Remove(db, key, queueJump);
        }


        /// <summary>
        /// See Strings.Get
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[]> Get(int db, string key, bool queueJump = false)
        {
            return Strings.Get(db, key, queueJump);
        }
        /// <summary>
        /// See Strings.GetString
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string> GetString(int db, string key, bool queueJump = false)
        {
            return Strings.GetString(db, key, queueJump);
        }
        /// <summary>
        /// See Strings.Increment
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> Increment(int db, string key, bool queueJump = false)
        {
            return Strings.Increment(db, key, 1, queueJump);
        }
        /// <summary>
        /// See Strings.Increment
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> IncrementBy(int db, string key, long value, bool queueJump = false)
        {
            return Strings.Increment(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.Decrement
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> DecrementBy(int db, string key, long value, bool queueJump = false)
        {
            return Strings.Decrement(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.Decrement
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> Decrement(int db, string key, bool queueJump = false)
        {
            return Strings.Decrement(db, key, 1, queueJump);
        }
        /// <summary>
        /// See Strings.Set
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task Set(int db, string key, byte[] value, bool queueJump = false)
        {
            return Strings.Set(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.Set
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task Set(int db, string key, string value, bool queueJump = false)
        {
            return Strings.Set(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.SetIfNotExists
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> SetIfNotExists(int db, string key, byte[] value, bool queueJump = false)
        {
            return Strings.SetIfNotExists(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.SetIfNotExists
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> SetIfNotExists(int db, string key, string value, bool queueJump = false)
        {
            return Strings.SetIfNotExists(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.Append
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> Append(int db, string key, string value, bool queueJump = false)
        {
            return Strings.Append(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.Append
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> Append(int db, string key, byte[] value, bool queueJump = false)
        {
            return Strings.Append(db, key, value, queueJump);
        }
        /// <summary>
        /// See Strings.Set
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task SetWithExpiry(int db, string key, int seconds, string value, bool queueJump = false)
        {
            return Strings.Set(db, key, value, seconds, queueJump);
        }
        /// <summary>
        /// See Strings.Set
        /// </summary>
        [Obsolete("Please use the Strings API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task SetWithExpiry(int db, string key, int seconds, byte[] value, bool queueJump = false)
        {
            return Strings.Set(db, key, value, seconds, queueJump);
        }
    }
}
