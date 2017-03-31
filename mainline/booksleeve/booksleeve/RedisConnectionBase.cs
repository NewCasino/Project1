using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Reflection.Emit;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Base class for a redis-connection; provides core redis services
    /// </summary>
    public abstract class RedisConnectionBase : IDisposable
    {
        private Socket socket;
        private NetworkStream redisStream;

        private readonly Queue<RedisMessage> unsent;
        private readonly int port, ioTimeout, syncTimeout;
        private readonly string host, password;
        /// <summary>
        /// The amount of time to wait for any individual command to return a result when using Wait
        /// </summary>
        public int SyncTimeout { get { return syncTimeout; } }
        /// <summary>
        /// The host for the redis server
        /// </summary>
        public string Host { get { return host; } }
        /// <summary>
        /// The password used to authenticate with the redis server
        /// </summary>
        protected string Password { get { return password; } }
        /// <summary>
        /// The port for the redis server
        /// </summary>
        public int Port { get { return port; } }
        /// <summary>
        /// The IO timeout to use when communicating with the redis server
        /// </summary>
        protected int IOTimeout { get { return ioTimeout; } }
        private RedisFeatures features;
        /// <summary>
        /// Features available to the redis server
        /// </summary>
        public virtual RedisFeatures Features { get { return features; } }

        private string name;
        /// <summary>
        /// Specify a name for this connection (displayed via Server.ListClients / CLIENT LIST)
        /// </summary>
        public string Name
        {
            get { return name; }
            set
            {
                if (value != null)
                {
                    // apply same validation that Redis does
                    char c;
                    for (int i = 0; i < value.Length; i++)
                        if ((c = value[i]) < '!' || c > '~')
                            throw new ArgumentException("Client names cannot contain spaces, newlines or special characters.", "Name");
                }
                if (State == ConnectionState.New)
                {
                    this.name = value;
                }
                else
                {
                    throw new InvalidOperationException("Name can only be set on new connections");
                }
            }
        }

        /// <summary>
        /// The version of the connected redis server
        /// </summary>
        public virtual Version ServerVersion
        {
            get
            {
                var tmp = features;
                return tmp == null ? null : tmp.Version;
            }
        }
        /// <summary>
        /// Explicitly specify the server version; this is useful when INFO is not available
        /// </summary>
        public void SetServerVersion(Version version, ServerType type)
        {
            features = version == null ? null : new RedisFeatures(version);
            ServerType = type;
        }

        /// <summary>
        /// Obtains fresh statistics on the usage of the connection
        /// </summary>
        protected void GetCounterValues(out int messagesSent, out int messagesReceived,
            out int queueJumpers, out int messagesCancelled, out int unsent, out int errorMessages, out int timeouts,
            out int syncCallbacks, out int asyncCallbacks, out int syncCallbacksInProgress, out int asyncCallbacksInProgress)
        {
            messagesSent = Interlocked.CompareExchange(ref this.messagesSent, 0, 0);
            messagesReceived = Interlocked.CompareExchange(ref this.messagesReceived, 0, 0);
            queueJumpers = Interlocked.CompareExchange(ref this.queueJumpers, 0, 0);
            messagesCancelled = Interlocked.CompareExchange(ref this.messagesCancelled, 0, 0);
            messagesSent = Interlocked.CompareExchange(ref this.messagesSent, 0, 0);
            errorMessages = Interlocked.CompareExchange(ref this.errorMessages, 0, 0);
            timeouts = Interlocked.CompareExchange(ref this.timeouts, 0, 0);
            unsent = OutstandingCount;
            syncCallbacks = Interlocked.CompareExchange(ref this.syncCallbacks, 0, 0);
            asyncCallbacks = Interlocked.CompareExchange(ref this.asyncCallbacks, 0, 0);
            syncCallbacksInProgress = Interlocked.CompareExchange(ref this.syncCallbacksInProgress, 0, 0);
            asyncCallbacksInProgress = Interlocked.CompareExchange(ref this.asyncCallbacksInProgress, 0, 0);
        }
        /// <summary>
        /// Issues a basic ping/pong pair against the server, returning the latency
        /// </summary>
        protected Task PingImpl(bool queueJump, bool duringInit = false, object state = null)
        {
            return Task<long>.Delay(0);
            //var msg = new PingMessage();
            //if(duringInit) msg.DuringInit();
            //return ExecuteInt64(msg, queueJump, state);
        }
        /// <summary>
        /// The default time to wait for individual commands to complete when using Wait
        /// </summary>
        protected const int DefaultSyncTimeout = 10000;
        // dont' really want external subclasses
        internal RedisConnectionBase(string host, int port = 6379, int ioTimeout = -1, string password = null, int maxUnsent = int.MaxValue,
            int syncTimeout = DefaultSyncTimeout)
        {
            if (syncTimeout <= 0) throw new ArgumentOutOfRangeException("syncTimeout");
            this.syncTimeout = syncTimeout;
            this.unsent = new Queue<RedisMessage>();
            this.host = host;
            this.port = port;
            this.ioTimeout = ioTimeout;
            this.password = password;

            IncludeDetailInTimeouts = true;

            this.sent = new Queue<RedisMessage>();
        }
        static bool TryParseVersion(string value, out Version version)
        {  // .NET 4.0 has Version.TryParse, but 3.5 CP does not
            var match = Regex.Match(value, "^[0-9.]+");
            if (match.Success) value = match.Value;
            try
            {
                version = new Version(value);
                return true;
            }
            catch
            {
                version = default(Version);
                return false;
            }
        }

        private int state;
        /// <summary>
        /// The current state of the connection
        /// </summary>
        public ConnectionState State
        {
            get { return (ConnectionState)state; }
        }
        /// <summary>
        /// Releases any resources associated with the connection
        /// </summary>
        public void Dispose()
        {
            NominateShutdownType(ShutdownType.ClientDisposed);
            OnDispose();
        }
        /// <summary>
        /// Releases any resources associated with the connection
        /// </summary>
        protected virtual void OnDispose() 
        {
            try { Close(false); } catch { }
            abort = true;
            try { if (redisStream != null) redisStream.Dispose(); }
            catch { }
            try { if (outBuffer != null) outBuffer.Dispose(); }
            catch { }
            try { if (socket != null) {                
                Trace("dispose", "closing socket...");
                socket.Shutdown(SocketShutdown.Both);
                socket.Close();
                socket.Dispose();
                Trace("dispose", "closed socket");                
            } } catch (Exception ex){
                Trace("dispose", ex.Message);
            }
            socket = null;
            redisStream = null;
            outBuffer = null;
            Error = null;
            Trace("dispose", "done");
        }
        /// <summary>
        /// Called after opening a connection
        /// </summary>
        protected virtual void OnOpened() { }
        /// <summary>
        /// Called before opening a connection
        /// </summary>
        protected virtual void OnOpening() { }

        /// <summary>
        /// Called during connection init, but after the AUTH is sent (if needed)
        /// </summary>
        /// <returns>Whether to release any queued messages</returns>
        protected virtual bool OnInitConnection() { return true; }

        [Conditional("VERBOSE")]
        internal static void Trace(string category, string message)
        {
#if VERBOSE
            var threadId = System.Threading.Thread.CurrentThread.ManagedThreadId;
            
#if VERBOSE_CONSOLE
            Console.WriteLine(category + "\t[" + threadId + "] " + DateTime.Now.ToString("HH:mm:ss.ffff") + ": " + message);
#else
            System.Diagnostics.Trace.WriteLine("[" + threadId + "] " + DateTime.Now.ToString("HH:mm:ss.ffff") + ": " + message, category);
#endif
#endif
        }
        [Conditional("VERBOSE")]
        internal static void Trace(string category, string message, params object[] args)
        {
#if VERBOSE
            Trace(category, string.Format(message, args));
#endif
        }

        /// <summary>
        /// An already-completed task that indicates success
        /// </summary>
        protected static readonly Task<bool> AlwaysTrue = FromResult(true);
        static Task<T> FromResult<T>(T val)
        {
            TaskCompletionSource<T> source = new TaskCompletionSource<T>();
            source.TrySetResult(val);
            return source.Task;
        }

        /// <summary>
        /// Attempts to open the connection to the remote server
        /// </summary>
        public Task Open()
        {
            var foundState = (ConnectionState)Interlocked.CompareExchange(ref state, (int)ConnectionState.Opening, (int)ConnectionState.New);
            switch(foundState)
            {
                case ConnectionState.Open:
                    return AlwaysTrue;
                case ConnectionState.New:
                    break; // fine
                default:
                    throw new InvalidOperationException("Connection is " + (ConnectionState)foundState); // not shiny
            }
                
            var source = new TaskCompletionSource<bool>();
            try
            {
                OnOpening();
                ConnectAsync(source);
                return source.Task;
            } catch(Exception ex)
            {
                source.SafeSetException(ex);
                DoShutdown("open", ex, ConnectionState.Opening);
                throw;
            }
        }
        private void ConnectAsync(TaskCompletionSource<bool> source)
        {
            Trace("> connect", "async");
            var socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            socket.NoDelay = true;
            socket.SendTimeout = this.ioTimeout;
            var args = new SocketAsyncEventArgs {
                RemoteEndPoint = new DnsEndPoint(this.host, this.port),
                UserToken = Tuple.Create(source, socket),
            };
            args.Completed += ConnectAsyncComplete;
            if (!socket.ConnectAsync(args)) ConnectAsyncComplete(socket, args);
            
        }
        private void ConnectAsyncComplete(object sender, SocketAsyncEventArgs args)
        {
            // note: args.ConnectSocket does not exist on Mono
            var tuple = (Tuple<TaskCompletionSource<bool>, Socket>)args.UserToken;
            var source = tuple.Item1;
            try
            {
                Trace("< connect", "async: {0}", args.SocketError);
                switch (args.SocketError)
                {
                    case SocketError.Success:
                        this.socket = tuple.Item2;
                        var readArgs = new SocketAsyncEventArgs();
                        readArgs.Completed += this.AsyncReadCompleted;
                        readArgs.SetBuffer(buffer, 0, buffer.Length);
                        this.readArgs = readArgs;
                        this.InitOutbound(source);
                        break;
                    default:
                        throw new SocketException((int)args.SocketError);
                }
            }
            catch (Exception ex)
            {
                source.SafeSetException(ex);
                DoShutdown("connect", ex, ConnectionState.Opening);
            }
            
        }

#if VERBOSE
        class CountingOutputStream : Stream
        {
            public override void Close()
            {
                tail.Close();
                base.Close();
            }
            protected override void Dispose(bool disposing)
            {
                if (disposing) { tail.Dispose(); }
                base.Dispose(disposing);
            }
            private readonly Stream tail;
            public CountingOutputStream(Stream tail)
            {
                this.tail = tail;
            }
            private long position;
            public override long Position
            {
                get { return position; }
                set { throw new NotSupportedException(); }
            }
            public override void Write(byte[] buffer, int offset, int count)
            {
                tail.Write(buffer, offset, count);
                position += count;
            }
            public override void WriteByte(byte value)
            {
                tail.WriteByte(value);
                position++;
            }
            public override bool CanWrite
            {
                get { return true; }
            }
            public override void Flush()
            {
                tail.Flush();
            }
            public override void SetLength(long value)
            {
                throw new NotSupportedException();
            }
            public override long Length
            {
                get { return position; }
            }
            public override bool CanSeek
            {
                get { return false; }
            }
            public override long Seek(long offset, SeekOrigin origin)
            {
                throw new NotSupportedException();
            }
            public override bool CanRead
            {
                get { return false; }
            }
            public override int Read(byte[] buffer, int offset, int count)
            {
                throw new NotSupportedException();
            }
        }
#endif
        private SocketAsyncEventArgs readArgs;
        void InitOutbound(TaskCompletionSource<bool> source)
        {
            try {
                //readArgs.SetBuffer(buffer, 0, buffer.Length);
                //if (readArgs.SocketError != SocketError.Success)
                //{
                //    if (readArgs.ConnectByNameError != null) throw readArgs.ConnectByNameError;
                //    throw new InvalidOperationException("Socket error: " + readArgs.SocketError);
                //}
                //socket = readArgs.ConnectSocket;
                //socket.NoDelay = true;
                Trace("connected", socket.RemoteEndPoint.ToString());
                redisStream = new NetworkStream(socket);
                
                outBuffer = new BufferedStream(redisStream, 512); // buffer up operations
#if VERBOSE
                outBuffer = new CountingOutputStream(outBuffer); // so we can report the position etc
#endif
                redisStream.ReadTimeout = redisStream.WriteTimeout = ioTimeout;
                
                Trace("init", "OnOpened");
                OnOpened();

                Trace("init", "start reading");
                bool haveData = ReadMoreAsync();

                if (!string.IsNullOrEmpty(password))
                {
                    var msg = RedisMessage.Create(-1, RedisLiteral.AUTH, password).ExpectOk().Critical();
                    msg.DuringInit();
                    EnqueueMessage(msg, true);
                }

                var asyncState = Tuple.Create(this, source);
                Task initTask;
                if (ServerVersion != null && ServerType != BookSleeve.ServerType.Unknown)
                { // no need to query for it; we already know what we need; use a CLIENT SETNAME or PING instead
                    Trace("init", "ping/name");
                    initTask = TrySetName(true, duringInit: true, state: asyncState) ?? PingImpl(false, duringInit: true, state: asyncState);
                    OnHandshakeComplete(false);
                }
                else
                {
                    Trace("init", "get info");
                    var info = GetInfoImpl(null, true, duringInit:true, state: asyncState);
                    //info.ContinueWith(initInfoCallback, TaskContinuationOptions.ExecuteSynchronously);
                    //initTask = info;
                    initTask = info.ContinueWith(initInfoCallback, TaskContinuationOptions.ExecuteSynchronously);
                }
                // the 4.0 Task API is a bit broken here - can't pass async-state multi-level. It is fixed in 4.5
                // (albeit in a bit of a sucky way)
                initTask.ContinueWith(t => InitCommandCallback(t, asyncState), TaskContinuationOptions.ExecuteSynchronously);

                Trace("init", "OnInitConnection");
                if (OnInitConnection())
                {
                    ReleaseHeldMessages();
                }
                else
                {
                    FlushOutbound(); // make sure INFO etc get sent promptly
                }
                
                if (haveData) ReadReplyHeader(); // this is really unlikely, but need to make sure we don't drop the ball
            }
            catch (Exception ex)
            {
                source.SafeSetException(ex);
                DoShutdown("init-ountbound", ex, ConnectionState.Opening);
            }
        }

        /// <summary>
        /// Releases the queue of any messages "sent" before the connection was open
        /// </summary>
        protected void ReleaseHeldMessages()
        {
            Trace("init", "release held messages");
            hold = false;
            EnqueueMessage(null, true); // start pushing (use this rather than WritePendingQueue to ensure no timing edge-cases with
                                        // other threads, etc);
        }

        static void InitCommandCallback(Task task, object asyncState)
        {
            Trace("init-command", "processing");
            var state = (Tuple<RedisConnectionBase, TaskCompletionSource<bool>>)asyncState; // task.AsyncState;
            var @this = state.Item1;
            var source = state.Item2;

            bool ok = task.IsCompleted && !task.IsFaulted && !task.IsCanceled;
            Exception ex = null;
            if (task.IsFaulted)
            {
                RedisException re;
                ex = task.Exception; 
                if (task.Exception.InnerExceptions.Count == 1 && (re = task.Exception.InnerExceptions[0] as RedisException) != null)
                {
                    ex = re;
                    ok = re.Message.StartsWith("ERR"); // means the command isn't available, but ultimately the server is
                                                       // talking to us, so I think we'll be just fine!
                }
            }
            if (ok)
            {
                Interlocked.CompareExchange(ref @this.state, (int)ConnectionState.Open, (int)ConnectionState.Opening);
                Trace("init-command", "completed");
                source.TrySetResult(true);
            }
            else if (task.IsCanceled)
            {
                Trace("init-command", "cancelled");
                source.TrySetCanceled();
            }
            else
            {
                Trace("init-command", "faulted");
                source.SafeSetException(ex);
                @this.DoShutdown("init-callback", ex, ConnectionState.Opening);
            }
        }

        /// <summary>
        /// Invoked when we have completed the handshake
        /// </summary>
        protected virtual void OnHandshakeComplete(bool fromInfo)
        {
            if(fromInfo) TrySetName(true, duringInit: true);
        }
        static readonly Action<Task<string>> initInfoCallback = task =>
        {
            var state = (Tuple<RedisConnectionBase, TaskCompletionSource<bool>>)task.AsyncState;
            var @this = state.Item1;
            if (!task.IsFaulted && task.IsCompleted)
            {
                try
                {
                    Trace("parse info", "processing");
                    // process this when available
                    var parsed = ParseInfo(task.Result);
                    string s;
                    Version version = null;
                    if (parsed.TryGetValue("redis_version", out s))
                    {
                        if (!TryParseVersion(s, out version)) version = null;
                    }
                    ServerType serverType = ServerType.Unknown;

                    bool checkRole = true;
                    if (parsed.TryGetValue("redis_mode", out s))
                    {
                        switch(s)
                        {
                            case "sentinel":
                                serverType = BookSleeve.ServerType.Sentinel;
                                checkRole = false;
                                break;
                            case "cluster":
                                serverType = BookSleeve.ServerType.Cluster;
                                checkRole = false;
                                break;
                            //case "standalone":
                        }
                    }
                    if (checkRole && parsed.TryGetValue("role", out s) && s != null)
                    {
                        switch (s)
                        {
                            case "master": serverType = BookSleeve.ServerType.Master; break;
                            case "slave": serverType = BookSleeve.ServerType.Slave; break;
                        }
                    }
                    @this.SetServerVersion(version, serverType);
                    @this.OnHandshakeComplete(true);
                    Trace("parse info", "complete");
                }
                catch (Exception ex)
                {
                    Trace("parse info", "fail: " + ex.Message);
                    @this.OnError("parse info", ex, false);
                }
            }
        };
        /// <summary>
        /// Specify a name for the current connection
        /// </summary>
        protected Task TrySetName(bool queueJump, bool duringInit = false, object state = null)
        {
            if (!string.IsNullOrEmpty(name))
            {
                switch (ServerType)
                {
                    case ServerType.Master:
                    case ServerType.Slave:
                        var tmp = Features;
                        if (tmp != null && tmp.ClientName)
                        {
                            var msg = RedisMessage.Create(-1, RedisLiteral.CLIENT, RedisLiteral.SETNAME, name);
                            if (duringInit) msg.DuringInit();
                            return ExecuteVoid(msg, queueJump, state);
                        }
                        break;
                }
            }
            return null;
        }

        bool ReadMoreAsync()
        {
            Trace("read", "async");
            bufferOffset = bufferCount = 0;

            var tmp = socket;
            if (tmp == null) return true; // let the caller conclude that it is EOF

            if (tmp.ReceiveAsync(readArgs)) return false; // not yet available

            Trace("read", "data available immediately");
            if (readArgs.SocketError == SocketError.Success)
            {
                bufferCount = readArgs.BytesTransferred;
                return true; // completed and OK
            }

            // otherwise completed immediately but still need to process errors etc
            AsyncReadCompleted(tmp, readArgs);
            return false;
        }

        void AsyncReadCompleted(object sender, SocketAsyncEventArgs e)
        {
            try
            {
                Trace("receive", "< {0}, {1}, {2} bytes", e.LastOperation, e.SocketError, e.BytesTransferred);
                switch (e.LastOperation)
                {
                    case SocketAsyncOperation.Receive:
                        switch (readArgs.SocketError)
                        {
                            case SocketError.Success:
                                bufferCount = e.BytesTransferred;
                                ReadReplyHeader();
                                break;
                            case SocketError.ConnectionAborted:
                            case SocketError.OperationAborted:
                                if (abort)
                                { // that's OK; that means we closed our socket before the server closed his, but
                                    // we were expecting this - treat it like an EOF
                                    bufferCount = 0;
                                    ReadReplyHeader();
                                    break;
                                }
                                else
                                {
                                    throw new SocketException((int)readArgs.SocketError);
                                }
                            default:
                                throw new SocketException((int)readArgs.SocketError);
                        }
                        break;
                    default:
                        throw new NotImplementedException(e.LastOperation.ToString());
                }
            }
            catch (Exception ex)
            {
                Trace("async-read error", ex.Message);
                DoShutdown("receive", ex);
            }
        }

        //private static readonly AsyncCallback readComplete = ReadComplete;
        //static void ReadComplete(IAsyncResult args)
        //{
        //    if (args.CompletedSynchronously) return;
        //    var conn = (RedisConnectionBase)args.AsyncState;
        //    if (conn.ProcessAsyncResults(args)) conn.ReadReplyHeader();
        //}
        //bool ProcessAsyncResults(IAsyncResult args)
        //{
        //    try
        //    {
        //        SocketError err;
        //        int bytesRead;
        //        var tmp = socket;
        //        if (tmp == null)
        //        {
        //            bufferCount = 0;
        //            return false; // already shutdown
        //        }
        //        else
        //        {
        //            bytesRead = tmp.EndReceive(args, out err);
        //        }
        //        Trace("receive", "< {0}, {1} bytes", err, bytesRead);
        //        switch (err)
        //        {
        //            case SocketError.Success:
        //                bufferCount = bytesRead;
        //                return true;
        //            case SocketError.ConnectionAborted:
        //            case SocketError.OperationAborted:
        //                if (abort)
        //                { // that's OK; that means we closed our socket before the server closed his, but
        //                    // we were expecting this - treat it like an EOF
        //                    bufferCount = 0;
        //                    return true;
        //                }
        //                break;
        //        }
        //        throw new SocketException((int)err);
        //    }
        //    catch (ObjectDisposedException ex)
        //    {
        //        if (!abort)
        //        {
        //            Trace("async-read error", ex.Message);
        //            DoShutdown("receive", ex);
        //        }
        //        return false;
        //    }
        //    catch (Exception ex)
        //    {
        //        Trace("async-read error", ex.Message);
        //        DoShutdown("receive", ex);
        //        return false;
        //    }
        //}
        //bool ReadMoreAsync()
        //{
        //    bufferOffset = bufferCount = 0;
        //    Trace("read", "async");
        //    var result = socket.BeginReceive(buffer, 0, buffer.Length, SocketFlags.None, readComplete, this);
        //    if (result.CompletedSynchronously)
        //    {
        //        Trace("read", "data available immediately");
        //        return ProcessAsyncResults(result);
        //    }
        //    return false;
        //}

        /// <summary>
        /// The INFO command returns information and statistics about the server in format that is simple to parse by computers and easy to red by humans.
        /// </summary>
        /// <remarks>http://redis.io/commands/info</remarks>
        [Obsolete("Please use .Server.GetInfo instead")]
        public Task<string> GetInfo(bool queueJump = false)
        {
            return GetInfoImpl(null, queueJump, false);
        }
        /// <summary>
        /// The INFO command returns information and statistics about the server in format that is simple to parse by computers and easy to red by humans.
        /// </summary>
        /// <remarks>http://redis.io/commands/info</remarks>
        [Obsolete("Please use .Server.GetInfo instead")]
        public Task<string> GetInfo(string category, bool queueJump = false)
        {
            return GetInfoImpl(category, queueJump, false);
        }

        internal Task<string> GetInfoImpl(string category, bool queueJump, bool duringInit, object state = null)
        {
            var msg = string.IsNullOrEmpty(category) ? RedisMessage.Create(-1, RedisLiteral.INFO) : RedisMessage.Create(-1, RedisLiteral.INFO, category);
            if (duringInit) msg.DuringInit();
            return ExecuteString(msg, queueJump, state);
        }

        internal static Dictionary<string, string> ParseInfo(string result)
        {
            string[] lines = result.Split(new[] { "\r\n" }, StringSplitOptions.RemoveEmptyEntries);
            var data = new Dictionary<string, string>();
            for (int i = 0; i < lines.Length; i++)
            {
                string line = lines[i];
                if (string.IsNullOrEmpty(line) || line[0] == '#') continue; // 2.6+ can have empty lines, and comment lines
                int idx = line.IndexOf(':');
                if (idx > 0) // double check this line looks about right
                {
                    data.Add(line.Substring(0, idx), line.Substring(idx + 1));
                }
            }
            return data;
        }

        int timeouts;

        /// <summary>
        /// Indicate the number of messages that have not yet been set.
        /// </summary>
        public virtual int OutstandingCount
        {
            get
            {
                lock (unsent) { return unsent.Count; }
            }
        }
      
        /// <summary>
        /// Raised when a connection becomes closed.
        /// </summary>
        public event EventHandler Closed;
        volatile bool abort;
        /// <summary>
        /// Closes the connection; either draining the unsent queue (to completion), or abandoning the unsent queue.
        /// </summary>
        public virtual Task CloseAsync(bool abort)
        {
            this.abort |= abort;
            Task result = AlwaysTrue;
            if (!this.abort && QuitOnClose)
            {
                switch(ShutdownType)
                {
                    // only send for "clean" shutdowns; no point trying to send QUIT if we know the connection died
                    case BookSleeve.ShutdownType.ClientClosed:
                    case BookSleeve.ShutdownType.ClientDisposed:
                        switch (state)
                        {
                            case (int)ConnectionState.Opening:
                            case (int)ConnectionState.Open:
                                Interlocked.Exchange(ref state, (int)ConnectionState.Closing);
                                if (hold || outBuffer != null)
                                {
                                    Trace("close", "sending quit...");
                                    try
                                    {
                                        result = ExecuteVoid(RedisMessage.Create(-1, RedisLiteral.QUIT), false);
                                    }
                                    catch
                                    {
                                        // if we can't sent QUIT, then frankly it is pretty reasonable that we're already closed!
                                    }
                                }
                                break;
                        }
                        break;
                }
            }
            hold = true;
            return result;
        }

        private int shutdownType;
        /// <summary>
        /// If the connection has been shut down, what was the reason?
        /// </summary>
        public ShutdownType ShutdownType { get { return (ShutdownType) Interlocked.CompareExchange(ref shutdownType, 0, 0);}}
        private void NominateShutdownType(ShutdownType value)
        {
            // set the shutdown type but **only** if it is currently None
            if (Interlocked.CompareExchange(ref shutdownType, (int)value, 0) == 0)
            {
                Trace("shutdown-type", ((ShutdownType)value).ToString());
            }
        }
        

        /// <summary>
        /// Closes the connection; either draining the unsent queue (to completion), or abandoning the unsent queue.
        /// </summary>
        public void Close(bool abort)
        {
            NominateShutdownType(ShutdownType.ClientClosed);
            Wait(CloseAsync(abort));
        }

        /// <summary>
        /// Should a QUIT be sent when closing the connection?
        /// </summary>
        protected virtual bool QuitOnClose { get { return true; } }

//        private void ReadMoreAsync()
//        {
//#if VERBOSE
//            Trace.WriteLine(socketNumber + "? async");
//#endif
//            bufferOffset = bufferCount = 0;
//            var tmp = redisStream;
//            if (tmp != null)
//            {
//                tmp.BeginRead(buffer, 0, BufferSize, readReplyHeader, tmp); // read more IO here (in parallel)
//            }
//        }
        private bool ReadMoreSync()
        {
            Trace("read", "sync");
            var tmp = socket;
            if (tmp == null) return false;
            bufferOffset = bufferCount = 0;
            int bytesRead = tmp.Receive(buffer);
            Trace("read", "{0} bytes", bytesRead);
            if (bytesRead > 0)
            {
                bufferCount = bytesRead;
                return true;
            }
            return false;
        }
        internal enum CallbackMode
        {
            Async, SyncChecked, SyncUnchecked,
            Continuation, NoContinuation
        }

        /// <summary>
        /// How frequently should keep-alives be sent?
        /// </summary>
        protected virtual int KeepAliveSeconds { get { return -1; } }

        private void ReadReplyHeader()
        {
            try
            {
            MoreDataAvailable:
                if (bufferCount <= 0 || socket == null)
                {   // EOF
                    Trace("< EOF", "received");
                    DoShutdown("End of stream", null);
                    return;
                }
                else
                {
                    while (bufferCount > 0)
                    {
                        Trace("reply-header", "< {0} bytes buffered", bufferCount);
                        RedisResult result = ReadSingleResult();
                        Trace("reply-header", "< {0} bytes remain", bufferCount);
                        Interlocked.Increment(ref messagesReceived);
                        CallbackMode callbackMode;
                        object ctx = ProcessReply(ref result, out callbackMode);

                        if (result.IsError)
                        {
                            Interlocked.Increment(ref errorMessages);
                            OnError("Redis server", result.Error(), false);
                        }

                        ProcessCallbacks(ctx, result, callbackMode);
                        Trace("reply-header", "check for more");
                    }
                    Trace("reply-header", "@ buffer empty");
                    if (ReadMoreAsync()) goto MoreDataAvailable;
                }
            }
            catch (Exception ex)
            {
                Trace("reply-header", ex.Message);
                DoShutdown("Invalid inbound stream", ex);
            }
        }

        internal void ProcessCallbacks(object ctx, RedisResult result, CallbackMode callbackMode)
        {
            switch (callbackMode)
            {
                case CallbackMode.Continuation:
                    // has a continuation, so will be async if "Concurrent" or "ConcurrentIfContination"
                    // - only sync if PreserveOrder
                    callbackMode = completionMode == ResultCompletionMode.PreserveOrder
                        ? CallbackMode.SyncChecked : CallbackMode.Async;
                    break;
                case CallbackMode.NoContinuation:
                    // has no continuation, so will be async if "Concurrent"
                    callbackMode = completionMode == ResultCompletionMode.Concurrent
                        ? CallbackMode.Async : CallbackMode.SyncChecked;
                    break;
                // otherwise, we'll trust the values already assigned
            }

            switch (callbackMode)
            {
                case CallbackMode.SyncChecked:
                    Interlocked.Increment(ref this.syncCallbacks);
                    Interlocked.Increment(ref this.syncCallbacksInProgress);
#if DEBUG
                    Interlocked.Increment(ref allSyncCallbacks);
#endif
                    syncCompleteThreadId = CurrentThreadId;
                    ProcessCallbacks(this, ctx, result, false);
                    syncCompleteThreadId = -1;
                    break;
                case CallbackMode.SyncUnchecked:
                    Interlocked.Increment(ref this.syncCallbacks);
                    Interlocked.Increment(ref this.syncCallbacksInProgress);
#if DEBUG
                    Interlocked.Increment(ref allSyncCallbacks);
#endif
                    ProcessCallbacks(this, ctx, result, false);
                    break;
                case CallbackMode.Async:
                default:
                    Interlocked.Increment(ref this.asyncCallbacks);
                    Interlocked.Increment(ref this.asyncCallbacksInProgress);
#if DEBUG
                    Interlocked.Increment(ref allAsyncCallbacks);
#endif
                    var state = Tuple.Create(this, ctx, result);
                    ThreadPool.QueueUserWorkItem(processCallbacksAsync, state);
                    break;
            }
        }
        private int syncCallbacks, asyncCallbacks, syncCallbacksInProgress, asyncCallbacksInProgress;
#if DEBUG
        private static long allSyncCallbacks, allAsyncCallbacks;
        /// <summary>
        /// The total number of sync callbacks on all connectons
        /// </summary>
        public static long AllSyncCallbacks { get { return Interlocked.CompareExchange(ref allSyncCallbacks, 0, 0);}}
        /// <summary>
        /// The total number of async callbacks on all connectons
        /// </summary>
        public static long AllAsyncCallbacks { get { return Interlocked.CompareExchange(ref allAsyncCallbacks, 0, 0);}}
#endif
        private static readonly WaitCallback processCallbacksAsync = ProcessCallbacksAsync;

        private static void ProcessCallbacks(RedisConnectionBase connection, object ctx, RedisResult result, bool isAsync)
        {
            try
            {
                Trace("callback", "processing callback for: {0}", result);
                connection.ProcessCallbacksImpl(ctx, result);
                Trace("callback", "processed callback");
            }
            catch (Exception ex)
            {
                Trace("callback", ex.Message);
                connection.OnError("Processing callbacks", ex, false);
            }
            finally
            {
                if (isAsync)
                    Interlocked.Decrement(ref connection.asyncCallbacksInProgress);
                else
                    Interlocked.Decrement(ref connection.syncCallbacksInProgress);
            }
        }
        private static void ProcessCallbacksAsync(object state)
        {
            var tuple = (Tuple<RedisConnectionBase, object, RedisResult>)state;
            ProcessCallbacks(tuple.Item1, tuple.Item2, tuple.Item3, true);
        }


        /// <summary>
        /// Peek at the next item in the sent-queue
        /// </summary>
        internal RedisMessage PeekSent(bool skipSelect)
        {
            lock (sent)
            {
                switch(sent.Count)
                {
                    case 0: return null;
                    case 1: return sent.Peek();
                    default:
                        var msg = sent.Peek();
                        // no point reporting SELECT if we can help it; that
                        // is not very useful
                        if (msg.Command == RedisLiteral.SELECT)
                        {
                            foreach (var inner in sent)
                            {
                                if (inner.Command != RedisLiteral.SELECT) return inner;
                            }
                        }
                        return msg;
                }
            }
        }

        internal virtual object ProcessReply(ref RedisResult result, out CallbackMode callbackMode)
        {
            RedisMessage message;
            lock (sent)
            {
                int count = sent.Count;
                if (count == 0) throw new RedisException("Data received with no matching message");
                message = sent.Dequeue();
                if (count == 1) Monitor.Pulse(sent); // in case the outbound stream is closing and needs to know we're up-to-date
            }
            
            return ProcessReply(ref result, message, out callbackMode);
        }

        internal virtual object ProcessReply(ref RedisResult result, RedisMessage message, out CallbackMode callbackMode)
        {
            byte[] expected;
            if (!result.IsError && (expected = message.Expected) != null)
            {
                result = result.IsMatch(expected)
                ? RedisResult.Pass : RedisResult.Error(result.ValueString);
            }

            if (result.IsError && message.MustSucceed)
            {
                throw new RedisException("A critical operation failed: " + message.ToString());
            }
            callbackMode = message.CallbackMode;
            return message;
        }
        internal virtual void ProcessCallbacksImpl(object ctx, RedisResult result)
        {
            if(ctx != null) CompleteMessage((RedisMessage)ctx, result);
        }

        private RedisResult ReadSingleResult()
        {
            byte b = ReadByteOrFail();
            switch ((char)b)
            {
                case '+':
                    return RedisResult.Message(ReadBytesToCrlf());
                case '-':
                    return RedisResult.Error(ReadStringToCrlf());
                case ':':
                    return RedisResult.Integer(ReadInt64());
                case '$':
                    return RedisResult.Bytes(ReadBulkBytes());
                case '*':
                    int count = (int)ReadInt64();
                    if (count == -1) return RedisResult.Multi(null);
                    RedisResult[] inner = new RedisResult[count];
                    for (int i = 0; i < count; i++)
                    {
                        inner[i] = ReadSingleResult();
                    }
                    return RedisResult.Multi(inner);
                default:
                    throw new RedisException("Not expecting header: &x" + b.ToString("x2"));
            }
        }
        internal void CompleteMessage(RedisMessage message, RedisResult result)
        {
            try
            {
                message.Complete(result, IncludeDetailInTimeouts);
            }
            catch (Exception ex)
            {
                OnError("Completing message", ex, false);
            }
        }

        private void DoShutdown(string cause, Exception error, ConnectionState onlyWhen)
        {
            if (Interlocked.CompareExchange(ref state, (int)ConnectionState.Closed, (int)onlyWhen) == (int)onlyWhen)
            {
                DoShutdown(cause, error);
            }
        }
        private void DoShutdown(string cause, Exception error)
        {
            Interlocked.Exchange(ref state, (int)ConnectionState.Closed);
            NominateShutdownType(error == null ? ShutdownType.ServerClosed : BookSleeve.ShutdownType.Error);
            try
            {
                Close(error != null);
            }
            catch { }

            if (error != null)
            {
                try
                {
                    OnError(cause, error, true);
                }
                catch { }
            }

            var shutdown = Shutdown;
            Shutdown = null; // only once
            if (shutdown != null)
            {
                try
                {
                    shutdown(this, new ErrorEventArgs(error, cause, true));
                }
                catch { }
            }

            ShuttingDown(error);
            Dispose();

            var closed = Closed;
            Closed = null; // only once
            if (closed != null)
            {
                try
                {
                    closed(this, EventArgs.Empty);
                }
                catch { }
            }
        }

         /// <summary>
         /// Invoked when the server is shutting down; includes any error information
         /// </summary>
        public event EventHandler<ErrorEventArgs> Shutdown;

        /// <summary>
        /// Invoked when the server is terminating
        /// </summary>
        protected virtual void ShuttingDown(Exception error)
        {
            RedisMessage message;
            RedisResult result = null;

            lock (sent)
            {
                if (sent.Count != 0)
                {
                    Trace("shuttingdown", "aborting sent queue ({0} items)", sent.Count);
                    result = RedisResult.Error(
                        error == null ? "The server terminated before a reply was received"
                        : ("Error processing data: " + error.Message));
                }
                while (sent.Count != 0)
                { // notify clients of things that just didn't happen

                    message = sent.Dequeue();
                    Trace("shuttingdown", "aborting {0}", message);
                    CompleteMessage(message, result);
                }
            }
            CancelUnsent();
        }
        private readonly Queue<RedisMessage> sent;



        private static readonly byte[] empty = new byte[0];
        private int Read(byte[] scratch, int offset, int maxBytes)
        {
            if (bufferCount > 0 || ReadMoreSync())
            {
                int count = Math.Min(maxBytes, bufferCount);
                Buffer.BlockCopy(buffer, bufferOffset, scratch, offset, count);
                bufferOffset += count;
                bufferCount -= count;
                return count;
            }
            else
            {
                return 0;
            }
        }
        private byte[] ReadBulkBytes()
        {
            int len;
            checked
            {
                len = (int)ReadInt64();
            }
            switch (len)
            {
                case -1: return null;
                case 0: BurnCrlf(); return empty;
            }
            byte[] data = new byte[len];
            int bytesRead, offset = 0;
            while (len > 0 && (bytesRead = Read(data, offset, len)) > 0)
            {
                len -= bytesRead;
                offset += bytesRead;
            }
            if (len > 0) throw new EndOfStreamException("EOF reading bulk-bytes");
            BurnCrlf();
            return data;
        }
        private byte ReadByteOrFail()
        {
            if (bufferCount > 0 || ReadMoreSync())
            {
                bufferCount--;
                return buffer[bufferOffset++];
            }
            throw new EndOfStreamException();
        }
        private void BurnCrlf()
        {
            if (ReadByteOrFail() != (byte)'\r' || ReadByteOrFail() != (byte)'\n') throw new InvalidDataException("Expected crlf terminator not found");
        }

        const int BufferSize = 2048;
        private readonly byte[] buffer = new byte[BufferSize];
        int bufferOffset = 0, bufferCount = 0;

        private byte[] ReadBytesToCrlf()
        {
            // check for data inside the buffer first
            int bytes = FindCrlfInBuffer();
            byte[] result;
            if (bytes >= 0)
            {
                result = new byte[bytes];
                Buffer.BlockCopy(buffer, bufferOffset, result, 0, bytes);
                // subtract the data; don't forget to include the CRLF
                bufferCount -= (bytes + 2);
                bufferOffset += (bytes + 2);
            }
            else
            {
                byte[] oversizedBuffer;
                int len = FillBodyBufferToCrlf(out oversizedBuffer);
                result = new byte[len];
                Buffer.BlockCopy(oversizedBuffer, 0, result, 0, len);
            }


            return result;
        }
        int FindCrlfInBuffer()
        {
            int max = bufferOffset + bufferCount - 1;
            for (int i = bufferOffset; i < max; i++)
            {
                if (buffer[i] == (byte)'\r' && buffer[i + 1] == (byte)'\n')
                {
                    int bytes = i - bufferOffset;
                    return bytes;
                }
            }
            return -1;
        }
        private string ReadStringToCrlf()
        {
            // check for data inside the buffer first
            int bytes = FindCrlfInBuffer();
            string result;
            if (bytes >= 0)
            {
                result = Encoding.UTF8.GetString(buffer, bufferOffset, bytes);
                // subtract the data; don't forget to include the CRLF
                bufferCount -= (bytes + 2);
                bufferOffset += (bytes + 2);
            }
            else
            {
                // check for data that steps over the buffer
                byte[] oversizedBuffer;
                int len = FillBodyBufferToCrlf(out oversizedBuffer);
                result = Encoding.UTF8.GetString(oversizedBuffer, 0, len);
            }
            return result;
        }

        private int FillBodyBufferToCrlf(out byte[] oversizedBuffer)
        {
            bool haveCr = false;
            bodyBuffer.SetLength(0);
            byte b;
            do
            {
                b = ReadByteOrFail();
                if (haveCr)
                {
                    if (b == (byte)'\n')
                    {// we have our string
                        oversizedBuffer = bodyBuffer.GetBuffer();
                        return (int)bodyBuffer.Length;
                    }
                    else
                    {
                        bodyBuffer.WriteByte((byte)'\r');
                        haveCr = false;
                    }
                }
                if (b == (byte)'\r')
                {
                    haveCr = true;
                }
                else
                {
                    bodyBuffer.WriteByte(b);
                }
            } while (true);
        }

        private long ReadInt64()
        {
            byte[] oversizedBuffer;
            int len = FillBodyBufferToCrlf(out oversizedBuffer);
            // crank our own int parser... why not...
            int tmp;
            switch (len)
            {
                case 0:
                    throw new EndOfStreamException("No data parsing integer");
                case 1:
                    if ((tmp = ((int)oversizedBuffer[0] - '0')) >= 0 && tmp <= 9)
                    {
                        return tmp;
                    }
                    break;
            }
            bool isNeg = oversizedBuffer[0] == (byte)'-';
            if (isNeg && len == 2 && (tmp = ((int)oversizedBuffer[1] - '0')) >= 0 && tmp <= 9)
            {
                return -tmp;
            }

            long value = 0;
            for (int i = isNeg ? 1 : 0; i < len; i++)
            {
                if ((tmp = ((int)oversizedBuffer[i] - '0')) >= 0 && tmp <= 9)
                {
                    value = (value * 10) + tmp;
                }
                else
                {
                    throw new FormatException("Unable to parse integer: " + Encoding.UTF8.GetString(oversizedBuffer, 0, len));
                }
            }
            return isNeg ? -value : value;
        }

        /// <summary>
        /// Indicates the number of commands executed on a per-database basis
        /// </summary>
        protected Dictionary<int, int> GetDbUsage()
        {
            lock (dbUsage)
            {
                return new Dictionary<int, int>(dbUsage);
            }
        }
        int messagesSent, messagesReceived, queueJumpers, messagesCancelled, errorMessages;
        private readonly Dictionary<int, int> dbUsage = new Dictionary<int, int>();
        private void LogUsage(int db)
        {
            lock (dbUsage)
            {
                int count;
                if (dbUsage.TryGetValue(db, out count))
                {
                    dbUsage[db] = count + 1;
                }
                else
                {
                    dbUsage.Add(db, 1);
                }
            }
        }
        /// <summary>
        /// Invoked when any error message is received on the connection.
        /// </summary>
        public event EventHandler<ErrorEventArgs> Error;
        /// <summary>
        /// Raises an error event
        /// </summary>
        protected void OnError(object sender, ErrorEventArgs args)
        {
            var handler = Error;
            if (handler != null)
            {
                handler(sender, args);
            }
        }
        /// <summary>
        /// Raises an error event
        /// </summary>
        protected void OnError(string cause, Exception ex, bool isFatal)
        {
            var handler = Error;
            var agg = ex as AggregateException;
            if (handler == null)
            {
                if (agg != null)
                {
                    foreach (var inner in agg.InnerExceptions)
                    {
                        Trace(cause, inner.Message);
                    }
                }
                else
                {
                    Trace(cause, ex.Message);
                }
            }
            else
            {
                if (agg != null)
                {
                    foreach (var inner in agg.InnerExceptions)
                    {
                        handler(this, new ErrorEventArgs(inner, cause, isFatal));
                    }
                }
                else
                {
                    handler(this, new ErrorEventArgs(ex, cause, isFatal));
                }
            }
        }
        private Stream outBuffer;
        internal void Flush(bool all)
        {
            if (all)
            {
                var tmp1 = outBuffer;
                if (tmp1 != null) tmp1.Flush();
            }
            var tmp2 = redisStream;
            if(tmp2 != null) tmp2.Flush();
            Trace("send", all ? "full-flush" : "part-flush");
        }

        private int db = 0;
        //private void Outgoing()
        //{
        //    try
        //    {

        //        int db = 0;
        //        RedisMessage next;
        //        Trace.WriteLine("Redis send-pump is starting");
        //        bool isHigh, shouldFlush;
        //        while (unsent.TryDequeue(false, out next, out isHigh, out shouldFlush))
        //        {

        //            Flush(shouldFlush);

        //        }
        //        Interlocked.CompareExchange(ref state, (int)ConnectionState.Closing, (int)ConnectionState.Open);
        //        if (redisStream != null)
        //        {
        //            var quit = RedisMessage.Create(-1, RedisLiteral.QUIT).ExpectOk().Critical();

        //            RecordSent(quit, !abort);
        //            quit.Write(outBuffer);
        //            outBuffer.Flush();
        //            redisStream.Flush();
        //            Interlocked.Increment(ref messagesSent);
        //        }
        //        Trace.WriteLine("Redis send-pump is exiting");
        //    }
        //    catch (Exception ex)
        //    {
        //        OnError("Outgoing queue", ex, true);
        //    }

        //}

        internal void WriteMessage(ref int db, RedisMessage next, IList<QueuedMessage> queued)
        {
            var snapshot = outBuffer;
            if (snapshot == null)
            {
                throw new InvalidOperationException("Cannot write message; output is unavailable");
            }
            if (next.Db >= 0)
            {
                // not all servers support databases...
                switch(ServerType)
                {
                    case BookSleeve.ServerType.Cluster:
                    case BookSleeve.ServerType.Sentinel:
                        if (next.Db != 0) throw new InvalidOperationException("This connection does not support databases; database 0 must be specified");
                        break;
                    default:
                        /*
                        if (db != next.Db)
                        {
                            db = next.Db;
                            RedisMessage changeDb = RedisMessage.Create(db, RedisLiteral.SELECT, db).ExpectOk().Critical();
                            if (queued != null)
                            {
                                queued.Add((QueuedMessage)(changeDb = new QueuedMessage(changeDb)));
                            }
                            RecordSent(changeDb);
                            changeDb.Write(snapshot);
                            Interlocked.Increment(ref messagesSent);
                        }
                        */
                        LogUsage(db);
                        break;
                }
            }
            if (next.Command == RedisLiteral.QUIT)
            {
                abort = true; // no more!
            }
            if (next.Command == RedisLiteral.SELECT)
            {
                // dealt with above; no need to send SELECT, SELECT
            }
            else
            {
                var mm = next as IMultiMessage;
                var tmp = next;
                if (queued != null)
                {
                    if (mm != null) throw new InvalidOperationException("Cannot perform composite operations (such as transactions) inside transactions");
                    queued.Add((QueuedMessage)(tmp = new QueuedMessage(tmp)));
                }

                if (mm == null)
                {
                    RecordSent(tmp);
                    tmp.Write(snapshot);
                    Interlocked.Increment(ref messagesSent);
                    switch (tmp.Command)
                    {
                        // scripts can change database
                        case RedisLiteral.EVAL:
                        case RedisLiteral.EVALSHA:
                        // transactions can be aborted without running the inner commands (SELECT) that have been written
                        case RedisLiteral.DISCARD:
                        case RedisLiteral.EXEC:
                            // we can't trust the current database; whack it
                            db = -1;
                            break;
                    }
                }
                else
                {
                    mm.Execute(this, ref db);
                }
            }
        }

        internal void WriteRaw(RedisMessage message)
        {
            if (message.Db >= 0) throw new ArgumentException("message", "WriteRaw cannot be used with db-centric messages");
            RecordSent(message);
            message.Write(outBuffer);
            Interlocked.Increment(ref messagesSent);
        }
        /// <summary>
        /// Return the number of items in the sent-queue
        /// </summary>
        protected int GetSentCount() { lock (sent) { return sent.Count; } }
        internal virtual void RecordSent(RedisMessage message, bool drainFirst = false) {
            Debug.Assert(message != null, "messages should not be null");
            lock (sent)
            {
                if (drainFirst && sent.Count != 0)
                {
                    // drain it down; the dequeuer will wake us
                    Monitor.Wait(sent);
                }
                sent.Enqueue(message);
            }
        }
        /// <summary>
        /// Indicates the current state of the connection to the server
        /// </summary>
        public enum ConnectionState
        {
            /// <summary>
            /// A connection that has not yet been innitialized
            /// </summary>
            [Obsolete("Please use New instead"), DebuggerBrowsable(DebuggerBrowsableState.Never)]
            Shiny = 0,
            /// <summary>
            /// A connection that has not yet been innitialized
            /// </summary>
            New = 0,
            /// <summary>
            /// A connection that is in the process of opening
            /// </summary>
            Opening = 1,
            /// <summary>
            /// An open connection
            /// </summary>
            Open = 2,
            /// <summary>
            /// A connection that is in the process of closing
            /// </summary>
            Closing = 3,
            /// <summary>
            /// A connection that is now closed and cannot be used
            /// </summary>
            Closed = 4
        }
        private readonly MemoryStream bodyBuffer = new MemoryStream();


        internal Task<bool> ExecuteBoolean(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultBoolean();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<long> ExecuteInt64(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultInt64(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task ExecuteVoid(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultVoid(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<double> ExecuteDouble(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultDouble();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<byte[]> ExecuteBytes(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultBytes();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<RedisResult> ExecuteRaw(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultRaw(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<string> ExecuteString(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultString(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        internal Task<long?> ExecuteNullableInt64(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultNullableInt64();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        internal Task<double?> ExecuteNullableDouble(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultNullableDouble(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        internal Task<byte[][]> ExecuteMultiBytes(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultMultiBytes(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<string[]> ExecuteMultiString(RedisMessage message, bool queueJump, object state = null)
        {
            var msgResult = new MessageResultMultiString(state);
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        internal Task<KeyValuePair<byte[], double>[]> ExecutePairs(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultPairs();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        internal Task<Dictionary<string, byte[]>> ExecuteHashPairs(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultHashPairs();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        internal Task<Dictionary<string, string>> ExecuteStringPairs(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultStringPairs();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }
        internal Task<KeyValuePair<string, double>[]> ExecuteStringDoublePairs(RedisMessage message, bool queueJump)
        {
            var msgResult = new MessageResultStringDoublePairs();
            message.SetMessageResult(msgResult);
            EnqueueMessage(message, queueJump);
            return msgResult.Task;
        }

        private readonly object writeLock = new object();
        private int pendingWriterCount;
        private void WritePendingQueue()
        {
            RedisMessage next;
            do
            {
                lock (unsent)
                {
                    next = unsent.Count == 0 ? null : unsent.Dequeue();
                }
                if (next != null)
                {
                    Trace("pending", "dequeued: {0}", next);
                    WriteMessage(next, true);
                }
            } while (next != null);
        }
        private void WriteMessage(RedisMessage message, bool isHigh)
        {
            if (abort && message.Command != RedisLiteral.QUIT)
            {
                CompleteMessage(message, RedisResult.Cancelled);
                return;
            }
            if (!message.ChangeState(MessageState.NotSent, MessageState.Sent))
            {
                // already cancelled; not our problem any more...
                Interlocked.Increment(ref messagesCancelled);
                return;
            }
            if (isHigh) Interlocked.Increment(ref queueJumpers);
            WriteMessage(ref db, message, null);
            // Redis tends to shutdown the entire socket if you close the SEND part eagerly
            //if (message.Command == RedisLiteral.QUIT)
            //{
            //    FlushOutbound();
            //    if(socket != null) socket.Shutdown(SocketShutdown.Send);
            //}
        }
        private volatile bool hold = true;

        private void FlushOutbound()
        {
            lock (writeLock)
            {
                Flush(true);
            }
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
        protected void SuspendFlush()
        {
            Interlocked.Increment(ref pendingWriterCount);
        }
        /// <summary>
        /// Resume eager-flushing (flushing if the write-queue becomes empty briefly). See SuspendFlush for
        /// full usage.
        /// </summary>
        protected void ResumeFlush()
        {
            if (Interlocked.Decrement(ref pendingWriterCount) == 0)
            {
                lock (writeLock)
                {
                    Flush(true);
                }
            }
        }
        /// <summary>
        /// Writes a group of messages, but allowing other threads to inject messages between them;
        /// this method minimises the numbers of packets by preventing flush until all are written
        /// </summary>
        internal void EnqueueMessages(RedisMessage[] all, bool queueJump)
        {
            if (all == null) throw new ArgumentNullException("all");
            switch(all.Length) {
                case 0:
                    return;
                case 1:
                    EnqueueMessage(all[0], queueJump);
                    return;
            }

            // so: at least 2 messages; spoof an extra writer to prevent premature flushing
            SuspendFlush();
            try
            {
                for (int i = 0; i < all.Length - 1; i++)
                {
                    EnqueueMessage(all[i], queueJump);
                }
            }
            finally
            {
                ResumeFlush();
            }
            // and write the last message outside of the fake writer, so it will flush if no more writers
            EnqueueMessage(all[all.Length - 1], queueJump);

        }
        /// <summary>
        /// The message to supply to callers when rejecting messages
        /// </summary>
        protected virtual string GetCannotSendMessage()
        {
            return string.Format("The connection has been closed ({0}); no new messages can be delivered", ShutdownType);
        }
        internal void EnqueueMessage(RedisMessage message, bool queueJump)
        {
            bool decr = true;
            Interlocked.Increment(ref pendingWriterCount);
            try
            {
                if (message != null && !message.IsDuringInit)
                {
                    if (queueJump || hold)
                    {
                        if (abort) throw new InvalidOperationException(GetCannotSendMessage());
                        lock (unsent)
                        {
                            Trace("pending", "enqueued: {0}", message);
                            unsent.Enqueue(message);
                        }
                        if (hold)
                        {
                            Interlocked.Decrement(ref pendingWriterCount);
                            return;
                        }
                    }
                }
                lock (writeLock)
                {
                    if (message == null)
                    {   // process any backlog and flush
                        WritePendingQueue();
                        Flush(true);
                    }
                    else if (message.IsDuringInit)
                    {
                        // ONLY write that message; no queues
                        WriteMessage(message, false);
                    }
                    else if (queueJump)
                    {
                        // we enqueued to the end of the queue; just write the queue
                        WritePendingQueue();
                    }
                    else
                    {
                        // we didn't enqueue; write the queue, then our message, then queue again
                        WritePendingQueue();
                        WriteMessage(message, false);
                        WritePendingQueue();
                    }
                    bool fullFlush = Interlocked.Decrement(ref pendingWriterCount) == 0;
                    decr = false;

                    if (message == null || !message.IsDuringInit)
                    { // this excludes the case where we are just sending an init message, where we don't flush
                        Flush(fullFlush);
                    }
                }
            }
            catch
            {
                if(decr) Interlocked.Decrement(ref pendingWriterCount);
                throw;
            }
        }
        internal void CancelUnsent()
        {
            lock (unsent)
            {
                if (unsent.Count != 0)
                {
                    Trace("cancelunsent", "aborting unsent queue ({0} items)", unsent.Count);
                }
                while (unsent.Count != 0)
                {
                    var next = unsent.Dequeue();
                    Trace("cancelunsent", "aborting {0}", next);
                    RedisResult result = RedisResult.Cancelled;
                    RedisConnectionBase.CallbackMode callbackMode;
                    object ctx = ProcessReply(ref result, next, out callbackMode);
                    ProcessCallbacks(ctx, result, callbackMode);
                }
            }
        }
        static readonly RedisMessage[] noMessages = new RedisMessage[0];
        internal RedisMessage[] DequeueAll()
        {
            lock (unsent)
            {
                int len = unsent.Count;
                if (len == 0) return noMessages;
                var arr = new RedisMessage[len];
                for (int i = 0; i < arr.Length; i++)
                    arr[i] = unsent.Dequeue();
                return arr;
            }
        }
        /// <summary>
        /// If the task is not yet completed, blocks the caller until completion up to a maximum of SyncTimeout milliseconds.
        /// Once a task is completed, the result is returned.
        /// </summary>
        /// <param name="task">The task to wait on</param>
        /// <returns>The return value of the task.</returns>
        /// <exception cref="TimeoutException">If SyncTimeout milliseconds is exceeded.</exception>
        public T Wait<T>(Task<T> task)
        {
            Wait((Task)task);
            return task.Result;
        }

        /// <summary>
        /// If true, then when using the Wait methods, information about the oldest outstanding message
        /// is included in the exception; this often points to a particular operation that was monopolising
        /// the connection
        /// </summary>
        public bool IncludeDetailInTimeouts { get; set; }

        volatile int syncCompleteThreadId = -1;

        private int CurrentThreadId
        {
            get { return System.Threading.Thread.CurrentThread.ManagedThreadId; }
        }

        /// <summary>
        /// If the task is not yet completed, blocks the caller until completion up to a maximum of SyncTimeout milliseconds.
        /// </summary>
        /// <param name="task">The task to wait on</param>
        /// <exception cref="TimeoutException">If SyncTimeout milliseconds is exceeded.</exception>
        /// <remarks>If an exception is throw, it is extracted from the AggregateException (unless multiple exceptions are found)</remarks>
        public void Wait(Task task)
        {
            if (task == null) throw new ArgumentNullException("task");
            DetectReEntrantCallback();
            try
            {
                if (!task.Wait(syncTimeout))
                {
                    throw CreateTimeout();
                }
            }
            catch (AggregateException ex)
            {
                if (ex.InnerExceptions.Count == 1)
                {
                    throw ex.InnerExceptions[0];
                }
                throw;
            }
        }

        private void DetectReEntrantCallback()
        {
            if (syncCompleteThreadId >= 0 && syncCompleteThreadId == CurrentThreadId)
            {
                throw new InvalidOperationException("You cannot Wait while a callback is executing synchronously (ResultCompletionMode.PreserveOrder etc) as this would produce a deadlock; if using 'await', please use SafeAwaitable(); if using 'ContinueWith', please do not specify 'TaskContinuationOptions.ExecuteSynchronously'");
            }
        }
        /// <summary>
        /// Give some information about the oldest incomplete (but sent) message on the server
        /// </summary>
        protected virtual string GetTimeoutSummary()
        {
            return null;
        }
        private TimeoutException CreateTimeout()
        {
            string message = null;
            if (state != (int)ConnectionState.Open)
            {
                message = "The operation has timed out; the connection is not open";
#if VERBOSE
                message += " (" + ((ConnectionState)state).ToString() + ")";
#endif
                
            }
            else if (IncludeDetailInTimeouts)
            {
                string compete = GetTimeoutSummary();
                if (!string.IsNullOrWhiteSpace(compete))
                {
                    message = "The operation has timed out; possibly blocked by: " + compete;
                }
            }
#if VERBOSE
            if (message != null)
            {
                message += " (after " + (outBuffer == null ? -1 : outBuffer.Position) + " bytes)";
            }
#endif
            return message == null ? new TimeoutException() : new TimeoutException(message);
        }
        /// <summary>
        /// Waits for all of a set of tasks to complete, up to a maximum of SyncTimeout milliseconds.
        /// </summary>
        /// <param name="tasks">The tasks to wait on</param>
        /// <exception cref="TimeoutException">If SyncTimeout milliseconds is exceeded.</exception>
        public void WaitAll(params Task[] tasks)
        {
            if (tasks == null) throw new ArgumentNullException("tasks");
            DetectReEntrantCallback();
            if (!Task.WaitAll(tasks, syncTimeout))
            {
                throw CreateTimeout();
            }
        }
        /// <summary>
        /// Waits for any of a set of tasks to complete, up to a maximum of SyncTimeout milliseconds.
        /// </summary>
        /// <param name="tasks">The tasks to wait on</param>
        /// <returns>The index of a completed task</returns>
        /// <exception cref="TimeoutException">If SyncTimeout milliseconds is exceeded.</exception>        
        public int WaitAny(params Task[] tasks)
        {
            if (tasks == null) throw new ArgumentNullException("tasks");
            DetectReEntrantCallback();
            return Task.WaitAny(tasks, syncTimeout);
        }
        /// <summary>
        /// Add a continuation (a callback), to be executed once a task has completed
        /// </summary>
        /// <param name="task">The task to add a continuation to</param>
        /// <param name="action">The continuation to perform once completed</param>
        /// <returns>A new task representing the composed operation</returns>
        public Task ContinueWith<T>(Task<T> task, Action<Task<T>> action)
        {
            return task.ContinueWith(action, CancellationToken.None, TaskContinuationOptions.LongRunning, TaskScheduler.Default);
        }
        /// <summary>
        /// Add a continuation (a callback), to be executed once a task has completed
        /// </summary>
        /// <param name="task">The task to add a continuation to</param>
        /// <param name="action">The continuation to perform once completed</param>
        /// <returns>A new task representing the composed operation</returns>
        public Task ContinueWith(Task task, Action<Task> action)
        {
            return task.ContinueWith(action, CancellationToken.None, TaskContinuationOptions.LongRunning, TaskScheduler.Default);
        }

        /// <summary>
        /// What type of connection is this
        /// </summary>
        public ServerType ServerType { get; private set; }

        private ResultCompletionMode completionMode = InitCompletionMode(DefaultCompletionMode);
        /// <summary>
        /// Gets or sets the behavior for processing incoming messages.
        /// </summary>
        public ResultCompletionMode CompletionMode {
            get { return completionMode; }
            set { completionMode = InitCompletionMode(value); }
        }

        

        private static ResultCompletionMode defaultCompletionMode = ResultCompletionMode.Concurrent;
        /// <summary>
        /// Gets or sets the default CompletionMode value for all new connections.
        /// </summary>
        public static ResultCompletionMode DefaultCompletionMode
        {
            get { return defaultCompletionMode; }
            set { defaultCompletionMode = value; }
        }

        /// <summary>
        /// Attempt to reduce Task overhead by completing tasks without continuations synchronously (default is asynchronously)
        /// </summary>
        [Browsable(false), EditorBrowsable(EditorBrowsableState.Never)]
        [Obsolete("Please use DefaultCompletionMode = ResultCompletionMode.ConcurrentIfContinuation")]
        public static void EnableSyncCallbacks()
        {
            DefaultCompletionMode = ResultCompletionMode.ConcurrentIfContinuation;
        }
        private static ResultCompletionMode InitCompletionMode(ResultCompletionMode mode)
        {
            if (mode == ResultCompletionMode.ConcurrentIfContinuation && NoContinuations == null)
            {
                try
                {
                    var field = typeof(Task).GetField("m_continuationObject", BindingFlags.NonPublic | BindingFlags.Instance);
                    if (field == null) throw new InvalidOperationException("Expected field not found: Task.m_continuationObject");

                    var method = new DynamicMethod("NoContinuations", typeof(bool), new[] { typeof(Task) },
                        typeof(Task), true);
                    var il = method.GetILGenerator();
                    il.Emit(OpCodes.Ldarg_0);
                    il.Emit(OpCodes.Ldflda, field);
                    il.Emit(OpCodes.Ldnull);
                    il.Emit(OpCodes.Ldnull);
                    il.EmitCall(OpCodes.Call, typeof(Interlocked).GetMethod("CompareExchange", new[] { typeof(object).MakeByRefType(), typeof(object), typeof(object) }), null);
                    il.Emit(OpCodes.Ldnull);
                    il.Emit(OpCodes.Ceq);
                    il.Emit(OpCodes.Ret);

                    var func = (Func<Task, bool>)method.CreateDelegate(typeof(Func<Task, bool>));
                    TaskCompletionSource<int> source = new TaskCompletionSource<int>();
                    var before = func(source.Task);
                    source.Task.ContinueWith(t => { });
                    var after = func(source.Task);
                    if (!before) throw new InvalidOperationException("vanilla task should report true");
                    if (after) throw new InvalidOperationException("task with continuation should report false");
                    source.TrySetResult(0);
                    NoContinuations = func;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Trace.WriteLine(ex.Message);
                    NoContinuations = null; // have to assume the worst, then
                }
            }
            return mode;
        }
        internal static Func<Task, bool> NoContinuations;

    }

    /// <summary>
    /// What type of server does this represent
    /// </summary>
    public enum ServerType
    {
        /// <summary>
        /// The server is not yet connected, or is not recognised
        /// </summary>
        Unknown = 0,
        /// <summary>
        /// The server is a master node, suitable for read and write
        /// </summary>
        Master = 1,
        /// <summary>
        /// The server is a replication slave, suitable for read
        /// </summary>
        Slave = 2,
        /// <summary>
        /// The server is a sentinel, used for anutomated configuration
        /// and failover
        /// </summary>
        Sentinel = 3,
        /// <summary>
        /// The server is part of a cluster
        /// </summary>
        Cluster= 4
    }
}

