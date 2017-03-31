#if CLUSTER
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Commands that apply to key/value pairs, where the value
    /// can be a string, a BLOB, or interpreted as a number
    /// </summary>
    /// <remarks>http://redis.io/commands#string</remarks>
    public interface IClusterStringCommands
    {
        /// <summary>
        /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
        /// </summary>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/get</remarks>
        Task<byte[]> Get(string key);

        /// <summary>
        /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
        /// </summary>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/get</remarks>
        Task<string> GetString(string key);

        /// <summary>
        /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
        /// </summary>
        /// <returns>the value of key, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/get</remarks>
        Task<long?> GetInt64(string key);

        /// <summary>
        /// Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type.
        /// </summary>
        /// <remarks>http://redis.io/commands/set</remarks>
        Task Set(string key, string value);

        /// <summary>
        /// Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type.
        /// </summary>
        /// <remarks>http://redis.io/commands/set</remarks>
        Task Set(string key, long value);

        /// <summary>
        /// Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type.
        /// </summary>
        /// <remarks>http://redis.io/commands/set</remarks>
        Task Set(string key, byte[] value);
        
    }

    partial class RedisCluster : IClusterStringCommands
    {
        /// <summary>
        /// Commands that apply to key/value pairs, where the value
        /// can be a string, a BLOB, or interpreted as a number
        /// </summary>
        /// <remarks>http://redis.io/commands#string</remarks>
        public IClusterStringCommands Strings { get { return this; } }

        Task<byte[]> IClusterStringCommands.Get(string key)
        {
            return GetConnection(key).Strings.Get(0, key, false);
        }

        Task<string> IClusterStringCommands.GetString(string key)
        {
            return GetConnection(key).Strings.GetString(0, key, false);
        }
        Task<long?> IClusterStringCommands.GetInt64(string key)
        {
            return GetConnection(key).Strings.GetInt64(0, key, false);
        }
        Task IClusterStringCommands.Set(string key, string value)
        {
            return GetConnection(key).Strings.Set(0, key, value, false);
        }
        Task IClusterStringCommands.Set(string key, long value)
        {
            return GetConnection(key).Strings.Set(0, key, value, false);
        }

        Task IClusterStringCommands.Set(string key, byte[] value)
        {
            return GetConnection(key).Strings.Set(0, key, value, false);
        }
    }
}
#endif