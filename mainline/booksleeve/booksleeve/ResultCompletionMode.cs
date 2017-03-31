
namespace BookSleeve
{
    /// <summary>
    /// Indicates how incoming messages should be completed / dispatched.
    /// </summary>
    public enum ResultCompletionMode
    {
        /// <summary>
        /// Results are always completed synchronously; this guarantees to preserve order, but means that long-running
        /// continuations may block other operations from completing even when the data is available.
        /// </summary>
        PreserveOrder,

        /// <summary>
        /// Results are dispatched asynchronously; no guarantee of order is offered.
        /// </summary>
        Concurrent,

        /// <summary>
        /// The system will attempt to determine whether any given operation has a continuation; if it does, it will
        /// dispatch it concurrently to avoid risk of blocking scenarios; if it does not, it will complete it
        /// synchronously for performance.
        /// </summary>
        ConcurrentIfContinuation
    }
}
