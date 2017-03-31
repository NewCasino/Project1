using System;
using System.Data;
using System.Collections.Generic;
using System.Net;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

using BLToolkit.Data;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;

namespace CM.db
{
    [Serializable]
    public enum PasswordEncryptionMode
    {
        MD5 = 0,
        RC4 = 1, // for jetbull
        SHA1_IntraGame = 2, // for IntraGame
        SHA2_512 = 3,
    }
    /// <summary>
    /// Stores data about a domain. Could also be referred to as an operator.
    /// </summary>
    [Serializable]
    public class cmSite
    {
        private string m_SessionCookieDomain;

        [PrimaryKey, Identity, MapField("SiteID"), NonUpdatable]
        public int ID { get; set; }

        public string DistinctName { get; set; }

        public string DisplayName { get; set; }

        public string Description { get; set; }

        public string TemplateDomainDistinctName { get; set; }

        public string DefaultTheme { get; set; }

        public int DomainID { get; set; }

        public int HttpPort { get; set; }

        public int HttpsPort { get; set; }

        public bool UseRemoteStylesheet { get; set; }

        public string StaticFileServerDomainName { get; set; }

        [DefaultValue("'/Home'")]
        public string DefaultUrl { get; set; }

        [DefaultValue("'en'")]
        public string DefaultCulture { get; set; }

        [DefaultValue("900")]
        public int SessionTimeoutSeconds { get; set; }

        [NonUpdatable]
        public string ApiUsername { get; set; }

        [NonUpdatable]
        public string SecurityToken { get; set; }

        [NonUpdatable]
        public string SessionCookieDomain
        {
            get
            {
                try
                {
                    if (HttpContext.Current == null
                        || HttpContext.Current.Request == null
                        || HttpContext.Current.Request.Url == null)
                        return m_SessionCookieDomain;

                    string host = HttpContext.Current.Request.Url.Host;

                    //If the accessing domain name is CMS console
                    //the cookie is not set;
                    if (string.Equals(host, "cms.gammatrix-dev.net", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms-qa.gammatrix-dev.net", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms-stage.gammatrix-dev.net", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms.gm-dev.everymatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms.gm-qa.everymatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms.gm-stage.everymatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms.gm.dev.everymatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms.gm.qa.everymatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms.gm.stage.everymatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms2012.gammatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms2.gammatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "cms3.gammatrix.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "admin.energycasino.com", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(host, "localhost", StringComparison.InvariantCultureIgnoreCase))
                    {
                        return string.Empty;
                    }

                    //If the accessing domain name is an IP address, 
                    //the cookie domain is not set.
                    if (host.IsValidIpAddress())
                        return string.Empty;

                    string domain = string.Empty;
                    string[] fields;

                    Dictionary<string, int> dicTestEnvHost = new Dictionary<string, int>();
                    dicTestEnvHost[".gammatrix-dev.net"] = 3;
                    dicTestEnvHost[".stage.everymatrix.com"] = 4;
                    dicTestEnvHost[".qa.everymatrix.com"] = 4;
                    dicTestEnvHost[".dev.everymatrix.com"] = 4;

                    foreach (string key in dicTestEnvHost.Keys)
                    {
                        if (host.EndsWith(key))
                        {
                            //If the accessing domain name is under test env domain (i.e, www.jetbull.gammatrix-dev.net), 
                            //the cookie domain is set to jetbull.gammatrix-dev.net
                            fields = host.Split('.');
                            domain = string.Empty;
                            for (var i = fields.Length - dicTestEnvHost[key]; i < fields.Length; i++)
                                domain += fields[i] + ".";
                            return domain.TrimStart('.').TrimEnd('.');
                        }
                    }


                    //Otherwise, the root domain name is set as the cookie domain. 
                    //For example, www.casino.jetbull.com and www.jetbull.com and jetbull.com all get the same cookie domain jetbull.com;
                    //www.casino.jetbull.com.mx and www.jetbull.com.mx and jetbull.com.mx all get the same cookie domain jetbull.com.mx
                    //Note: the same logic will be applied to domain XXX.net, XXX.org, XXX.co and XXX.net.XX, XXX.org.XX, XXX.co.XX
                    var tlds = new[]
                            {
                                ".com",
                                ".net",
                                ".org",
                                ".co",
                            };//top-level domains

                    foreach (var tld in tlds)
                    {
                        if (host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase) > 0)
                        {
                            var temp = host.Substring(0, host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                            if (temp.LastIndexOf(".") >= 0)
                                temp = temp.Substring(temp.LastIndexOf(".") + 1);
                            var domain2 = temp + host.Substring(host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                            return domain2.TrimStart('.').TrimEnd('.');
                        }
                    }

                    fields = host.Split('.');
                    if (fields.Length < 2)
                        return host;
                    domain = string.Empty;
                    for (var i = fields.Length - 2; i < fields.Length; i++)
                        domain += fields[i] + ".";
                    return domain.TrimStart('.').TrimEnd('.');

                }
                catch
                {
                    return m_SessionCookieDomain;
                }
            }
            set
            {
                m_SessionCookieDomain = value;
            }
        }

        [NonUpdatable]
        public string SessionCookieDomainInDatabase
        {
            get
            {
                return m_SessionCookieDomain;
            }
        }

        [NonUpdatable]
        [DefaultValue("'cmSession'")]
        public string SessionCookieName { get; set; }

        [NonUpdatable]
        public string EmailHost { get; set; }

        [NonUpdatable]
        public PasswordEncryptionMode PasswordEncryptionMode { get; set; }

        [NonUpdatable]
        public string OperatorName { get; set; }
    }
}
