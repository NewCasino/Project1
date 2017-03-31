<%@ WebHandler Language="C#" Class="_clear_session_cache" %>

using System;
using System.Web;
using CM.State;
using System.Globalization;
using CM.db;
using CM.db.Accessor;
using System.Linq;
using CM.Web;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using System.Configuration;

using EveryMatrix.SessionAgent.Protocol;
using EveryMatrix.SessionAgent;


public class _clear_session_cache : IHttpHandler
{
    private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );
    
    public void ProcessRequest(HttpContext context)
    {
        if (!string.IsNullOrWhiteSpace(context.Request.QueryString["SessionGUID"]))
        {
            CustomProfile.ClearSessionCache(context.Request.QueryString["SessionGUID"]);
        }
        else
        {
            if (!string.IsNullOrWhiteSpace(context.Request.QueryString["userid"]))
                ClearSessionByUserID(context);
            else
            {
                context.Response.Write("Nothing received!");
                return;
            }
        }
    } 
    public void ClearSessionByUserID(HttpContext context)
    {
        try
        {
            string clientIP = context.Request.GetRealUserAddress();
            if (
                !clientIP.Equals("127.0.0.1") &&
                !clientIP.Equals("85.9.28.130") &&
                !clientIP.Equals("85.9.28.130") &&
                !clientIP.Equals("83.99.165.207") &&
                !clientIP.Equals("109.205.93.1") &&    // titus
                !clientIP.Equals("109.205.93.50") &&
                !clientIP.Equals("175.0.128.132") &&   // odin
                !clientIP.Equals("124.233.3.10") &&    // changsha
                !clientIP.StartsWith("109.205.92.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("78.133.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("192.168.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("172.16.111.", false, CultureInfo.InvariantCulture) &&
                !clientIP.StartsWith("10.0.", false, CultureInfo.InvariantCulture)
                )
            {
                // context.Response.StatusCode = 403;
                context.Response.Write("Your Ip " + clientIP + " , Access Denied!");
                return;
            }

            long userID;
            if (!long.TryParse(context.Request.QueryString["userid"], NumberStyles.Integer, CultureInfo.InvariantCulture, out userID))
            {
                return;
            }
            _agentClient.ReloadAliveSessionCache(userID);
            context.Response.Write("Done");
            return;

        }
        catch (Exception ex)
        {
            context.Response.Write(ex.Message);
        }
        return;
    }
    public bool IsReusable
    {
        get
        {
            return true;
        }
    }

}