using System;

namespace CM.db
{
    public enum LogType
    {
        Information = 0,
        Warning = 1,
        Error = 2,
        Exception = 3,
        CodeProfiler = 4,
        Access = 5,
        Email = 6,
        Restart = 10,
    }


    public sealed class cmLog
    {
        public long   ID { get; set; }
        public string Message { get; set; }
        public LogType LogType { get; set; }
        public string Type { get; set; }
        public string Source { get; set; }
        public string UserName { get; set; }
        public string SessionID { get; set; }
        public int UserID { get; set; }
        public string Data { get; set; }
        public string StackTrace { get; set; }
        public string BaseUrl { get; set; }
        public string PathAndQuery { get; set; }
        public string IP { get; set; }
        public string ServerName { get; set; }
        public string UrlReferrer { get; set; }
        public string Url { get; set; }
        public string OperatorName { get; set; }
        public string HttpMethod { get; set; }
        public decimal ElapsedSeconds { get; set; }

        //used for email log
        public string EmailType { get; set; }
        public string From { get; set; }
        public string ReplyTo { get; set; }
        public string To { get; set; }
        public string Subject { get; set; }
        public string Body { get; set; }

        public DateTime Ins { get; set; }
    }
}
