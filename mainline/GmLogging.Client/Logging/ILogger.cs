using System;
using System.Collections.Generic;
using System.Linq;

namespace GmGaming.Infrastructure.Logging
{
    public interface ILogger
    {
        void Log(LogLevels logLevel, string format, params object[] formatArgs);
        void LogException(LogLevels logLevel, Exception exception, string format, params object[] formatArgs);

        void Log(LogLevels logLevel, IDictionary<string, object> parameters, string format = null, params object[] formatArgs);
        void LogException(LogLevels logLevel, Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs);

        void Trace(string format, params object[] formatArgs);
        void TraceException(Exception exception, string format, params object[] formatArgs);

        void Trace(IDictionary<string, object> parameters, string format = null, params object[] formatArgs);
        void TraceException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs);

        void Info(string format, params object[] formatArgs);
        void InfoException(Exception exception, string format, params object[] formatArgs);

        void Info(IDictionary<string, object> parameters, string format, params object[] formatArgs);
        void InfoException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs);

        void Warn(string format, params object[] formatArgs);
        void WarnException(Exception exception, string format, params object[] formatArgs);

        void Warn(IDictionary<string, object> parameters, string format, params object[] formatArgs);
        void WarnException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs);

        void Error(string format, params object[] formatArgs);
        void ErrorException(Exception exception, string format, params object[] formatArgs);

        void Error(IDictionary<string, object> parameters, string format, params object[] formatArgs);
        void ErrorException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs);
    }
}
