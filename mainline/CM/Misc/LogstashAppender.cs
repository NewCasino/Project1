using CM.db;
using CM.Sites;
using CM.State;
using EveryMatrix.Logging;
using log4net;
using log4net.Appender;
using log4net.Core;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace CM.Misc
{
    public class LogstashAppender: AppenderSkeleton
    {
        public string LogType { get; set; }
        protected override void Append(LoggingEvent loggingEvent)
        {
            RenderLoggingEvent(loggingEvent);
            Log4NetEntry entry = new Log4NetEntry()
            {
                Level = loggingEvent.Level.Name,
                Message = loggingEvent.RenderedMessage,
                Source = loggingEvent.LoggerName,
            };
            string details = loggingEvent.GetExceptionString();
            if (!string.IsNullOrWhiteSpace(details))
                entry.Details = details;
            Logger.Default.Append(entry, this.LogType);
        }
    }
}
