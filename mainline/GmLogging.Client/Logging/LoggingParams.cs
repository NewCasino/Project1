using System;
using System.Collections.Generic;
using System.Linq;

namespace GmGaming.Infrastructure.Logging
{
    public static class LoggingParams
    {
        public const string ExpireTime = "ExpireTime";

        public static class Reserved
        {
            public const string CallStack = "CallStack";
            public const string Exception = "Exception";
            public const string RequestID = "RequestID";
            public const string Message = "Message";
            public const string LogLevel = "LogLevel";
            public const string Server = "Server";
            public const string LogClientTime = "LogClientTime";
        }
    }
}
