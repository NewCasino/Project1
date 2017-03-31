<%@ WebHandler Language="C#" Class="_oauth_return" %>

using System;
using System.Collections.Generic;
using System.Web;
using OAuth;

/// <summary>
/// The handle for ecocard return back
/// </summary>
public class _oauth_return : IHttpHandler
{
    
    public void ProcessRequest (HttpContext context) {
        try
        {
            var authParty = Enum.Parse(typeof(ExternalAuthParty), context.Request.QueryString["authParty"], true) is ExternalAuthParty ? (ExternalAuthParty) Enum.Parse(typeof(ExternalAuthParty), context.Request.QueryString["authParty"], true) : ExternalAuthParty.Unknown;
            IExternalAuthClient client = ExternalAuthManager.GetClient(authParty);
            var referrer = client.CheckReturn(dicPassIn(context));
            referrer.Save();
            context.Response.Redirect(referrer.CallbackUrl, false);
        }
        catch (Exception ex)
        {
            context.Response.Write(ex.ToString());
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

    private Dictionary<string, string> dicPassIn(HttpContext context)
    {
        var dicNameValue = new Dictionary<string, string>();

        foreach (string k in context.Request.QueryString.Keys)
            dicNameValue[k] = context.Request.QueryString[k].DefaultIfNullOrEmpty(string.Empty);

        return dicNameValue;
    }
    
}