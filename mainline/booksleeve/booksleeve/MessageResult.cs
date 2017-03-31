using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookSleeve
{
    internal interface IMessageResult
    {
        void Complete(RedisResult result, RedisMessage message, bool includeDetail);
        Task Task { get; }
    }

    internal abstract class MessageResult<T> : IMessageResult
    {
        protected virtual void ProcessError(RedisResult result, RedisMessage message, bool includeDetail)
        {
            var ex = result.Error();
            if (message != null && includeDetail) ex.Data.Add("redis-command", message.ToString());
            source.SafeSetException(ex);
        }
        private readonly TaskCompletionSource<T> source;
        public Task<T> Task { get { return source.Task; } }
        Task IMessageResult.Task { get { return source.Task; } }
        protected MessageResult(object state = null)
        {
            source = new TaskCompletionSource<T>(state);
        }
        public void Complete(RedisResult result, RedisMessage message, bool includeDetail)
        {
            if (result.IsCancellation)
            {
                source.TrySetCanceled();
            }
            else if (result.IsError)
            {
                ProcessError(result, message, includeDetail);
            }
            else
            {
                T value;
                try
                {
                    value = GetValue(result);
                }
                catch (Exception ex)
                {
                    source.SafeSetException(ex);
                    return;
                }
                source.TrySetResult(value);
            }
        }
        protected abstract T GetValue(RedisResult result);
    }
    internal sealed class MessageResultDouble : MessageResult<double>
    {
        public MessageResultDouble(object state = null) : base(state) { }
        protected override double  GetValue(RedisResult result) { return result.ValueDouble; }
    }
    internal sealed class MessageResultInt64 : MessageResult<long>
    {
        public MessageResultInt64(object state = null) : base(state) { }
        protected override long GetValue(RedisResult result) { return result.ValueInt64; }
    }
    internal sealed class MessageResultNullableInt64 : MessageResult<long?>
    {
        public MessageResultNullableInt64(object state = null) : base(state) { }
        protected override long? GetValue(RedisResult result) { return result.IsNil ? (long?)null : (long?)result.ValueInt64; }
    }
    internal sealed class MessageResultNullableDouble : MessageResult<double?>
    {
        public MessageResultNullableDouble(object state = null) : base(state) { }
        protected override double? GetValue(RedisResult result) { return result.IsNil ? (double?)null : (double?)result.ValueDouble; }
    }
    internal sealed class MessageResultBoolean : MessageResult<bool>
    {
        public MessageResultBoolean(object state = null) : base(state) { }
        protected override bool GetValue(RedisResult result) { return result.ValueBoolean; }
    }
    internal sealed class MessageResultString : MessageResult<string>
    {
        public MessageResultString(object state = null) : base(state) { }
        protected override string GetValue(RedisResult result) { return result.ValueString; }
    }
    internal sealed class MessageResultScript : MessageResult<object>
    {
        private readonly RedisConnection connection;
        private readonly bool inferStrings;
        protected override void ProcessError(RedisResult result, RedisMessage message, bool includeDetail)
        {
            try {
                var msg = result.Error().Message;
                if (msg.StartsWith("NOSCRIPT"))
                {   // only way of unloading is to unload all ("SCRIPT FLUSH")... so our
                    // existing cache is now completely toast
                    connection.ResetScriptCache();
                }
            } catch {
                /* best efforts only */
            }
            base.ProcessError(result, message, includeDetail);
        }
        public MessageResultScript(RedisConnection connection, bool inferStrings, object state = null) : base(state) {
            this.connection = connection;
            this.inferStrings = inferStrings;
        }
        protected override object GetValue(RedisResult result)
        {
            return result.Parse(inferStrings);
        }

    }
    internal sealed class MessageResultRaw : MessageResult<RedisResult>
    {
        public MessageResultRaw(object state = null) : base(state) { }
        protected override RedisResult GetValue(RedisResult result) { return result; }
    }
    internal sealed class MessageResultMultiString : MessageResult<string[]>
    {
        public MessageResultMultiString(object state = null) : base(state) { }
        protected override string[] GetValue(RedisResult result) { return result.ValueItemsString(); }
    }
    internal sealed class MessageResultBytes : MessageResult<byte[]>
    {
        public MessageResultBytes(object state = null) : base(state) { }
        protected override byte[] GetValue(RedisResult result) { return result.ValueBytes; }
    }
    internal sealed class MessageResultMultiBytes : MessageResult<byte[][]>
    {
        public MessageResultMultiBytes(object state = null) : base(state) { }
        protected override byte[][] GetValue(RedisResult result) { return result.ValueItemsBytes(); }
    }
    internal sealed class MessageResultPairs : MessageResult<KeyValuePair<byte[], double>[]>
    {
        protected override KeyValuePair<byte[], double>[] GetValue(RedisResult result) { return result.ExtractPairs(); }
    }
    internal sealed class MessageResultStringDoublePairs : MessageResult<KeyValuePair<string, double>[]>
    {
        protected override KeyValuePair<string, double>[] GetValue(RedisResult result) { return result.ExtractStringDoublePairs(); }
    }
    internal sealed class MessageResultHashPairs : MessageResult<Dictionary<string, byte[]>>
    {
        protected override Dictionary<string, byte[]> GetValue(RedisResult result) { return result.ExtractHashPairs(); }
    }
    internal sealed class MessageResultStringPairs : MessageResult<Dictionary<string, string>>
    {
        protected override Dictionary<string, string> GetValue(RedisResult result) { return result.ExtractStringPairs(); }
    }
    internal sealed class MessageResultVoid : MessageResult<bool>
    {
        public MessageResultVoid(object state = null) : base(state) { }
        public new Task Task { get { return base.Task; } }
        protected override bool GetValue(RedisResult result) { result.Assert(); return true; }
    }
    internal sealed class MessageLockResult : MessageResult<bool>
    {
        protected override bool GetValue(RedisResult result)
        {
            var items = result.ValueItems;
            return items != null;
        }
    }
}
