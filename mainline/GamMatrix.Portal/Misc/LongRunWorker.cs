using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Globalization;
using System.Data;
using System.IO;
using System.Web.Hosting;

using BLToolkit.DataAccess;
using BLToolkit.Data;
using CM.db;

using CM.db.Accessor;
using GamMatrixAPI;
using GmCore;


internal enum TaskType
{
    UpdateLastAccessTime,
    LogoffSession,
    LoginSucceed,
    UpdateRoleString,
}

public sealed class BackgroundTask
{
    internal TaskType TaskType { get; set; }
    internal DateTime DateTime { get; set; }
    internal long UserID { get; set; }
    internal string UserIP { get; set; }
    internal string SessionID { get; set; }
    internal string Content { get; set; }
    internal int DomainID { get; set; }
    internal int SessionTimeoutSeconds { get; set; }
    internal SessionExitReason SessionExitReason { get; set; }

    internal string SessionSID { get; set; }
}

public static class LongRunWorker
{
    private static void DoWork(object state)
    {
        BackgroundTask task = state as BackgroundTask;

        try
        {
            using (DbManager dbMgr = new DbManager())
            {
                switch (task.TaskType)
                {
                    case TaskType.UpdateLastAccessTime:
                        {
                            SessionAccessor sa = DataAccessor.CreateInstance<SessionAccessor>(dbMgr);
                            sa.UpdateLastAccess(task.SessionID, task.DateTime);
                            break;
                        }

                    case TaskType.UpdateRoleString:
                        {
                            SessionAccessor sa = DataAccessor.CreateInstance<SessionAccessor>(dbMgr);
                            sa.UpdateRoleString(task.SessionID, task.Content);
                            break;
                        }

                    case TaskType.LogoffSession:
                        {
                            SessionAccessor sa = DataAccessor.CreateInstance<SessionAccessor>(dbMgr);
                            sa.Logoff(task.SessionID, task.DateTime, task.SessionExitReason);
                            if (task.SessionExitReason != SessionExitReason.Reentry)
                            {
                                LogoutNotificationRequest request = new LogoutNotificationRequest()
                                {
                                    UserID = task.UserID,
                                    SESSION_USERID = task.UserID,
                                    SESSION_ID = task.SessionSID,
                                    SESSION_USERIP = task.UserIP,
                                    SESSION_USERSESSIONID = task.SessionID,
                                };
                                GamMatrixClient client = GamMatrixClient.Get();
                                client.SingleRequest(request);
                            }
                            break;
                        }

                    case TaskType.LoginSucceed:
                        {
                            UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbMgr);
                            List<string> list = ua.LoginSucceed(task.SessionID, task.UserID, task.DateTime);
                            LogoutNotificationRequest request;
                            GamMatrixClient client = GamMatrixClient.Get();
                            foreach (string guid in list)
                            {
                                CustomProfileEx.ClearSessionCache(guid);

                                request = new LogoutNotificationRequest()
                                {
                                    UserID = task.UserID,
                                    SESSION_USERID = task.UserID,
                                    SESSION_ID = task.SessionSID,
                                    SESSION_USERIP = task.UserIP,
                                    SESSION_USERSESSIONID = task.SessionID,
                                };
                                client.SingleRequest(request);
                            }
                            break;
                        }
                }
            }
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
        }



    }

    public static void UpdateLastAccessTime(string guid)
    {
        BackgroundTask task = new BackgroundTask()
        {
            TaskType = TaskType.UpdateLastAccessTime,
            SessionID = guid,
            DateTime = DateTime.Now,
        };
        BackgroundThreadPool.QueueUserWorkItem( "UpdateLastAccessTime", DoWork, task);
    }

    public static void LogoffSession(long userID, string guid, SessionExitReason exitReason)
    {
        BackgroundTask task = new BackgroundTask()
        {
            TaskType = TaskType.LogoffSession,
            SessionID = guid,
            DateTime = DateTime.Now,
            SessionExitReason = exitReason,
            UserID = userID,
            SessionSID = GamMatrixClient.GetSessionIDForCurrentOperator(),
        };
        BackgroundThreadPool.QueueUserWorkItem( "LogoffSession", DoWork, task, true);
    }

    public static void LoginSucceed(long userID, string guid, string ip)
    {
        BackgroundTask task = new BackgroundTask()
        {
            TaskType = TaskType.LoginSucceed,
            UserID = userID,
            UserIP = ip,
            SessionID = guid,
            DateTime = DateTime.Now,
            SessionSID = GamMatrixClient.GetSessionIDForCurrentOperator(),
        };
        BackgroundThreadPool.QueueUserWorkItem( "LoginSucceed", DoWork, task, true);
    }

    public static void UpdateRoleString(string guid, string roleString)
    {
        BackgroundTask task = new BackgroundTask()
        {
            TaskType = TaskType.UpdateRoleString,
            SessionID = guid,
            Content = roleString,
        };
        BackgroundThreadPool.QueueUserWorkItem( "UpdateRoleString", DoWork, task, true);
    }

}
