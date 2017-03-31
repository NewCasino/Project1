<%@ WebHandler Language="C#" Class="EGTJackpotData" %>

using System;
using System.Web;
using System.Web.Caching;
using CM.Content;

public class EGTJackpotData : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        string cache = HttpRuntime.Cache["EGTJackpotBanner_" + CM.Sites.SiteManager.Current.DistinctName] as string;
        if (cache == null)
        {
            System.Net.WebClient client = new System.Net.WebClient();
            client.Headers.Add("Content-Type", "application/x-www-form-urlencoded");
            byte[] responseData = client.DownloadData(Metadata.Get("/Casino/Jackpots/_EGTJackpotBannerWidget_ascx.EGTJackpotUrl"));
            string returnStr = System.Text.Encoding.UTF8.GetString(responseData);

            HttpRuntime.Cache.Insert("EGTJackpotBanner_" + CM.Sites.SiteManager.Current.DistinctName, returnStr, null, DateTime.Now.AddSeconds(10), Cache.NoSlidingExpiration, CacheItemPriority.NotRemovable, null);
            cache = HttpRuntime.Cache["EGTJackpotBanner_" + CM.Sites.SiteManager.Current.DistinctName] as string;
        }

        context.Response.ContentType = "application/x-www-form-urlencoded";
        context.Response.Write(cache);
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}