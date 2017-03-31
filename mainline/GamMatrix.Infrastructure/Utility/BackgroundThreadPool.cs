using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Threading;
using System.Text;
using System.Globalization;


public sealed class BackgroundThreadPool
{
    internal sealed class WorkItem
    {
        internal WaitCallback cb;
        internal object state;
        internal string name;
    }

    private const int INITIAL_THREAD_COUNT = 1;
    private static BackgroundThreadPool s_Singleton = new BackgroundThreadPool();

    private ManualResetEvent _manualResetEvent = new ManualResetEvent(true);
    private List<Thread> _threads = new List<Thread>();
    private List<WorkItem> _items = new List<WorkItem>();
    private int _workItemCount = 0;
    private object _lock = new object();

    public static int WorkItemCount { get { return s_Singleton._workItemCount; } }

    public static ICollection<Thread> GetThreads()
    {
        return s_Singleton._threads;
    }

    public static string GetTasks()
    {
        StringBuilder sb = new StringBuilder();

        lock (s_Singleton._lock)
        {
            for( int i = 0; i < s_Singleton._items.Count; i++)
            {
                sb.AppendFormat("Task [#{0}] : {1}\n", i, s_Singleton._items[i].name);
            }
        }

        return sb.ToString();
    }

    public static void QueueUserWorkItem(string name, WaitCallback callback, object state)
    {
        s_Singleton.InternalQueueUserWorkItem(name, callback, state, false);
    }

    public static void QueueUserWorkItem(string name, WaitCallback callback, object state, bool highPriority)
    {
        s_Singleton.InternalQueueUserWorkItem(name, callback, state, highPriority);
    }


    private void InternalQueueUserWorkItem(string name, WaitCallback callback, object state, bool highPriority)
    {
        WorkItem item = new WorkItem()
        {
            cb = callback,
            state = state,
            name = name,
        };
        lock (_lock)
        {
            if (highPriority)
                _items.Insert(0, item);
            else
                _items.Add(item);
        }
        Interlocked.Increment(ref _workItemCount);
        _manualResetEvent.Set();
    }

    private BackgroundThreadPool()
    {
        GC.KeepAlive(this);
        for (int i = 0; i < INITIAL_THREAD_COUNT; i++)
        {
            Thread thread = new Thread(WorkerThread);
            thread.IsBackground = true;
            thread.Priority = ThreadPriority.BelowNormal;
            thread.Name = string.Format(CultureInfo.InvariantCulture, "#{0}", i + 1);
            thread.Start();
            _threads.Add(thread);
        }
    }


    private void WorkerThread()
    {      
        for(;;)
        {
            _manualResetEvent.WaitOne();
            WorkItem item;
            for (; ; )
            {
                lock (_lock)
                {
                    if (_items.Count == 0)
                    {
                        _manualResetEvent.Reset();
                        break;
                    }
                    item = _items[0];
                    _items.RemoveAt(0);
                    if (_items.Count > 0)
                        _manualResetEvent.Set();
                    else
                        _manualResetEvent.Reset();
                }

                Interlocked.Decrement(ref _workItemCount);
                try
                {
                    item.cb(item.state);
                }
                catch
                {
                }
            }
           
        }
    }

}
