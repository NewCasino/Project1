using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BookSleeve
{
    /// <summary>
    /// Indicates the reason that a connection was shut down
    /// </summary>
    public enum ShutdownType
    {
        /// <summary>
        /// The connection is not shut down
        /// </summary>
        None = 0,
        /// <summary>
        /// The connection was closed by the client calling close
        /// </summary>
        ClientClosed = 1,
        /// <summary>
        /// The connection was closed by the client being disposed
        /// </summary>
        ClientDisposed = 2,
        /// <summary>
        /// The server closed the connection (EOF)
        /// </summary>
        ServerClosed = 3,
        /// <summary>
        /// The connection was terminated due to an unexpected error
        /// </summary>
        Error = 4
    }
}
