<%@ WebHandler Language="C#" Class="_raw_xml" %>

using System;
using System.Web;
using GmCore;
using GamMatrixAPI;

public class _raw_xml : IHttpHandler
{
    
    public void ProcessRequest (HttpContext context) {
        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            XProGamingAPIRequest request = new XProGamingAPIRequest()
            {
                GetGamesListWithLimits = true,
                GetGamesListWithLimitsGameType = (int)0,
                GetGamesListWithLimitsOnlineOnly = 0,
            };
            request = client.SingleRequest<XProGamingAPIRequest>(request);
            context.Response.Write(request.GetGamesListWithLimitsResponse);
            context.Response.ContentType = "text/plain";
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}