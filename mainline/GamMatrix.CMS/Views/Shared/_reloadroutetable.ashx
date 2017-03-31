<%@ WebHandler Language="C#" Class="_reload_route_table" %>

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
using System.Text;
using CM.Sites;
using EveryMatrix.SessionAgent.Protocol;
using EveryMatrix.SessionAgent;
using System.Collections.Generic;


public class _reload_route_table : IHttpHandler
{
    private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );
    
    public void ProcessRequest(HttpContext context)
    {
        StringBuilder sb = new StringBuilder();
        string distinctName = context.Request.QueryString["site"];
        if (!string.IsNullOrWhiteSpace(distinctName))
        {
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            site.ReloadConfigration();
            sb.AppendFormat("{0} : ok\n", site.DistinctName);
        }
        else
        {
            try
            {
                int count = 0;
                int startCount = 0;
                if(!string.IsNullOrWhiteSpace(context.Request.QueryString["start"]))
                {
                    startCount = int.Parse(context.Request.QueryString["start"]);
                }
                List<cmSite> sites = SiteManager.GetSites();
                foreach(var site in sites)
                {
                    count++;
                    if (count < startCount || (count > startCount + 10)) continue;
                    site.ReloadConfigration();
                    sb.AppendFormat("{0}. {1} : ok\n", count, site.DistinctName);
                }
            }
            catch(Exception ex)
            {
                sb.Append(ex.Message);
            }
            
        }

        context.Response.Write(sb.ToString());
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