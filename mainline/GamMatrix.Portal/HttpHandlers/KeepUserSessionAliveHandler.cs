using System.Configuration;
using System.Globalization;
using System.Web;
using EveryMatrix.SessionAgent;

namespace GamMatrix.HttpHandlers
{
    public class KeepUserSessionAliveHandler : IHttpHandler
    {
        private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );



        public void ProcessRequest(HttpContext context)
        {
            /*
            string clientIP = context.Request.GetRealUserAddress();
            if (!clientIP.Equals("127.0.0.1") &&
                !clientIP.Equals("124.233.3.10") &&
                !clientIP.Equals("85.9.28.130") &&
                !clientIP.Equals("83.99.165.207") &&
                !clientIP.StartsWith("78.133.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("109.205.92.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("192.168.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("172.16.111.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("10.0.", false, CultureInfo.InvariantCulture))
            {
                context.Response.StatusCode = 403;
                context.Response.Write("Access Denied!");
                return;
            }
             * */

            //Logger.BeginAccess();
            Logger.EndAccess(0);
            long userID;
            if ( !long.TryParse(context.Request.QueryString["userid"], NumberStyles.Integer, CultureInfo.InvariantCulture, out userID))
            {
                return;
            }

            _agentClient.KeepSessionAlive(userID);
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
