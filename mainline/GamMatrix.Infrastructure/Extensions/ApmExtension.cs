using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

/// <summary>
/// Converts .NET TPL async task pattern to the APM pattern. See [Stephen Toub's blog post](http://blogs.msdn.com/b/pfxteam/archive/2011/06/27/10179452.aspx)
/// </summary>
public static class ApmExtension
{
    public static Task<TResult> ToApm<TResult>(this Task<TResult> task, AsyncCallback callback, object state)
    {
        if (task == null)
        {
            throw new ArgumentNullException("task");
        }

        if (task.AsyncState == state)
        {
            if (callback != null)
            {
                task.ContinueWith(
                    (t, cb) => ((AsyncCallback)cb)(t),
                    callback,
                    CancellationToken.None,
                    TaskContinuationOptions.None,
                    TaskScheduler.Default);
            }

            return task;
        }

        var tcs = new TaskCompletionSource<TResult>(state);
        task.ContinueWith(
            t =>
            {
                if (t.IsFaulted)
                {
                    tcs.TrySetException(t.Exception.InnerExceptions);
                }
                else if (t.IsCanceled)
                {
                    tcs.TrySetCanceled();
                }
                else
                {
                    tcs.TrySetResult(t.Result);
                }

                if (callback != null)
                {
                    callback(tcs.Task);
                }

            },
            CancellationToken.None,
            TaskContinuationOptions.None,
            TaskScheduler.Default);

        return tcs.Task;
    }

    public static Task ToApm(this Task task, AsyncCallback callback, object state)
    {
        if (task == null)
        {
            throw new ArgumentNullException("task");
        }

        if (task.AsyncState == state)
        {
            if (callback != null)
            {
                task.ContinueWith(
                    (t, cb) => ((AsyncCallback)cb)(t),
                    callback,
                    CancellationToken.None,
                    TaskContinuationOptions.None,
                    TaskScheduler.Default);
            }

            return task;
        }

        var tcs = new TaskCompletionSource<object>(state);
        task.ContinueWith(
            t =>
            {
                if (t.IsFaulted)
                {
                    tcs.TrySetException(t.Exception.InnerExceptions);
                }
                else if (t.IsCanceled)
                {
                    tcs.TrySetCanceled();
                }
                else
                {
                    tcs.TrySetResult(null);
                }

                if (callback != null)
                {
                    callback(tcs.Task);
                }
            },
            CancellationToken.None,
            TaskContinuationOptions.None,
            TaskScheduler.Default);

        return tcs.Task;
    }
}