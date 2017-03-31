
using System.Threading.Tasks;
using System;
using System.ComponentModel;
using System.Text;
namespace BookSleeve
{
    /// <summary>
    /// Commands that apply to basic lists of items per key; lists
    /// preserve insertion order and have no enforced uniqueness (duplicates
    /// are allowed)
    /// </summary>
    /// <remarks>http://redis.io/commands#list</remarks>
    public interface IListCommands
    {
        /// <summary>
        /// Inserts value in the list stored at key either before or after the reference value pivot.
        /// </summary>
        /// <remarks>When key does not exist, it is considered an empty list and no operation is performed.</remarks>
        /// <returns>the length of the list after the insert operation, or -1 when the value pivot was not found.</returns>
        /// <remarks>http://redis.io/commands/linsert</remarks>
        Task<long> InsertBefore(int db, string key, byte[] pivot, byte[] value, bool queueJump = false);
        /// <summary>
        /// Inserts value in the list stored at key either before or after the reference value pivot.
        /// </summary>
        /// <remarks>When key does not exist, it is considered an empty list and no operation is performed.</remarks>
        /// <returns>the length of the list after the insert operation, or -1 when the value pivot was not found.</returns>
        /// <remarks>http://redis.io/commands/linsert</remarks>
        Task<long> InsertBefore(int db, string key, string pivot, string value, bool queueJump = false);
        /// <summary>
        /// Inserts value in the list stored at key either before or after the reference value pivot.
        /// </summary>
        /// <remarks>When key does not exist, it is considered an empty list and no operation is performed.</remarks>
        /// <returns>the length of the list after the insert operation, or -1 when the value pivot was not found.</returns>
        /// <remarks>http://redis.io/commands/linsert</remarks>
        Task<long> InsertAfter(int db, string key, byte[] pivot, byte[] value, bool queueJump = false);
        /// <summary>
        /// Inserts value in the list stored at key either before or after the reference value pivot.
        /// </summary>
        /// <remarks>When key does not exist, it is considered an empty list and no operation is performed.</remarks>
        /// <returns>the length of the list after the insert operation, or -1 when the value pivot was not found.</returns>
        /// <remarks>http://redis.io/commands/linsert</remarks>
        Task<long> InsertAfter(int db, string key, string pivot, string value, bool queueJump = false);

        /// <summary>
        /// Returns the element at index index in the list stored at key. The index is zero-based, so 0 means the first element, 1 the second element and so on. Negative indices can be used to designate elements starting at the tail of the list. Here, -1 means the last element, -2 means the penultimate and so forth.
        /// </summary>
        /// <returns>the requested element, or nil when index is out of range.</returns>
        /// <remarks>http://redis.io/commands/lindex</remarks>
        Task<byte[]> Get(int db, string key, int index, bool queueJump = false);
        /// <summary>
        /// Returns the element at index index in the list stored at key. The index is zero-based, so 0 means the first element, 1 the second element and so on. Negative indices can be used to designate elements starting at the tail of the list. Here, -1 means the last element, -2 means the penultimate and so forth.
        /// </summary>
        /// <returns>the requested element, or nil when index is out of range.</returns>
        /// <remarks>http://redis.io/commands/lindex</remarks>
        Task<string> GetString(int db, string key, int index, bool queueJump = false);
        /// <summary>
        /// Sets the list element at index to value. For more information on the index argument, see LINDEX.
        /// </summary>
        /// <remarks>An error is returned for out of range indexes.</remarks>
        /// <remarks>http://redis.io/commands/lset</remarks>
        Task Set(int db, string key, int index, string value, bool queueJump = false);
        /// <summary>
        /// Sets the list element at index to value. For more information on the index argument, see LINDEX.
        /// </summary>
        /// <remarks>An error is returned for out of range indexes.</remarks>
        /// <remarks>http://redis.io/commands/lset</remarks>
        Task Set(int db, string key, int index, byte[] value, bool queueJump = false);
        /// <summary>
        /// Returns the length of the list stored at key. If key does not exist, it is interpreted as an empty list and 0 is returned. 
        /// </summary>
        /// <returns>the length of the list at key.</returns>
        /// <remarks>http://redis.io/commands/llen</remarks>
        Task<long> GetLength(int db, string key, bool queueJump = false);
        /// <summary>
        /// Removes and returns the first element of the list stored at key.
        /// </summary>
        /// <returns>the value of the first element, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/lpop</remarks>
        Task<string> RemoveFirstString(int db, string key, bool queueJump = false);
        /// <summary>
        /// Removes and returns the first element of the list stored at key.
        /// </summary>
        /// <returns>the value of the first element, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/lpop</remarks>
        Task<byte[]> RemoveFirst(int db, string key, bool queueJump = false);
        /// <summary>
        /// Removes and returns the last element of the list stored at key.
        /// </summary>
        /// <returns>the value of the first element, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/rpop</remarks>
        Task<string> RemoveLastString(int db, string key, bool queueJump = false);
        /// <summary>
        /// Removes and returns the last element of the list stored at key.
        /// </summary>
        /// <returns>the value of the first element, or nil when key does not exist.</returns>
        /// <remarks>http://redis.io/commands/rpop</remarks>
        Task<byte[]> RemoveLast(int db, string key, bool queueJump = false);

        /// <summary>IMPORTANT: blocking commands will interrupt multiplexing, and should not be used on a connection being used by parallel consumers.
        /// BLPOP is a blocking list pop primitive. It is the blocking version of LPOP because it blocks the connection when there are no elements to pop from any of the given lists. An element is popped from the head of the first list that is non-empty, with the given keys being checked in the order that they are given. A timeout of zero can be used to block indefinitely.
        /// </summary>
        /// <returns>A null when no element could be popped and the timeout expired, otherwise the popped element.</returns>
        /// <remarks>http://redis.io/commands/blpop</remarks>
        Task<Tuple<string,string>> BlockingRemoveFirstString(int db, string[] keys, int timeoutSeconds, bool queueJump = false);
        /// <summary>IMPORTANT: blocking commands will interrupt multiplexing, and should not be used on a connection being used by parallel consumers.
        /// BLPOP is a blocking list pop primitive. It is the blocking version of LPOP because it blocks the connection when there are no elements to pop from any of the given lists. An element is popped from the head of the first list that is non-empty, with the given keys being checked in the order that they are given. A timeout of zero can be used to block indefinitely.
        /// </summary>
        /// <returns>A null when no element could be popped and the timeout expired, otherwise the popped element.</returns>
        /// <remarks>http://redis.io/commands/blpop</remarks>
        Task<Tuple<string, byte[]>> BlockingRemoveFirst(int db, string[] keys, int timeoutSeconds, bool queueJump = false);
        /// <summary>IMPORTANT: blocking commands will interrupt multiplexing, and should not be used on a connection being used by parallel consumers.
        /// BRPOP is a blocking list pop primitive. It is the blocking version of RPOP because it blocks the connection when there are no elements to pop from any of the given lists. An element is popped from the tail of the first list that is non-empty, with the given keys being checked in the order that they are given. A timeout of zero can be used to block indefinitely.
        /// </summary>
        /// <returns>A null when no element could be popped and the timeout expired, otherwise the popped element.</returns>
        /// <remarks>http://redis.io/commands/brpop</remarks>
        Task<Tuple<string, string>> BlockingRemoveLastString(int db, string[] keys, int timeoutSeconds, bool queueJump = false);
        /// <summary>IMPORTANT: blocking commands will interrupt multiplexing, and should not be used on a connection being used by parallel consumers.
        /// BRPOP is a blocking list pop primitive. It is the blocking version of RPOP because it blocks the connection when there are no elements to pop from any of the given lists. An element is popped from the tail of the first list that is non-empty, with the given keys being checked in the order that they are given. A timeout of zero can be used to block indefinitely.
        /// </summary>
        /// <returns>A null when no element could be popped and the timeout expired, otherwise the popped element.</returns>
        /// <remarks>http://redis.io/commands/brpop</remarks>
        Task<Tuple<string,byte[]>> BlockingRemoveLast(int db, string[] keys, int timeoutSeconds, bool queueJump = false);
        /// <summary>IMPORTANT: blocking commands will interrupt multiplexing, and should not be used on a connection being used by parallel consumers.
        /// BRPOPLPUSH is the blocking variant of RPOPLPUSH. When source contains elements, this command behaves exactly like RPOPLPUSH. When source is empty, Redis will block the connection until another client pushes to it or until timeout is reached. A timeout of zero can be used to block indefinitely.
        /// </summary>
        /// <string>For example: consider source holding the list a,b,c, and destination holding the list x,y,z. Executing RPOPLPUSH results in source holding a,b and destination holding c,x,y,z.</string>
        /// <remarks>If source does not exist, the value nil is returned and no operation is performed. If source and destination are the same, the operation is equivalent to removing the last element from the list and pushing it as first element of the list, so it can be considered as a list rotation command.</remarks>
        /// <returns>the element being popped and pushed.</returns>
        /// <remarks>http://redis.io/commands/brpoplpush</remarks>
        Task<byte[]> BlockingRemoveLastAndAddFirst(int db, string source, string destination, int timeoutSeconds, bool queueJump = false);
        /// <summary>IMPORTANT: blocking commands will interrupt multiplexing, and should not be used on a connection being used by parallel consumers.
        /// BRPOPLPUSH is the blocking variant of RPOPLPUSH. When source contains elements, this command behaves exactly like RPOPLPUSH. When source is empty, Redis will block the connection until another client pushes to it or until timeout is reached. A timeout of zero can be used to block indefinitely.
        /// </summary>
        /// <string>For example: consider source holding the list a,b,c, and destination holding the list x,y,z. Executing RPOPLPUSH results in source holding a,b and destination holding c,x,y,z.</string>
        /// <remarks>If source does not exist, the value nil is returned and no operation is performed. If source and destination are the same, the operation is equivalent to removing the last element from the list and pushing it as first element of the list, so it can be considered as a list rotation command.</remarks>
        /// <returns>the element being popped and pushed.</returns>
        /// <remarks>http://redis.io/commands/brpoplpush</remarks>
        Task<string> BlockingRemoveLastAndAddFirstString(int db, string source, string destination, int timeoutSeconds, bool queueJump = false);

        /// <summary>
        /// Inserts value at the head of the list stored at key. If key does not exist and createIfMissing is true, it is created as empty list before performing the push operation. 
        /// </summary>
        /// <returns> the length of the list after the push operation.</returns>
        /// <remarks>http://redis.io/commands/lpush</remarks>
        /// <remarks>http://redis.io/commands/lpushx</remarks>
        Task<long> AddFirst(int db, string key, string value, bool createIfMissing = true, bool queueJump = false);
        /// <summary>
        /// Inserts value at the head of the list stored at key. If key does not exist and createIfMissing is true, it is created as empty list before performing the push operation. 
        /// </summary>
        /// <returns> the length of the list after the push operation.</returns>
        /// <remarks>http://redis.io/commands/lpush</remarks>
        /// <remarks>http://redis.io/commands/lpushx</remarks>
        Task<long> AddFirst(int db, string key, byte[] value, bool createIfMissing = true, bool queueJump = false);
        /// <summary>
        /// Inserts value at the tail of the list stored at key. If key does not exist and createIfMissing is true, it is created as empty list before performing the push operation. 
        /// </summary>
        /// <returns> the length of the list after the push operation.</returns>
        /// <remarks>http://redis.io/commands/rpush</remarks>
        /// <remarks>http://redis.io/commands/rpushx</remarks>
        Task<long> AddLast(int db, string key, string value, bool createIfMissing = true, bool queueJump = false);
        /// <summary>
        /// Inserts value at the tail of the list stored at key. If key does not exist and createIfMissing is true, it is created as empty list before performing the push operation. 
        /// </summary>
        /// <returns> the length of the list after the push operation.</returns>
        /// <remarks>http://redis.io/commands/rpush</remarks>
        /// <remarks>http://redis.io/commands/rpushx</remarks>
        Task<long> AddLast(int db, string key, byte[] value, bool createIfMissing = true, bool queueJump = false);
        /// <summary>
        /// Removes the first count occurrences of elements equal to value from the list stored at key.
        /// </summary>
        /// <remarks>The count argument influences the operation in the following ways:
        /// count &gt; 0: Remove elements equal to value moving from head to tail.
        /// count &lt; 0: Remove elements equal to value moving from tail to head.
        /// count = 0: Remove all elements equal to value.
        /// For example, LREM list -2 "hello" will remove the last two occurrences of "hello" in the list stored at list.</remarks>
        /// <returns>the number of removed elements.</returns>
        /// <remarks>http://redis.io/commands/lrem</remarks>
        Task<long> Remove(int db, string key, string value, int count = 1, bool queueJump = false);
        /// <summary>
        /// Removes the first count occurrences of elements equal to value from the list stored at key.
        /// </summary>
        /// <remarks>The count argument influences the operation in the following ways:
        /// count &gt; 0: Remove elements equal to value moving from head to tail.
        /// count &lt; 0: Remove elements equal to value moving from tail to head.
        /// count = 0: Remove all elements equal to value.
        /// For example, LREM list -2 "hello" will remove the last two occurrences of "hello" in the list stored at list.</remarks>
        /// <returns>the number of removed elements.</returns>
        /// <remarks>http://redis.io/commands/lrem</remarks>
        Task<long> Remove(int db, string key, byte[] value, int count = 1, bool queueJump = false);

        /// <summary>
        /// Trim an existing list so that it will contain only the specified range of elements specified. Both start and stop are zero-based indexes, where 0 is the first element of the list (the head), 1 the next element and so on.
        /// start and end can also be negative numbers indicating offsets from the end of the list, where -1 is the last element of the list, -2 the penultimate element and so on.
        /// </summary>
        /// <example>For example: LTRIM foobar 0 2 will modify the list stored at foobar so that only the first three elements of the list will remain.</example>
        /// <remarks>Out of range indexes will not produce an error: if start is larger than the end of the list, or start > end, the result will be an empty list (which causes key to be removed). If end is larger than the end of the list, Redis will treat it like the last element of the list.</remarks>
        /// <remarks>http://redis.io/commands/ltrim</remarks>
        Task Trim(int db, string key, int start, int stop, bool queueJump = false);
        /// <summary>
        /// Trim an existing list so that it will contain only the specified count.
        /// </summary>
        /// <remarks>http://redis.io/commands/ltrim</remarks>
        Task Trim(int db, string key, int count, bool queueJump = false);

        /// <summary>
        /// Atomically returns and removes the last element (tail) of the list stored at source, and pushes the element at the first element (head) of the list stored at destination.
        /// </summary>
        /// <string>For example: consider source holding the list a,b,c, and destination holding the list x,y,z. Executing RPOPLPUSH results in source holding a,b and destination holding c,x,y,z.</string>
        /// <remarks>If source does not exist, the value nil is returned and no operation is performed. If source and destination are the same, the operation is equivalent to removing the last element from the list and pushing it as first element of the list, so it can be considered as a list rotation command.</remarks>
        /// <returns>the element being popped and pushed.</returns>
        /// <remarks>http://redis.io/commands/rpoplpush</remarks>
        Task<byte[]> RemoveLastAndAddFirst(int db, string source, string destination, bool queueJump = false);
        /// <summary>
        /// Atomically returns and removes the last element (tail) of the list stored at source, and pushes the element at the first element (head) of the list stored at destination.
        /// </summary>
        /// <string>For example: consider source holding the list a,b,c, and destination holding the list x,y,z. Executing RPOPLPUSH results in source holding a,b and destination holding c,x,y,z.</string>
        /// <remarks>If source does not exist, the value nil is returned and no operation is performed. If source and destination are the same, the operation is equivalent to removing the last element from the list and pushing it as first element of the list, so it can be considered as a list rotation command.</remarks>
        /// <returns>the element being popped and pushed.</returns>
        /// <remarks>http://redis.io/commands/rpoplpush</remarks>
        Task<string> RemoveLastAndAddFirstString(int db, string source, string destination, bool queueJump = false);
        /// <summary>
        /// Returns the specified elements of the list stored at key. The offsets start and end are zero-based indexes, with 0 being the first element of the list (the head of the list), 1 being the next element and so on.
        /// </summary>
        /// <remarks>These offsets can also be negative numbers indicating offsets starting at the end of the list. For example, -1 is the last element of the list, -2 the penultimate, and so on.</remarks>
        /// <returns>list of elements in the specified range.</returns>
        /// <remarks>http://redis.io/commands/lrange</remarks>
        Task<string[]> RangeString(int db, string key, int start, int stop, bool queueJump = false);
        /// <summary>
        /// Returns the specified elements of the list stored at key. The offsets start and end are zero-based indexes, with 0 being the first element of the list (the head of the list), 1 being the next element and so on.
        /// </summary>
        /// <remarks>These offsets can also be negative numbers indicating offsets starting at the end of the list. For example, -1 is the last element of the list, -2 the penultimate, and so on.</remarks>
        /// <returns>list of elements in the specified range.</returns>
        /// <remarks>http://redis.io/commands/lrange</remarks>
        Task<byte[][]> Range(int db, string key, int start, int stop, bool queueJump = false);
    }

    partial class RedisConnection : IListCommands
    {
        /// <summary>
        /// Commands that apply to basic lists of items per key; lists
        /// preserve insertion order and have no enforced uniqueness (duplicates
        /// are allowed)
        /// </summary>
        /// <remarks>http://redis.io/commands#list</remarks>
        public IListCommands Lists
        {
            get { return this; }
        }

        Task<long> IListCommands.InsertBefore(int db, string key, byte[] pivot, byte[] value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LINSERT, key, RedisLiteral.BEFORE, pivot, value), queueJump);
        }

        Task<long> IListCommands.InsertBefore(int db, string key, string pivot, string value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LINSERT, key, RedisLiteral.BEFORE, pivot, value), queueJump);
        }

        Task<long> IListCommands.InsertAfter(int db, string key, byte[] pivot, byte[] value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LINSERT, key, RedisLiteral.AFTER, pivot, value), queueJump);
        }

        Task<long> IListCommands.InsertAfter(int db, string key, string pivot, string value, bool queueJump)
        {
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LINSERT, key, RedisLiteral.AFTER, pivot, value), queueJump);
        }

        /// <summary>
        /// Returns the element at index index in the list stored at key. The index is zero-based, so 0 means the first element, 1 the second element and so on. Negative indices can be used to designate elements starting at the tail of the list. Here, -1 means the last element, -2 means the penultimate and so forth.
        /// </summary>
        /// <returns> the requested element, or nil when index is out of range.</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<string> GetStringFromList(int db, string key, int index, bool queueJump = false)
        {
            return Lists.GetString(db, key, index, queueJump);
        }
        /// <summary>
        /// Returns the element at index index in the list stored at key. The index is zero-based, so 0 means the first element, 1 the second element and so on. Negative indices can be used to designate elements starting at the tail of the list. Here, -1 means the last element, -2 means the penultimate and so forth.
        /// </summary>
        /// <returns> the requested element, or nil when index is out of range.</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[]> GetFromList(int db, string key, int index, bool queueJump = false)
        {
            return Lists.Get(db, key, index, queueJump);
        }
        Task<byte[]> IListCommands.Get(int db, string key, int index, bool queueJump)
        {
            
            return ExecuteBytes(RedisMessage.Create(db,RedisLiteral.LINDEX, key, index), queueJump);
        }

        Task<string> IListCommands.GetString(int db, string key, int index, bool queueJump)
        {
            
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.LINDEX, key, index), queueJump);
        }

        Task IListCommands.Set(int db, string key, int index, string value, bool queueJump)
        {
            
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.LSET, key, index, value).ExpectOk(), queueJump);
        }

        Task IListCommands.Set(int db, string key, int index, byte[] value, bool queueJump)
        {
            
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.LSET, key, index, value).ExpectOk(), queueJump);
        }

        /// <summary>
        /// Query the number of items in a list
        /// </summary>
        /// <param name="db">The database to operate on</param>
        /// <param name="key">The key of the list</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The number of items in the list, or 0 if it does not exist</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> ListLength(int db, string key, bool queueJump = false)
        {
            return Lists.GetLength(db, key, queueJump);
        }
        Task<long> IListCommands.GetLength(int db, string key, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LLEN, key), queueJump);
        }
        /// <summary>
        /// Removes an item from the start of a list
        /// </summary>
        /// <param name="db">The database to operatate on</param>
        /// <param name="key">The list to remove an item from</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The contents of the item removed, or null if empty</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[]> LeftPop(int db, string key, bool queueJump = false)
        {
            return Lists.RemoveFirst(db, key, queueJump);
        }
        /// <summary>
        /// Removes an item from the end of a list
        /// </summary>
        /// <param name="db">The database to operatate on</param>
        /// <param name="key">The list to remove an item from</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The contents of the item removed, or null if empty</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[]> RightPop(int db, string key, bool queueJump = false)
        {
            return Lists.RemoveLast(db, key, queueJump);
        }


        Task<string> IListCommands.RemoveFirstString(int db, string key, bool queueJump)
        {
            
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.LPOP, key), queueJump);
        }

        Task<byte[]> IListCommands.RemoveFirst(int db, string key, bool queueJump)
        {
            
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.LPOP, key), queueJump);
        }

        Task<string> IListCommands.RemoveLastString(int db, string key, bool queueJump)
        {
            
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.RPOP, key), queueJump);
        }

        Task<byte[]> IListCommands.RemoveLast(int db, string key, bool queueJump)
        {
            
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.RPOP, key), queueJump);
        }

        /// <summary>
        /// Prepend an item to a list
        /// </summary>
        /// <param name="db">The database to operate on</param>
        /// <param name="key">The key of the list</param>
        /// <param name="value">The item to add</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The number of items now in the list</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> LeftPush(int db, string key, byte[] value, bool queueJump = false)
        {
            return Lists.AddFirst(db, key, value, true, queueJump);
        }
        /// <summary>
        /// Prepend an item to a list
        /// </summary>
        /// <param name="db">The database to operate on</param>
        /// <param name="key">The key of the list</param>
        /// <param name="value">The item to add</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The number of items now in the list</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> LeftPush(int db, string key, string value, bool queueJump = false)
        {
            return Lists.AddFirst(db, key, value, true, queueJump);
        }
        Task<long> IListCommands.AddFirst(int db, string key, string value, bool createIfMissing, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, createIfMissing ? RedisLiteral.LPUSH : RedisLiteral.LPUSHX, key, value), queueJump);
        }

        Task<long> IListCommands.AddFirst(int db, string key, byte[] value, bool createIfMissing, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, createIfMissing ? RedisLiteral.LPUSH : RedisLiteral.LPUSHX, key, value), queueJump);
        }
        /// <summary>
        /// Append an item to a list
        /// </summary>
        /// <param name="db">The database to operate on</param>
        /// <param name="key">The key of the list</param>
        /// <param name="value">The item to add</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The number of items now in the list</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> RightPush(int db, string key, byte[] value, bool queueJump = false)
        {
            return Lists.AddLast(db, key, value, true, queueJump);
        }

        /// <summary>
        /// Append an item to a list
        /// </summary>
        /// <param name="db">The database to operate on</param>
        /// <param name="key">The key of the list</param>
        /// <param name="value">The item to add</param>
        /// <param name="queueJump">Whether to overtake unsent messages</param>
        /// <returns>The number of items now in the list</returns>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<long> RightPush(int db, string key, string value, bool queueJump = false)
        {
            return Lists.AddLast(db, key, value, true, queueJump);
        }
        Task<long> IListCommands.AddLast(int db, string key, string value, bool createIfMissing, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, createIfMissing ? RedisLiteral.RPUSH : RedisLiteral.RPUSHX, key, value), queueJump);
        }

        Task<long> IListCommands.AddLast(int db, string key, byte[] value, bool createIfMissing, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, createIfMissing ? RedisLiteral.RPUSH : RedisLiteral.RPUSHX, key, value), queueJump);
        }

        Task<long> IListCommands.Remove(int db, string key, string value, int count, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LREM, key, count, value), queueJump);
        }

        Task<long> IListCommands.Remove(int db, string key, byte[] value, int count, bool queueJump)
        {
            
            return ExecuteInt64(RedisMessage.Create(db, RedisLiteral.LREM, key, count, value), queueJump);
        }
        Task IListCommands.Trim(int db, string key, int count, bool queueJump)
        {
            if (count < 0) throw new ArgumentOutOfRangeException("count");
            if (count == 0) return Keys.Remove(db, key, queueJump);
            return Lists.Trim(db, key, 0, count - 1, queueJump);
        }
        Task IListCommands.Trim(int db, string key, int start, int stop, bool queueJump)
        {
            return ExecuteVoid(RedisMessage.Create(db, RedisLiteral.LTRIM, key, start, stop).ExpectOk(), queueJump);
        }


        /// <summary>
        /// See Lists.RemoveLastAndAddFirst
        /// </summary>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[]> PopFromListPushToList(int db, string from, string to, bool queueJump = false)
        {
            return Lists.RemoveLastAndAddFirst(db, from, to, queueJump);
        }
        Task<byte[]> IListCommands.RemoveLastAndAddFirst(int db, string source, string destination, bool queueJump)
        {
            return ExecuteBytes(RedisMessage.Create(db, RedisLiteral.RPOPLPUSH, source, destination), queueJump);
        }

        Task<string> IListCommands.RemoveLastAndAddFirstString(int db, string source, string destination, bool queueJump)
        {
            return ExecuteString(RedisMessage.Create(db, RedisLiteral.RPOPLPUSH, source, destination), queueJump);
        }


        /// <summary>
        /// See Lists.Range
        /// </summary>
        [Obsolete("Please use the Lists API", false), EditorBrowsable(EditorBrowsableState.Never)]
        public Task<byte[][]> ListRange(int db, string key, int start, int stop, bool queueJump = false)
        {
            return Lists.Range(db, key, start, stop, queueJump);    
        }
        Task<string[]> IListCommands.RangeString(int db, string key, int start, int stop, bool queueJump)
        {
            return ExecuteMultiString(RedisMessage.Create(db, RedisLiteral.LRANGE, key, start, (stop == int.MaxValue ? -1 : stop)), queueJump);
        }

        Task<byte[][]> IListCommands.Range(int db, string key, int start, int stop, bool queueJump)
        {
            return ExecuteMultiBytes(RedisMessage.Create(db, RedisLiteral.LRANGE, key, start, (stop == int.MaxValue ? -1 : stop)), queueJump);
        }


        static RedisMessage GetBlockingPop(int db, RedisLiteral command, string[] keys, int timeoutSeconds)
        {
            var args = new RedisMessage.RedisParameter[keys.Length + 1];
            for (int i = 0; i < keys.Length; i++)
                args[i] = keys[i];
            args[keys.Length] = timeoutSeconds;
            return RedisMessage.Create(db, command, args);
        }
        Task<Tuple<string, string>> IListCommands.BlockingRemoveFirstString(int db, string[] keys, int timeoutSeconds, bool queueJump)
        {
            var source = new TaskCompletionSource<Tuple<string, string>>();
            var msg = ExecuteMultiString(GetBlockingPop(db, RedisLiteral.BLPOP, keys, timeoutSeconds), queueJump, source);
            msg.ContinueWith(x => {
                var src = (TaskCompletionSource<Tuple<string, string>>)x.AsyncState;
                if(x.ShouldSetResult(src)) {
                    src.TrySetResult(x.Result == null ? null : Tuple.Create(x.Result[0], x.Result[1]));
                }
            });
            return source.Task;
        }
        Task<Tuple<string, byte[]>> IListCommands.BlockingRemoveFirst(int db, string[] keys, int timeoutSeconds, bool queueJump)
        {
            var source = new TaskCompletionSource<Tuple<string, byte[]>>();
            var msg = ExecuteMultiBytes(GetBlockingPop(db, RedisLiteral.BLPOP, keys, timeoutSeconds), queueJump, source);
            msg.ContinueWith(x => {
                var src = (TaskCompletionSource<Tuple<string, byte[]>>)x.AsyncState;
                if(x.ShouldSetResult(src)) {
                    src.TrySetResult(x.Result == null ? null : Tuple.Create(Encoding.UTF8.GetString(x.Result[0]), x.Result[1]));
                }
            });
            return source.Task;
        }
        Task<Tuple<string, string>> IListCommands.BlockingRemoveLastString(int db, string[] keys, int timeoutSeconds, bool queueJump)
        {
            var source = new TaskCompletionSource<Tuple<string, string>>();
            var msg = ExecuteMultiString(GetBlockingPop(db, RedisLiteral.BRPOP, keys, timeoutSeconds), queueJump, source);
            msg.ContinueWith(x => {
                var src = (TaskCompletionSource<Tuple<string, string>>)x.AsyncState;
                if (x.ShouldSetResult(src))
                {
                    src.TrySetResult(x.Result == null ? null : Tuple.Create(x.Result[0], x.Result[1]));
                }
            });
            return source.Task;
        }
        Task<Tuple<string, byte[]>> IListCommands.BlockingRemoveLast(int db, string[] keys, int timeoutSeconds, bool queueJump)
        {
            var source = new TaskCompletionSource<Tuple<string, byte[]>>();
            var msg = ExecuteMultiBytes(GetBlockingPop(db, RedisLiteral.BRPOP, keys, timeoutSeconds), queueJump, source);
            msg.ContinueWith(x => {
                var src = (TaskCompletionSource<Tuple<string, byte[]>>)x.AsyncState;
                if (x.ShouldSetResult(src))
                {
                    src.TrySetResult(x.Result == null ? null : Tuple.Create(Encoding.UTF8.GetString(x.Result[0]), x.Result[1]));
                }
            });
            return source.Task;
        }
        Task<byte[]> IListCommands.BlockingRemoveLastAndAddFirst(int db, string source, string destination, int timeoutSeconds, bool queueJump)
        {
            var taskSource = new TaskCompletionSource<byte[]>();
            var msg = ExecuteRaw(RedisMessage.Create(db, RedisLiteral.BRPOPLPUSH, source, destination, timeoutSeconds), queueJump, taskSource);
            msg.ContinueWith(x => {
                var src = (TaskCompletionSource<byte[]>)x.AsyncState;
                if (x.ShouldSetResult(src))
                {
                    src.TrySetResult(x.Result == null || x.Result is MultiRedisResult ? null : x.Result.ValueBytes);
                }
            });
            return taskSource.Task;
        }
        Task<string> IListCommands.BlockingRemoveLastAndAddFirstString(int db, string source, string destination, int timeoutSeconds, bool queueJump)
        {
            var taskSource = new TaskCompletionSource<string>();
            var msg = ExecuteRaw(RedisMessage.Create(db, RedisLiteral.BRPOPLPUSH, source, destination, timeoutSeconds), queueJump, taskSource);
            msg.ContinueWith(x => {
                var src = (TaskCompletionSource<string>)x.AsyncState;
                if (x.ShouldSetResult(src))
                {
                    src.TrySetResult(x.Result == null || x.Result is MultiRedisResult ? null : x.Result.ValueString);
                }
            });
            return taskSource.Task;
        }
    }
}
