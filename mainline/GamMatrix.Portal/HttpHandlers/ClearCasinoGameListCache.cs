using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Text;
using System.Web;
using CasinoEngine;
using CM.Sites;
using Newtonsoft.Json;

namespace GamMatrix.CMS.HttpHandlers
{
    public sealed class ClearCasinoGameListCache : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            if (string.Equals(context.Request.QueryString["type"], "new", StringComparison.InvariantCultureIgnoreCase))
            {
                ClearCache(context);
                return;
            }
            int siteID = 0;
            
            if (!int.TryParse(context.Request.QueryString["siteid"], out siteID))
            {

                NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
                if (servers == null || servers.Count == 0)
                    throw new Exception("Error, can not find the server configration.");

                using (WebClient client = new WebClient())
                {
                    foreach (string item in servers)
                    {
                        string url = string.Format("http://{0}/{1}?siteid={2}"
                            , servers[item]
                            , context.Request.AppRelativeCurrentExecutionFilePath.TrimStart('~').TrimStart('/')
                            , SiteManager.Current.ID);

                        client.DownloadString(url);
                    }
                }
            }
            else
            {
                CasinoEngineClient.ClearGamesCache(siteID);

                Logger.Information("CE", "Clear CE games cache.");
                context.Response.ContentType = "text/plain";
                context.Response.Write("OK");
            }
        }

        public bool IsReusable
        {
            get
            {
                return true;
            }
        }

        private void ClearCache(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            try
            {
                var buffer = new byte[context.Request.ContentLength];
                context.Request.InputStream.Read(buffer, 0, buffer.Length);
                var json = Encoding.UTF8.GetString(buffer, 0, buffer.Length);
                if (string.IsNullOrWhiteSpace(json))
                {
                    context.Response.Write("Invalid Request");
                    return;
                }

                StringBuilder errorBuilder = new StringBuilder();
                Dictionary<long, string> domains = JsonConvert.DeserializeObject<Dictionary<long, string>>(json);
                foreach (var domain in domains)
                {
                    var domainID = domain.Key;

                    var sites = SiteManager.GetSites().Where(s => s.DomainID == domainID).ToList();
                    foreach (var site in sites)
                    {
                        try
                        {
                            if (domain.Value == "JackpotList")
                            {
                                CasinoEngineClient.ClearJackpotsCache(site.ID);
                            }

                            if (domain.Value == "LiveCasinoTableList")
                            {
                                CasinoEngineClient.ClearLiveCasinoTablesCache(site.ID);
                            }

                            CasinoEngineClient.ClearGamesCache(site.ID);
                        }
                        catch (Exception ex)
                        {
                            errorBuilder.AppendLine(ex.Message);
                        }
                    }
                }

                if (errorBuilder.Length == 0)
                    context.Response.Write("OK");
                else
                    context.Response.Write(errorBuilder.ToString());
            }
            catch (Exception ex)
            {
                context.Response.Write(ex.Message);
            }
        }
    }
}
