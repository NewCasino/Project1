
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
namespace BookSleeve
{
    /// <summary>
    /// Describes a pre-condition used in a redis transaction
    /// </summary>
    public abstract class Condition
    {
        /// <summary>
        /// Enforces that the given key must exist
        /// </summary>
        public static Condition KeyExists(int db, string key)
        {
            return new ExistsCondition(db, key, null, true);
        }
        /// <summary>
        /// Enforces that the given key must not exist
        /// </summary>
        public static Condition KeyNotExists(int db, string key)
        {
            return new ExistsCondition(db, key, null, false);
        }
        /// <summary>
        /// Enforces that the given hash-field must exist
        /// </summary>
        public static Condition HashFieldExists(int db, string key, string hashField)
        {
            if (string.IsNullOrEmpty(hashField)) throw new ArgumentException("hashField");
            return new ExistsCondition(db, key, hashField, true);
        }
        /// <summary>
        /// Enforces that the given hash-field must not exist
        /// </summary>
        public static Condition HashFieldNotExists(int db, string key, string hashField)
        {
            if (string.IsNullOrEmpty(hashField)) throw new ArgumentException("hashField");
            return new ExistsCondition(db, key, hashField, false);
        }

        /// <summary>
        /// Enforces that the given key must have the specified value
        /// </summary>
        public static Condition KeyEquals(int db, string key, string value)
        {
            if (value == null) return KeyNotExists(db, key);
            return new StringEqualsCondition(db, key, null, true, value);
        }
        /// <summary>
        /// Enforces that the given key must have the specified value
        /// </summary>
        public static Condition KeyEquals(int db, string key, long? value)
        {
            if (value == null) return KeyNotExists(db, key);
            return new Int64EqualsCondition(db, key, null, true, value);
        }
        /// <summary>
        /// Enforces that the given key must not have the specified value
        /// </summary>
        public static Condition KeyNotEquals(int db, string key, string value)
        {
            if (value == null) return KeyExists(db, key);
            return new StringEqualsCondition(db, key, null, false, value);
        }
        /// <summary>
        /// Enforces that the given key must not have the specified value
        /// </summary>
        public static Condition KeyNotEquals(int db, string key, long? value)
        {
            if (value == null) return KeyExists(db, key);
            return new Int64EqualsCondition(db, key, null, false, value);
        }
        /// <summary>
        /// Enforces that the given hash-field must have the specified value
        /// </summary>
        public static Condition HashFieldEquals(int db, string key, string hashField, string value)
        {
            if (string.IsNullOrEmpty(hashField)) throw new ArgumentException("hashField");
            if (value == null) return HashFieldNotExists(db, key, hashField);
            return new StringEqualsCondition(db, key, hashField, true, value);
        }
        /// <summary>
        /// Enforces that the given hash-field must have the specified value
        /// </summary>
        public static Condition HashFieldEquals(int db, string key, string hashField, long? value)
        {
            if (string.IsNullOrEmpty(hashField)) throw new ArgumentException("hashField");
            if (value == null) return HashFieldNotExists(db, key, hashField);
            return new Int64EqualsCondition(db, key, hashField, true, value);
        }
        /// <summary>
        /// Enforces that the given hash-field must not have the specified value
        /// </summary>
        public static Condition HashFieldNotEquals(int db, string key, string hashField, string value)
        {
            if (string.IsNullOrEmpty(hashField)) throw new ArgumentException("hashField");
            if (value == null) return HashFieldExists(db, key, hashField);
            return new StringEqualsCondition(db, key, hashField, false, value);
        }
        /// <summary>
        /// Enforces that the given hash-field must not have the specified value
        /// </summary>
        public static Condition HashFieldNotEquals(int db, string key, string hashField, long? value)
        {
            if (string.IsNullOrEmpty(hashField)) throw new ArgumentException("hashField");
            if (value == null) return HashFieldExists(db, key, hashField);
            return new Int64EqualsCondition(db, key, hashField, false, value);
        }

        internal abstract Task<bool> Task { get; }
        internal bool Validate()
        {
            var task = Task;
            return task.Status == TaskStatus.RanToCompletion && task.Result;
        }
        private Condition() { }

        internal abstract IEnumerable<RedisMessage> CreateMessages();

        private abstract class EqualsCondition : Condition
        {
            readonly TaskCompletionSource<bool> result = new TaskCompletionSource<bool>();
            readonly bool expectedEqual;
            readonly int db;
            readonly string key, hashField;

            internal sealed override Task<bool> Task { get { return result.Task; } }

            // avoid lots of delegate creations
            static readonly Action<Task> testEquality =
                task =>
                {
                    var state = (EqualsCondition)task.AsyncState;
                    if (task.ShouldSetResult(state.result)) state.result.TrySetResult(state.ResultEquals(task) == state.expectedEqual);
                };

            internal sealed override IEnumerable<RedisMessage> CreateMessages()
            {
                yield return RedisMessage.Create(db, RedisLiteral.WATCH, key);
                var msgResult = CreateMessageResult(this);
                // we want this ExecuteSynchronously so that we can exploit the ordered nature of the reader to check all the
                // results efficiently
                msgResult.Task.ContinueWith(testEquality, TaskContinuationOptions.ExecuteSynchronously);
                var message = hashField == null ? RedisMessage.Create(db, RedisLiteral.GET, key)
                                                : RedisMessage.Create(db, RedisLiteral.HGET, key, hashField);
                message.SetMessageResult(msgResult);
                yield return message;
            }
            protected abstract IMessageResult CreateMessageResult(object state);
            protected abstract bool ResultEquals(Task completedTask);
            protected EqualsCondition(int db, string key, string hashField, bool expectedEqual)
            {
                if (string.IsNullOrEmpty(key)) throw new ArgumentException("key");
                this.db = db;
                this.key = key;
                this.hashField = hashField;
                this.expectedEqual = expectedEqual;
            }
        }
        private class StringEqualsCondition : EqualsCondition
        {
            public StringEqualsCondition(int db, string key, string hashField, bool expectedEqual, string expectedValue)
                : base(db, key, hashField, expectedEqual)
            {
                this.expectedValue = expectedValue;
            }
            readonly string expectedValue;
            protected override bool ResultEquals(Task completedTask)
            {
                return ((Task<string>)completedTask).Result == expectedValue;
            }
            protected override IMessageResult CreateMessageResult(object state)
            {
                return new MessageResultString(state);
            }            
        }
        private class Int64EqualsCondition : EqualsCondition
        {
            public Int64EqualsCondition(int db, string key, string hashField, bool expectedEqual, long? expectedValue)
                : base(db, key, hashField, expectedEqual)
            {
                this.expectedValue = expectedValue;
            }
            readonly long? expectedValue;
            protected override bool ResultEquals(Task completedTask)
            {
                return ((Task<long?>)completedTask).Result == expectedValue;
            }
            protected override IMessageResult CreateMessageResult(object state)
            {
                return new MessageResultNullableInt64(state);
            }
        }
        internal class ExistsCondition : Condition
        {
            readonly TaskCompletionSource<bool> result = new TaskCompletionSource<bool>();
            readonly bool expectedResult;
            readonly int db;
            readonly string key, hashField;

            public bool ExpectedResult { get { return expectedResult; } }
            public string HashField { get { return hashField; } }
            public string Key { get { return key; } }

            public ExistsCondition(int db, string key, string hashField, bool expectedResult)
            {
                if (string.IsNullOrEmpty(key)) throw new ArgumentException("key");
                this.key = key;
                this.hashField = hashField;
                this.db = db;
                this.expectedResult = expectedResult;
            }
            internal override Task<bool> Task { get { return result.Task; } }

            // avoid lots of delegate creations
            static readonly Action<Task<bool>> testExisted =
                task =>
                {
                    var state = (ExistsCondition)task.AsyncState;
                    if(task.ShouldSetResult(state.result)) state.result.TrySetResult(task.Result == state.expectedResult);
                };
            internal override IEnumerable<RedisMessage> CreateMessages()
            {
                yield return RedisMessage.Create(db, RedisLiteral.WATCH, key); 
                var msgResult = new MessageResultBoolean(this);
                // we want this ExecuteSynchronously so that we can exploit the ordered nature of the reader to check all the
                // results efficiently
                msgResult.Task.ContinueWith(testExisted, TaskContinuationOptions.ExecuteSynchronously);
                var message = hashField == null ? RedisMessage.Create(db, RedisLiteral.EXISTS, key)
                                                : RedisMessage.Create(db, RedisLiteral.HEXISTS, key, hashField);
                message.SetMessageResult(msgResult);   
                yield return message;
            }

        }
    }
}
