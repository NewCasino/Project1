using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Provides a Redis connection for listening for (and handling) the subscriber part of a pub/sub implementation.
    /// Messages are sent using RedisConnection.Publish.
    /// </summary>
    public sealed class RedisSubscriberConnection : RedisConnectionBase
    {
        /// <summary>
        /// This event is raised when a message is received on any subscribed channel; this is supplemental
        /// to any direct callbacks specified.
        /// </summary>
        public event Action<string, byte[]> MessageReceived;

        private readonly Dictionary<string, Action<string, byte[]>> subscriptions
            = new Dictionary<string, Action<string, byte[]>>();
        private void AddNamedSubscription(string key, Action<string, byte[]> handler)
        {
            if (handler != null)
            {
                lock (subscriptions)
                {
                    Action<string, byte[]> existing;
                    if (subscriptions.TryGetValue(key, out existing))
                        subscriptions[key] = existing + handler;
                    else
                        subscriptions.Add(key, handler);
                }
            }
        }

        /// <summary>
        /// Should a QUIT be sent when closing the connection?
        /// </summary>
        protected override bool QuitOnClose
        {
            get { return false; }
        }
        private void AddNamedSubscriptions(string[] keys, Action<string, byte[]> handler)
        {
            if (handler != null)
            {
                lock (subscriptions)
                {
                    // check all first
                    for (int i = 0; i < keys.Length; i++)
                    {
                        string key = keys[i];
                        Action<string, byte[]> existing;
                        if (subscriptions.TryGetValue(key, out existing))
                            subscriptions[key] = existing + handler;
                        else
                            subscriptions.Add(key, handler);
                    }
                }
            }
        }
        private void RemoveNamedSubscription(string key)
        {
            lock (subscriptions) { subscriptions.Remove(key); }
        }
        private void RemoveNamedSubscriptions(string[] keys)
        {
            lock (subscriptions) {
                for (int i = 0; i < keys.Length; i++ )
                    subscriptions.Remove(keys[i]);
            }
        }
        private void ProcessNamedSubscription(string subscriptionKey, string messageKey, RedisResult value)
        {
            if (string.IsNullOrEmpty(subscriptionKey)) return;
            Action<string, byte[]> handler;            
            lock (subscriptions)
            {
                if (!subscriptions.TryGetValue(subscriptionKey, out handler)) handler = null;
            }
            RaiseEvent(handler, messageKey, value);
        }
        private void RaiseEvent(Action<string, byte[]> handler, string key, RedisResult value)
        {
            if (handler == null) return;
            foreach (Action<string, byte[]> child in handler.GetInvocationList())
            {
                try
                {
                    child(key, value.ValueBytes);
                }
                catch (Exception ex)
                {
                    OnError("Subscriber callback", ex, false);
                }
            }
        }
        /// <summary>
        /// Create a new RedisSubscriberConnection instance
        /// </summary>
        /// <param name="host">The server to connect to (IP address or name)</param>
        /// <param name="port">The port on the server to connect to; typically 3679</param>
        /// <param name="ioTimeout">The timeout to use during IO operations; this can usually be left unlimited</param>
        /// <param name="password">If the server is secured, the server password (null if not secured)</param>
        /// <param name="maxUnsent">The maximum number of unsent messages to enqueue before new requests are blocking calls</param>
        public RedisSubscriberConnection(string host, int port = 6379, int ioTimeout = -1, string password = null, int maxUnsent = int.MaxValue)
            : base(host,port, ioTimeout, password, maxUnsent)
        {
        }
        private readonly byte[]
            message = Encoding.ASCII.GetBytes("message"),
            subscribe = Encoding.ASCII.GetBytes("subscribe"),
            unsubscribe = Encoding.ASCII.GetBytes("unsubscribe"),
            pmessage = Encoding.ASCII.GetBytes("pmessage"),
            psubscribe = Encoding.ASCII.GetBytes("psubscribe"),
            punsubscribe = Encoding.ASCII.GetBytes("punsubscribe");

        private void OnMessageReceived(string subscriptionKey, string messageKey, RedisResult value)
        {
            ProcessNamedSubscription(subscriptionKey, messageKey, value);
            RaiseEvent(MessageReceived, messageKey, value);
        }

        internal override object ProcessReply(ref RedisResult result, out CallbackMode callbackMode)
        {
            RedisResult[] subItems;
            if (!result.IsError && (subItems = result.ValueItems) != null)
            {
                // detect "message" and "pmessage" and don't dequeue for those
                switch(subItems.Length)
                {
                    case 3: // special-case message
                        if (subItems[0].IsMatch(message))
                        {
                            callbackMode = CallbackMode.Continuation; // events are a lot like continuations
                            return null;
                        }
                        break;
                    case 4: // special-case pmessage
                        if (subItems[0].IsMatch(pmessage))
                        {
                            callbackMode = CallbackMode.Continuation; // events are a lot like continuations
                            return null;
                        }
                        break;
                }
            }

            var next = PeekSent(false) as IMultiReplyMessage;
            if (next == null || next.Consume())
            {
                return base.ProcessReply(ref result, out callbackMode);
            }
            // if we get here, we are dealing with a multi-reply message that is not yet satisfied; do nothing
            callbackMode = CallbackMode.SyncUnchecked; // won't actually be doing anything
            return null;
        }
        /// <summary>
        /// Called during connection init, but after the AUTH is sent (if needed)
        /// </summary>
        /// <returns>Whether to release any queued messages</returns>
        protected override bool OnInitConnection()
        {
            base.OnInitConnection();
            // if a Name is present, we need to wait for INFO response;
            // if not, we can release it now
            return string.IsNullOrEmpty(Name); 
        }
        /// <summary>
        /// Invoked when we have completed the handshake
        /// </summary>
        protected override void OnHandshakeComplete(bool fromInfo)
        {
            base.OnHandshakeComplete(fromInfo);
            ReleaseHeldMessages();
        }

        internal override void ProcessCallbacksImpl(object ctx, RedisResult result)
        {
            RedisResult[] subItems;
            bool callBase = true;
            if (!result.IsError && (subItems = result.ValueItems) != null)
            {
                switch(subItems.Length)
                {
                    case 3:
                        var msgType = subItems[0];
                        if (msgType.IsMatch(message))
                        {
                            string key = subItems[1].ValueString;
                            OnMessageReceived(key, key, subItems[2]);
                            callBase = false;
                        }
                        else if (msgType.IsMatch(subscribe) || msgType.IsMatch(unsubscribe)
                            || msgType.IsMatch(psubscribe) || msgType.IsMatch(punsubscribe))
                        {
                            int newCount = (int)subItems[2].ValueInt64;
                            Interlocked.Exchange(ref subscriptionCount, newCount);
                        }
                        break;
                    case 4:
                        if (subItems[0].IsMatch(pmessage))
                        {
                            OnMessageReceived(subItems[1].ValueString, subItems[2].ValueString, subItems[3]);
                            callBase = false;
                        }
                        break;
                }
            }

            if (ctx != null && callBase) // don't call down to the base for things that aren't related to outbound messages
            {
                base.ProcessCallbacksImpl(ctx, result);
            }
        }
        private int subscriptionCount;
        /// <summary>
        /// The number of subscriptions currently help by the current connection (as reported by the server during the last
        /// subsribe/unsubscribe operation)
        /// </summary>
        public int SubscriptionCount { get { return Interlocked.CompareExchange(ref subscriptionCount, 0, 0); } }
        void ValidateKey(string key, bool pattern)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentOutOfRangeException("key", "Empty subscription key");
            if (pattern != (key.IndexOf('*') >= 0)) throw new ArgumentOutOfRangeException("key", "Pattern subscriptions require *; exact subscription must not include *");

        }
        void ValidateKeys(string[] keys, bool pattern)
        {
            if (keys == null || keys.Length == 0) throw new ArgumentNullException("keys","Empty or missing set of subscription keys");
            
            if(keys.Length == 1)
            {
                ValidateKey(keys[0], pattern);
            }
            else
            {
                var uniques = new HashSet<string>();
                for(int i = 0 ; i < keys.Length ; i++)
                {
                    ValidateKey(keys[i], pattern);
                    if (!uniques.Add(keys[i])) throw new ArgumentException("Key is duplicated: " + keys[i], "keys");
                }
            }            
        }
        /// <summary>
        /// Subscribe to a channel
        /// </summary>
        /// <param name="key">The channel name</param>
        /// <param name="handler">A callback to invoke when messages are received on this channel;
        /// note that the MessageReceived event will also be raised, so this callback can be null.</param>
        /// <remarks>Channels are server-wide; they are not per-database</remarks>
        public Task Subscribe(string key, Action<string, byte[]> handler = null)
        {
            ValidateKey(key, false);
            AddNamedSubscription(key, handler);
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.SUBSCRIBE, key), false);
        }
        /// <summary>
        /// Subscribe to a set of channels
        /// </summary>
        /// <param name="keys">The channel names</param>
        /// <param name="handler">A callback to invoke when messages are received on these channel;
        /// note that the MessageReceived event will also be raised, so this callback can be null.</param>
        /// <remarks>Channels are server-wide; they are not per-database</remarks>
        public Task Subscribe(string[] keys, Action<string, byte[]> handler = null)
        {
            ValidateKeys(keys, false);
            AddNamedSubscriptions(keys, handler);
            return ExecuteVoid(RedisMessage.CreateMultiSub(RedisLiteral.SUBSCRIBE, keys), false);
        }
        /// <summary>
        /// Subscribe to a set of pattern (using wildcards, for exmaple "Foo*")
        /// </summary>
        /// <param name="key">The pattern to subscribe</param>
        /// <param name="handler">A callback to invoke when matching messages are received; this can be null
        /// as the MessageReceived event will also be raised</param>
        /// <remarks>Channels are server-wide, not per-database</remarks>        
        public Task PatternSubscribe(string key, Action<string, byte[]> handler = null)
        {
            ValidateKey(key, true);
            AddNamedSubscription(key, handler);
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.PSUBSCRIBE, key), false);
        }
        /// <summary>
        /// Subscribe to a set of patterns (using wildcards, for exmaple "Foo*")
        /// </summary>
        /// <param name="keys">The patterns to subscribe</param>
        /// <param name="handler">A callback to invoke when matching messages are received; this can be null
        /// as the MessageReceived event will also be raised</param>
        /// <remarks>Channels are server-wide, not per-database</remarks>
        public Task PatternSubscribe(string[] keys, Action<string, byte[]> handler = null)
        {
            ValidateKeys(keys, true);
            AddNamedSubscriptions(keys, handler);
            return ExecuteVoid(RedisMessage.CreateMultiSub(RedisLiteral.PSUBSCRIBE, keys), false);
        }
        /// <summary>
        /// Unsubscribe from a channel
        /// </summary>
        /// <param name="key">The channel name</param>
        /// <remarks>Channels are server-wide; they are not per-database</remarks>
        public Task Unsubscribe(string key)
        {
            ValidateKey(key, false);
            RemoveNamedSubscription(key);
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.UNSUBSCRIBE, key), false);
        }
        /// <summary>
        /// Unsubscribe from a set of channels
        /// </summary>
        /// <param name="keys">The channel names</param>
        /// <remarks>Channels are server-wide; they are not per-database</remarks>
        public Task Unsubscribe(string[] keys)
        {
            ValidateKeys(keys, false);
            RemoveNamedSubscriptions(keys);
            return ExecuteVoid(RedisMessage.CreateMultiSub(RedisLiteral.UNSUBSCRIBE, keys), false);
        }
        /// <summary>
        /// Unsubscribe from a pattern (which must match a pattern previously subscribed)
        /// </summary>
        /// <param name="key">The pattern to unsubscribe</param>
        /// <remarks>Channels are server-wide, not per-database</remarks>
        public Task PatternUnsubscribe(string key)
        {
            ValidateKey(key, true);
            RemoveNamedSubscription(key);
            return ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.PUNSUBSCRIBE, key), false);
        }
        /// <summary>
        /// Unsubscribe from a set of patterns (which must match patterns previously subscribed)
        /// </summary>
        /// <param name="keys">The patterns to unsubscribe</param>
        /// <remarks>Channels are server-wide, not per-database</remarks>
        public Task PatternUnsubscribe(string[] keys)
        {
            ValidateKeys(keys, true);
            RemoveNamedSubscriptions(keys);
            return ExecuteVoid(RedisMessage.CreateMultiSub(RedisLiteral.PUNSUBSCRIBE, keys), false);
        }
    }
}
