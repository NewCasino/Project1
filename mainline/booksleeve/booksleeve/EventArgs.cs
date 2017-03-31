using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BookSleeve
{
    /// <summary>
    /// Event data relating to an exception in Redis
    /// </summary>
    public sealed class ErrorEventArgs : EventArgs
    {
        /// <summary>
        /// The exception that occurred
        /// </summary>
        public Exception Exception { get; private set; }
        /// <summary>
        /// What the system was doing when this error occurred
        /// </summary>
        public string Cause { get; private set; }
        /// <summary>
        /// True if this error has rendered the connection unusable
        /// </summary>
        public bool IsFatal { get; private set; }
        internal ErrorEventArgs(Exception exception, string cause, bool isFatal)
        {
            this.Exception = exception;
            this.Cause = cause;
            this.IsFatal = isFatal;
        }
    }
}
