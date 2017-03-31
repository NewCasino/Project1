<%@ WebHandler Language="C#" Class="_keep_user_session_alive_handler" %>


using System;
using System.Globalization;
using System.Web;
using CM.State;
using CM.Sites;

public class _keep_user_session_alive_handler : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {

        Logger.BeginAccess();
        
        long userID;
        if (!long.TryParse(context.Request.QueryString["userid"], NumberStyles.Integer, CultureInfo.InvariantCulture, out userID))
        {
            return;
        }

        string sessionID = CustomProfile.GetUserSessionID(userID);
        if (string.IsNullOrEmpty(sessionID))
        {
            context.Response.Write("No valid session found!");
            return;
        }
        context.Response.Write(string.Format( "Session is found for user {0}", userID));

        string url = string.Format("{0}&_sid={1}", context.Request.Url.PathAndQuery, sessionID);
        context.RewritePath(url);
        CustomProfile.Current.Init(context, true);
        CustomProfile.Current.SyncToMemorycahced();
        Logger.EndAccess(0);
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}