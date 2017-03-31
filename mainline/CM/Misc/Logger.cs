using System;
using System.Globalization;
using System.Text;
using System.Web;
using CM.db;
using CM.Sites;
using CM.State;
using EveryMatrix.Logging;
using System.Configuration;
using System.Runtime.Serialization;
using CM.Misc;

[DataContract]
public class LogEntry : LogEntryBase
{
    [DataMember(Name = "LogType", EmitDefaultValue = false, Order = 0)]
    public string LogType { get; set; }

    [DataMember(Name = "Message", EmitDefaultValue = false, Order = 1)]
    public string Message { get; set; }

    [DataMember(Name = "Source", EmitDefaultValue = false, Order = 2)]
    public string Source { get; set; }

    [DataMember(Name = "OperatorName", EmitDefaultValue = false, Order = 3)]
    public string OperatorName { get; set; }

    [DataMember(Name = "Url", EmitDefaultValue = false, Order = 4)]
    public string Url { get; set; }

    [DataMember(Name = "ServerName", EmitDefaultValue = false, Order = 5)]
    public string ServerName { get; set; }

    [DataMember(Name = "IP", EmitDefaultValue = false, Order = 6)]
    public string IP { get; set; }

    [DataMember(Name = "UserID", EmitDefaultValue = false, Order = 7)]
    public int UserID { get; set; }

    [DataMember(Name = "UserName", EmitDefaultValue = false, Order = 8)]
    public string UserName { get; set; }

    [DataMember(Name = "SessionID", EmitDefaultValue = false, Order = 9)]
    public string SessionID { get; set; }

    [DataMember(Name = "StackTrace", EmitDefaultValue = false, Order = 10)]
    public string StackTrace { get; set; }

    [DataMember(Name = "BaseUrl", EmitDefaultValue = false, Order = 11)]
    public string BaseUrl { get; set; }

    [DataMember(Name = "PathAndQuery", EmitDefaultValue = false, Order = 12)]
    public string PathAndQuery { get; set; }

    [DataMember(Name = "HttpMethod", EmitDefaultValue = false, Order = 13)]
    public string HttpMethod { get; set; }

    [DataMember(Name = "UrlReferrer", EmitDefaultValue = false, Order = 14)]
    public string UrlReferrer { get; set; }

    [DataMember(Name = "UserAgent", EmitDefaultValue = false, Order = 15)]
    public string UserAgent { get; set; }

    [DataMember(Name = "ElapsedSeconds", EmitDefaultValue = false, Order = 16)]
    public decimal ElapsedSeconds { get; set; }
}

[DataContract]
public class EmailLogEntry : LogEntryBase
{
    public LogType LogType { get; set; }
    public string IP { get; set; }
    public int UserID { get; set; }
    public string SessionID { get; set; }
    public string ServerName { get; set; }
    public string OperatorName { get; set; }
    public string EmailType { get; set; }
    public string From { get; set; }
    public string ReplyTo { get; set; }
    public string To { get; set; }
    public string Subject { get; set; }
    public string Body { get; set; }
}

public static class Logger
{
    private static string[] IGNORED_EXCEPTIONS = new string[] {
        "SYS_1111",
        "SYS_1008",
        "SYS_1125",
        "EverleafNetworkProxy error: 2 (No data found)",
        "Attempted to perform an unauthorized operation",
        "A potentially dangerous Request.Path value was detected from the client",
        "Thread was being aborted",
        };

    //readonly static ILog log = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

    static readonly LogstashClient _singleton = new LogstashClient(new LogstashClientOption()
    {
        Urls = ConfigurationManager.AppSettings["Logstash.Urls"].Split(new char[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries),
    });

    public static LogstashClient Default { get { return _singleton; } }

    private static void Append(LogEntry log, LogType logType)
    {
        try
        {
            if (HttpContext.Current != null)
            {
                HttpRequest request = HttpContext.Current.Request;
                if (request != null)
                {
                    log.BaseUrl = string.Format("{0}://{1}"
                        , request.IsHttps() ? "https" : "http"
                        , request.Url.Host
                        );
                    log.HttpMethod = request.HttpMethod;
                    log.PathAndQuery = request.RawUrl;
                    if (request.UrlReferrer != null)
                        log.UrlReferrer = request.UrlReferrer.ToString();
                    log.IP = HttpContext.Current.Request.GetRealUserAddress();
                    log.ServerName = HttpContext.Current.Request.ServerVariables["LOCAL_ADDR"];
                    log.UserAgent = HttpContext.Current.Request.UserAgent;
                }

                CustomProfile profile = CustomProfile.Current;
                if (profile != null)
                {
                    log.SessionID = profile.SessionID;
                    if (profile.IsAuthenticated)
                    {
                        log.UserID = profile.UserID;
                        log.UserName = profile.UserName;
                    }
                }
                log.OperatorName = SiteManager.Current.DistinctName;
            }
        }
        catch { }

        log.LogType = logType.ToString();
        log.Time = DateTime.Now;

        if (logType == LogType.Access)
        {
            Logger.Default.Append(log, string.Format("cms-{0}-access", ConfigurationManager.AppSettings["Environment"].ToLowerInvariant()));
        }
        else if (logType == LogType.Restart)
        {
            Logger.Default.Append(log, string.Format("cms-{0}-restart", ConfigurationManager.AppSettings["Environment"].ToLowerInvariant()));
        }
        else
        {
            Logger.Default.Append(log, string.Format("cms-{0}-log", ConfigurationManager.AppSettings["Environment"].ToLowerInvariant()));
        }
        
    }

    public static void AppendFormat(LogType logType, string source, string format, params object[] args)
    {
        LogEntry log = new LogEntry()
        {
            Source = source,
        };

        if (args != null && args.Length > 0)
            log.Message = string.Format(CultureInfo.InvariantCulture, format, args);
        else
            log.Message = format;

        Append(log, logType);
    }

    public static void Information(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Information, source, format, args);
    }

    public static void Warning(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Warning, source, format, args);
    }

    public static void CodeProfiler(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.CodeProfiler, source, format, args);
    }

    public static void Error(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Error, source, format, args);
    }

    public static void RestartException(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Restart, source, format, args);
    }

    public static void Exception(Exception exception)
    {

        StringBuilder sb = new StringBuilder();
        string source = null;
        string message = null;
        while (exception != null)
        {
            source = exception.Source;
            message = exception.Message;

            foreach (string ignoredException in IGNORED_EXCEPTIONS)
            {
                if (message.IndexOf(ignoredException, StringComparison.InvariantCulture) >= 0)
                    return;
            }

            sb.Append("\r\n-------------------------------------\r\n");
            sb.AppendFormat("Exception:{0}\r\n", exception.Message);
            sb.AppendFormat("Source:{0}\r\n", exception.Source);
            try
            {
                sb.AppendFormat("DateTime:{0}\r\n", DateTime.Now);
                if (HttpContext.Current != null)
                {
                    if (HttpContext.Current.Request != null)
                    {
                        if (HttpContext.Current.Request.HttpMethod.Equals("HEAD"))
                            return; // ignore the HEAD request

                        sb.AppendFormat("HTTP Method:{0}\r\n", HttpContext.Current.Request.HttpMethod);
                        sb.AppendFormat("URL:{0}\r\n", HttpContext.Current.Request.Url);
                        sb.AppendFormat("IP:{0}\r\n", HttpContext.Current.Request.GetRealUserAddress());
                        if (HttpContext.Current.Request.UrlReferrer != null)
                            sb.AppendFormat("Referrer Url:{0}\r\n", HttpContext.Current.Request.UrlReferrer);
                        if (HttpContext.Current.Request.UserAgent != null)
                            sb.AppendFormat("User Agent:{0}\r\n", HttpContext.Current.Request.UserAgent);
                    }

                    sb.AppendFormat("UserID:{0}\r\n", CustomProfile.Current.UserID);
                    sb.AppendFormat("UserName:{0}\r\n", CustomProfile.Current.UserName);
                    sb.AppendFormat("SessionID:{0}\r\n", CustomProfile.Current.SessionID);
                }
            }
            catch
            {
            }
            sb.AppendFormat("Stack Trace:\r\n{0}\r\n", exception.StackTrace);

            exception = exception.InnerException;
        }

        LogEntry log = new LogEntry()
        {
            Message = message,
            StackTrace = sb.ToString(),
            Source = source,
        };

        ExceptionHandler.AppendToEmail(sb.ToString());
        Append(log, LogType.Exception);
    }

    public static void Email(string emailType, string from, string replyTo, string to, string subject, string body)
    {
        EmailLogEntry log = new EmailLogEntry()
        {
            LogType = LogType.Email,
            Time = DateTime.Now,
            EmailType = emailType,
            From = from,
            ReplyTo = replyTo,
            To = to,
            Subject = subject,
            Body = body,
            ServerName = HttpContext.Current.Request.ServerVariables["LOCAL_ADDR"],
        };

        Logger.Default.Append(log, string.Format("cms-{0}-email", ConfigurationManager.AppSettings["Environment"].ToLowerInvariant()));
    }

    public static void EndAccess(decimal elapsedSeconds)
    {
        try
        {
            LogEntry log = new LogEntry()
            {
                ElapsedSeconds = elapsedSeconds,
            };

            Append(log, LogType.Access);
        }
        catch
        {
        }
    }
}

#region old Logger class
/*
public static class Logger
{

    private static void DoWork(object state)
    {
        cmLog log = state as cmLog;
        try
        {
            using (DbManager db = new DbManager("Log"))
            {
                try
                {
                    switch (log.LogType)
                    {
                        case LogType.Access:
                            {
                                LogAccessor.AppendAccessLog(db, log);
                                break;
                            }

                        case LogType.Email:
                            {
                                LogAccessor.AppendEmailLog(db, log);
                                break;
                            }

                        default:
                            {
                                LogAccessor.AppendLog(db, log);
                                break;
                            }

                    }
                }
                catch (Exception ex)
                {
                }
            }
        }
        catch (Exception ex)
        {
        }
    }


    /// <summary>
    /// append a log record to s_RecordsToInsert
    /// </summary>
    /// <param name="log"></param>
    private static void Append(cmLog log)
    {
        try
        {
            if (HttpContext.Current != null)
            {
                if (log.LogType != LogType.Access)
                    log.ID = CurrentLogID;

                HttpRequest request = HttpContext.Current.Request;
                if (request != null)
                {
                    log.BaseUrl = string.Format("{0}://{1}"
                        , request.IsHttps() ? "https" : "http"
                        , request.Url.Host
                        );
                    log.HttpMethod = request.HttpMethod;
                    log.PathAndQuery = request.RawUrl;
                    if (request.UrlReferrer != null)
                        log.UrlReferrer = request.UrlReferrer.ToString();
                    log.IP = HttpContext.Current.Request.GetRealUserAddress();
                    log.ServerName = HttpContext.Current.Request.ServerVariables["LOCAL_ADDR"];
                    log.Data = HttpContext.Current.Request.UserAgent;
                }

                CustomProfile profile = CustomProfile.Current;
                if (profile != null)
                {
                    log.SessionID = profile.SessionID;
                    if (profile.IsAuthenticated)
                    {
                        log.UserID = profile.UserID;
                        log.UserName = profile.UserName;
                    }
                }
                log.OperatorName = SiteManager.Current.DistinctName;
            }
        }
        catch
        {
        }

        log.Ins = DateTime.Now;

        BackgroundThreadPool.QueueUserWorkItem(string.Format("Insert Log (Log Type: {0})", log.LogType.ToString()), DoWork, log);
    }

    public static void AppendFormat(LogType logType, string source, string format, params object[] args)
    {
        cmLog log = new cmLog()
        {
            LogType = logType,
            Source = source,
        };
        if (args != null && args.Length > 0)
            log.Message = string.Format(CultureInfo.InvariantCulture, format, args);
        else
            log.Message = format;
        Logger.Append(log);
    }

    public static void Information(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Information, source, format, args);
    }
    public static void Warning(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Warning, source, format, args);
    }
    public static void CodeProfiler(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.CodeProfiler, source, format, args);
    }
    public static void Error(string source, string format, params object[] args)
    {
        Logger.AppendFormat(LogType.Error, source, format, args);
    }


    private static long CurrentLogID
    {
        get
        {
            try
            {
                if (HttpContext.Current != null)
                {
                    return (long)HttpContext.Current.Items["__logger_id"];
                }
            }
            catch
            {
            }
            return 0L;
        }
        set
        {
            try
            {
                if (HttpContext.Current != null)
                {
                    HttpContext.Current.Items["__logger_id"] = value;
                }
            }
            catch
            {
            }
        }
    }

    public static void BeginAccess()
    {
        CurrentLogID = UniqueInt64.Generate();
    }

    public static void EndAccess(decimal elapsedSeconds)
    {
        try
        {
            cmLog log = new cmLog()
            {
                ID = CurrentLogID,
                LogType = LogType.Access,
                ElapsedSeconds = elapsedSeconds,
            };
            Logger.Append(log);
        }
        catch
        {
        }
    }

    private static string[] IGNORED_EXCEPTIONS = new string[] {
        "SYS_1111",
        "SYS_1008",
        "SYS_1125",
        "EverleafNetworkProxy error: 2 (No data found)",
        "Attempted to perform an unauthorized operation",
        "A potentially dangerous Request.Path value was detected from the client",
        "Thread was being aborted",
    };
    public static void Exception(Exception exception)
    {

        StringBuilder sb = new StringBuilder();
        string source = null;
        string message = null;
        while (exception != null)
        {
            source = exception.Source;
            message = exception.Message;

            foreach (string ignoredException in IGNORED_EXCEPTIONS)
            {
                if (message.IndexOf(ignoredException, StringComparison.InvariantCulture) >= 0)
                    return;
            }

            sb.Append("\r\n-------------------------------------\r\n");
            sb.AppendFormat("Exception:{0}\r\n", exception.Message);
            sb.AppendFormat("Source:{0}\r\n", exception.Source);
            try
            {
                sb.AppendFormat("DateTime:{0}\r\n", DateTime.Now);
                if (HttpContext.Current != null)
                {
                    if (HttpContext.Current.Request != null)
                    {
                        if (HttpContext.Current.Request.HttpMethod.Equals("HEAD"))
                            return; // ignore the HEAD request

                        sb.AppendFormat("HTTP Method:{0}\r\n", HttpContext.Current.Request.HttpMethod);
                        sb.AppendFormat("URL:{0}\r\n", HttpContext.Current.Request.Url);
                        sb.AppendFormat("IP:{0}\r\n", HttpContext.Current.Request.GetRealUserAddress());
                        if (HttpContext.Current.Request.UrlReferrer != null)
                            sb.AppendFormat("Referrer Url:{0}\r\n", HttpContext.Current.Request.UrlReferrer);
                        if (HttpContext.Current.Request.UserAgent != null)
                            sb.AppendFormat("User Agent:{0}\r\n", HttpContext.Current.Request.UserAgent);
                    }

                    sb.AppendFormat("UserID:{0}\r\n", CustomProfile.Current.UserID);
                    sb.AppendFormat("UserName:{0}\r\n", CustomProfile.Current.UserName);
                    sb.AppendFormat("SessionID:{0}\r\n", CustomProfile.Current.SessionID);
                }
            }
            catch
            {
            }
            sb.AppendFormat("Stack Trace:\r\n{0}\r\n", exception.StackTrace);

            exception = exception.InnerException;
        }

        cmLog log = new cmLog()
        {
            LogType = LogType.Exception,
            Message = message,
            StackTrace = sb.ToString(),
            Source = source,
        };
        ExceptionHandler.AppendToEmail(sb.ToString());
        Logger.Append(log);
    }

    public static void Email(string emailType, string from, string replyTo, string to, string subject, string body)
    {
        cmLog log = new cmLog()
        {
            EmailType = emailType,
            From = from,
            ReplyTo = replyTo,
            To = to,
            Subject = subject,
            Body = body,
            LogType = LogType.Email,
        };

        Logger.Append(log);
    }

}
 */
#endregion