using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;
using System.Web.Hosting;
using CM.Content;
using CM.db;
using CM.State;

namespace CM.Sites
{
    /// <summary>
    /// Http Module handles all requests
    /// </summary>
    public sealed class MvcHttpModule : IHttpModule
    {
        
        private static readonly char[] s_Seperator = new char[1] { '/' };

        /// <summary>
        /// Dispose 
        /// </summary>
        public void Dispose()
        {
        }

        /// <summary>
        /// Initialize with HttpApplication
        /// </summary>
        /// <param name="context"></param>
        public void Init(HttpApplication context)
        {
            context.BeginRequest += new EventHandler(OnBeginRequest);
        }



        void OnBeginRequest(object sender, EventArgs e)
        {
            
            if (PreProcessRequest())
            {
                CustomProfile profile = HttpContext.Current.Profile.AsCustomProfile();
                
                long startTick = DateTime.Now.Ticks;
                try
                {
                    //Logger.BeginAccess();
                    
                    profile.Init(HttpContext.Current);

                    string host = HttpContext.Current.Request.Url.Host;
                    if (host.IndexOf(".gammatrix.com") < 0 )
                    {
                        SiteManager.SiteAndHost siteAndHost = SiteManager.GetByHostName(host);
                        cmSite site = SiteManager.GetSiteByDistinctName(siteAndHost.Site.DistinctName);
                        /*SiteCDNAccessRule rule = SiteCDNAccessRule.Get(site, false);
                        
                        
                        string ip = HttpContext.Current.Request.GetRealUserAddress();

                        if (rule.IPAddresses.Where(f=>f.Value == ip).Count() == 0) 
                        //if (!ip.Equals("119.39.124.139", StringComparison.InvariantCulture) &&
                        //!ip.Equals("124.233.3.10", StringComparison.InvariantCulture))
                        {
                            GEOLocationCDN.CheckGeoLocation(HttpContext.Current, profile.IpCountryID.ToString());
                        }*/
                    }

                    MvcHttpHandlerEx hander = new MvcHttpHandlerEx();
                    hander.PublicProcessRequest(HttpContext.Current);

                    
                }
                catch (Exception ex)
                {
                    ExceptionHandler.Process(ex);
                    //Logger.Exception(ex);
                    
                }
                finally
                {
                    
                    Logger.EndAccess((DateTime.Now.Ticks - startTick) / 10000000.000M);
                    HttpContext.Current.Response.End();
                }
            }
        }



        #region DetectLanguage
        private string DetectLanguage(SiteManager.SiteAndHost siteAndHost, HttpContext context, out string langCode, out string langCodeFromUrl)
        {
            string url = context.Request.RawUrl;
            if (url.Length > 0 && url[0] == '/')
            {
                string[] parts = url.TrimStart('/').Split(s_Seperator, 2);
                if (parts.Length == 2)
                {
                    bool matched = false;
                    string code = parts[0].ToLowerInvariant();
                    switch (code)
                    {
                        case "lt":
                        case "en":
                        case "tr":
                        case "ka":
                        case "nl":
                        case "el":
                        case "es":
                        case "et":
                        case "de":
                        case "pl":
                        case "cs":
                        case "ru":
                        case "fr":
                        case "it":
                        case "fi":
                        case "pt":
                        case "da":
                        case "da-dk":
                        case "sv":
                        case "no":
                        case "hu":
                        case "sq":
						case "sk":
                        case "ro":
                        case "bg":
                        case "sr":
                        case "he":
                        case "hr":
                        case "lv":
                        case "ko":
                        case "sl":
                        case "pt-br":
                        case "vi":
                        case "ja":
                        case "uk":
                        case "en-au":
                        case "en-za":
                        case "en-gb":
                        case "en-nz":
                        case "en-ca":
                        case "se":
                        case "th":
                        case "af":
                        case "mt":
                            {
                                matched = true;
                                break;
                            }
                        case "zh":
                        case "zh-cn":
                        case "zh-tw":
                            {
                                matched = true;
                                break;
                            }
                        case "ar":
                            {
                                matched = true;
                                break;
                            }
                        default:
                            break;
                    }// switch
                    if (matched)
                    {
                        url = "/" + parts[1];
                        langCode = code;
                        langCodeFromUrl = code;
                        HttpContext.Current.RewritePath(url);
                        return url;
                    }
                }
            }

            langCodeFromUrl = string.Empty;

            {
                if (!string.IsNullOrWhiteSpace(siteAndHost.Host.DefaultCulture))
                {
                    langCode = siteAndHost.Host.DefaultCulture;
                    return url;
                }
                if (!string.IsNullOrWhiteSpace(context.Request.QueryString["culture"]))
                {
                    var supporttedLanguages = siteAndHost.Site.GetSupporttedLanguages().FirstOrDefault(l =>
                            string.Equals(l.LanguageCode, context.Request.QueryString["culture"], StringComparison.CurrentCultureIgnoreCase) ||
                            string.Equals(l.LanguageCode.Truncate(2), context.Request.QueryString["culture"].Truncate(2), StringComparison.CurrentCultureIgnoreCase));

                    if (supporttedLanguages != null)
                    {
                        langCode = supporttedLanguages.LanguageCode;
                        return url;
                    }
                }

                // detect preferred language cookie
                HttpCookie cookie = context.Request.Cookies["CMS_Language"];
                if (cookie != null && !string.IsNullOrWhiteSpace(cookie.Value))
                {
                    langCode = cookie.Value;
                    return url;
                }

                // detect the language by configured IP country map.
                IPLocation ipLocation = IPLocation.GetByIP(context.Request.GetRealUserAddress());
                if (ipLocation != null)
                {
                    var languages = siteAndHost.Site.LoadCountryLanguages();
                    if (languages.ContainsKey(ipLocation.CountryID))
                    {
                        langCode = languages[ipLocation.CountryID];
                        return url;
                    }
                }

                // detect the preferred language in web browser setting
                string[] userLanguages = context.Request.UserLanguages;
                if (userLanguages != null)
                {
                    foreach (string preferredLanguage in userLanguages)
                    {
                        string code = preferredLanguage.ToLowerInvariant();
                        switch (code)
                        {
                            // convert the iOS language code
                            case "nb":
                            case "nb-no":
                                code = "no";
                                break;

                            default:
                                break;
                        }
                        var supporttedLanguages = siteAndHost.Site.GetSupporttedLanguages().FirstOrDefault(l =>
                            string.Equals(l.LanguageCode, code, StringComparison.CurrentCultureIgnoreCase) ||
                            string.Equals(l.LanguageCode, code, StringComparison.CurrentCultureIgnoreCase));

                        if (supporttedLanguages != null)
                        {
                            langCode = supporttedLanguages.LanguageCode;
                            return url;
                        }
                    }
                }

                // use default language for the site
                langCode = siteAndHost.Site.DefaultCulture;
            }

            langCode = langCode.ToLower(CultureInfo.InvariantCulture);
            return url;
        }
        #endregion


        #region IsIpAddressBlocked
        private bool IsIpAddressBlocked(cmSite site)
        {
            try
            {
                string ip = HttpContext.Current.Request.GetRealUserAddress();

                SiteAccessRule rule = SiteAccessRule.Get(site);


                bool isBlocked = false;
                int countryId =  IPLocation.GetByIP(ip).CountryID ; 
                if (rule.CountriesFilterType == SiteAccessRule.FilterType.Exclude)
                {
                    isBlocked = (null != rule.CountriesList && rule.CountriesList.Count > 0) ? rule.CountriesList.Contains(countryId) : false;
                }
                if (rule.CountriesFilterType == SiteAccessRule.FilterType.Include)
                {
                    isBlocked = (null != rule.CountriesList && rule.CountriesList.Count > 0) ? !rule.CountriesList.Contains(countryId) :  true   ;
                }
                if (!isBlocked)
                {
                    switch (rule.AccessMode)
                    {
                        case SiteAccessRule.AccessModeType.NotSet:
                            isBlocked = rule.IsWhitelistMode ? !rule.IPAddresses.ContainsKey(ip) : rule.IPAddresses.ContainsKey(ip);
                            break;
                        case SiteAccessRule.AccessModeType.Whitelist:
                            isBlocked = !rule.IPAddresses.ContainsKey(ip);
                            break;
                        case SiteAccessRule.AccessModeType.Blacklist:
                            isBlocked = rule.IPAddresses.ContainsKey(ip);
                            break;
                        case SiteAccessRule.AccessModeType.SoftLaunch:
                            if (rule.IPAddresses.ContainsKey(ip))
                                isBlocked = false;
                            else
                            {
                                if (rule.IPAddresses.Count < rule.SoftLaunchNumber)
                                {
                                    isBlocked = false;
                                    //add the current ip to the ip addresses
                                    rule.IPAddresses.Add(ip, ip);
                                    rule.Save(site, rule, false);
                                }
                                else
                                {
                                    isBlocked = true;
                                }
                            }
                            break;
                    }
                } 
                if (isBlocked)
                {
                    if (ip.StartsWith("10.0.", StringComparison.InvariantCulture) ||
                        ip.StartsWith("192.168.", StringComparison.InvariantCulture) ||
                        ip.StartsWith("109.205.9", StringComparison.InvariantCulture) ||
                        ip.StartsWith("78.133.", StringComparison.InvariantCulture) ||
                        ip.StartsWith("172.16.111.", StringComparison.InvariantCulture) ||
                        ip.StartsWith("95.131.233.", StringComparison.InvariantCulture) ||
                        ip.Equals("127.0.0.1", StringComparison.InvariantCulture) ||
                        ip.Equals("85.9.28.130", StringComparison.InvariantCulture) ||
                        ip.Equals("124.233.3.10", StringComparison.InvariantCulture)  ||
                        ip.Equals("119.39.124.139", StringComparison.InvariantCulture))
                    {
                        return false;
                    }
                }

                if (isBlocked)
                {
                    HttpContext.Current.Response.ContentType = "text/html";
                    HttpContext.Current.Response.Write(rule.BlockedMessage.Replace("$IP$", ip));
                    //HttpContext.Current.Response.End();
                    HttpContext.Current.Response.Flush(); // Sends all currently buffered output to the client.
                    HttpContext.Current.Response.SuppressContent = true;  // Gets or sets a value indicating whether to send HTTP content to the client.
                    HttpContext.Current.ApplicationInstance.CompleteRequest(); // Causes ASP.NET to bypass all events and filtering in the HTTP pipeline chain of execution and directly execute the EndRequest event.
                }

                return isBlocked;
            }
            catch
            {
                return false;
            }
        }
        #endregion

        /// <summary>
        /// When the request begin, this method is called
        /// </summary>
        bool PreProcessRequest()
        {
            if (HttpContext.Current.Request.Url.Host.IsValidIpAddress())
            {
                if (HttpContext.Current.Request.RawUrl.Equals("/node", StringComparison.InvariantCultureIgnoreCase))
                {
                    string physicalPath = HostingEnvironment.MapPath(HttpContext.Current.Request.RawUrl);
                    if (File.Exists(physicalPath))
                    {
                        HttpContext.Current.Response.ClearHeaders();
                        HttpContext.Current.Response.Clear();
                        HttpContext.Current.Response.WriteFile(physicalPath);
                        HttpContext.Current.Response.End();
                    }
                }
            }

            string host = HttpContext.Current.Request.Url.Host;
            SiteManager.SiteAndHost siteAndHost = SiteManager.GetByHostName(host);

            if (siteAndHost != null)
            {
                SiteManager.Current = siteAndHost.Site;

                if (DDOSRedirector.Handle(SiteManager.Current.DomainID))
                    return false;

                if (IsIpAddressBlocked(SiteManager.Current))
                    return false;

                string langCode;
                string langCodeFromUrl;
                string url = DetectLanguage(siteAndHost, HttpContext.Current, out langCode, out langCodeFromUrl);

                HttpContext.Current.Items["GM_Language"] = langCode;

                // set the thread culture
                try
                {
                    CultureInfo culture = new CultureInfo(langCode);
                    HttpContext.Current.Items["IsRightToLeft"] = culture.TextInfo.IsRightToLeft;
                    Thread.CurrentThread.CurrentCulture = culture;
                    Thread.CurrentThread.CurrentUICulture = culture;
                }
                catch
                {
                }

                int index = url.LastIndexOf('?');
                string urlQueryString = null;
                if (index > 0)
                {
                    urlQueryString = url.Substring(index);
                    url = url.Substring(0, index);
                }

                // backward compatibility for .c extension name
                if (url.EndsWith(".c", StringComparison.InvariantCultureIgnoreCase))
                {
                    url = Regex.Replace(url, @"(\.c)$", string.Empty, RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                    url += urlQueryString;
                    HttpContext.Current.Response.AddHeader("Location", url);
                    HttpContext.Current.Response.StatusCode = 301;
                    HttpContext.Current.Response.End();
                    return false;
                }

                index = url.LastIndexOf('.');
                if (index < 0)
                {
                    string urlToRewrite = null;
                    if (url == "/")
                        urlToRewrite = siteAndHost.Site.DefaultUrl;
                    else
                    {
                        Dictionary<string, string> rules = siteAndHost.Site.GetUrlRewriteRules();
                        rules.TryGetValue(url.ToLowerInvariant(), out urlToRewrite);

                        rules = siteAndHost.Site.GetHttpRedirectionRules();
                        string urlToRedirect;
                        if (rules.TryGetValue(url.ToLowerInvariant(), out urlToRedirect))
                        {
                            if (urlToRedirect.StartsWith("/", StringComparison.InvariantCultureIgnoreCase))
                            {
                                if(!string.IsNullOrEmpty(langCodeFromUrl))
                                    urlToRedirect = string.Format(CultureInfo.InvariantCulture, "/{0}{1}{2}", langCode, urlToRedirect, urlQueryString);
                                else
                                    urlToRedirect = string.Format(CultureInfo.InvariantCulture, "{0}{1}", urlToRedirect, urlQueryString);
                            }
                            HttpContext.Current.Response.ClearHeaders();
                            HttpContext.Current.Response.Clear();
                            HttpContext.Current.Response.AddHeader("Location", urlToRedirect);
                            HttpContext.Current.Response.StatusCode = 301;
                            HttpContext.Current.Response.End();
                            return false;
                        }
                    }

                    if( urlToRewrite != null )
                        HttpContext.Current.RewritePath(urlToRewrite);

                    typeof(HttpContext).InvokeMember("_ProfileDelayLoad"
                        , BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.SetField
                        , null
                        , HttpContext.Current
                        , new object[] { true }
                        );

                    return true;
                }
                else // if this is a request with extension filename
                {
                    if (!url.StartsWith("/Views/", StringComparison.InvariantCultureIgnoreCase) &&
                        !url.StartsWith("/App_Themes/", StringComparison.InvariantCultureIgnoreCase) &&
                        !url.StartsWith("/images/", StringComparison.InvariantCultureIgnoreCase) &&
                        !url.StartsWith("/js/", StringComparison.InvariantCultureIgnoreCase) &&
                        !url.StartsWith("/temp/", StringComparison.InvariantCultureIgnoreCase) &&
                        !url.StartsWith("/revisions/", StringComparison.InvariantCultureIgnoreCase) &&
                        !url.StartsWith("/logs/", StringComparison.InvariantCultureIgnoreCase))
                    {
                        string extName = url.Substring(index);
                        string contentType = "text/html";
                        string physicalPath;
                        switch (extName.ToLower(CultureInfo.InvariantCulture))
                        {

                            case ".ico":
                                contentType = "image/x-icon";
                                break;
                            case ".xml":
                                contentType = "text/xml";
                                break;
                            case ".txt":
                                contentType = "text/plain";
                                break;
                            case ".png":
                                contentType = "image/png";
                                break;
                            case ".htm":
                            case ".html":
                                contentType = "text/html";
                                break;
                            case ".ashx":
                                {
                                    contentType = null;
                                }
                                break;
                            case ".webapp":
                                contentType = null;
                                break;
                            case ".js":
                                contentType = "text/javascript";
                                break;
                            case ".json":
                                contentType = "application/json";
                                break;
                            default:
                                return false;
                        }// switch

                        // check the file in /Views/{distinctname}/ and rewrite
                        HttpResponse response = HttpContext.Current.Response;
                        physicalPath = HostingEnvironment.MapPath(url);
                        if (!File.Exists(physicalPath))
                        {
                            string newUrl = string.Format("/Views/{0}{1}", siteAndHost.Site.DistinctName, url);
                            physicalPath = HostingEnvironment.MapPath(newUrl);
                            if (File.Exists(physicalPath))
                            {
                                if (contentType != null)
                                {
                                    response.ClearHeaders();
                                    response.Clear();
                                    response.ContentType = contentType;
                                    response.TransmitFile(physicalPath);
                                    response.End();
                                }
                                else
                                {
                                    HttpContext.Current.RewritePath(newUrl);
                                }
                            }
                            else if (!string.IsNullOrEmpty(siteAndHost.Site.TemplateDomainDistinctName))
                            {
                                newUrl = string.Format("/Views/{0}{1}", siteAndHost.Site.TemplateDomainDistinctName, url);
                                physicalPath = HostingEnvironment.MapPath(newUrl);
                                if (File.Exists(physicalPath))
                                {
                                    if (contentType != null)
                                    {
                                        response.ClearHeaders();
                                        response.Clear();
                                        response.ContentType = contentType;
                                        response.TransmitFile(physicalPath);
                                        response.End();
                                    }
                                    else
                                    {
                                        HttpContext.Current.RewritePath(newUrl);
                                    }
                                }
                            }
                        }

                    }
                }
            }
            else
            {
                if (!HttpContext.Current.Request.Url.Host.IsValidIpAddress())
                {
                    SiteManager.ReloadSiteHostCache();
                }

                Logger.RestartException("Restart", string.Format("Current Url: {0}", HttpContext.Current.Request.Url.ToString()));
                HttpContext.Current.Response.Write(".");
                HttpContext.Current.Response.End();
            }

            return false;
        }

        
    }
}
