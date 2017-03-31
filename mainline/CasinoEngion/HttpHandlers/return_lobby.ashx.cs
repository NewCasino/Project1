using System;
using System.Linq;
using System.Web;
using CE.db;

namespace CasinoEngine.HttpHandlers
{
    /// <summary>
    /// Summary description for return_lobby
    /// </summary>
    public class return_lobby : IHttpHandler
    {

        public void ProcessRequest(HttpContext context)
        {
            if (string.IsNullOrWhiteSpace(context.Request.QueryString["domainid"]) ||
                string.IsNullOrWhiteSpace(context.Request.QueryString["type"]) )
                return;

            int domainID;
            if (!int.TryParse(context.Request.QueryString["domainid"], out domainID))
                return;

            ceDomainConfigEx domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
                return;

            if (string.Equals(context.Request.QueryString["type"], "mobile", StringComparison.InvariantCultureIgnoreCase))
            {
                context.Response.Redirect(domain.MobileLobbyUrl);
            }
            else
            {
                context.Response.Redirect(domain.LobbyUrl);
            }
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }
}