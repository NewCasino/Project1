<%@ WebHandler Language="C#" Class="test" %>

using System;
using System.Web;
using GmCore;
using GamMatrixAPI;

public class test : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            XProGamingAPIRequest request = new XProGamingAPIRequest()
            {
                GetLastWinners = true,
                GetLastWinnersDaysBack = 30,
            };
            request = client.SingleRequest<XProGamingAPIRequest>(request);
            context.Response.Write(request.GetLastWinnersResponse);
            context.Response.ContentType = "text/xml";
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}