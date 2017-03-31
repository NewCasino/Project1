using GmGaming.Infrastructure;
using GmGaming.Infrastructure.Logging;
using GmLogging.Client;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;

namespace GmGaming.WebApi
{
    public class DefaultLogger : ILogger
    {
        static Type thisType = typeof(DefaultLogger);

        string loggingApiUrl;
        string loggingAppName;

        bool isLoggingOn;
        bool isLogCallStack;
        LogLevels minLogLevel = LogLevels.Error;
        string appServerName = string.Empty;

        LoggingClientProxy proxy;
        public LoggingClientProxy Proxy
        {
            get
            {
                if (proxy == null)
                {
                    //string loggingApiUrl = "http://10.0.11.26/api/loggingapi"; //appSettingsManager.GetSetting(CommonConstants.Settings.LoggingApiUrl);
                    //string loggingAppName = "CasinoEngine"; //appSettingsManager.GetSetting(CommonConstants.Settings.LoggingAppName);
                    proxy = new LoggingClientProxy(loggingApiUrl, loggingAppName);
                }

                return proxy;
            }
        }


        public DefaultLogger(string loggingApiUrl, string loggingAppName, bool isLoggingOn, bool isLogCallStack, LogLevels minLogLevel, string serverName /*IRequestSessionState requestSessionState, IAppSettingsManager appSettingsManager*/)
        {
            this.loggingApiUrl = loggingApiUrl;
            this.loggingAppName = loggingAppName;
            this.isLoggingOn = isLoggingOn;
            this.isLogCallStack = isLogCallStack;
            this.minLogLevel = minLogLevel;
            this.appServerName = serverName;

            if (string.IsNullOrEmpty(loggingApiUrl))
                throw new NullReferenceException("loggingApiUrl");
            if (string.IsNullOrEmpty(loggingAppName))
                throw new NullReferenceException("loggingAppName");
            if (string.IsNullOrEmpty(appServerName))
                throw new NullReferenceException("appServerName");
        }

        public void Log(LogLevels logLevel, string format, params object[] formatArgs)
        {
            Log(logLevel, null, format, formatArgs);
        }

        public void LogException(LogLevels logLevel, Exception exception, string format, params object[] formatArgs)
        {
            LogException(logLevel, exception, null, format, formatArgs);
        }

        public void Log(LogLevels logLevel, IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            if (!isLoggingOn)
                return;

            if (logLevel < minLogLevel)
                return;

            if (parameters == null)
                parameters = new Dictionary<string, object>();

            parameters[LoggingParams.Reserved.LogLevel] = (int)logLevel;
            parameters[LoggingParams.Reserved.Server] = appServerName;
            parameters[LoggingParams.Reserved.LogClientTime] = DateTime.Now;

            if (isLogCallStack)
            {
                StringBuilder sbstackTrace = new StringBuilder();
                StackTrace stackTrace = new StackTrace();

                for (Int32 i = 0; i < stackTrace.FrameCount; i++)
                {
                    StackFrame frame = stackTrace.GetFrame(i);
                    System.Reflection.MethodBase method = frame.GetMethod();
                    if (method.DeclaringType == thisType)
                        continue;
                    string frameMsg = string.Format("{0}.{1}", method.DeclaringType, method.Name);
                    sbstackTrace.AppendLine(frameMsg);
                    // currently allow only one line
                    break;
                }

                parameters[LoggingParams.Reserved.CallStack] = sbstackTrace.ToString();
            }

            //string requestID = requestSessionState.GetRequestID();
            //if (!string.IsNullOrEmpty(requestID))
            //{
            //    parameters[LoggingParams.Reserved.RequestID] = requestID;
            //}

            if (!string.IsNullOrWhiteSpace(format))
            {
                string message = null;
                if (formatArgs != null && formatArgs.Length > 0)
                {
                    // don't throw error if string.Format fails
                    try
                    {
                        message = string.Format(format, formatArgs);
                    }
                    catch
                    {
                        message = format + "args: " + string.Join(", ", formatArgs);
                    }
                }
                else
                {
                    message = format;
                }

                parameters[LoggingParams.Reserved.Message] = message;
            }

            Proxy.AddLogAsync(parameters);
        }

        public void LogException(LogLevels logLevel, Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            if (parameters == null)
                parameters = new Dictionary<string, object>();
            string exceptionStr = ConvertExceptionToString(exception);
            parameters[LoggingParams.Reserved.Exception] = exceptionStr;

            Log(logLevel, parameters, format, formatArgs);
        }

        private string ConvertExceptionToString(Exception exception)
        {
            return exception != null ? exception.ToString() : string.Empty;
        }

        public void Trace(string format, params object[] formatArgs)
        {
            Log(LogLevels.Trace, format, formatArgs);
        }

        public void TraceException(Exception exception, string format, params object[] formatArgs)
        {
            LogException(LogLevels.Trace, exception, format, formatArgs);
        }

        public void Trace(IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            Log(LogLevels.Trace, parameters, format, formatArgs);
        }

        public void TraceException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            LogException(LogLevels.Trace, exception, parameters, format, formatArgs);
        }

        public void Info(string format, params object[] formatArgs)
        {
            Log(LogLevels.Info, format, formatArgs);
        }

        public void InfoException(Exception exception, string format, params object[] formatArgs)
        {
            LogException(LogLevels.Info, exception, format, formatArgs);
        }

        public void Info(IDictionary<string, object> parameters, string format, params object[] formatArgs)
        {
            Log(LogLevels.Info, parameters, format, formatArgs);
        }

        public void InfoException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            LogException(LogLevels.Info, exception, parameters, format, formatArgs);
        }

        public void Warn(string format, params object[] formatArgs)
        {
            Log(LogLevels.Warn, format, formatArgs);
        }

        public void WarnException(Exception exception, string format, params object[] formatArgs)
        {
            LogException(LogLevels.Warn, exception, format, formatArgs);
        }

        public void Warn(IDictionary<string, object> parameters, string format, params object[] formatArgs)
        {
            Log(LogLevels.Warn, parameters, format, formatArgs);
        }

        public void WarnException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            LogException(LogLevels.Warn, exception, parameters, format, formatArgs);
        }

        public void Error(string format, params object[] formatArgs)
        {
            Log(LogLevels.Error, format, formatArgs);
        }

        public void ErrorException(Exception exception, string format, params object[] formatArgs)
        {
            LogException(LogLevels.Error, exception, format, formatArgs);
        }

        public void Error(IDictionary<string, object> parameters, string format, params object[] formatArgs)
        {
            Log(LogLevels.Error, parameters, format, formatArgs);
        }

        public void ErrorException(Exception exception, IDictionary<string, object> parameters, string format = null, params object[] formatArgs)
        {
            LogException(LogLevels.Error, exception, parameters, format, formatArgs);
        }
    }
}