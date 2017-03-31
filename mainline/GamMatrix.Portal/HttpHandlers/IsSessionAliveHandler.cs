using System;
using System.Globalization;
using System.Text;
using System.Web;
using CM.Sites;
using CM.State;

namespace GamMatrix.CMS.HttpHandlers
{
    public sealed class IsSessionAliveHandler : IHttpHandler
    {
        public bool IsReusable
        {
            get { return true; }
        }

        public void ProcessRequest(HttpContext context)
        {
            long startTick = DateTime.Now.Ticks;
            try
            {
                //Logger.BeginAccess();
                CustomProfile.Current.Init(context);

                StringBuilder xml = new StringBuilder();
                xml.AppendLine("<?xml version=\"1.0\" ?>");
                xml.AppendLine("<Response>");
                if (!CustomProfile.Current.IsAuthenticated || CustomProfile.Current.DomainID != SiteManager.Current.DomainID)
                    xml.Append("<IsActive>false</IsActive>");
                else
                {
                    xml.Append("<IsActive>true</IsActive>");
                    xml.AppendFormat(CultureInfo.InvariantCulture, "<UserID>{0:D}</UserID>", CustomProfile.Current.UserID);
                    xml.AppendFormat(CultureInfo.InvariantCulture, "<UserName>{0}</UserName>", CustomProfile.Current.UserName);
                    xml.AppendFormat(CultureInfo.InvariantCulture, "<DisplayName>{0}</DisplayName>", CustomProfile.Current.DisplayName);
                }
                xml.AppendLine("</Response>");

                context.Response.ContentType = "text/xml";
                context.Response.Write(xml);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            finally
            {
                Logger.EndAccess((DateTime.Now.Ticks - startTick) / 10000000.000M);
            }
        }
    }
}
