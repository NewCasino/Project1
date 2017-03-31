using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;
using System.ComponentModel;

namespace BookSleeve
{
    /// <summary>
    /// A thread-safe, multiplexed connection to a Redis server; each connection
    /// should be cached and re-used (without synchronization) from multiple
    /// callers for maximum efficiency. Usually only a single RedisConnection
    /// is required
    /// </summary>
    public partial class RedisConnection : RedisConnectionBase
    {
        /// <summary>
        /// Constants representing the different storage devices in redis
        /// </summary>
        public static class ItemTypes
        {
            /// <summary>
            /// Returned for a key that does not exist
            /// </summary>
            public const string None = "none";
            /// <summary>
            /// Redis Lists are simply lists of strings, sorted by insertion order. It is possible to add elements to a Redis List pushing new elements on the head (on the left) or on the tail (on the right) of the list.
            /// </summary>
            /// <remarks>http://redis.io/topics/data-types#lists</remarks>
            public const string List = "list";
            /// <summary>
            /// Strings are the most basic kind of Redis value. Redis Strings are binary safe, this means that a Redis string can contain any kind of data, for instance a JPEG image or a serialized Ruby object.
            /// </summary>
            /// <remarks>http://redis.io/topics/data-types#strings</remarks>
            public const string String = "string";
            /// <summary>
            /// Redis Sets are an unordered collection of Strings. It is possible to add, remove, and test for existence of members in O(1) (constant time regardless of the number of elements contained inside the Set).
            /// </summary>
            /// <remarks>http://redis.io/topics/data-types#sets</remarks>
            public const string Set = "set";
            /// <summary>
            /// Redis Sorted Sets are, similarly to Redis Sets, non repeating collections of Strings. The difference is that every member of a Sorted Set is associated with score, that is used in order to take the sorted set ordered, from the smallest to the greatest score.
            /// </summary>
            /// <remarks>http://redis.io/topics/data-types#sorted-sets</remarks>
            public const string SortedSet = "zset";
            /// <summary>
            /// Redis Hashes are maps between string field and string values, so they are the perfect data type to represent objects (for instance Users with a number of fields like name, surname, age, and so forth)
            /// </summary>
            /// <remarks>http://redis.io/topics/data-types#hashes</remarks>
            public const string Hash = "hash";
        }
        internal const bool DefaultAllowAdmin = false;
        /// <summary>
        /// Creates a new RedisConnection to a designated server
        /// </summary>
        public RedisConnection(string host, int port = 6379, int ioTimeout = -1, string password = null, int maxUnsent = int.MaxValue, bool allowAdmin = DefaultAllowAdmin, int syncTimeout = DefaultSyncTimeout)
            : base(host, port, ioTimeout, password, maxUnsent, syncTimeout)
        {
            this.allowAdmin = allowAdmin;
        }
        /// <summary>
        /// Creates a child RedisConnection, such as for a RedisTransaction
        /// </summary>
        protected RedisConnection(RedisConnection parent) : base(
            parent.Host, parent.Port, parent.IOTimeout, parent.Password, int.MaxValue, parent.SyncTimeout)
        {
            this.allowAdmin = parent.allowAdmin;
        }
        /// <summary>
        /// Allows multiple commands to be buffered and sent to redis as a single atomic unit
        /// </summary>
        public virtual RedisTransaction CreateTransaction()
        {
            return new RedisTransaction(this);
        }
        /// <summary>
        /// Allows multiple commands to be buffered and sent to redis collectively, but without any guarantee of atomicity
        /// </summary>
        public virtual RedisBatch CreateBatch()
        {
            return new RedisBatch(this);
        }
        private RedisSubscriberConnection subscriberChannel;

        private RedisSubscriberConnection SubscriberFactory()
        {
            var conn = new RedisSubscriberConnection(Host, Port, IOTimeout, Password, 100);
            conn.Name = Name;
            conn.SetServerVersion(this.ServerVersion, this.ServerType);
            conn.Error += OnError;
            conn.Open();
            return conn;
        }

        /// <summary>
        /// How frequently should keep-alives be sent?
        /// </summary>
        protected override int KeepAliveSeconds { get { return keepAliveSeconds; } }

        /// <summary>
        /// Configures an automatic keep-alive PING at a pre-determined interval; this is especially
        /// useful if CONFIG GET is not available.
        /// </summary>
        public void SetKeepAlive(int seconds)
        {
            keepAliveSeconds = seconds;
            StopKeepAlive();
            if (seconds > 0)
            {
                Trace("keep-alive", "set to {0} seconds", seconds);
                timer = new System.Timers.Timer(seconds * 500); // check twice in the interval; Tick will decide which (if either) to use
                timer.Elapsed += (tick ?? (tick = Tick));
                timer.Start();
            }
        }
        /// <summary>
        /// The message to supply to callers when rejecting messages
        /// </summary>
        protected override string GetCannotSendMessage()
        {
            string msg = base.GetCannotSendMessage();
            int millis = LastSentMillisecondsAgo;
            if (millis >= 0)
            {
                msg = msg + string.Format("; the last command was sent {0}ms ago", millis);
            }
            return msg;
        }

        /// <summary>
        /// Time (in milliseconds) since the last command was sent
        /// </summary>
        public int LastSentMillisecondsAgo
        {
            get
            {
                int then = lastSentTicks, now = Environment.TickCount;
                const int MSB = 1 << 31;
                if ((now & MSB) != (then & MSB)) // the sign has flipped; Ticks is only the same siugn for 24.9 days at a time
                    return -1;
                return now - then;
            }
        }

        private int LastKeepAliveMillisecondsAgo
        {
            get
            {
                int then = lastSentKeepAliveTicks, now = Environment.TickCount;
                if (then == 0) return -1;
                const int MSB = 1 << 31;
                if ((now & MSB) != (then & MSB)) // the sign has flipped; Ticks is only the same siugn for 24.9 days at a time
                    return -1;
                return now - then;
            }
        }

        private System.Timers.ElapsedEventHandler tick;
        void Tick(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (State == ConnectionState.Open)
            {
                // ping if nothing sent in *3/4* the interval; for example, if keep-alive is every 4 seconds we'll
                // send a PING if nothing was written in the last 3 seconds

                int millis = LastSentMillisecondsAgo;
                if(millis < 0 || millis > (keepAliveSeconds * 750))
                {
                    Trace("keep-alive", "ping");
                    lastSentKeepAliveTicks = Environment.TickCount;
                    PingImpl(true, duringInit: false);
                }
            }
        }
        private volatile int lastSentTicks, lastSentKeepAliveTicks;

        void StopKeepAlive()
        {
            var tmp = timer;
            timer = null;
            using (tmp)
            {
                if (tmp != null)
                {
                    tmp.Stop();
                    tmp.Close();
                }
            }
        }
        System.Timers.Timer timer;
        int keepAliveSeconds = -1;

        /// <summary>
        /// Closes the connection; either draining the unsent queue (to completion), or abandoning the unsent queue.
        /// </summary>
        public override Task CloseAsync(bool abort)
        {
            StopKeepAlive();
            return base.CloseAsync(abort);
        }
        /// <summary>
        /// Called during connection init, but after the AUTH is sent (if needed)
        /// </summary>
        protected override bool OnInitConnection()
        {
            var result = base.OnInitConnection();

            if (keepAliveSeconds < 0) // not known
            {
                var options = GetConfigImpl("timeout", true);
                options.ContinueWith(x =>
                {
                    if (x.IsFaulted || x.IsCanceled)
                    {
                        var ex = x.Exception; // need to yank this to make TPL happy, but not going to get excited about it
                        GC.KeepAlive(ex); // just an opaque empty method; to ensure it got yanked
                    }
                    else if (x.IsCompleted)
                    {
                        int timeout;
                        string text;
                        if (x.Result.TryGetValue("timeout", out text) && int.TryParse(text, NumberStyles.Any, CultureInfo.InvariantCulture, out timeout)
                            && timeout > 0)
                        {
                            SetKeepAlive(Math.Max(1, (timeout - 15) * 4)  / 5); // allow a few seconds contingency; so a timeout of 300 (5 minutes)
                                                                                  // will actually be set to check every 228 seconds (3m48s)
                        }
                        else
                        {
                            SetKeepAlive(0);
                        }
                    }
                });
            }

            return result;
        }

        /// <summary>
        /// Creates a pub/sub connection to the same redis server
        /// </summary>
        public RedisSubscriberConnection GetOpenSubscriberChannel()
        {
            // use (atomic) reference test for a lazy quick answer
            if (subscriberChannel != null) return subscriberChannel;
            RedisSubscriberConnection newValue = null;
            try
            {
                newValue = SubscriberFactory();
                if (Interlocked.CompareExchange(ref subscriberChannel, newValue, null) == null)
                {
                    // the field was null; we won the race; happy happy
                    var tmp = newValue;
                    newValue = null;
                    return tmp;
                }
                else
                {
                    // we lost the race; use Interlocked to be sure we report the right thing
                    return Interlocked.CompareExchange(ref subscriberChannel, null, null);
                }
            }
            finally
            {
                // if newValue still has a value, we failed to swap it; perhaps we
                // lost the thread race, or perhaps an exception was thrown; either way,
                // that sucka is toast
                using (newValue as IDisposable) 
                {
                }
            }
        }
        /// <summary>
        /// Releases any resources associated with the connection
        /// </summary>
        protected override void OnDispose()
        {
            var subscribers = subscriberChannel;
            if (subscribers != null) subscribers.Dispose();
            base.OnDispose();
        }

        private readonly bool allowAdmin;

        /// <summary>
        /// Query usage metrics for this connection
        /// </summary>
        public Counters GetCounters()
        {
            return GetCounters(true);
        }

        /// <summary>
        /// Query usage metrics for this connection
        /// </summary>
        public Counters GetCounters(bool allowTalkToServer)
        {
            int messagesSent, messagesReceived, queueJumpers, messagesCancelled, unsent, errorMessages, timeouts, syncCallbacks, asyncCallbacks, syncCallbacksInProgress, asyncCallbacksInProgress;
            GetCounterValues(out messagesSent, out messagesReceived, out queueJumpers, out messagesCancelled, out unsent, out errorMessages, out timeouts, out syncCallbacks, out asyncCallbacks, out syncCallbacksInProgress, out asyncCallbacksInProgress);
            return new Counters(
                messagesSent, messagesReceived, queueJumpers, messagesCancelled,
                timeouts, unsent, errorMessages, syncCallbacks, asyncCallbacks, syncCallbacksInProgress, asyncCallbacksInProgress,
                GetSentCount(),
                GetDbUsage(), LastSentMillisecondsAgo, LastKeepAliveMillisecondsAgo, KeepAliveSeconds, State,
                // important that ping happens last, as this may artificially drain the queues
                allowTalkToServer ? 0 : -1
            );
        }
        internal override void RecordSent(RedisMessage message, bool drainFirst)
        {
            base.RecordSent(message, drainFirst);
            lastSentTicks = Environment.TickCount;
        }


        /// <summary>
        /// Give some information about the oldest incomplete (but sent) message on the server
        /// </summary>
        protected override string GetTimeoutSummary()
        {
            var msg = PeekSent(true);
            return msg == null ? null : msg.ToString();
        }

        /// <summary>
        /// Takes a server out of "slave" mode, to act as a replication master.
        /// </summary>
        [Obsolete("Please use the Server API")]
        public Task PromoteToMaster()
        {
            return Server.MakeMaster();
        }

        /// <summary>
        /// Temporarily suspends eager-flushing (flushing if the write-queue becomes empty briefly). Buffer-based flushing
        /// will still occur when the data is full. This is useful if you are performing a large number of
        /// operations in close duration, and want to avoid packet fragmentation. Note that you MUST call
        /// ResumeFlush at the end of the operation - preferably using Try/Finally so that flushing is resumed
        /// even upon error. This method is thread-safe; any number of callers can suspend/resume flushing
        /// concurrently - eager flushing will resume fully when all callers have called ResumeFlush.
        /// </summary>
        /// <remarks>Note that some operations (transaction conditions, etc) require flushing - this will still
        /// occur even if the buffer is only part full.</remarks>
        public new void SuspendFlush()
        {
            base.SuspendFlush();
        }
        /// <summary>
        /// Resume eager-flushing (flushing if the write-queue becomes empty briefly). See SuspendFlush for
        /// full usage.
        /// </summary>
        public new void ResumeFlush()
        {
            base.ResumeFlush();
        }

        /// <summary>
        /// Posts a message to the given channel.
        /// </summary>
        /// <returns>the number of clients that received the message.</returns>
        public Task<long> Publish(string key, string value, bool queueJump = false)
        {
            return ExecuteInt64(RedisMessage.Create(-1, RedisLiteral.PUBLISH, key, value), queueJump);
        }
        /// <summary>
        /// Posts a message to the given channel.
        /// </summary>
        /// <returns>the number of clients that received the message.</returns>
        public Task<long> Publish(string key, byte[] value, bool queueJump = false)
        {
            return ExecuteInt64(RedisMessage.Create(-1, RedisLiteral.PUBLISH, key, value), queueJump);
        }

        /// <summary>
        /// Indicates the number of messages that have not yet been sent to the server.
        /// </summary>
        public override int OutstandingCount
        {
            get
            {
                return base.OutstandingCount + GetSentCount();
            }
        }

        internal Task<Tuple<string,int>> QuerySentinelMaster(string serviceName)
        {
           if(string.IsNullOrEmpty(serviceName)) throw new ArgumentNullException("serviceName");
           TaskCompletionSource<Tuple<string,int>> taskSource = new TaskCompletionSource<Tuple<string,int>>();
           ExecuteMultiString(RedisMessage.Create(-1, RedisLiteral.SENTINEL, "get-master-addr-by-name", serviceName), false, taskSource)
                .ContinueWith(querySentinelMasterCallback);
           return taskSource.Task;
        }
        static readonly Action<Task<string[]>> querySentinelMasterCallback = task =>
        {
            var state = (TaskCompletionSource<Tuple<string, int>>)task.AsyncState;
            if (task.ShouldSetResult(state))
            {
                var arr = task.Result;
                int i;
                if (arr == null)
                {
                    state.TrySetResult(null);
                }
                else if (arr.Length == 2 && int.TryParse(arr[1], out i))
                {
                    state.TrySetResult(Tuple.Create(arr[0], i));
                }
                else
                {
                    state.SafeSetException(new InvalidOperationException("Invalid sentinel result: " + string.Join(",", arr)));
                }
            }
        };
    }
}
