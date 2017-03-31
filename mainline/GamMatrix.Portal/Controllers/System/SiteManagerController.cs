using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Threading;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;
using CM.State;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class SiteManagerController : ControllerEx
    {
        /// <summary>
        /// The class stores the search task information
        /// </summary>
        internal sealed class RollbackTaskInfo
        {
            public int UserID { get; set; }
            public cmSite Site { get; set; }
            public DateTime Time { get; set; }
            public AutoResetEvent AutoResetEvent { get; private set; }
            public bool IsCompleted { get; set; }
            public ConcurrentQueue<RollbackResult> ResultQueue { get; private set; }

            public RollbackTaskInfo()
            {
                this.IsCompleted = false;
                this.AutoResetEvent = new AutoResetEvent(false);
                this.ResultQueue = new ConcurrentQueue<RollbackResult>();
            }
        }

        internal sealed class RollbackResult
        {
            public string RelativePath { get; set; }
            public string RollbackTo { get; set; }
            public string Error { get; set; }
        }

        private static Dictionary<string, RollbackTaskInfo> s_RollbackTasks = new Dictionary<string, RollbackTaskInfo>();

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();

            return View(SiteManager.GetSiteByDistinctName(distinctName));
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult TabAccessControl(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();

            return View("TabAccessControl", SiteManager.GetSiteByDistinctName(distinctName));
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetHostNames(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);

            HostAccessor ha = DataAccessor.CreateInstance<HostAccessor>();
            var hosts = ha.GetBySiteID(site.ID).Select(h => new { h.HostName, h.DefaultCulture }).ToArray();


            return this.Json(new { @success = true, @hosts = hosts }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult Save(string distinctName, cmSite domain)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                using (DbManager dbManager = new DbManager())
                {
                    SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>(dbManager);
                    cmSite existingDomain = da.GetByDistinctName(distinctName);
                    if (existingDomain == null)
                        throw new Exception("The special domain does not exist.");

                    string relativePath = "/.config/site_properties.setting";
                    string name = "Properties";

                    Revisions.BackupIfNotExists<cmSite>(site, existingDomain, relativePath, name);

                    SqlQuery<cmSite> query = new SqlQuery<cmSite>(dbManager);
                    existingDomain.DisplayName = domain.DisplayName;
                    existingDomain.DefaultUrl = domain.DefaultUrl;
                    existingDomain.DefaultTheme = domain.DefaultTheme;
                    existingDomain.TemplateDomainDistinctName = domain.TemplateDomainDistinctName;
                    existingDomain.DefaultCulture = domain.DefaultCulture;
                    query.Update(existingDomain);

                    Revisions.Backup<cmSite>(site, existingDomain, relativePath, name);
                }

                // reload the cache from db
                //DomainManager.ReloadConfigrarion(false);
                domain.ReloadCache(Request.RequestContext, CacheManager.CacheType.DomainCache);

                return Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return Json(new { @success = false, @error = ex.Message });
            }

        }



        public JsonResult PrepareUpload(string distinctName, string filename, int size)
        {
            try
            {
                if (size > 1024 * 1024 * 50)
                    throw new Exception("Error, the file is bigger than 50MB.");

                List<string> allowedFiles = new List<string>
                {
                    "robots.txt", "sitemap.txt", "sitemap.xml",
                    "sitemap.xml.gz", "sitemap.html", "sitemap_images.xml", "sitemap_video.xml",
                    "sitemap_news.xml", "ror.xml", "urllist.txt", "LiveSearchSiteAuth.xml",
                    "apple-touch-icon.png",
                    "apple-touch-icon-57x57-precomposed.png", 
                    "apple-touch-icon-72x72-precomposed.png",
                    "apple-touch-icon-114x114-precomposed.png",
                    "Default.png", "Default-Landscape.png", "Default-Portrait.png",
                    "favicon.ico", "favicon-32.png", "favicon-48.png","default@2x.png",
                    "default-568@2x.png","favicon-180.png","default-iphone6@2x.png","default-iphone6plus@2x.png",
                    "default-iphone6-landscape@2x.png","default-iphone6plus-landscape@2x.png",
                    "default-ipad@2x.png","default-ipad-landscape@2x.png","apple-touch-icon-120x120-precomposed.png","apple-touch-icon-76x76-precomposed.png",
                    "apple-touch-icon-152x152-precomposed.png"
                };
                if (!allowedFiles.Exists(f => string.Equals(f, filename, StringComparison.InvariantCultureIgnoreCase)))
                {
                    if (!Regex.IsMatch(filename, @"^(Google)([a-z0-9]+)(\.html)$", RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.CultureInvariant) &&
                        !Regex.IsMatch(filename, @"^(yandex_)([a-z0-9]+)(\.txt)$", RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    {
                        throw new Exception("Error, this is not an accepted file, check your file name.");
                    }
                }

                distinctName = distinctName.DefaultDecrypt();
                string dest = Server.MapPath(string.Format("~/Views/{0}/{1}.tmp", distinctName, filename));

                using (FileStream fs = new FileStream(dest, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.Delete | FileShare.ReadWrite))
                {
                    fs.SetLength(size);
                    fs.Flush();
                    fs.Close();
                }

                return this.Json(new { @success = true, @key = dest.DefaultEncrypt() });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpPost]
        public ContentResult PartialUpload()
        {
            try
            {
                int offset = int.Parse(Request.Headers["CurrentPosition"]);
                string dest = Request.Headers["UploadIdentity"].DefaultDecrypt();
                if (string.IsNullOrEmpty(dest) || !global::System.IO.File.Exists(dest))
                    throw new Exception("Error, invalid parameter.");

                Stream stream = Request.InputStream;
                byte[] buffer = new byte[stream.Length];
                stream.Read(buffer, 0, buffer.Length);

                bool completed = false;

                using (FileStream fs = new FileStream(dest, FileMode.Open, FileAccess.ReadWrite, FileShare.Delete | FileShare.ReadWrite))
                {
                    if (offset + buffer.Length > fs.Length)
                        throw new Exception("Error, invalid size.");

                    fs.Position = offset;
                    fs.Write(buffer, 0, buffer.Length);
                    fs.Flush();

                    completed = offset + buffer.Length >= fs.Length;

                    // verify the dimensions for the image
                    if (completed)
                    {
                        string basePath = HostingEnvironment.MapPath("~/Views/");
                        string uploadedFile = dest.Substring(basePath.Length).Split('\\')[1];
                        int width = 0, height = 0;
                        switch (uploadedFile.ToLowerInvariant())
                        {
                            case "favicon-32.png.tmp":
                                width = height = 32;
                                break;
                            case "favicon-48.png.tmp":
                                width = height = 48;
                                break;
                            case "apple-touch-icon.png.tmp":
                                width = height = 57;
                                break;
                            case "apple-touch-icon-57x57-precomposed.png.tmp":
                                width = height = 57;
                                break;
                            case "apple-touch-icon-72x72-precomposed.png.tmp":
                                width = height = 72;
                                break;
                            case "apple-touch-icon-114x114-precomposed.png.tmp":
                                width = height = 114;
                                break;
                            case "default.png.tmp":
                                width = 320;
                                height = 460;
                                break;
                            case "default-landscape.png.tmp":
                                width = 1024;
                                height = 748;
                                break;
                            case "default-portrait.png.tmp":
                                width = 768;
                                height = 1004;
                                break;
                            case "default@2x.png.tmp":
                                width = 640;
                                height = 960;
                                break;
                            case "default-568@2x.png.tmp":
                                width = 640;
                                height = 1096;
                                break;
                            case "favicon-180.png.tmp":
                                width = 180;
                                height = 180;
                                break;
                            case "retinahd_icon.png.tmp":
                                width = 180;
                                height = 180;
                                break;
                            case "default-iphone6@2x.png.tmp":
                                width = 750;
                                height = 1294;
                                break;
                            case "default-iphone6plus@2x.png.tmp":
                                width = 1242;
                                height = 2148;
                                break;
                            case "default-iphone6-landscape@2x.png.tmp":
                                width = 1334;
                                height = 710;
                                break;
                            case "default-iphone6plus-landscape@2x.png.tmp":
                                width = 2208;
                                height = 1182;
                                break;
                            case "default-ipad@2x.png.tmp":
                                width = 1536;
                                height = 2008;
                                break;
                            case "default-ipad-landscape@2x.png.tmp":
                                width = 2048;
                                height = 1496;
                                break;
                            case "apple-touch-icon-120x120-precomposed.png.tmp":
                                width = 120;
                                height = 120;
                                break;
                            case "apple-touch-icon-76x76-precomposed.png.tmp":
                                width = 76;
                                height = 76;
                                break;
                            case "apple-touch-icon-152x152-precomposed.png.tmp":
                                width = 152;
                                height = 152;
                                break;
                            default:
                                break;
                        }
                        if (width > 0 && height > 0)
                        {
                            fs.Position = 0;
                            using (Bitmap bitmap = new Bitmap(fs))
                            {
                                if (bitmap.Width != width || bitmap.Height != height)
                                {
                                    fs.Close();
                                    fs.Dispose();
                                    global::System.IO.File.Delete(dest);
                                    string msg = string.Format("Error! The dimensions of uploaded [{0}] are {1}px X {2}px, which does not match the specification ( {3}px X {4}px )."
                                        , Path.GetFileNameWithoutExtension(dest)
                                        , bitmap.Width
                                        , bitmap.Height
                                        , width
                                        , height
                                        );
                                    throw new Exception(msg);
                                }
                            }
                        }
                    }
                }

                if (completed)
                {
                    string newFilename = Regex.Replace(dest, @"(\.tmp)$", string.Empty);

                    string relativePath = "/.config/site_files.setting";
                    string name = new global::System.IO.FileInfo(newFilename).Name;
                    string distinctName = newFilename.Substring(newFilename.IndexOf("\\Views\\", StringComparison.InvariantCultureIgnoreCase) + "\\Views\\".Length);
                    distinctName = distinctName.Substring(0, distinctName.IndexOf("\\"));

                    cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                    if (global::System.IO.File.Exists(newFilename))
                    {
                        Revisions.BackupIfNotExists(site, newFilename, relativePath, name);
                        global::System.IO.File.Delete(newFilename);
                    }

                    global::System.IO.File.Move(dest, newFilename);

                    Revisions.Backup(site, newFilename, relativePath, name);
                }

                return this.Content("OK");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Content(ex.Message);
            }
        }

        [HttpPost]
        public JsonResult SaveHostNames(string distinctName)
        {
            using (DbManager dbManager = new DbManager())
            {
                try
                {
                    distinctName = distinctName.DefaultDecrypt();
                    cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                    string relativePath = "/.config/site_hostname.setting";
                    string name = "Host Name";

                    HostAccessor ha = DataAccessor.CreateInstance<HostAccessor>(dbManager);
                    Dictionary<string, string> oldHosts = ha.GetBySiteID(site.ID).ToDictionary(h => h.HostName, h => h.DefaultCulture);

                    Revisions.BackupIfNotExists<Dictionary<string, string>>(site, oldHosts, relativePath, name);

                    dbManager.BeginTransaction();

                    ha.RemoveBySiteID(site.ID);

                    SqlQuery<cmHost> query = new SqlQuery<cmHost>(dbManager);

                    int total = int.Parse(Request.Form["total"]);
                    for (int i = 0; i < total; i++)
                    {
                        string hostname = Request.Form[string.Format("HostName_{0}", i)].Trim();
                        string language = Request.Form[string.Format("Language_{0}", i)].Trim();
                        if (string.IsNullOrEmpty(hostname))
                            continue;

                        cmHost host = new cmHost();
                        host.DefaultCulture = language;
                        host.HostName = hostname;
                        host.SiteID = site.ID;
                        query.Insert(host);
                    }

                    dbManager.CommitTransaction();

                    Dictionary<string, string> newHosts = ha.GetBySiteID(site.ID).ToDictionary(h => h.HostName, h => h.DefaultCulture);
                    Revisions.Backup<Dictionary<string, string>>(site, newHosts, relativePath, name);

                    site.ReloadCache(Request.RequestContext, CacheManager.CacheType.DomainCache);

                    return this.Json(new { @success = true });
                }
                catch (Exception ex)
                {
                    dbManager.RollbackTransaction();
                    Logger.Exception(ex);
                    return this.Json(new { @success = false, @error = ex.Message });
                }
            }
        }
        [HttpPost]
        public JsonResult SaveDomainControl(string distinctName, bool isDomainRestrictedMode, string MainDomainName, string[] EnabledDomains, string[] DisabledDomains)
        {
            try
            {
                if (!CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                {
                    return this.Json(new { @success = false, @error = "No permission" }, JsonRequestBehavior.AllowGet);
                }
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
                SiteRestrictDomainRule rule = new SiteRestrictDomainRule()
                {
                    IsDomainRestrictedMode = isDomainRestrictedMode,
                    MainDomainName = MainDomainName,
                };
                List<string> list = new List<string>();
                if (EnabledDomains != null)
                {
                    foreach (string enabledDomain in EnabledDomains)
                    {
                        list.Add(enabledDomain.ToLower());
                    }
                }
                if (list.Count > 0) { rule.EnabledDomainList = list; }
                list = new List<string>();
                if (DisabledDomains != null)
                {
                    foreach (string disabledDomains in DisabledDomains)
                    {
                        list.Add(disabledDomains.ToLower());
                    }
                }
                if (list.Count > 0) { rule.DisabledDomainList = list; }
                rule.Save(site, rule);
                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }
        [HttpPost]
        public JsonResult SaveAccessControl(string distinctName, SiteAccessRule.AccessModeType accessMode, int softLaunchNumber, string[] ipAddresses, string blockedMessage)
        {
            try
            {
                if (!CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                {
                    return this.Json(new { @success = false, @error = "No permission" }, JsonRequestBehavior.AllowGet);
                }
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                SiteAccessRule rule = SiteAccessRule.Get(site, false);
                //rule.IsWhitelistMode = isWhitelistMode;
                rule.AccessMode = accessMode;
                rule.SoftLaunchNumber = softLaunchNumber;
                rule.BlockedMessage = blockedMessage;
                rule.IPAddresses.Clear();
                if (ipAddresses != null)
                {
                    foreach (string ipAddress in ipAddresses)
                    {
                        rule.IPAddresses.Add(ipAddress, ipAddress);
                    }
                }
                rule.Save(site, rule);

                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        public JsonResult SaveCDNAccessControl(string distinctName, string[] ipAddresses)
        {
            try
            {
                if (!CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                {
                    return this.Json(new { @success = false, @error = "No permission" }, JsonRequestBehavior.AllowGet);
                }
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                SiteCDNAccessRule rule = new SiteCDNAccessRule();
                if (ipAddresses != null)
                {
                    foreach (string ipAddress in ipAddresses)
                    {
                        rule.IPAddresses.Add(ipAddress, ipAddress);
                    }
                }
                rule.Save(site, rule);

                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);

                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
        private string GetSupportedCountryHtml(string distinctName, cmSite site)
        {
            StringBuilder html = new StringBuilder();
            SiteAccessRule rule = SiteAccessRule.Get(site, false);
            Finance.CountryList countryList = new Finance.CountryList();
            countryList.Type = Finance.CountryList.FilterType.Exclude;
            try
            {
                countryList.List = rule.CountriesList;
                countryList.Type = rule.CountriesFilterType == SiteAccessRule.FilterType.Include ? Finance.CountryList.FilterType.Include : Finance.CountryList.FilterType.Exclude;
            }
            catch (Exception ex)
            {
                countryList = new Finance.CountryList();
                countryList.Type = Finance.CountryList.FilterType.Exclude;
                Logger.Exception(ex);
            }
            html.Append(FormatCountryList(distinctName, countryList).SafeHtmlEncode());

            return html.ToString();
        }

        private string FormatCountryList(string distinctName, Finance.CountryList countryList)
        {
            List<CountryInfo> countries = CountryManager.GetAllCountries(distinctName);

            StringBuilder text = new StringBuilder();
            if (countryList.Type == Finance.CountryList.FilterType.Exclude)
            {
                if (countryList.List == null ||
                    countryList.List.Count == 0)
                {
                    text.Append("All");
                }
                else
                {
                    text.Append("Exclude ");
                }
            }
            else
            {
                if (countryList.List == null ||
                    countryList.List.Count == 0)
                {
                    text.Append("None");
                }
            }

            if (countryList.List != null)
            {
                foreach (int countryID in countryList.List)
                {
                    CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
                    if (country != null)
                        text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", country.EnglishName);
                }
                if (text.Length > 0)
                    text.Remove(text.Length - 1, 1);
            }
            return text.ToString();
        }
        [HttpGet]
        public JsonResult LoadSupportedCountries(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
                string html = GetSupportedCountryHtml(distinctName, site);
                return this.Json(new { @success = true, @html = html }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
        [HttpGet]
        public JsonResult ClearMetadataCache(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                site.ReloadCache(Request.RequestContext, CacheManager.CacheType.MetadataCache);

                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public ActionResult SupportedCountry(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            SiteAccessRule rule = SiteAccessRule.Get(site, false);
            Finance.CountryList countryList = new Finance.CountryList();
            try
            {
                countryList.Type = rule.CountriesFilterType == SiteAccessRule.FilterType.Exclude ? Finance.CountryList.FilterType.Exclude : Finance.CountryList.FilterType.Include;
                countryList.List = rule.CountriesList;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                countryList = new Finance.CountryList();
                countryList.Type = Finance.CountryList.FilterType.Exclude;
            }

            this.ViewData["CountryList"] = countryList;
            return this.View("SupportedCountry", site);
        }

        [HttpPost]
        public JsonResult SaveSupportedCountry(string distinctName, Finance.CountryList.FilterType filterType, List<int> list)
        {

            try
            {
                if (!CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                {
                    return this.Json(new { @success = false, @error = "No permission" });
                }
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
                SiteAccessRule rule = SiteAccessRule.Get(site, false);
                rule.CountriesFilterType = filterType == Finance.CountryList.FilterType.Exclude ? SiteAccessRule.FilterType.Exclude : SiteAccessRule.FilterType.Include;
                rule.CountriesList = list;

                rule.Save(site, rule);

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetHostMapping(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);

            HostAccessor ha = DataAccessor.CreateInstance<HostAccessor>();
            var hosts = ha.GetBySiteID(site.ID).Select(h => h.HostName).ToArray();
            var hostMapping = SiteHostMapping.Get(distinctName, false);

            var results = hosts.Select(h => new
            {
                HostName = h,
                MappingHostName = hostMapping.ContainsKey(h) ? hostMapping[h] : string.Empty,
            }).ToArray();

            return this.Json(new
            {
                @success = true,
                @hostMapping = results
            }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult SaveHostMapping(string distinctName)
        {
            using (DbManager dbManager = new DbManager())
            {
                try
                {
                    distinctName = distinctName.DefaultDecrypt();
                    cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                    Dictionary<string, string> hostMapping = new Dictionary<string, string>();
                    int total = int.Parse(Request.Form["total"]);
                    for (int i = 0; i < total; i++)
                    {
                        string hostname = Request.Form[string.Format("HostName_{0}", i)].Trim();
                        string mappingHostname = Request.Form[string.Format("MappingHostName_{0}", i)].Trim();
                        if (string.IsNullOrEmpty(hostname) || string.IsNullOrEmpty(mappingHostname))
                            continue;

                        if (hostMapping.ContainsKey(hostname))
                            continue;

                        hostMapping.Add(hostname, mappingHostname);
                    }

                    SiteHostMapping.Save(site, hostMapping);

                    return this.Json(new { @success = true });
                }
                catch (Exception ex)
                {
                    dbManager.RollbackTransaction();
                    Logger.Exception(ex);
                    return this.Json(new { @success = false, @error = ex.Message });
                }
            }
        }

        [HttpPost]
        public JsonResult SearchChangeFiles(string distinctName, string relationPath, DateTime startTime, DateTime endTime, int pageSize)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relationPath = string.Format("%{0}%", relationPath);

                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                List<cmRevision> changeFiles = ra.GetChangeFiles(site.ID, relationPath, startTime, endTime, pageSize);

                return this.Json(new
                {
                    @success = true,
                    @changeFiles = changeFiles.Select(cf => new
                        {
                            Path = cf.RelativePath,
                            LastModifyTime = cf.Ins.ToString("dd/MM/yyyy HH:mm:ss"),
                            LastModifyUsername = cf.Username,
                            RelativePath = GetRelativePath(cf.RelativePath),
                            SearchPattner = GetSearchPattner(cf.RelativePath),
                        }).ToArray()
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        private string GetRelativePath(string relativePath)
        {
            try
            {

                string last = relativePath.Substring(relativePath.LastIndexOf("/"));
                if (last.StartsWith("/.", StringComparison.InvariantCultureIgnoreCase))
                    return relativePath.Substring(0, relativePath.LastIndexOf("/")).DefaultEncrypt();

                return relativePath.DefaultEncrypt();
            }
            catch
            {
                return relativePath.DefaultEncrypt();
            }
        }

        private string GetSearchPattner(string relativePath)
        {
            try
            {
                string last = relativePath.Substring(relativePath.LastIndexOf("/"));
                if (last.StartsWith("/.", StringComparison.InvariantCultureIgnoreCase))
                    return last;

                return string.Empty;
            }
            catch
            {
                return string.Empty;
            }
        }

        [HttpPost]
        public JsonResult SearchChanges(string distinctName, DateTime time)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                List<cmRevision> changes = ra.GetChanges(site.ID, time);

                return this.Json(new
                {
                    @success = true,
                    @changes = changes.Select(c => new
                    {
                        ID = c.ID,
                        Path = c.RelativePath,
                        LastModifyTime = c.Ins.ToString("dd/MM/yyyy HH:mm:ss"),
                        LastModifyUsername = c.Username,
                    }).ToArray()
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        public JsonResult Rollback(string distinctName, DateTime time)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                RollbackTaskInfo info;
                if (!s_RollbackTasks.TryGetValue(distinctName, out info))
                    info = null;

                if (info != null)
                {
                    if (!info.IsCompleted)
                        throw new Exception("Rollback is running.");
                    else
                        s_RollbackTasks.Remove(distinctName);
                }

                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                info = new RollbackTaskInfo()
                {
                    UserID = CustomProfile.Current.UserID,
                    Site = site,
                    Time = time,
                };
                s_RollbackTasks[distinctName] = info;

                Task.Factory.StartNew(() => RollbackProcess(info));

                return this.Json(new
                {
                    @success = true,
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        private static void RollbackProcess(RollbackTaskInfo info)
        {
            RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
            List<cmRevision> changes = ra.GetChanges(info.Site.ID, info.Time);

            //get the paths need to be rollbacked
            var relativePaths = changes.OrderBy(c => c.RelativePath).Select(c => c.RelativePath).Distinct().ToList();

            foreach (var relativePath in relativePaths)
            {
                RollbackResult result = new RollbackResult()
                {
                    RelativePath = relativePath,
                };

                try
                {
                    //find all revisions for the special path
                    var revisions = ra.GetLastRevisions(info.Site.ID, relativePath);
                    //find the revision need to be rollback
                    var revision = revisions.FirstOrDefault(r => r.Ins <= info.Time);

                    if (revisions == null)
                        throw new Exception("No revision to rollback");

                    Revisions.RollbackRevision(revision.ID, info.UserID);
                    result.RollbackTo = string.Format("Rollback to {0}", revision.Ins.ToString("dd/MM/yyyy HH:mm:ss"));
                }
                catch (Exception ex)
                {
                    result.RollbackTo = "Can't rollback";
                    result.Error = ex.Message;
                }

                info.ResultQueue.Enqueue(result);
            }

            info.IsCompleted = true;
            info.AutoResetEvent.Set();
        }

        [HttpGet]
        public ActionResult GetRollbackResult(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();

            RollbackTaskInfo info;
            s_RollbackTasks.TryGetValue(distinctName, out info);
            
            if (info == null)
                return this.Json(new { @success = false, @error = "Error, cannot the special task." }, JsonRequestBehavior.AllowGet);

            if (!info.IsCompleted)
                info.AutoResetEvent.WaitOne(2000);

            List<RollbackResult> results = new List<RollbackResult>();
            RollbackResult result = null;
            while (info.ResultQueue.TryDequeue(out result))
            {
                results.Add(result);
            }

            if (info.IsCompleted)
                s_RollbackTasks.Remove(distinctName);

            return this.Json(new { @success = true, @isCompleted = info.IsCompleted, @results = results.ToArray() }, JsonRequestBehavior.AllowGet);
        }        
    }
}
