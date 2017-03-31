using System;
using System.Threading;
using GamMatrixAPI;

namespace GmCore
{
    /// <summary>
    /// Summary description for AsyncResult
    /// </summary>
    public sealed class AsyncResult : IAsyncResult
    {
        private readonly Action<AsyncResult> _asyncCallback;
        private ManualResetEvent _asyncWaitHandle;

        public object AsyncState { get; internal set; }
        public object UserState1 { get; internal set; }
        public object UserState2 { get; internal set; }
        public object UserState3 { get; internal set; }
        public bool CompletedSynchronously { get { return false; } }
        public bool IsCompleted { get; private set; }
        public Exception Exception { get; private set; }
        private GamMatrixAPI.ReplyResponse ReplyResponse  { get; set; }

        public AsyncResult(Action<AsyncResult> asyncCallback)
        {
            _asyncCallback = asyncCallback;
        }

        public WaitHandle AsyncWaitHandle 
        { 
            get 
            {
                if (_asyncWaitHandle == null)
                {
                    bool done = IsCompleted;
                    ManualResetEvent evt = new ManualResetEvent(done);
                    if (Interlocked.CompareExchange(ref _asyncWaitHandle, evt, null) != null)
                    {
                        // Another thread created this object's event; dispose
                        // the event we just created
                        evt.Close();
                    }
                    else
                    {
                        if (!done && IsCompleted)
                        {
                            // If the operation wasn't done when we created
                            // the event but now it is done, set the event
                            _asyncWaitHandle.Set();
                        }
                    }

                }
                return _asyncWaitHandle;
            } 
        }

        internal void Complete(Exception exception, GamMatrixAPI.ReplyResponse replyResponse)
        {
            try
            {
                this.Exception = exception;
                this.ReplyResponse = replyResponse;
                if (_asyncWaitHandle != null) _asyncWaitHandle.Set();

                if (_asyncCallback != null)
                {
                    _asyncCallback(this);
                }

                this.IsCompleted = true;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public ReplyResponse EndSingleRequest()
        {
            if (this.Exception != null)
                throw this.Exception;

            return this.ReplyResponse;
        }

    }
}