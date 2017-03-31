using System;
using System.Collections.Generic;
using System.Text;

namespace BookSleeve
{
    /// <summary>
    /// Summary statistics for the RedisConnection
    /// </summary>
    public sealed class Counters
    {
        private readonly IDictionary<int, int> dbUsage;
        private readonly int messagesSent, messagesReceived, queueJumpers, messagesCancelled, timeouts, unsentQueue, sentQueue, errorMessages, ping,
            syncCallbacks, asyncCallbacks, syncCallbacksInProgress, asyncCallbacksInProgress, lastSentMillisecondsAgo, lastKeepAliveMillisecondsAgo, keepAliveSeconds;
        private readonly RedisConnectionBase.ConnectionState state;
        internal Counters(int messagesSent, int messagesReceived, int queueJumpers, int messagesCancelled, int timeouts,
            int unsentQueue, int errorMessages, int syncCallbacks, int asyncCallbacks, int syncCallbacksInProgress, int asyncCallbacksInProgress,
            int sentQueue, IDictionary<int, int> dbUsage, int lastSentMillisecondsAgo, int lastKeepAliveMillisecondsAgo, int keepAliveSeconds, RedisConnectionBase.ConnectionState state, int ping)
        {
            this.messagesSent = messagesSent;
            this.messagesReceived = messagesReceived;
            this.queueJumpers = queueJumpers;
            this.messagesCancelled = messagesCancelled;
            this.timeouts = timeouts;
            this.unsentQueue = unsentQueue;
            this.errorMessages = errorMessages;
            this.sentQueue = sentQueue;
            this.dbUsage = dbUsage;
            this.ping = ping;
            this.syncCallbacks = syncCallbacks;
            this.asyncCallbacks = asyncCallbacks;
            this.syncCallbacksInProgress = syncCallbacksInProgress;
            this.asyncCallbacksInProgress = asyncCallbacksInProgress;
            this.lastSentMillisecondsAgo = lastSentMillisecondsAgo;
            this.lastKeepAliveMillisecondsAgo = lastKeepAliveMillisecondsAgo;
            this.keepAliveSeconds = keepAliveSeconds;
            this.state = state;
        }
        /// <summary>
        /// How frequently should keep-alives be sent?
        /// </summary>
        public int KeepAliveSeconds { get { return keepAliveSeconds; } }
        /// <summary>
        /// Time (in milliseconds) since the last command was sent
        /// </summary>
        public int LastSentMillisecondsAgo { get { return lastSentMillisecondsAgo; } }
        /// <summary>
        /// Time (in milliseconds) since the last command was sent explicitly because of a keep-alive
        /// </summary>
        public int LastKeepAliveMillisecondsAgo { get { return lastKeepAliveMillisecondsAgo; } }
        /// <summary>
        /// The state of the server connection
        /// </summary>
        public RedisConnectionBase.ConnectionState State { get { return state; } }
        /// <summary>
        /// The number of callbacks executed (total) synchronously
        /// </summary>
        public int SyncCallbacks { get { return syncCallbacks; } }
        /// <summary>
        /// The number of callbacks executed (total) asynchronously
        /// </summary>
        public int AsyncCallbacks { get { return asyncCallbacks; } }
        /// <summary>
        /// The number of callbacks executing (currently) synchronously
        /// </summary>
        public int SyncCallbacksInProgress { get { return syncCallbacksInProgress; } }
        /// <summary>
        /// The number of callbacks executing (currently) asynchronously
        /// </summary>
        public int AsyncCallbacksInProgress { get { return asyncCallbacksInProgress; } }
        /// <summary>
        /// The number of messages sent to the Redis server
        /// </summary>
        public int MessagesSent { get { return messagesSent; } }
        /// <summary>
        /// The number of messages received from the Redis server
        /// </summary>
        public int MessagesReceived { get { return messagesReceived; } }
        /// <summary>
        /// The number of queued messages that were withdrawn without being sent
        /// </summary>
        public int MessagesCancelled { get { return messagesCancelled; } }
        /// <summary>
        /// The number of operations that timed out
        /// </summary>
        public int Timeouts { get { return timeouts; } }
        /// <summary>
        /// The number of operations that were sent ahead of queued items
        /// </summary>
        public int QueueJumpers { get { return queueJumpers; } }
        /// <summary>
        /// The number of messages waiting to be sent
        /// </summary>
        public int UnsentQueue { get { return unsentQueue; } }
        /// <summary>
        /// The number of error messages received by the server
        /// </summary>
        public int ErrorMessages { get { return errorMessages; } }
        /// <summary>
        /// The number of messages that have been sent and are waiting for a response</summary>
        public int SentQueue { get { return sentQueue; } }
        /// <summary>
        /// The current time (milliseconds) taken to send a Redis PING command and
        /// receive a PONG reply
        /// </summary>
        public int Ping { get { return ping; } }
        /// <summary>
        /// Obtain a string representation of the counters
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder()
                 .Append("Sent: ").Append(MessagesSent).AppendLine()
                 .Append("Received: ").Append(MessagesReceived).AppendLine()
                 .Append("Cancelled: ").Append(MessagesCancelled).AppendLine()
                 .Append("Timeouts: ").Append(Timeouts).AppendLine()
                 .Append("Queue jumpers: ").Append(QueueJumpers).AppendLine()
                 .Append("Ping (ms): ").Append(Ping).AppendLine()
                 .Append("Sent queue: ").Append(SentQueue).AppendLine()
                 .Append("Unsent queue: ").Append(UnsentQueue).AppendLine()
                 .Append("Error messages: ").Append(ErrorMessages).AppendLine()
                 .Append("Sync callbacks: ").Append(SyncCallbacks).AppendLine()
                 .Append("Async callbacks: ").Append(AsyncCallbacks).AppendLine()
                 .Append("Sync-callbacks in progress: ").Append(SyncCallbacksInProgress).AppendLine()
                 .Append("Async-callbacks in progress: ").Append(AsyncCallbacksInProgress).AppendLine()
                 .Append("Last sent (ms ago): ").Append(LastSentMillisecondsAgo).AppendLine()
                 .Append("Last keep-alive (ms ago): ").Append(LastKeepAliveMillisecondsAgo).AppendLine()
                 .Append("Keep-alive (seconds): ").Append(KeepAliveSeconds).AppendLine()
                 .Append("State: ").Append(State).AppendLine();
            int[] keys = new int[dbUsage.Count], values = new int[dbUsage.Count];
            dbUsage.Keys.CopyTo(keys, 0);
            dbUsage.Values.CopyTo(values, 0);
            Array.Sort(values, keys); // sort both arrays based on the counts (ascending)
            for (int i = keys.Length - 1; i >= 0; i--)
            {
                sb.Append("DB ").Append(keys[i]).Append(": ").Append(values[i]).AppendLine();
            }
            return sb.ToString();
        }
    }
}
