using System;
using System.Diagnostics;
using System.Text;
using System.Web;
using System.Configuration;
using System.Runtime.Serialization;

using EveryMatrix.Logging;

namespace CE.Utils
{
    [LogType(Name = "ce1-log")]
    [DataContract]
    public class LogEntry : LogEntryBase
    {
        [DataMember(Name = "logType")]
        public string LogType { get; set; }

        [DataMember(Name = "env")]
        public string Env { get; set; }

        [DataMember(Name = "message")]
        public string Message { get; set; }

        public LogEntry()
        {
            base.Version = 2;
        }
    }

    public static class Logger
    {
        static readonly LogstashClient _singleton = new LogstashClient(new LogstashClientOption()
        {
            //Urls = new string[] { "tcp://10.0.11.43:6001", "tcp://10.0.11.45:6001" },
            Urls = ConfigurationManager.AppSettings["Logstash.Urls"].Split(new char[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries),

            //ClientCertificate = new X509Certificate(@"G:\EM2\SDK\dotnet-sdk\Sample_Log\client.p12"),

            // Optional JsonSerializer to replace the built-in DataContractJsonSerializer
            //JsonSerializer = new NewtonsoftJsonSerializer(), // or NewtonsoftJsonSerializer(), ServiceStackJsonSerializer()

        });

        static LogstashClient Default { get { return _singleton; } }

        // eventcreate /ID 1 /L APPLICATION /T INFORMATION /SO CasinoEngine  /D "CasinoEngine"
        public static void Information(string msg)
        {
            EventLog.WriteEntry("CasinoEngine", msg, EventLogEntryType.Information);
            LogEntry entry = new LogEntry()
            {
                LogType = "Information",
                Env = ConfigurationManager.AppSettings["Environment"],
                Message = msg,
            };
            Logger.Default.Append(entry);
        }

        public static void FailureAudit(string msg)
        {
            EventLog.WriteEntry("CasinoEngine", msg, EventLogEntryType.FailureAudit);
            LogEntry entry = new LogEntry()
            {
                LogType = "FailureAudit",
                Env = ConfigurationManager.AppSettings["Environment"],
                Message = msg,
            };
            Logger.Default.Append(entry);
        }

        public static void Exception(Exception ex, string extra = null)
        {
            StringBuilder sb = new StringBuilder();
            while (ex != null)
            {
                sb.AppendFormat("{0}\n", ex.Message);

                try
                {
                    if (HttpContext.Current != null)
                    {
                        sb.AppendFormat("URL: {0}\n", HttpContext.Current.Request.Url.ToString());
                        foreach (string key in HttpContext.Current.Request.Form.Keys)
                        {
                            sb.AppendFormat("{0}= {1}\n", key, HttpContext.Current.Request.Form[key]);
                        }
                    }
                }
                catch
                {
                }

                if (!string.IsNullOrEmpty(extra))
                    sb.AppendFormat("Extra: {0}\n", extra);

                sb.AppendFormat("{0}\n=====================================================================\n", ex.StackTrace);
                ex = ex.InnerException;
            }
            ExceptionHandler.AppendToEmail(sb.ToString());
            EventLog.WriteEntry("CasinoEngine", sb.ToString(), EventLogEntryType.Error);

            LogEntry entry = new LogEntry()
            {
                LogType = "Exception",
                Env = ConfigurationManager.AppSettings["Environment"],
                Message = sb.ToString(),
            };
            Logger.Default.Append(entry);
        }
    }
}
