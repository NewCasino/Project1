using System;
using System.Configuration;
using System.Text;
using System.Threading;
using System.Web;
using CM.State;
using EveryMatrix.SessionAgent;

namespace GamMatrix.CMS.HttpHandlers
{
    /// <summary>
    /// Summary description for InfoHttpHandler
    /// </summary>
    public sealed class InfoHttpHandler : IHttpHandler
    {
        private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );

        public void ProcessRequest(HttpContext context)
        {

            CustomProfile.Current.Init(context);

            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("SessionID : {0}\n", CustomProfile.Current.SessionID);
            sb.AppendFormat("IsAuthenticated : {0}\n", CustomProfile.Current.IsAuthenticated);
            sb.AppendFormat("LastAccess : {0}\n", CustomProfile.Current.LastAccess);
            sb.AppendFormat("ServerTime : {0}\n", DateTime.Now);
            sb.AppendFormat("UserName : {0}\n", CustomProfile.Current.UserName);
            sb.AppendFormat("MachineName : {0}\n", context.Server.MachineName);
            sb.AppendFormat("IP : {0}\n", context.Request.GetRealUserAddress());
            sb.AppendFormat("IP Country ID : {0}\n", CustomProfile.Current.IpCountryID);

            int workerThreads, completionPortThreads;
            int availableWorkerThreads, availableCompletionPortThreads;
            ThreadPool.GetMaxThreads( out workerThreads, out completionPortThreads);
            ThreadPool.GetAvailableThreads(out availableWorkerThreads, out availableCompletionPortThreads);
            sb.AppendFormat("Work Threads: {0} / {1}\n", availableWorkerThreads, workerThreads);
            sb.AppendFormat("Completion Port Threads: {0} / {1}\n", availableCompletionPortThreads, completionPortThreads);

            sb.AppendFormat("Queued Work Items : {0}\n", BackgroundThreadPool.WorkItemCount);

            var threads = BackgroundThreadPool.GetThreads();
            foreach (Thread thread in threads)
            {
                sb.AppendFormat("Thread [{0}] : {1} | {2}\n", thread.Name, thread.Priority.ToString(), thread.ThreadState.ToString() );
            }

            sb.AppendFormat("{0}\n", BackgroundThreadPool.GetTasks());

            sb.Append("\n\n----------------------------------------\n");
            sb.Append("SESSION\n----------------------------------------\n");

            sb.AppendFormat("SessionID : {0}\n", CustomProfile.Current.SessionID);
            sb.AppendFormat("IsAuthenticated : {0}\n", CustomProfile.Current.IsAuthenticated);
            sb.AppendFormat("Domain ID : {0}\n", CustomProfile.Current.DomainID);
            sb.AppendFormat("User ID : {0}\n", CustomProfile.Current.UserID);
            sb.AppendFormat("Username : {0}\n", CustomProfile.Current.UserName);
            sb.AppendFormat("Currency : {0}\n", CustomProfile.Current.UserCurrency);
            sb.AppendFormat("User Country ID : {0}\n", CustomProfile.Current.UserCountryID);
            sb.AppendFormat("Session Limit Seconds : {0}\n", CustomProfile.Current.SessionLimitSeconds);
            
            sb.AppendFormat("IP Country ID : {0}\n", CustomProfile.Current.IpCountryID);
            sb.AppendFormat("IsEmailVerified : {0}\n", CustomProfile.Current.IsEmailVerified);
            sb.AppendFormat("IsExternal : {0}\n", CustomProfile.Current.IsExternal);
            sb.AppendFormat("FirstName : {0}\n", CustomProfile.Current.FirstName);
            sb.AppendFormat("SurName : {0}\n", CustomProfile.Current.SurName);
            sb.AppendFormat("Email : {0}\n", CustomProfile.Current.Email);
            sb.AppendFormat("AffiliateMarker : {0}\n", CustomProfile.Current.AffiliateMarker);
            sb.AppendFormat("DisplayName : {0}\n", CustomProfile.Current.DisplayName);
            sb.AppendFormat("Registration : {0}\n", CustomProfile.Current.JoinTime);
            sb.AppendFormat("LastAccess : {0}\n", CustomProfile.Current.LastAccess);
            sb.AppendFormat("LoginIP : {0}\n", CustomProfile.Current.LoginIP);
            sb.AppendFormat("RoleString : {0}\n", CustomProfile.Current.RoleString);
            

            sb.Append("\n\n----------------------------------------\n");
            sb.Append("HTTP HEADERS\n----------------------------------------\n");

            foreach (string key in context.Request.Headers.AllKeys)
            {
                sb.AppendFormat("{0} : {1}\n", key, context.Request.Headers[key]);
            }


            context.Response.ContentType = "text/plain";
            context.Response.Write(sb.ToString());
        }

        public bool IsReusable
        {
            get
            {
                return true;
            }
        }
    }
}