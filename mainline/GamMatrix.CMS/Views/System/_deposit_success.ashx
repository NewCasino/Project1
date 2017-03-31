<%@ WebHandler Language="C#" Class="_deposit_success" %>

using System;
using System.Web;
using CM.db;

/// <summary>
/// The handle for ecocard return back
/// </summary>
public class _deposit_success : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        string sid = context.Request.QueryString["TxID"];
        if (!string.IsNullOrWhiteSpace(sid))
        {
            string url = cmTransParameter.ReadObject<string>(sid, "SuccessUrl");
            context.Response.Redirect(url);
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}