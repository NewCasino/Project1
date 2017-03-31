using System;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Utility classes for working safely with tasks
    /// </summary>
    public static class TaskUtils
    {
        /// <summary>
        /// Create a task wrapper that is safe to use with "await", by avoiding callback-inlining
        /// </summary>
        public static Task SafeAwaitable(this Task task)
        {
            if (task.IsCompleted || task.IsCanceled) return task;
            var source = new TaskCompletionSource<bool>();
            task.ContinueWith(t =>
            {
                if (t.ShouldSetResult(source)) source.TrySetResult(true);
            }, TaskContinuationOptions.LongRunning);
            return source.Task;
        }
        /// <summary>
        /// Create a task wrapper that is safe to use with "await", by avoiding callback-inlining 
        /// </summary>
        public static Task<T> SafeAwaitable<T>(this Task<T> task)
        {
            if (task.IsCompleted || task.IsCanceled) return task;
            var source = new TaskCompletionSource<T>();
            task.ContinueWith(t =>
            {
                if (t.ShouldSetResult(source)) source.TrySetResult(t.Result);
            }, TaskContinuationOptions.LongRunning);
            return source.Task;
        }

        internal static bool ShouldSetResult<T>(this Task task, TaskCompletionSource<T> source)
        {
            if (task.IsFaulted)
            {
                source.SafeSetException(task.Exception);
            }
            else if (task.IsCanceled)
            {
                source.TrySetCanceled();
            }
            else if (task.IsCompleted)
            {
                return true;
            }
            return false;
        }
        internal static void SafeSetException<T>(this TaskCompletionSource<T> source, Exception ex)
        {
            if (ex == null)
            {
                source.TrySetCanceled(); // nothing actually wrong...
            }
            else if(source.TrySetException(ex))
            { // and consume it immediately to make the GC a happy bunny
                GC.KeepAlive(source.Task.Exception); // this is just an opaque method; does nothing
            }
        }
    }
}
