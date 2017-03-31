
using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.ComponentModel;
namespace BookSleeve
{
    /// <summary>
    /// Commands that apply to sorted sets per key. A sorted set keeps a "score"
    /// per element, and this score is used to order the elements. Duplicates
    /// are not allowed (typically, the score of the duplicate is added to the
    /// pre-existing element instead).
    /// </summary>
    /// <remarks>http://redis.io/commands#sorted_set</remarks>
    public interface ISortedSetCommands
    {
        /// <summary>
        /// Adds all the specified members with the specified scores to the sorted set stored at key. It is possible to specify multiple score/member pairs. If a specified member is already a member of the sorted set, the score is updated and the element reinserted at the right position to ensure the correct ordering. If key does not exist, a new sorted set with the specified members as sole members is created, like if the sorted set was empty. If the key exists but does not hold a sorted set, an error is returned.
        /// The score values should be the string representation of a numeric value, and accepts double precision floating point numbers.
        /// </summary>
        /// <returns>The number of elements added to the sorted sets, not including elements already existing for which the score was updated.</returns>
        /// <remarks>http://redis.io/commands/zadd</remarks>
        Task<bool> Add(int db, string key, string value, double score, bool queueJump = false);
        /// <summary>
        /// Adds all the specified members with the specified scores to the sorted set stored at key. It is possible to specify multiple score/member pairs. If a specified member is already a member of the sorted set, the score is updated and the element reinserted at the right position to ensure the correct ordering. If key does not exist, a new sorted set with the specified members as sole members is created, like if the sorted set was empty. If the key exists but does not hold a sorted set, an error is returned.
        /// The score values should be the string representation of a numeric value, and accepts double precision floating point numbers.
        /// </summary>
        /// <returns>The number of elements added to the sorted sets, not including elements already existing for which the score was updated.</returns>
        /// <remarks>http://redis.io/commands/zadd</remarks>
        Task<bool> Add(int db, string key, byte[] value, double score, bool queueJump = false);
        /// <summary>
        /// Returns the sorted set cardinality (number of elements) of the sorted set stored at key.
        /// </summary>
        /// <returns>the cardinality (number of elements) of the sorted set, or 0 if key does not exist.</returns>
        /// <remarks>http://redis.io/commands/zcard</remarks>
        Task<long> GetLength(int db, string key, bool queueJump = false);
        /// <summary>
        /// Returns the number of elements in the sorted set at key with a score between min and max.
        /// The min and max arguments have the same semantic as described for ZRANGEBYSCORE.
        /// </summary>
        /// <returns>the number of elements in the specified score range.</returns>
        /// <remarks>http://redis.io/commands/zcount</remarks>
        Task<long> GetLength(int db, string key, double min, double max, bool queueJump = false);
        /// <summary>
        /// Increments the score of member in the sorted set stored at key by increment. If member does not exist in the sorted set, it is added with increment as its score (as if its previous score was 0.0). If key does not exist, a new sorted set with the specified member as its sole member is created.
        /// An error is returned when key exists but does not hold a sorted set.
        /// The score value should be the string representation of a numeric value, and accepts double precision floating point numbers. It is possible to provide a negative value to decrement the score.
        /// </summary>
        /// <remarks>http://redis.io/commands/zincrby</remarks>
        /// <returns>the new score of member (a double precision floating point number), represented as string.</returns>
        Task<double> Increment(int db, string key, string member, double delta, bool queueJump = false);
        /// <summary>
        /// Increments the score of member in the sorted set stored at key by increment. If member does not exist in the sorted set, it is added with increment as its score (as if its previous score was 0.0). If key does not exist, a new sorted set with the specified member as its sole member is created.
        /// An error is returned when key exists but does not hold a sorted set.
        /// The score value should be the string representation of a numeric value, and accepts double precision floating point numbers. It is possible to provide a negative value to decrement the score.
        /// </summary>
        /// <remarks>http://redis.io/commands/zincrby</remarks>
        /// <returns>the new score of member (a double precision floating point number), represented as string.</returns>
        Task<double> Increment(int db, string key, byte[] member, double delta, bool queueJump = false);
        /// <summary>
        /// Increments the score of member in the sorted set stored at key by increment. If member does not exist in the sorted set, it is added with increment as its score (as if its previous score was 0.0). If key does not exist, a new sorted set with the specified member as its sole member is created.
        /// An error is returned when key exists but does not hold a sorted set.
        /// The score value should be the string representation of a numeric value, and accepts double precision floating point numbers. It is possible to provide a negative value to decrement the score.
        /// </summary>
        /// <remarks>http://redis.io/commands/zincrby</remarks>
        /// <returns>the new score of member (a double precision floating point number), represented as string.</returns>
        Task<double>[] Increment(int db, string key, string[] members, double delta, bool queueJump = false);
        /// <summary>
        /// Increments the score of member in the sorted set stored at key by increment. If member does not exist in the sorted set, it is added with increment as its score (as if its previous score was 0.0). If key does not exist, a new sorted set with the specified member as its sole member is created.
        /// An error is returned when key exists but does not hold a sorted set.
        /// The score value should be the string representation of a numeric value, and accepts double precision floating point numbers. It is possible to provide a negative value to decrement the score.
        /// </summary>
        /// <remarks>http://redis.io/commands/zincrby</remarks>
        /// <returns>the new score of member (a double precision floating point number), represented as string.</returns>
        Task<double>[] Increment(int db, string key, byte[][] members, double delta, bool queueJump = false);

        /// <summary>
        /// Returns the specified range of elements in the sorted set stored at key. The elements are considered to be ordered from the lowest to the highest score. Lexicographical order is used for elements with equal score.
        /// See ZREVRANGE when you need the elements ordered from highest to lowest score (and descending lexicographical order for elements with equal score).
        /// Both start and stop are zero-based indexes, where 0 is the first element, 1 is the next element and so on. They can also be negative numbers indicating offsets from the end of the sorted set, with -1 being the last element of the sorted set, -2 the penultimate element and so on.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrange</remarks>
        /// <remarks>http://redis.io/commands/zrevrange</remarks>
        /// <returns>list of elements in the specified range (optionally with their scores).</returns>
        Task<KeyValuePair<byte[], double>[]> Range(int db, string key, long start, long stop, bool ascending = true, bool queueJump = false);
        /// <summary>
        /// Returns the specified range of elements in the sorted set stored at key. The elements are considered to be ordered from the lowest to the highest score. Lexicographical order is used for elements with equal score.
        /// See ZREVRANGE when you need the elements ordered from highest to lowest score (and descending lexicographical order for elements with equal score).
        /// Both start and stop are zero-based indexes, where 0 is the first element, 1 is the next element and so on. They can also be negative numbers indicating offsets from the end of the sorted set, with -1 being the last element of the sorted set, -2 the penultimate element and so on.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrange</remarks>
        /// <remarks>http://redis.io/commands/zrevrange</remarks>
        /// <returns>list of elements in the specified range (optionally with their scores).</returns>
        Task<KeyValuePair<string, double>[]> RangeString(int db, string key, long start, long stop, bool ascending = true, bool queueJump = false);
        /// <summary>
        /// Returns the specified range of elements in the sorted set stored at key. The elements are considered to be ordered from the lowest to the highest score. Lexicographical order is used for elements with equal score.
        /// See ZREVRANGE when you need the elements ordered from highest to lowest score (and descending lexicographical order for elements with equal score).
        /// Both start and stop are zero-based indexes, where 0 is the first element, 1 is the next element and so on. They can also be negative numbers indicating offsets from the end of the sorted set, with -1 being the last element of the sorted set, -2 the penultimate element and so on.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrange</remarks>
        /// <remarks>http://redis.io/commands/zrevrange</remarks>
        /// <returns>list of elements in the specified range (optionally with their scores).</returns>
        Task<KeyValuePair<string, double>[]> RangeString(int db, string key,
                                                   double min = double.NegativeInfinity, double max = double.PositiveInfinity,
                                                    bool ascending = true,
                                                   bool minInclusive = true, bool maxInclusive = true,
                                                   long offset = 0, long count = long.MaxValue, bool queueJump = false);

        /// <summary>
        /// Returns all the elements in the sorted set at key with a score between min and max (including elements with score equal to min or max). The elements are considered to be ordered from low to high scores.
        /// The elements having the same score are returned in lexicographical order (this follows from a property of the sorted set implementation in Redis and does not involve further computation).
        /// The optional LIMIT argument can be used to only get a range of the matching elements (similar to SELECT LIMIT offset, count in SQL). Keep in mind that if offset is large, the sorted set needs to be traversed for offset elements before getting to the elements to return, which can add up to O(N) time complexity.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrangebyscore</remarks>
        /// <remarks>http://redis.io/commands/zrevrangebyscore</remarks>
        /// <returns>list of elements in the specified score range (optionally with their scores).</returns>
        Task<KeyValuePair<byte[], double>[]> Range(int db, string key,
                                                   double min = double.NegativeInfinity, double max = double.PositiveInfinity,
                                                    bool ascending = true,
                                                   bool minInclusive = true, bool maxInclusive = true,
                                                   long offset = 0, long count = long.MaxValue, bool queueJump = false);

        /// <summary>
        /// Returns the rank of member in the sorted set stored at key, with the scores ordered from low to high. The rank (or index) is 0-based, which means that the member with the lowest score has rank 0.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrank</remarks>
        /// <remarks>http://redis.io/commands/zrevrank</remarks>
        /// <returns>If member exists in the sorted set, Integer reply: the rank of member. If member does not exist in the sorted set or key does not exist, Bulk reply: nil.</returns>
        Task<long?> Rank(int db, string key, string member, bool ascending = true, bool queueJump = false);
        /// <summary>
        /// Returns the rank of member in the sorted set stored at key, with the scores ordered from low to high. The rank (or index) is 0-based, which means that the member with the lowest score has rank 0.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrank</remarks>
        /// <remarks>http://redis.io/commands/zrevrank</remarks>
        /// <returns>If member exists in the sorted set, Integer reply: the rank of member. If member does not exist in the sorted set or key does not exist, Bulk reply: nil.</returns>
        Task<long?> Rank(int db, string key, byte[] member, bool ascending = true, bool queueJump = false);

        /// <summary>
        /// Returns the score of member in the sorted set at key. If member does not exist in the sorted set, or key does not exist, nil is returned.
        /// </summary>
        /// <remarks>http://redis.io/commands/zscore</remarks>
        /// <returns>the score of member (a double precision floating point number), represented as string.</returns>
        Task<double?> Score(int db, string key, string member, bool queueJump = false);
        /// <summary>
        /// Returns the score of member in the sorted set at key. If member does not exist in the sorted set, or key does not exist, nil is returned.
        /// </summary>
        /// <remarks>http://redis.io/commands/zscore</remarks>
        /// <returns>the score of member (a double precision floating point number), represented as string.</returns>
        Task<double?> Score(int db, string key, byte[] member, bool queueJump = false);

        /// <summary>
        /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
        /// An error is returned when key exists and does not hold a sorted set.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrem</remarks>
        /// <returns>The number of members removed from the sorted set, not including non existing members.</returns>
        Task<bool> Remove(int db, string key, string member, bool queueJump = false);
        /// <summary>
        /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
        /// An error is returned when key exists and does not hold a sorted set.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrem</remarks>
        /// <returns>The number of members removed from the sorted set, not including non existing members.</returns>
        Task<bool> Remove(int db, string key, byte[] member, bool queueJump = false);
        /// <summary>
        /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
        /// An error is returned when key exists and does not hold a sorted set.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrem</remarks>
        /// <returns>The number of members removed from the sorted set, not including non existing members.</returns>
        Task<long> Remove(int db, string key, string[] members, bool queueJump = false);
        /// <summary>
        /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
        /// An error is returned when key exists and does not hold a sorted set.
        /// </summary>
        /// <remarks>http://redis.io/commands/zrem</remarks>
        /// <returns>The number of members removed from the sorted set, not including non existing members.</returns>
        Task<long> Remove(int db, string key, byte[][] members, bool queueJump = false);
        /// <summary>
        /// Removes all elements in the sorted set stored at key with rank between start and stop. Both start and stop are 0-based indexes with 0 being the element with the lowest score. These indexes can be negative numbers, where they indicate offsets starting at the element with the highest score. For example: -1 is the element with the highest score, -2 the element with the second highest score and so forth.
        /// </summary>
        /// <remarks>http://redis.io/commands/zremrangebyrank</remarks>
        /// <returns>the number of elements removed.</returns>
        Task<long> RemoveRange(int db, string key, long start, long stop, bool queueJump = false);
        /// <summary>
        /// Removes all elements in the sorted set stored at key with a score between min and max (inclusive).
        /// </summary>
        /// <remarks>http://redis.io/commands/zremrangebyscore</remarks>
        /// <returns>the number of elements removed.</returns>
        /// <remarks>Since version 2.1.6, min and max can be exclusive, following the syntax of ZRANGEBYSCORE.</remarks>
        Task<long> RemoveRange(int db, string key, double min, double max, bool minInclusive = true, bool maxInclusive = true, bool queueJump = false);

        /// <summary>
        /// Computes the intersection of numkeys sorted sets given by the specified keys, and stores the result in destination.
        /// </summary>
        /// <remarks>http://redis.io/commands/zinterstore</remarks>
        /// <returns>the number of elements in the resulting set.</returns>
        Task<long> IntersectAndStore(int db, string destionation, string[] keys, RedisAggregate aggregate = RedisAggregate.Sum, bool queueJump = false);

        /// <summary>
        /// Computes the union of numkeys sorted sets given by the specified keys, and stores the result in destination. It is mandatory to provide the number of input keys (numkeys) before passing the input keys and the other (optional) arguments.
        /// </summary>
        /// <remarks>http://redis.io/commands/zunionstore</remarks>
        /// <returns>the number of elements in the resulting set.</returns>
        Task<long> UnionAndStore(int db, string destination, string[] keys, RedisAggregate aggregate = RedisAggregate.Sum, bool queueJump = false);
    }

    partial class RedisConnection : ISortedSetCommands
    {
        /// <summary>
        /// Commands that apply to sorted sets per key. A sorted set keeps a "score"
        /// per element, and this score is used to order the elements. Duplicates
        /// are not allowed (typically, the score of the duplicate is added to the
        /// pre-existing element instead).
        /// </summary>
        /// <remarks>http://redis.io/commands#sorted_set</remarks>
        public ISortedSetCommands SortedSets
        {
            get { return this; }
        }
        /// <summary>
        /// See SortedSets.Add
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> AddToSortedSet(int db, string key, string value, double score, bool queueJump = false)
        {
            return SortedSets.Add(db, key, value, score, queueJump);
        }
        /// <summary>
        /// See SortedSets.Add
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<bool> AddToSortedSet(int db, string key, byte[] value, double score, bool queueJump = false)
        {
            return SortedSets.Add(db, key, value, score, queueJump);
        }
        Task<bool> ISortedSetCommands.Add(int db, string key, string value, double score, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.ZADD, key, score, value), queueJump);
        }

        Task<bool> ISortedSetCommands.Add(int db, string key, byte[] value, double score, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.ZADD, key, score, value), queueJump);
        }
        /// <summary>
        /// See SortedSets.GetLength
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> CardinalityOfSortedSet(int db, string key, bool queueJump = false)
        {
            return SortedSets.GetLength(db, key, queueJump);
        }
        Task<long> ISortedSetCommands.GetLength(int db, string key, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.ZCARD, key), queueJump);
        }

        Task<long> ISortedSetCommands.GetLength(int db, string key, double min, double max, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.ZCOUNT, key, min, max), queueJump);
        }

        Task<double> ISortedSetCommands.Increment(int db, string key, string member, double delta, bool queueJump)
        {
            
            return ExecuteDouble(RedisMessage.Create(db, RedisLiteral.ZINCRBY, key, delta, member), queueJump);
        }

        Task<double> ISortedSetCommands.Increment(int db, string key, byte[] member, double delta, bool queueJump)
        {

            return ExecuteDouble(RedisMessage.Create(db, RedisLiteral.ZINCRBY, key, delta, member), queueJump);
        }
        Task<double>[] ISortedSetCommands.Increment(int db, string key, string[] members, double delta, bool queueJump)
        {
            
            if (members == null) throw new ArgumentNullException("members");
            Task<double>[] result = new Task<double>[members.Length];
            var ss = SortedSets;
            for (int i = 0; i < members.Length; i++)
            {
                result[i] = ss.Increment(db, key, members[i], delta, queueJump);
            }
            return result;
        }

        Task<double>[] ISortedSetCommands.Increment(int db, string key, byte[][] members, double delta, bool queueJump)
        {
            
            if (members == null) throw new ArgumentNullException("members");
            Task<double>[] result = new Task<double>[members.Length];
            var ss = SortedSets;
            for (int i = 0; i < members.Length; i++)
            {
                result[i] = ss.Increment(db, key, members[i], delta, queueJump);
            }
            return result;
        }
        /// <summary>
        /// See SortedSets.Increment
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<double> IncrementSortedSet(int db, string key, byte[] value, double score, bool queueJump = false)
        {
            return SortedSets.Increment(db, key, value, score, queueJump);
        }
        /// <summary>
        /// See SortedSets.Increment
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<double> IncrementSortedSet(int db, string key, string value, double score, bool queueJump = false)
        {
            return SortedSets.Increment(db, key, value, score, queueJump);
        }
        /// <summary>
        /// See SortedSets.Increment
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<double>[] IncrementSortedSet(int db, string key, double score, string[] values, bool queueJump = false)
        {
            return SortedSets.Increment(db, key, values, score, queueJump);
        }
        /// <summary>
        /// See SortedSets.Increment
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<double>[] IncrementSortedSet(int db, string key, double score, byte[][] values, bool queueJump = false)
        {
            return SortedSets.Increment(db, key, values, score, queueJump);
        }
        Task<KeyValuePair<byte[], double>[]> ISortedSetCommands.Range(int db, string key, long start, long stop, bool ascending, bool queueJump)
        {            
            return ExecutePairs(RedisMessage.Create(db, ascending ? RedisLiteral.ZRANGE : RedisLiteral.ZREVRANGE, key, start,
                (stop == long.MaxValue ? -1 : stop), RedisLiteral.WITHSCORES), queueJump);
        }

        Task<KeyValuePair<string, double>[]> ISortedSetCommands.RangeString(int db, string key, long start, long stop, bool ascending, bool queueJump)
        {
            return ExecuteStringDoublePairs(RedisMessage.Create(db, ascending ? RedisLiteral.ZRANGE : RedisLiteral.ZREVRANGE, key, start,
                (stop == long.MaxValue ? -1 : stop), RedisLiteral.WITHSCORES), queueJump);
        }
        Task<KeyValuePair<string, double>[]> ISortedSetCommands.RangeString(int db, string key, double min, double max, bool ascending, bool minInclusive, bool maxInclusive, long offset, long count, bool queueJump)
        {
            RedisMessage msg = GetRangeRequest(db, key, min, max, ascending, minInclusive, maxInclusive, offset, count);
            return ExecuteStringDoublePairs(msg, queueJump);
        }

        Task<KeyValuePair<byte[], double>[]> ISortedSetCommands.Range(int db, string key, double min, double max, bool ascending, bool minInclusive, bool maxInclusive, long offset, long count, bool queueJump)
        {
            RedisMessage msg = GetRangeRequest(db, key, min, max, ascending, minInclusive, maxInclusive, offset, count);
            return ExecutePairs(msg, queueJump);
        }

        private static RedisMessage GetRangeRequest(int db, string key, double min, double max, bool ascending, bool minInclusive, bool maxInclusive, long offset, long count)
        {
            RedisMessage msg;
            if (minInclusive && maxInclusive && double.IsNegativeInfinity(min) && double.IsPositiveInfinity(max) && offset >= 0 && count != 0)
            { // considering entire set; can be done more efficiently with ZRANGE/ZREVRANGE
                msg = RedisMessage.Create(db, ascending ? RedisLiteral.ZRANGE : RedisLiteral.ZREVRANGE, key, offset,
                    (count < 0 || count == long.MaxValue) ? -1 : (offset + count - 1), RedisLiteral.WITHSCORES);
            }
            else if (offset == 0 && (count < 0 || count == long.MaxValue))
            { // no need for a LIMIT
                msg = RedisMessage.Create(db, ascending ? RedisLiteral.ZRANGEBYSCORE : RedisLiteral.ZREVRANGEBYSCORE, key,
                    ascending ? RedisMessage.RedisParameter.Range(min, minInclusive) : RedisMessage.RedisParameter.Range(max, maxInclusive),
                    ascending ? RedisMessage.RedisParameter.Range(max, maxInclusive) : RedisMessage.RedisParameter.Range(min, minInclusive),
                    RedisLiteral.WITHSCORES);
            }
            else
            {
                msg = RedisMessage.Create(db, ascending ? RedisLiteral.ZRANGEBYSCORE : RedisLiteral.ZREVRANGEBYSCORE, key,
                    ascending ? RedisMessage.RedisParameter.Range(min, minInclusive) : RedisMessage.RedisParameter.Range(max, maxInclusive),
                    ascending ? RedisMessage.RedisParameter.Range(max, maxInclusive) : RedisMessage.RedisParameter.Range(min, minInclusive),
                    RedisLiteral.WITHSCORES, RedisLiteral.LIMIT, offset, (count < 0 || count == long.MaxValue) ? -1 : count);
            }
            return msg;
        }
        /// <summary>
        /// See SortedSets.GetRange
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<KeyValuePair<byte[], double>[]> GetRangeOfSortedSetDescending(int db, string key, int start, int stop, bool queueJump = false)
        {
            return SortedSets.Range(db, key, start, stop, false, queueJump);
        }
        /// <summary>
        /// See SortedSets.GetRange
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<KeyValuePair<byte[], double>[]> GetRangeOfSortedSet(int db, string key, int start, int stop, bool queueJump = false)
        {
            return SortedSets.Range(db, key, start, stop, true, queueJump);
        }
        Task<long?> ISortedSetCommands.Rank(int db, string key, string member, bool ascending, bool queueJump)
        {
            return ExecuteNullableInt64(RedisMessage.Create(db, ascending ? RedisLiteral.ZRANK : RedisLiteral.ZREVRANK, key, member), queueJump);
        }
        Task<long?> ISortedSetCommands.Rank(int db, string key, byte[] member, bool ascending, bool queueJump)
        {
            return ExecuteNullableInt64(RedisMessage.Create(db, ascending ? RedisLiteral.ZRANK : RedisLiteral.ZREVRANK, key, member), queueJump);
        }
        Task<double?> ISortedSetCommands.Score(int db, string key, string member, bool queueJump)
        {
            return ExecuteNullableDouble(RedisMessage.Create(db, RedisLiteral.ZSCORE, key, member), queueJump);
        }
        Task<double?> ISortedSetCommands.Score(int db, string key, byte[] member, bool queueJump)
        {
            return ExecuteNullableDouble(RedisMessage.Create(db, RedisLiteral.ZSCORE, key, member), queueJump);
        }
        Task<bool> ISortedSetCommands.Remove(int db, string key, string member, bool queueJump)
        {   
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.ZREM, key, member), queueJump);
        }

        Task<bool> ISortedSetCommands.Remove(int db, string key, byte[] member, bool queueJump)
        {
            
            return ExecuteBoolean(RedisMessage.Create(db, RedisLiteral.ZREM, key, member), queueJump);
        }

        Task<long> ISortedSetCommands.Remove(int db, string key, string[] members, bool queueJump)
        {
            return ExecMultiAddRemove(db, RedisLiteral.ZREM, key, members, queueJump);
        }
        Task<long> ISortedSetCommands.Remove(int db, string key, byte[][] members, bool queueJump)
        {
            return ExecMultiAddRemove(db, RedisLiteral.ZREM, key, members, queueJump);
        }
        /// <summary>
        /// See SortedSets.RemoveRange
        /// </summary>
        [Obsolete("Please use the SortedSets API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> RemoveFromSortedSetByScore(int db, string key, int start, int stop, bool queueJump = false)
        {
            return SortedSets.RemoveRange(db, key, (double)start, (double)stop, queueJump);
        }
        Task<long> ISortedSetCommands.RemoveRange(int db, string key, long start, long stop, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.ZREMRANGEBYRANK, key, start, stop), queueJump);
        }

        Task<long> ISortedSetCommands.RemoveRange(int db, string key, double min, double max, bool minInclusive, bool maxInclusive, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.ZREMRANGEBYSCORE, key, RedisMessage.RedisParameter.Range(min, minInclusive), RedisMessage.RedisParameter.Range(max, maxInclusive)), queueJump);
        }

        Task<long> ISortedSetCommands.IntersectAndStore(int db, string destination, string[] keys, RedisAggregate aggregate, bool queueJump)
        {
            string[] parameters = new string[keys.Length + 3]; //prepend the number of keys and append the aggregate keyword and the aggregation type
            parameters[0] = keys.Length.ToString();
            keys.CopyTo(parameters, 1);
            parameters[keys.Length + 1] = "AGGREGATE";
            parameters[keys.Length + 2] = aggregate.ToString();

            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.ZINTERSTORE, destination, parameters), queueJump);          
        }

        Task<long> ISortedSetCommands.UnionAndStore(int db, string destination, string[] keys, RedisAggregate aggregate, bool queueJump)
        {
            string[] parameters = new string[keys.Length + 3]; //prepend the number of keys and append the aggregate keyword and the aggregation type
            parameters[0] = keys.Length.ToString();
            keys.CopyTo(parameters, 1);
            parameters[keys.Length + 1] = "AGGREGATE";
            parameters[keys.Length + 2] = aggregate.ToString();

            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.ZUNIONSTORE, destination, parameters), queueJump);
        }
    }
}
