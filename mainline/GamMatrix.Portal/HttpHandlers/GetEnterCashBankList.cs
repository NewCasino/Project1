using System.Collections.Generic;
using System.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.HttpHandlers
{
    public sealed class GetEnterCashBankList : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            bool fromCache = true;

            if (!string.IsNullOrWhiteSpace(context.Request.QueryString["fromCache"]))
                bool.TryParse(context.Request.QueryString["fromCache"], out fromCache);

            List<EnterCashRequestBankInfo> list = GetEnterCashBankInfo(fromCache);

            string xml = "";
            if (list == null)
            {
                list = new List<EnterCashRequestBankInfo>();
            }
            xml = System.Text.Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(list));

            context.Response.ContentType = "text/xml";
            context.Response.Write(xml);
        }

        private List<EnterCashRequestBankInfo> GetEnterCashBankInfo(bool fromCache)
        {
            if (fromCache)
            {
                string cacheKey = string.Format("GamMatrixClient.EnterCashGetBankInfoRequest.{0}", CM.Sites.SiteManager.Current.DistinctName);
                DelayUpdateCache<List<EnterCashRequestBankInfo>> cache = HttpRuntime.Cache[cacheKey] as DelayUpdateCache<List<EnterCashRequestBankInfo>>;

                List<EnterCashRequestBankInfo> list;

                DelayUpdateCache<List<EnterCashRequestBankInfo>>.TryGetValue(cacheKey, out list, null, 600);


                return list == null ? new List<EnterCashRequestBankInfo>() : list;
            }
            else
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    return client.SingleRequest<EnterCashGetBankInfoRequest>(new EnterCashGetBankInfoRequest()).Data;
                }
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
