//using System;
//using System.Collections.Generic;
//using System.Threading;
//using System.Diagnostics;

//namespace BookSleeve
//{
    
    
 
//    /// <summary>
//    /// Implements a thread-safe queue for use in a producer/consumer scenario
//    /// </summary>
//    /// <remarks> This is based on http://stackoverflow.com/questions/530211/creating-a-blocking-queuet-in-net/530228#530228 </remarks>
//    internal class MessageQueue
//    {
//        bool closed;
//        public void Close()
//        {
//            lock (stdPriority)
//            {
//                closed = true;
//                Monitor.PulseAll(stdPriority);
//            }
//        }
//        public void Open()
//        {
//            lock (stdPriority)
//            {
//                closed = false;
//                Monitor.PulseAll(stdPriority);
//            }
//        }
//        private readonly Queue<RedisMessage> stdPriority = new Queue<RedisMessage>(), // we'll use stdPriority as the sync-lock for both
//            highPriority = new Queue<RedisMessage>();

//        private readonly int maxSize;
//        private int keepAliveMilliseconds = int.MaxValue;
//        public void SetKeepAlive(int seconds)
//        {
//            int newTimeout;
//            checked
//            {
//                newTimeout = (seconds > 0 && seconds != int.MaxValue) ? (1000 * seconds) : int.MaxValue;
//            }
//            lock(stdPriority)
//            {
//                if (newTimeout != keepAliveMilliseconds)
//                {
//                    keepAliveMilliseconds = newTimeout;
//                    if (!closed && stdPriority.Count == 0 && highPriority.Count == 0)
//                    {
//                        // nothing is waiting, so the timeout won't get reset - add a PING into the mix
//                        stdPriority.Enqueue(new PingMessage());
//                        Monitor.PulseAll(stdPriority);
//                    }
//                }
//            }
//        }
//        public MessageQueue(int maxSize)
//        {
//            this.maxSize = maxSize;
//        }

//        public void Enqueue(RedisMessage item, bool highPri)
//        {
//            lock (stdPriority)
//            {
//                if (closed)
//                {
//                    throw new InvalidOperationException("The queue is closed");
//                }
//                if (highPri)
//                {
//                    highPriority.Enqueue(item);
//                }
//                else
//                {
//                    while (stdPriority.Count >= maxSize)
//                    {
//                        Monitor.Wait(stdPriority);
//                    }
//                    stdPriority.Enqueue(item);
//                }
//                if (stdPriority.Count + highPriority.Count == 1)
//                {
//                    // wake up any blocked dequeue
//                    Monitor.PulseAll(stdPriority);
//                }
//            }
//        }
//        public RedisMessage[] DequeueAll()
//        {
//            lock (stdPriority)
//            {
//                RedisMessage[] result = new RedisMessage[highPriority.Count + stdPriority.Count];
//                highPriority.CopyTo(result, 0);
//                stdPriority.CopyTo(result, highPriority.Count);
//                highPriority.Clear();
//                stdPriority.Clear();
//                // wake up any blocked enqueue
//                Monitor.PulseAll(stdPriority);
//                return result;
//            }
//        }
//        public bool TryDequeue(bool noWait, out RedisMessage value, out bool isHigh, out bool shouldFlush)
//        {
//            lock (stdPriority)
//            {
//                int timeoutMilliseconds = this.keepAliveMilliseconds;
//                while (highPriority.Count == 0 && stdPriority.Count == 0 && timeoutMilliseconds > 0)
//                {
//                    if (closed || noWait)
//                    {
//                        value = null;
//                        isHigh = false;
//                        shouldFlush = true;
//                        return false;
//                    }
//                    if (timeoutMilliseconds == int.MaxValue)
//                    {
//                        Monitor.Wait(stdPriority);
//                    }
//                    else
//                    {
//                        var watch = Stopwatch.StartNew();
//                        Monitor.Wait(stdPriority, timeoutMilliseconds);
//                        watch.Stop();
//                        timeoutMilliseconds -= (int) watch.ElapsedMilliseconds;
//                    }
//                }

//                int loCount = stdPriority.Count, hiCount = highPriority.Count;
//                isHigh = hiCount > 0;
//                if (isHigh)
//                {
//                    value = highPriority.Dequeue();
//                    hiCount--;
//                    shouldFlush = hiCount == 0;
//                }
//                else if(loCount > 0)
//                {
//                    value = stdPriority.Dequeue();
//                    loCount--;
//                    shouldFlush = loCount == 0;
//                } else
//                { // nothing there! it must have been a KeepAlive timeout then
//                    shouldFlush = true; // want this sent NOW
//                    value = new PingMessage();
//                }

//                if ((!isHigh && loCount == maxSize - 1) || (loCount == 0 && hiCount == 0))
//                {
//                    // wake up any blocked enqueue
//                    Monitor.PulseAll(stdPriority);
//                }
//                if (isHigh && loCount == 0) isHigh = false;//can't be high if it didn't overtake
//                return true;
//            }
//        }

//        internal int GetCount()
//        {
//            lock (stdPriority)
//            {
//                return stdPriority.Count + highPriority.Count;
//            }
//        }
//    }
//}
