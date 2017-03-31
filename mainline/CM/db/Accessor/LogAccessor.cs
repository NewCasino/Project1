using System;
using System.Collections.Generic;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using MySql.Data.MySqlClient;

namespace CM.db.Accessor
{
    public abstract class LogAccessor : DataAccessor
    {
        private const string INSERT_ACCESS_LOG = @"CALL insert_access_log( @ID, @ServerName, @OperatorName, @ElapsedSeconds, @IP, @UserID, @SessionID, @HttpMethod, @BaseUrl, @PathAndQuery, @UrlReferrer, @UserAgent );";
        public static void AppendAccessLog(DbManager db, cmLog logItem)
        {           
            MySqlParameter[] parameters = new MySqlParameter[]
            {
                new MySqlParameter( "@ID", logItem.ID),
                new MySqlParameter( "@IP", logItem.IP),
                new MySqlParameter( "@ServerName", logItem.ServerName),
                new MySqlParameter( "@OperatorName", logItem.OperatorName),
                new MySqlParameter( "@ElapsedSeconds", logItem.ElapsedSeconds),
                new MySqlParameter( "@UserID", logItem.UserID),
                new MySqlParameter( "@SessionID", logItem.SessionID),
                new MySqlParameter( "@HttpMethod", logItem.HttpMethod),
                new MySqlParameter( "@BaseUrl", logItem.BaseUrl),
                new MySqlParameter( "@PathAndQuery", logItem.PathAndQuery),
                new MySqlParameter( "@UrlReferrer", logItem.UrlReferrer),
                new MySqlParameter( "@UserAgent", logItem.Data),
            };

            db.SetCommand(INSERT_ACCESS_LOG, parameters);
            db.ExecuteNonQuery();
        }


        private const string INSERT_LOG = @"
INSERT DELAYED INTO `log`
(
`AccessLogID`,
`LogType`,
`Source`,
`Message`,
`ServerName`,
`Operatorname`,
`IP`,
`UserID`,
`SessionID`,
`Url`,
`StackTrace`)
VALUES
(
@AccessLogID,
@LogType,
@Source,
@Message,
@ServerName,
@Operatorname,
@IP,
@UserID,
@SessionID,
@Url,
@StackTrace
);";

        public static void AppendLog(DbManager db, cmLog logItem)
        {           
            MySqlParameter[] parameters = new MySqlParameter[]
            {
                new MySqlParameter( "@AccessLogID", logItem.ID),
                new MySqlParameter( "@LogType", logItem.LogType),
                new MySqlParameter( "@Source", logItem.Source),
                new MySqlParameter( "@Message", logItem.Message),
                new MySqlParameter( "@ServerName", logItem.ServerName),
                new MySqlParameter( "@Operatorname", logItem.OperatorName),
                new MySqlParameter( "@IP", logItem.IP),
                new MySqlParameter( "@UserID", logItem.UserID),
                new MySqlParameter( "@SessionID", logItem.SessionID),
                new MySqlParameter( "@Url", logItem.PathAndQuery),
                new MySqlParameter( "@StackTrace", logItem.StackTrace),
            };

            db.SetCommand(INSERT_LOG, parameters);
            db.ExecuteNonQuery();
        }

        private const string INSERT_EMAIL_LOG = @"
INSERT DELAYED INTO `email_log`
(
`EmailType`,
`From`,
`ReplyTo`,
`To`,
`Subject`,
`Body`,
`UserID`,
`SessionID`,
`IP`,
`ServerName`,
`Operatorname`)
VALUES
(
@EmailType,
@From,
@ReplyTo,
@To,
@Subject,
@Body,
@UserID,
@SessionID,
@IP,
@ServerName,
@Operatorname
);";

        public static void AppendEmailLog(DbManager db, cmLog logItem)
        {
            MySqlParameter[] parameters = new MySqlParameter[]
            {
                new MySqlParameter( "@EmailType", logItem.EmailType),
                new MySqlParameter( "@From", logItem.From),
                new MySqlParameter( "@ReplyTo", logItem.ReplyTo),
                new MySqlParameter( "@To", logItem.To),
                new MySqlParameter( "@Subject", logItem.Subject),
                new MySqlParameter( "@Body", logItem.Body),
                new MySqlParameter( "@UserID", logItem.UserID),
                new MySqlParameter( "@SessionID", logItem.SessionID),
                new MySqlParameter( "@IP", logItem.IP),
                new MySqlParameter( "@ServerName", logItem.ServerName),
                new MySqlParameter( "@Operatorname", logItem.OperatorName),
            };

            db.SetCommand(INSERT_EMAIL_LOG, parameters);
            db.ExecuteNonQuery();
        }


        [SqlQuery("SELECT UNIX_TIMESTAMP(UTC_TIMESTAMP());")]
        public abstract long GetCurrentTimestamp();

        [SqlQuery(@"CALL query_statistics(@startStamp, @endStamp, @operatorName, @serverName);")]
        [Index("MinuteStamp")]
        public abstract Dictionary<long, MinuteStatistics> QueryStatistics(long startStamp, long endStamp, string operatorName, string serverName);

        [SqlQuery("SELECT DISTINCT ServerName FROM minute_statistics WHERE ServerName <> '';")]
        public abstract List<string> GetServers();


        [SqlQuery(@"SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT `ID`, `Message`, `LogType`, `Source`, `SessionID`, `UserID`, `ServerName`, `IP`, `Url`, `OperatorName`, `Ins`
FROM log 
WHERE (`LogType` = @logType OR @logType < 0)
AND (`UserID` = @userID OR @userID <= 0)
AND (`SessionID` = @sessionID OR @sessionID = '')
AND (`Source` = @source OR @source = '')
AND (`IP` = @ip OR @ip = '')
AND `Ins` BETWEEN @startTime AND @endTime
ORDER BY Ins DESC
LIMIT 0, @pageSize;")]
        public abstract List<cmLog> QueryLog(int logType, long userID, string sessionID, string source, string ip, DateTime startTime, DateTime endTime, int pageSize);

        [SqlQuery(@"SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT `StackTrace` FROM log WHERE `ID` = @id LIMIT 0, 1;")]
        public abstract string GetStackTrace(long id);


        [SqlQuery(@"SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT * FROM access_log 
WHERE MinuteStamp = @minuteStamp
AND (ServerName = @serverName OR @serverName = '' )
AND (OperatorName = @operatorName OR @operatorName = '')
ORDER BY ElapsedSeconds DESC;")]
        public abstract List<cmLog> QueryAccessLog(long minuteStamp, string serverName, string operatorName);


        [SqlQuery(@"SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT * FROM log 
WHERE AccessLogID = @accessLogID;")]
        public abstract List<cmLog> QueryLog(long accessLogID);
    }
}
