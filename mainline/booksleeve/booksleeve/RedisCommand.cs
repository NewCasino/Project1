using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace BookSleeve
{
    interface IMultiReplyMessage
    {
        bool Consume();
    }
    abstract class RedisMessage
    {
        private static readonly byte[][] literals;
        private static readonly RedisLiteral[] dbFree;
        
        static RedisMessage()
        {
            var arr = Enum.GetValues(typeof(RedisLiteral));
            literals = new byte[arr.Length][];
            foreach (RedisLiteral literal in arr)
            {
                literals[(int)literal] = Encoding.ASCII.GetBytes(literal.ToString().ToUpperInvariant());
            }
            List<RedisLiteral> tmp = new List<RedisLiteral>();
            var fields = typeof(RedisLiteral).GetFields(BindingFlags.Public | BindingFlags.Static);
            for (int i = 0; i < fields.Length; i++)
            {
                if (fields[i].IsDefined(typeof(DbFreeAttribute), false)) tmp.Add((RedisLiteral)fields[i].GetValue(null));
            }
            dbFree = tmp.ToArray();
        }

        private readonly int db;
        private readonly RedisLiteral command;
        private RedisLiteral expected = RedisLiteral.None;

        private byte flags;
        private const byte FLAGS_Critical = 0x01,
                           FLAGS_DuringInit = 0x02,
                           FLAGS_ForceAsync = 0x04,
                           FLAGS_ForceSync = 0x08;

        public bool MustSucceed
        {
            get { return (flags & FLAGS_Critical) != 0; }
        }
        public bool IsDuringInit
        {
            get { return (flags & FLAGS_DuringInit) != 0; }
        }
        private bool CompleteAsync
        {
            get { return (flags & FLAGS_ForceAsync) != 0; }
        }
        private bool CompleteSync
        {
            get { return (flags & FLAGS_ForceSync) != 0; }
        }
        internal void ForceAsync()
        {
            flags = (byte)((flags & ~FLAGS_ForceSync) | FLAGS_ForceAsync);
        }
        internal void ForceSync()
        {
            flags = (byte)((flags & ~FLAGS_ForceAsync) | FLAGS_ForceSync);
        }
        internal void DuringInit()
        {
            flags |= FLAGS_DuringInit;
        }
        public RedisMessage Critical()
        {
            flags |= FLAGS_Critical;
            return this;
        }
        public RedisMessage ExpectOk()
        {
            return Expect(RedisLiteral.OK);
        }
        public RedisMessage Expect(RedisLiteral result)
        {
            if (expected == RedisLiteral.None)
            {
                expected = result;
            }
            else
            {
                throw new InvalidOperationException();
            }
            return this;
        }
        public byte[] Expected
        {
            get
            {
                return expected == RedisLiteral.None ? null : literals[(int)expected];
            }
        }
        private IMessageResult messageResult;
        internal void SetMessageResult(IMessageResult messageResult)
        {
            if (Interlocked.CompareExchange(ref this.messageResult, messageResult, null) != null)
            {
                throw new InvalidOperationException("A message-result is already assigned");
            }
        }

        internal RedisConnectionBase.CallbackMode CallbackMode
        {
            get
            {
                if (CompleteAsync) return RedisConnectionBase.CallbackMode.Async; // explitly async
                if (CompleteSync) return RedisConnectionBase.CallbackMode.SyncUnchecked; // explicit sync (=safe, so unchecked)

                var msg = Interlocked.CompareExchange(ref this.messageResult, null, null);
                
                if (msg == null) return RedisConnectionBase.CallbackMode.SyncChecked; // there is no task to complete; do it sync

                var func = RedisConnectionBase.NoContinuations;
                if (func != null && func(msg.Task)) return RedisConnectionBase.CallbackMode.NoContinuation;
                return RedisConnectionBase.CallbackMode.Continuation;
            }
        }

        internal virtual void Complete(RedisResult result, bool includeDetail)
        {
            RedisConnectionBase.Trace("completed", "~ {0}", command);
            var snapshot = Interlocked.Exchange(ref messageResult, null); // only run once
            ChangeState(MessageState.Sent, MessageState.Complete);
            if (snapshot != null)
            {
                snapshot.Complete(result, this, includeDetail);
            }
        }
        private int messageState;
        internal bool ChangeState(MessageState from, MessageState to)
        {
            return Interlocked.CompareExchange(ref messageState, (int)to, (int)from) == (int)from;
        }
        public int Db { get { return db; } }
        public RedisLiteral Command { get { return command; } }
        protected RedisMessage(int db, RedisLiteral command)
        {
            bool isDbFree = false;
            for (int i = 0; i < dbFree.Length; i++)
            {
                if (dbFree[i] == command)
                {
                    isDbFree = true;
                    break;
                }
            }
            if (isDbFree)
            {
                if (db >= 0) throw new ArgumentOutOfRangeException("db", "A db is not required for " + command);
            }
            else
            {
                if (db < 0) throw new ArgumentOutOfRangeException("db", "A db must be specified for " + command);
            }
            this.db = db;
            this.command = command;

        }
        public static RedisMessage Create(int db, RedisLiteral command)
        {
            return new RedisMessageNix(db, command);
        }
        public static RedisMessage Create(int db, RedisLiteral command, RedisParameter arg0)
        {
            return new RedisMessageUni(db, command, arg0);
        }
        public static RedisMessage Create(int db, RedisLiteral command, string arg0)
        {
            return new RedisMessageUniString(db, command, arg0);
        }
        public static RedisMessage Create(int db, RedisLiteral command, string arg0, string arg1)
        {
            return new RedisMessageBiString(db, command, arg0, arg1);
        }
        public static RedisMessage Create(int db, RedisLiteral command, string arg0, string[] args)
        {
            if (args == null) return Create(db, command, arg0);
            switch (args.Length)
            {
                case 0:
                    return Create(db, command, arg0);
                case 1:
                    return Create(db, command, arg0, args[0]);
                default:
                    return new RedisMessageMultiString(db, command, arg0, args);
            }
        }
        public static RedisMessage Create(int db, RedisLiteral command, RedisParameter arg0, RedisParameter arg1)
        {
            return new RedisMessageBi(db, command, arg0, arg1);
        }
        public static RedisMessage Create(int db, RedisLiteral command, RedisParameter arg0, RedisParameter arg1, RedisParameter arg2)
        {
            return new RedisMessageTri(db, command, arg0, arg1, arg2);
        }
        public static RedisMessage Create(int db, RedisLiteral command, RedisParameter arg0, RedisParameter arg1, RedisParameter arg2, RedisParameter arg3)
        {
            return new RedisMessageQuad(db, command, arg0, arg1, arg2, arg3);
        }
        public abstract void Write(Stream stream);

        public static RedisMessage Create(int db, RedisLiteral command, string[] args)
        {
            if (args == null) return new RedisMessageNix(db, command);
            switch (args.Length)
            {
                case 0: return new RedisMessageNix(db, command);
                case 1: return new RedisMessageUni(db, command, args[0]);
                case 2: return new RedisMessageBi(db, command, args[0], args[1]);
                case 3: return new RedisMessageTri(db, command, args[0], args[1], args[2]);
                case 4: return new RedisMessageQuad(db, command, args[0], args[1], args[2], args[3]);
                default: return new RedisMessageMulti(db, command, Array.ConvertAll(args, s => (RedisParameter)s));
            }
        }
        public static RedisMessage Create(int db, RedisLiteral command, params RedisParameter[] args)
        {
            if (args == null) return new RedisMessageNix(db, command);
            switch (args.Length)
            {
                case 0: return new RedisMessageNix(db, command);
                case 1: return new RedisMessageUni(db, command, args[0]);
                case 2: return new RedisMessageBi(db, command, args[0], args[1]);
                case 3: return new RedisMessageTri(db, command, args[0], args[1], args[2]);
                case 4: return new RedisMessageQuad(db, command, args[0], args[1], args[2], args[3]);
                default: return new RedisMessageMulti(db, command, args);
            }
        }
        public override string ToString()
        {
            return db >= 0 ? (db + ": " + command) : command.ToString();
        }
        protected void WriteCommand(Stream stream, int argCount)
        {
            try
            {
                RedisConnectionBase.Trace("send", "write @{1}: {0}", this, stream.Position);
                stream.WriteByte((byte)'*');
                WriteRaw(stream, argCount + 1);
                WriteUnified(stream, command);
            }
            catch(Exception ex)
            {
                RedisConnectionBase.Trace("send", ex.Message);
                throw;
            }
        }
        protected static void WriteUnified(Stream stream, RedisLiteral value)
        {
            WriteUnified(stream, literals[(int)value]);
        }
        protected static void WriteUnified(Stream stream, string value)
        {
            WriteUnified(stream, Encoding.UTF8.GetBytes(value));
        }
        protected static void WriteUnified(Stream stream, byte[] value)
        {
            stream.WriteByte((byte)'$');
            WriteRaw(stream, value.Length);
            stream.Write(value, 0, value.Length);
            stream.Write(Crlf, 0, 2);
        }
        protected static void WriteUnified(Stream stream, long value)
        {
            // note: need to use string version "${len}\r\n{data}\r\n", not intger version ":{data}\r\n"
            // when this is part of a multi-block message (which unified *is*)
            if (value >= 0 && value <= 99)
            { // low positive integers are very common; special-case them
                int i = (int)value;
                if (i <= 9)
                {
                    stream.Write(oneByteIntegerPrefix, 0, oneByteIntegerPrefix.Length);
                    stream.WriteByte((byte)((int)'0' + i));
                }
                else
                {
                    stream.Write(twoByteIntegerPrefix, 0, twoByteIntegerPrefix.Length);
                    stream.WriteByte((byte)((int)'0' + (i / 10)));
                    stream.WriteByte((byte)((int)'0' + (i % 10)));
                }
            }
            else
            {
                // not *quite* as efficient, but fine
                var bytes = Encoding.ASCII.GetBytes(value.ToString());
                stream.WriteByte((byte)'$');
                WriteRaw(stream, bytes.Length);
                stream.Write(bytes, 0, bytes.Length);
            }
            stream.Write(Crlf, 0, 2);
        }
        protected static void WriteUnified(Stream stream, double value)
        {
            int i;
            if (value >= int.MinValue && value <= int.MaxValue && (i = (int)value) == value)
            {
                WriteUnified(stream, i); // use integer handling
            }
            else
            {
                WriteUnified(stream, ToString(value));
            }
        }
        private static string ToString(long value)
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }
        internal static string ToString(double value)
        {
            if (double.IsInfinity(value))
            {
                if (double.IsPositiveInfinity(value)) return "+inf";
                if (double.IsNegativeInfinity(value)) return "-inf";
            }
            return value.ToString("G", CultureInfo.InvariantCulture);
        }
        protected static void WriteRaw(Stream stream, long value)
        {
            if (value >= 0 && value <= 9)
            {
                stream.WriteByte((byte)((int)'0' + (int)value));
            }
            else if (value < 0 && value >= -9)
            {
                stream.WriteByte((byte)'-');
                stream.WriteByte((byte)((int)'0' - (int)value));
            }
            else
            {
                var bytes = Encoding.ASCII.GetBytes(value.ToString());
                stream.Write(bytes, 0, bytes.Length);
            }
            stream.Write(Crlf, 0, 2);
        }
        private static readonly byte[]
            oneByteIntegerPrefix = Encoding.ASCII.GetBytes("$1\r\n"),
            twoByteIntegerPrefix = Encoding.ASCII.GetBytes("$2\r\n");
        private static readonly byte[] Crlf = Encoding.ASCII.GetBytes("\r\n");


        sealed class RedisMessageSub : RedisMessage, IMultiReplyMessage
        {
            private int remainingReplies;
            public bool Consume()
            {
                return Interlocked.Decrement(ref remainingReplies) == 0;
            }
            public RedisMessageSub(RedisLiteral command, string[] keys)
                : base(-1, command)
            {
                if (keys == null) throw new ArgumentNullException("keys");
                if (keys.Length == 0) throw new ArgumentException("keys cannot be empty", "keys");
                this.keys = keys;
                this.remainingReplies = keys.Length;
            }
            private readonly string[] keys;
            public override void Write(Stream stream)
            {
                WriteCommand(stream, keys.Length);
                for (int i = 0; i < keys.Length; i++)
                    WriteUnified(stream, keys[i]);
            }
            public override string ToString()
            {
                StringBuilder sb = new StringBuilder(base.ToString());
                for (int i = 0; i < keys.Length; i++)
                    sb.Append(" ").Append(keys[i]);
                return sb.ToString();
            }
        }
        sealed class RedisMessageNix : RedisMessage
        {
            public RedisMessageNix(int db, RedisLiteral command)
                : base(db, command)
            { }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 0);
            }
        }
        sealed class RedisMessageUni : RedisMessage
        {
            private readonly RedisParameter arg0;
            public RedisMessageUni(int db, RedisLiteral command, RedisParameter arg0)
                : base(db, command)
            {
                this.arg0 = arg0;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 1);
                arg0.Write(stream);
            }
            public override string ToString()
            {
                return base.ToString() + " " + arg0.ToString();
            }
        }
        sealed class RedisMessageUniString : RedisMessage
        {
            private readonly string arg0;
            public RedisMessageUniString(int db, RedisLiteral command, string arg0)
                : base(db, command)
            {
                if (arg0 == null) throw new ArgumentNullException("arg0");
                this.arg0 = arg0;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 1);
                WriteUnified(stream, arg0);
            }
            public override string ToString()
            {
                return base.ToString() + " " + arg0;
            }
        }
        sealed class RedisMessageBiString : RedisMessage
        {
            private readonly string arg0, arg1;
            public RedisMessageBiString(int db, RedisLiteral command, string arg0, string arg1)
                : base(db, command)
            {
                if (arg0 == null) throw new ArgumentNullException("arg0");
                if (arg1 == null) throw new ArgumentNullException("arg1");
                this.arg0 = arg0;
                this.arg1 = arg1;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 2);
                WriteUnified(stream, arg0);
                WriteUnified(stream, arg1);
            }
            public override string ToString()
            {
                return base.ToString() + " " + arg0 + " " + arg1;
            }
        }
        sealed class RedisMessageMultiString : RedisMessage
        {
            private readonly string arg0;
            private readonly string[] args;
            public RedisMessageMultiString(int db, RedisLiteral command, string arg0, string[] args)
                : base(db, command)
            {
                if (arg0 == null) throw new ArgumentNullException("arg0");
                if (args == null) throw new ArgumentNullException("args");
                for (int i = 0; i < args.Length; i++)
                {
                    if (args[i] == null) throw new ArgumentNullException("args:" + i);
                }
                this.arg0 = arg0;
                this.args = args;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 1 + args.Length);
                WriteUnified(stream, arg0);
                for (int i = 0; i < args.Length; i++)
                    WriteUnified(stream, args[i]);
            }
            public override string ToString()
            {
                StringBuilder sb = new StringBuilder(base.ToString()).Append(" ").Append(arg0);
                for (int i = 0; i < args.Length; i++)
                    sb.Append(" ").Append(args[i]);
                return sb.ToString();
            }
        }
        sealed class RedisMessageBi : RedisMessage
        {
            private readonly RedisParameter arg0, arg1;
            public RedisMessageBi(int db, RedisLiteral command, RedisParameter arg0, RedisParameter arg1)
                : base(db, command)
            {
                this.arg0 = arg0;
                this.arg1 = arg1;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 2);
                arg0.Write(stream);
                arg1.Write(stream);
            }
            public override string ToString()
            {
                return base.ToString() + " " + arg0.ToString() + " " + arg1.ToString();
            }
        }
        sealed class RedisMessageTri : RedisMessage
        {
            private readonly RedisParameter arg0, arg1, arg2;
            public RedisMessageTri(int db, RedisLiteral command, RedisParameter arg0, RedisParameter arg1, RedisParameter arg2)
                : base(db, command)
            {
                this.arg0 = arg0;
                this.arg1 = arg1;
                this.arg2 = arg2;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 3);
                arg0.Write(stream);
                arg1.Write(stream);
                arg2.Write(stream);
            }
            public override string ToString()
            {
                return base.ToString() + " " + arg0.ToString() + " " + arg1.ToString() + " " + arg2.ToString();
            }
        }
        sealed class RedisMessageQuad : RedisMessage
        {
            private readonly RedisParameter arg0, arg1, arg2, arg3;
            public RedisMessageQuad(int db, RedisLiteral command, RedisParameter arg0, RedisParameter arg1, RedisParameter arg2, RedisParameter arg3)
                : base(db, command)
            {
                this.arg0 = arg0;
                this.arg1 = arg1;
                this.arg2 = arg2;
                this.arg3 = arg3;
            }
            public override void Write(Stream stream)
            {
                WriteCommand(stream, 4);
                arg0.Write(stream);
                arg1.Write(stream);
                arg2.Write(stream);
                arg3.Write(stream);
            }
            public override string ToString()
            {
                return base.ToString() + " " + arg0.ToString() + " " + arg1.ToString() + " " + arg2.ToString() + " " + arg3.ToString();
            }
        }
        sealed class RedisMessageMulti : RedisMessage
        {
            private readonly RedisParameter[] args;
            public RedisMessageMulti(int db, RedisLiteral command, RedisParameter[] args)
                : base(db, command)
            {
                this.args = args;
            }
            public override void Write(Stream stream)
            {
                if (args == null)
                {
                    WriteCommand(stream, 0);
                }
                else
                {
                    WriteCommand(stream, args.Length);
                    for (int i = 0; i < args.Length; i++)
                        args[i].Write(stream);
                }
            }
            public override string ToString()
            {
                StringBuilder sb = new StringBuilder(base.ToString());
                for (int i = 0; i < args.Length; i++)
                    sb.Append(" ").Append(args[i]);
                return sb.ToString();
            }
        }
        internal abstract class RedisParameter
        {
            public static implicit operator RedisParameter(RedisLiteral value) { return new RedisLiteralParameter(value); }
            public static implicit operator RedisParameter(string value) { return new RedisStringParameter(value); }
            public static implicit operator RedisParameter(byte[] value) { return new RedisBlobParameter(value); }
            public static implicit operator RedisParameter(long value) { return new RedisInt64Parameter(value); }
            public static implicit operator RedisParameter(double value) { return new RedisDoubleParameter(value); }
            public static RedisParameter Range(long value, bool inclusive)
            {
                if (inclusive) return new RedisInt64Parameter(value);
                return new RedisStringParameter("(" + RedisMessage.ToString(value));
            }
            public static RedisParameter Range(double value, bool inclusive)
            {
                if (inclusive) return new RedisDoubleParameter(value);
                return new RedisStringParameter("(" + RedisMessage.ToString(value));
            }
            public abstract void Write(Stream stream);
            class RedisLiteralParameter : RedisParameter
            {
                private readonly RedisLiteral value;
                public RedisLiteralParameter(RedisLiteral value) { this.value = value; }
                public override void Write(Stream stream)
                {
                    WriteUnified(stream, value);
                }
                public override string ToString()
                {
                    return value.ToString();
                }
            }
            class RedisStringParameter : RedisParameter
            {
                private readonly string value;
                public RedisStringParameter(string value)
                {
                    if (value == null) throw new ArgumentNullException("value");
                    this.value = value;
                }
                public override void Write(Stream stream)
                {
                    WriteUnified(stream, value);
                }
                public override string ToString()
                {
                    if (value == null) return "**NULL**";
                    if (value.Length < 20) return "\"" + value + "\"";
                    return "\"" + value.Substring(0, 15) + "...[" + value.Length.ToString() + "]";
                }
            }
            class RedisBlobParameter : RedisParameter
            {
                private readonly byte[] value;
                public RedisBlobParameter(byte[] value)
                {
                    if (value == null) throw new ArgumentNullException("value");
                    this.value = value;
                }
                public override void Write(Stream stream)
                {
                    WriteUnified(stream, value);
                }
                public override string ToString()
                {
                    if (value == null) return "**NULL**";
                    return "{" + value.Length.ToString() + " bytes}";
                }
            }
            class RedisInt64Parameter : RedisParameter
            {
                private readonly long value;
                public RedisInt64Parameter(long value) { this.value = value; }
                public override void Write(Stream stream)
                {
                    WriteUnified(stream, value);
                }
                public override string ToString()
                {
                    return value.ToString();
                }
            }
            class RedisDoubleParameter : RedisParameter
            {
                private readonly double value;
                public RedisDoubleParameter(double value) { this.value = value; }
                public override void Write(Stream stream)
                {
                    WriteUnified(stream, value);
                }
                public override string ToString()
                {
                    return value.ToString();
                }
            }

            internal static RedisParameter Create(object value)
            {
                if (value == null) throw new ArgumentNullException("value");
                switch (Type.GetTypeCode(value.GetType()))
                {
                    case TypeCode.String:
                        return (string)value;
                    case TypeCode.Single:
                        return (float)value;
                    case TypeCode.Double:
                        return (double)value;
                    case TypeCode.Byte:
                        return (byte)value;
                    case TypeCode.SByte:
                        return (sbyte)value;
                    case TypeCode.Int16:
                        return (short)value;
                    case TypeCode.Int32:
                        return (int)value;
                    case TypeCode.Int64:
                        return (long)value;
                    case TypeCode.Boolean:
                        return (bool)value ? 1 : 0;
                    default:
                        var blob = value as byte[];
                        if (blob != null) return blob;
                        throw new ArgumentException("Data-type not supported: " + value.GetType());

                }
            }
        }

        internal static RedisMessage CreateMultiSub(RedisLiteral redisLiteral, string[] keys)
        {
            return keys.Length == 1 ? Create(-1, redisLiteral, keys[0])
                : new RedisMessageSub(redisLiteral, keys);
        }
    }
    internal class QueuedMessage : RedisMessage
    {
        private readonly RedisMessage innnerMessage;

        public RedisMessage InnerMessage { get { return innnerMessage; } }
        public QueuedMessage(RedisMessage innnerMessage)
            : base(innnerMessage.Db, innnerMessage.Command)
        {
            if (innnerMessage == null) throw new ArgumentNullException("innnerMessage");
            this.innnerMessage = innnerMessage;
            Expect(RedisLiteral.QUEUED).Critical();
        }
        public override void Write(Stream stream)
        {
            innnerMessage.Write(stream);
        }
    }
    internal interface IMultiMessage
    {
        void Execute(RedisConnectionBase redisConnectionBase, ref int currentDb);
    }
    internal class BatchMessage : RedisMessage, IMultiMessage
    {
        private RedisMessage[] messages;
        public BatchMessage(RedisMessage[] messages) : base(-1, RedisLiteral.PING)
        {
            if (messages == null) throw new ArgumentNullException("messages");
            this.messages = messages;
        }
        public override void Write(Stream stream)
        {
            throw new NotSupportedException();
        }
        internal override void Complete(RedisResult result, bool includeDetail)
        {
            throw new NotSupportedException();
        }
        public void Execute(RedisConnectionBase conn, ref int currentDb)
        {
            for(int i = 0 ; i < messages.Length ; i++)
            {
                conn.WriteMessage(ref currentDb, messages[i], null);
            }
        }
    }
    internal class MultiMessage : RedisMessage, IMultiMessage
    {
        void IMultiMessage.Execute(RedisConnectionBase conn, ref int currentDb)
        {
            var pending = messages;

            if (ExecutePreconditions(conn, ref currentDb))
            {
                conn.WriteRaw(this); // MULTI
                List<QueuedMessage> newlyQueued = new List<QueuedMessage>(pending.Length); // estimate same length
                for (int i = 0; i < pending.Length; i++)
                {
                    conn.WriteMessage(ref currentDb, pending[i], newlyQueued);
                }
                newlyQueued.TrimExcess();
                conn.WriteMessage(ref currentDb, Execute(newlyQueued), null);
            }
            else
            {
                // preconditions failed; ABORT
                conn.WriteMessage(ref currentDb, RedisMessage.Create(-1, RedisLiteral.UNWATCH).ExpectOk().Critical(), null);

                // even though these weren't written, we still need to mark them cancelled
                exec.Abort(pending);
                // spoof a rollback; same appearance to the caller
                exec.Complete(RedisResult.Multi(null), false);
            }
        }

        private bool ExecutePreconditions(RedisConnectionBase conn, ref int currentDb)
        {
            if (conditions == null || conditions.Count == 0) return true;

            Task lastTask = null;
            foreach (var cond in conditions)
            {
                lastTask = cond.Task;
                foreach (var msg in cond.CreateMessages())
                {
                    msg.ForceSync();
                    conn.WriteMessage(ref currentDb, msg, null);
                }
            }
            conn.Flush(true); // make sure we send it all

            // now need to check all the preconditions passed
            if (lastTask != null)
            {
                // didn't get result fast enough; treat as abort
                if (!lastTask.Wait(conn.SyncTimeout)) return false;
            }

            foreach (var cond in conditions)
            {
                if (!cond.Validate()) return false;
            }

            return true;
        }
        private readonly List<Condition> conditions;
        public MultiMessage(RedisConnection parent, RedisMessage[] messages, List<Condition> conditions, object state)
            : base(-1, RedisLiteral.MULTI)
        {
            exec = new ExecMessage(parent, state);
            this.conditions = conditions;
            this.messages = messages;
            ExpectOk().Critical();
        }
        private RedisMessage[] messages;
        public override void Write(Stream stream)
        {
            WriteCommand(stream, 0);
        }
        private readonly ExecMessage exec;
        public RedisMessage Execute(List<QueuedMessage> queued)
        {
            exec.SetQueued(queued);
            return exec;
        }
        public Task<bool> Completion { get { return exec.Completion; } }
    }
    internal class ExecMessage : RedisMessage, IMessageResult
    {
        private RedisConnection parent;
        public ExecMessage(RedisConnection parent, object state)
            : base(-1, RedisLiteral.EXEC)
        {
            if (parent == null) throw new ArgumentNullException("parent");
            this.completion = new TaskCompletionSource<bool>(state);
            SetMessageResult(this);
            this.parent = parent;
            Critical();
        }
        private readonly TaskCompletionSource<bool> completion;

        public override void Write(Stream stream)
        {
            WriteCommand(stream, 0);
        }
        Task IMessageResult.Task { get { return completion.Task; } }
        public Task<bool> Completion { get { return completion.Task; } }
        private QueuedMessage[] queued;
        internal void SetQueued(List<QueuedMessage> queued)
        {
            if (queued == null) throw new ArgumentNullException("queued");
            if (this.queued != null) throw new InvalidOperationException();
            this.queued = queued.ToArray();
        }

        public void Abort(RedisMessage[] messages)
        {
            if (messages != null)
            {
                for (int i = 0; i < messages.Length; i++)
                {
                    var reply = RedisResult.Cancelled;
                    RedisConnectionBase.CallbackMode callbackMode;
                    var ctx = parent.ProcessReply(ref reply, messages[i], out callbackMode);
                    RedisConnectionBase.Trace("transaction", "{0} = {1}", ctx, reply);
                    parent.ProcessCallbacks(ctx, reply, callbackMode);
                }
            }
        }
        void SetInnerReplies(RedisResult result)
        {
            if (queued != null)
            {
                for (int i = 0; i < queued.Length; i++)
                {
                    var reply = result; // need to be willing for this to be mutated
                    RedisConnectionBase.CallbackMode callbackMode;
                    var ctx = parent.ProcessReply(ref reply, queued[i].InnerMessage, out callbackMode);
                    RedisConnectionBase.Trace("transaction", "{0} = {1}", ctx, reply);
                    parent.ProcessCallbacks(ctx, reply, callbackMode);
                }
            }
        }
        void IMessageResult.Complete(RedisResult result, RedisMessage message, bool includeDetail)
        {
            if (result.IsCancellation)
            {
                RedisConnectionBase.Trace("transaction", "cancelled");
                SetInnerReplies(result);
                completion.TrySetCanceled();
            }
            else if (result.IsError)
            {
                RedisConnectionBase.Trace("transaction", "error");
                SetInnerReplies(result);
                completion.SafeSetException(result.Error());
            }
            else
            {
                try
                {
                    if (result.IsNil)
                    {   // aborted
                        RedisConnectionBase.Trace("transaction", "aborted");
                        SetInnerReplies(RedisResult.Cancelled);
                        completion.TrySetResult(false);
                    }
                    else
                    {
                        var items = result.ValueItems;
                        if (items.Length != (queued == null ? 0 : queued.Length))
                            throw new InvalidOperationException(string.Format("{0} results expected, {1} received", queued.Length, items.Length));

                        RedisConnectionBase.Trace("transaction", "success");
                        for (int i = 0; i < items.Length; i++)
                        {
                            RedisResult reply = items[i];
                            RedisConnectionBase.CallbackMode callbackMode;
                            var ctx = parent.ProcessReply(ref reply, queued[i].InnerMessage, out callbackMode);
                            RedisConnectionBase.Trace("transaction", "{0} = {1}", ctx, reply);
                            parent.ProcessCallbacks(ctx, reply, callbackMode);
                        }
                        completion.TrySetResult(true);
                    }
                }
                catch (Exception ex)
                {
                    completion.SafeSetException(ex);
                    throw;
                }
            }
        }
    }
    internal class PingMessage : RedisMessage
    {
        private readonly DateTime created;
        private DateTime sent, received;
        public PingMessage()
            : base(-1, RedisLiteral.PING)
        {
            created = DateTime.UtcNow;
            Expect(RedisLiteral.PONG).Critical();
        }
        public override void Write(Stream stream)
        {
            WriteCommand(stream, 0);
            if (sent == DateTime.MinValue) sent = DateTime.UtcNow;

        }
        internal override void Complete(RedisResult result, bool includeDetail)
        {
            received = DateTime.UtcNow;
            base.Complete(result.IsError ? result : new RedisResult.TimingRedisResult(
                sent - created, received - sent), includeDetail);
        }
    }

    [AttributeUsage(AttributeTargets.Field, AllowMultiple = false, Inherited = false)]
    sealed internal class DbFreeAttribute : Attribute { }

    enum RedisLiteral
    {
        None = 0,
        // responses
        OK, QUEUED, PONG,
        // commands (extracted from http://redis.io/commands)
        APPEND,
        [DbFree]
        AUTH, BGREWRITEAOF, BITCOUNT, BITOP, BGSAVE, BLPOP, BRPOP, BRPOPLPUSH,
        [DbFree]
        CLIENT,
        [DbFree]
        SETNAME,
        [DbFree]
        CONFIG,
        GET, SET, RESETSTAT, DBSIZE, DEBUG, OBJECT, SEGFAULT, DECR, DECRBY, DEL,
        [DbFree]
        DISCARD,
        [DbFree]
        ECHO, EVAL, EVALSHA,
        [DbFree]
        EXEC, EXISTS, EXPIRE, EXPIREAT,
        [DbFree]
        FLUSHALL, FLUSHDB, GETBIT, GETRANGE, GETSET, HDEL, HEXISTS, HGET, HGETALL, HINCRBY, HINCRBYFLOAT, HKEYS, HLEN, HMGET, HMSET, HSET, HSETNX, HVALS, INCR, INCRBY, INCRBYFLOAT,
        [DbFree]
        INFO, KEYS, LASTSAVE, LINDEX, LINSERT, LLEN, LPOP, LPUSH, LPUSHX, LRANGE, LREM, LSET, LTRIM, MGET,
        [DbFree]
        MONITOR, MOVE, MSET, MSETNX,
        [DbFree]
        MULTI, PERSIST,
        [DbFree]
        PING,
        [DbFree]
        PSUBSCRIBE,
        [DbFree]
        PUBLISH,
        [DbFree]
        PUNSUBSCRIBE,
        [DbFree]
        QUIT, RANDOMKEY, RENAME, RENAMENX, RPOP, RPOPLPUSH, RPUSH, RPUSHX, SADD, SAVE, SCARD,
        [DbFree]
        SCRIPT,
        [DbFree]
        SENTINEL,
        SDIFF, SDIFFSTORE, SELECT, SETBIT, SETEX, SETNX, SETRANGE, SHUTDOWN, SINTER, SINTERSTORE, SISMEMBER,
        [DbFree]
        SLAVEOF, SLOWLOG, SMEMBERS, SMOVE, SORT, SPOP, SRANDMEMBER, SREM, STRLEN,
        [DbFree]
        SUBSCRIBE, SUBSTR, SUNION, SUNIONSTORE, SYNC, TTL, TYPE,
        [DbFree]
        TIME,
        [DbFree]
        UNSUBSCRIBE,
        [DbFree]
        UNWATCH,
        DUMP, RESTORE,
        WATCH, ZADD, ZCARD, ZCOUNT, ZINCRBY, ZINTERSTORE, ZRANGE, ZRANGEBYSCORE, ZRANK, ZREM, ZREMRANGEBYRANK, ZREMRANGEBYSCORE, ZREVRANGE, ZREVRANGEBYSCORE, ZREVRANK, ZSCORE, ZUNIONSTORE,
        // other
        NO, ONE, WITHSCORES, LIMIT, LOAD, BEFORE, AFTER, AGGREGATE, WEIGHTS, SUM, MIN, MAX, FLUSH, AND, OR, NOT, XOR, LIST, KILL, STORE, BY, ALPHA, DESC, NX, EX, PX, XX,

        // redis-cluster
        [DbFree]
        CLUSTER, NODES
    }
}