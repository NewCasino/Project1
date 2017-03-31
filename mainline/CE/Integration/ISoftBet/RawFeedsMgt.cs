using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using CE.db;

namespace ISoftBetIntegration
{
    public class RawFeedsMgt
    {
        public static Dictionary<string, ISoftBetIntegration.Game> Get(long domainID,string lang)
        {
            ceDomainConfigEx domain;
            if (domainID == Constant.SystemDomainID)
                domain = DomainManager.GetSysDomain();
            else
                domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);

            return null;
        }

        public static Dictionary<string, ISoftBetIntegration.Game> GetFlashGames(ceDomainConfigEx domain, string lang)
        {
            string url = domain.GetCfg(CE.DomainConfig.ISoftBet.FlashGameFeedsURL);
            url = string.Format(url, domain.GetCfg(CE.DomainConfig.ISoftBet.TargetServer), lang);

            string xml = GetRawXmlFeeds(url);

            return null;
        }

        public static string GetRawXmlFeeds(string url)
        {
            string xml = null;

            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.Accept = "application/json";
            request.ContentType = "application/xml";
            request.Method = "GET";

            HttpWebResponse response = request.GetResponse() as HttpWebResponse;
            using (Stream s = response.GetResponseStream())
            {
                using (StreamReader sr = new StreamReader(s))
                {
                    xml = sr.ReadToEnd();                    
                }
            }

            return xml;
        }
    }
}
