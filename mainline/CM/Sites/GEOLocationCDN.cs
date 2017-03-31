using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Web;

namespace CM.Sites
{
    public static class GEOLocationCDN
    {
        public static Dictionary<string, string> _countryCode2UrlMap = null; //new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);

        private static Dictionary<string, string> GetMap()
        {
            if (_countryCode2UrlMap == null)
            {
                lock (typeof(GEOLocationCDN))
                {
                    if (_countryCode2UrlMap == null)
                    {
                        _countryCode2UrlMap = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);
                        NameValueCollection coll = ConfigurationManager.GetSection("geoLocationCDN") as NameValueCollection;
                        if (coll != null)
                        {
                            foreach (string key in coll.AllKeys)
                            {
                                string countryCodes = coll[key];
                                if (string.IsNullOrWhiteSpace(countryCodes))
                                    continue;

                                string[] codes = countryCodes.Split(new char[] { ',', '|' }, StringSplitOptions.RemoveEmptyEntries);
                                foreach (string code in codes)
                                    _countryCode2UrlMap[code] = key;
                            }
                        }
                    }
                }
            }
            return _countryCode2UrlMap;
        }

        public static void CheckGeoLocation(HttpContext context, string countryCode)
        {
            Dictionary<string, string> map = GetMap();
            string url;
            if (map.TryGetValue(countryCode, out url))
            {
                context.Response.AddHeader("_PATTERN_URL", "//cdn.everymatrix.com");
                context.Response.AddHeader("_REPLACE_URL", url);
            }
        }
    }
}
