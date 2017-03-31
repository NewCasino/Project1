using System.IO;
using System.Runtime.Serialization;
using System.Text;
using System.Web;
using CM.Sites;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.HttpHandlers
{
    /// <summary>
    /// Summary description for InfoHttpHandler
    /// </summary>
    public sealed class InternalConfigurationHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            string clientIP = context.Request.GetRealUserAddress();
            if (!clientIP.Equals("127.0.0.1") &&
                !clientIP.Equals("124.233.3.10") &&
                !clientIP.Equals("85.9.28.130") )
            {
                context.Response.StatusCode = 403;
                context.Response.Write("Access Denied!");
                return;
            }

            using (GamMatrixClient client = new GamMatrixClient())
            {
                GetDomainModuleFeaturesRequest request = new GetDomainModuleFeaturesRequest()
                {
                    DomainID = SiteManager.Current.DomainID,
                };
                request = client.SingleRequest<GetDomainModuleFeaturesRequest>(request);


                DataContractSerializer formatter = new DataContractSerializer(request.GetType());
                using (MemoryStream ms = new MemoryStream())
                {
                    formatter.WriteObject(ms, request);
                    context.Response.ContentType = "text/xml";
                    string content = Encoding.UTF8.GetString(ms.ToArray());
                    context.Response.Write(content);
                 }
            }

        }

        public bool IsReusable
        {
            get
            {
                return true;
            }
        }
    }
}