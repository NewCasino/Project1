<%@ WebHandler Language="C#" Class="_get_sites_info" %>

using System;
using System.Web;
using System.Text;
using CM.Content;
using CM.Sites;
using CM.db;
using CM.db.Accessor;
using System.Collections.Generic;
using BLToolkit.DataAccess;
using System.Linq;

public class _get_sites_info : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        
        List<cmSite> sites = SiteManager.GetSites();
        var hosts = SiteManager.GetHosts();
        StringBuilder sb = new StringBuilder();
        sb.Append(@"<?xml version=""1.0"" encoding=""utf-8"" ?><Root><Sites>");
        
        HostAccessor ha = DataAccessor.CreateInstance<HostAccessor>();
        foreach (var site in sites)
        {
            try
            {
                var host = hosts.FirstOrDefault(f => f.SiteID == site.ID);
                if (site.DistinctName == "System" || host == null) continue;
                
                StringBuilder sbSite = new StringBuilder();
                sbSite.Append(@"<Site>");
                sbSite.Append(string.Format(@"<Url>{0}</Url>", host.HostName));
                LanguageInfo[] languages = site.GetSupporttedLanguages();
                sbSite.Append(@"<Languages>");
                foreach (var language in languages)
                {
                    sbSite.Append(string.Format(@"<Language>{0}</Language>", language.LanguageCode));
                }
                sbSite.Append(@"</Languages>");
                sbSite.Append(string.Format(@"<DistinctName>{0}</DistinctName>", site.DistinctName));
                sbSite.Append(@"</Site>");
                sb.Append(sbSite.ToString());
            }
            catch (Exception ex)
            {
            }
        }
        sb.Append(@"</Sites></Root>");
        //LanguageInfo[] languages = SiteManager.Current.GetSupporttedLanguages();
        context.Response.ContentType = "text/xml";
        context.Response.Write(sb.ToString());
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}