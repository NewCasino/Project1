using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Xml.Linq;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;
using Finance;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Dialog", ParameterUrl = "{distinctName}/{path}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class HistoryViewerController : ControllerEx
    {
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Dialog(string distinctName, string relativePath, string searchPattner)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (relativePath.StartsWith("/.config/", StringComparison.InvariantCultureIgnoreCase))
                {
                    string physicalPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/", distinctName)).TrimEnd('\\');
                    node = new ContentNode(contentTree, physicalPath, relativePath);
                }
                else
                {
                    if (!contentTree.AllNodes.TryGetValue(relativePath, out node))
                    {
                        return View("InvalidPath");
                        //throw new Exception("Error, invalid parameter [relativePath].");
                    }
                }
                this.ViewData["HistorySearchPattner"] = searchPattner;
                this.ViewData["Title"] = string.Format("Revisions - {0}", relativePath);
                return View("Dialog", node);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetRevisions(string distinctName, string relativePath, string searchPattner)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                if (relativePath == "/" && searchPattner.StartsWith("/"))
                {
                    var revisions = ra.GetLastRevisions(site.ID, searchPattner)
                    .Where(r => !r.RelativePath.StartsWith("/.config/")).Select(r => new
                    {
                        ID = r.ID.ToString(),
                        Ins = r.Ins.ToString("dd/MM/yyyy HH:mm:ss"),
                        Username = r.Username,
                        Comments = r.Comments,
                        ViewCss = !string.IsNullOrWhiteSpace(r.FilePath) ? "block" : "hidden",
                        RollbackCss = (!string.IsNullOrWhiteSpace(r.FilePath) && !relativePath.StartsWith("/.config/", StringComparison.InvariantCultureIgnoreCase)) ? "block" : "hidden",
                        SeperatorCss = (!string.IsNullOrWhiteSpace(r.FilePath) && !string.IsNullOrWhiteSpace(r.FilePath) && !relativePath.StartsWith("/.config/", StringComparison.InvariantCultureIgnoreCase)) ? "block" : "hidden"
                    }).ToArray();

                    return this.Json(new { @success = true, @revisions = revisions }, JsonRequestBehavior.AllowGet);
                }
                else
                {
                    var revisions = ra.GetLastRevisions(site.ID, relativePath + searchPattner).Select(r => new
                    {
                        ID = r.ID.ToString(),
                        Ins = r.Ins.ToString("dd/MM/yyyy HH:mm:ss"),
                        Username = r.Username,
                        Comments = r.Comments,
                        ViewCss = !string.IsNullOrWhiteSpace(r.FilePath) ? "block" : "hidden",
                        RollbackCss = (!string.IsNullOrWhiteSpace(r.FilePath) && !relativePath.StartsWith("/.config/", StringComparison.InvariantCultureIgnoreCase)) ? "block" : "hidden",
                        SeperatorCss = (!string.IsNullOrWhiteSpace(r.FilePath) && !string.IsNullOrWhiteSpace(r.FilePath) && !relativePath.StartsWith("/.config/", StringComparison.InvariantCultureIgnoreCase)) ? "block" : "hidden"
                    }).ToArray();

                    return this.Json(new { @success = true, @revisions = revisions }, JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetOverrides(string distinctName, string relativePath)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();
                string relativeFilePath = relativePath.Replace('/', '\\');

                string physicalPath = HostingEnvironment.MapPath(string.Format("~/Views/")).TrimEnd('\\');
                var operatorDirsList = Directory.GetDirectories(physicalPath);

                SiteAccessor ua = DataAccessor.CreateInstance<SiteAccessor>();
                List<cmSite> sites = ua.GetAll().Where(s => s.TemplateDomainDistinctName == distinctName).OrderBy(d => d.DisplayName).ToList();

                List<cmSite> result = new List<cmSite>();
                foreach (var operatorDir in operatorDirsList)
                {
                    var exists = global::System.IO.File.Exists(operatorDir + relativeFilePath);
                    if (exists && !operatorDir.EndsWith(distinctName))
                    {
                        var operatorSite = sites.FirstOrDefault(s => s.DefaultTheme == operatorDir.Replace(physicalPath + "\\", ""));
                        if (operatorSite != null)
                            result.Add(operatorSite);
                    }
                }

                var overridesList = result.Select(r => new
                {
                    Operator = r.DisplayName,
                    OperatorTheme = r.DefaultTheme,
                    OperatorThemeEnc = r.DefaultTheme.DefaultEncrypt(),
                }).ToArray();
                return this.Json(new { @success = true, @overrides = overridesList }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult CodeView(int revisionID)
        {
            try
            {
                this.ViewData["Title"] = string.Format("Revision {0}", revisionID);

                var revision = Revisions.GetRevisionByID(revisionID);
                if (revision == null)
                    throw new Exception("Error, can't find the revision.");

                string file = Revisions.GetBaseDirectory() + revision.FilePath;
                if (string.IsNullOrEmpty(file))
                    throw new Exception("Error, can't find the file.");

                if (revision.RelativePath.StartsWith("/.config/"))
                {
                    this.ViewData["FileContent"] = GetConfigContent(revision);
                }
                else if (revision.RelativePath.StartsWith("/.changes/"))
                {
                    this.ViewData["FileContent"] = GetChangesContent(revision);
                }
                else
                {
                    string content = WinFileIO.ReadWithoutLock(file);
                    if (content == null)
                    {
                        throw new Exception("Error, can't find the file.");
                    }
                    else
                    {
                        this.ViewData["FileContent"] = content;
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["FileContent"] = ex.Message;
            }
            return View("CodeView");
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Rollback(string revisionID)
        {
            try
            {
                Revisions.RollbackRevision(int.Parse(revisionID));

                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        private string GetComparisonUrl(string srcFile, string destFile)
        {
            if (!global::System.IO.File.Exists(srcFile) ||
                !global::System.IO.File.Exists(destFile))
            {
                throw new Exception("Error, can't locate the file.");
            }

            string url = Url.RouteUrl("FileDiff", new { @Action = "CompareFiles", src = srcFile.DefaultEncrypt(), dest = destFile.DefaultEncrypt() });
            return url;
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult CompareRevisions(int srcRevID, int destRevID)
        {
            try
            {
                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                cmRevision srcRevision = ra.GetByID(srcRevID);
                cmRevision destRevision = ra.GetByID(destRevID);
                if (srcRevision == null || destRevision == null)
                    throw new Exception("Error, can't locate the revision.");

                string srcFile = Revisions.GetBaseDirectory() + srcRevision.FilePath;
                string destFile = Revisions.GetBaseDirectory() + destRevision.FilePath;

                if (srcRevision.RelativePath.StartsWith("/.config/"))
                    srcFile = SaveToTempFile(GetConfigContent(srcRevision));

                if (destRevision.RelativePath.StartsWith("/.config/"))
                    destFile = SaveToTempFile(GetConfigContent(destRevision));

                return this.Redirect(GetComparisonUrl(srcFile, destFile));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return Content(ex.Message);
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult ShowChanges(int srcRevID, int destRevID)
        {
            try
            {
                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                cmRevision srcRevision = ra.GetByID(srcRevID);
                cmRevision destRevision = ra.GetByID(destRevID);
                if (srcRevision == null || destRevision == null)
                    throw new Exception("Error, can't locate the revision.");

                string srcFile = Revisions.GetBaseDirectory() + srcRevision.FilePath;
                string destFile = Revisions.GetBaseDirectory() + destRevision.FilePath;

                if (srcRevision.RelativePath.StartsWith("/.config/"))
                    srcFile = SaveToTempFile(GetConfigContent(srcRevision));

                if (destRevision.RelativePath.StartsWith("/.config/"))
                    destFile = SaveToTempFile(GetConfigContent(destRevision));

                string srcText = WinFileIO.ReadWithoutLock(srcFile);
                string destText = WinFileIO.ReadWithoutLock(destFile);
                Infrastructure.DiffEngine.ShowChanges a = new Infrastructure.DiffEngine.ShowChanges();
                string changText = a.ShowTextChanges(srcText, destText);
                if (string.IsNullOrWhiteSpace(changText))
                {
                    changText = "No changes";
                }
                this.ViewData["ChangeContent"] = changText;
                return View("CountryChanges");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return Content(ex.Message);
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult CompareOverrides(string srcDistinctName, string destDistinctName, string relativePath)
        {
            try
            {
                srcDistinctName = srcDistinctName.DefaultDecrypt();
                destDistinctName = destDistinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                string srcFile = HostingEnvironment.MapPath(string.Format("~/Views/{0}{1}", srcDistinctName, relativePath));
                string destFile = HostingEnvironment.MapPath(string.Format("~/Views/{0}{1}", destDistinctName, relativePath));
                return this.Redirect(GetComparisonUrl(srcFile, destFile));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return Content(ex.Message);
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult CompareWithTemplate(string distinctName, string relativePath, int revisionID = -1)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(relativePath, out node))
                    throw new Exception("Error, invalid parameter [relativePath].");

                if (node.NodeStatus != ContentNode.ContentNodeStatus.Overrode)
                    throw new Exception("Error, invalid node status.");

                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();

                string srcFile = Server.MapPath(string.Format("~/Views/{0}{1}", domain.TemplateDomainDistinctName, node.RelativePath));
                string destFile = Server.MapPath(string.Format("~/Views/{0}{1}", distinctName, node.RelativePath));
                if (revisionID != -1)
                {
                    cmRevision revision = ra.GetByID(revisionID);
                    if (revision == null)
                        throw new Exception("Error, can't locate the revision.");
                    destFile = Revisions.GetBaseDirectory() + revision.FilePath;
                }

                return this.Redirect(GetComparisonUrl(srcFile, destFile));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return Content(ex.Message);
            }
        }

        private string GetConfigContent(cmRevision revision)
        {
            cmSite domain = SiteManager.GetSites().FirstOrDefault(s => s.ID == revision.SiteID);
            switch (revision.RelativePath)
            {
                case "/.config/site_domain_access_rule.setting":
                    return GetSiteDomainAccessContent(revision);
                case "/.config/site_properties.setting":
                    return GetSitePropertiesContent(revision);
                case "/.config/site_hostname.setting":
                    return GetSiteHostNameContent(revision);
                case "/.config/site_files.setting":
                    return GetSiteFilesContent(revision);
                case "/.config/site_access_rule.setting":
                    return GetSiteAccessControlContent(revision);
                case "/.config/site_cdn_access_rule.setting":
                    return GetSiteCDNAccessControlContent(revision);
                case "/.config/site_host_mapping.setting":
                    return GetSiteHostMappingContent(revision);

                case "/.config/http_redirection.setting":
                    return GetHttpRedirectionContent(revision);
                case "/.config/url_rewrite.setting":
                    return GetUrlRewrittingContent(revision);

                case "/.config/languages.setting":
                    return GetLanguagesContent(revision);
                case "/.config/countries.setting":
                    return GetCountriesContent(revision);

                case "/.config/game_category.xml":
                    return GetCasinoCategoriesContent(revision);
                case "/.config/live_casino_category.xml":
                    return GetLiveCasinoTablesContent(revision);

                case "/.config/PaymentMethods.Ordinal":
                    return GetPaymentMethodsOrdinalContent(domain, revision);
                case "/.config/PaymentMethods.Visibility":
                    return GetPaymentMethodsVisibilityContent(domain, revision);
                case "/.config/PaymentMethods.FallbackVisibility":
                    return GetPaymentMethodsFallbackVisibilityContent(domain, revision);
                case "/.config/PaymentMethods.FallbackMode":
                    return GetPaymentMethodsFallbackModeContent(revision);
                case "/.config/BankWithdrawalConfiguration":
                    return GetBankWithdrawalConfigurationContent(domain, revision);

                default:
                    if (revision.RelativePath.StartsWith("/.config/operator/"))
                    {
                        return GetOperatorUpdateContent(revision);
                    }
                    else
                    {
                        //   /.config/PT_VISA.CountryList
                        string item = revision.RelativePath.Substring(revision.RelativePath.LastIndexOf("/") + 1);
                        var paymentMethod = GetPaymentMethod(domain, item);
                        return paymentMethod == null ? string.Empty : GetPaymentMethodContent(domain, revision);
                    }
            }
        }

        private string GetChangesContent(cmRevision revision)
        {
            return string.Empty;
        }

        private string SaveToTempFile(string fileContent)
        {
            string dir = string.Format("~/temp/{0:0000}{1:00}{2:00}{3:00}/"
                , DateTime.Now.Year
                , DateTime.Now.Month
                , DateTime.Now.Day
                , DateTime.Now.Hour
                );

            string path = this.Server.MapPath(dir);
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            string tempFile = string.Format("{0}\\{1}_{2}.temp"
                , path.TrimEnd('\\')
                , fileContent.DefaultIfNullOrEmpty(string.Empty).GetHashCode()
                , Guid.NewGuid().ToString("N")
                );

            using (StreamWriter sw = new StreamWriter(tempFile, false, Encoding.UTF8))
            {
                sw.Write(fileContent);
                sw.Flush();
            }

            return tempFile;
        }

        #region Payment Methods Manager
        private string GetPaymentMethodsOrdinalContent(cmSite domain, cmRevision revision)
        {
            PaymentMethodCategory[] categories = PaymentMethodManager.GetCategories(domain, "en");
            PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods(domain).ToArray();
            Dictionary<string, int> ordinalDictionary = PaymentMethodManager.TryDeserialize<Dictionary<string, int>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<string, int>());
            foreach (PaymentMethod paymentMethod in paymentMethods)
            {
                int ordinal;
                if (ordinalDictionary.TryGetValue(paymentMethod.UniqueName, out ordinal))
                    paymentMethod.Ordinal = ordinal;
            }

            StringBuilder sb = new StringBuilder();
            foreach (PaymentMethodCategory category in categories)
            {
                sb.AppendLine(category.GetDisplayName(domain, "en"));
                sb.AppendLine("");

                foreach (PaymentMethod paymentMethod in paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal))
                {
                    sb.AppendLine(paymentMethod.UniqueName);
                }

                sb.AppendLine("");
                sb.AppendLine("");
            }

            return sb.ToString();
        }

        private string GetPaymentMethodsVisibilityContent(cmSite domain, cmRevision revision)
        {
            PaymentMethodCategory[] categories = PaymentMethodManager.GetCategories(domain, "en");
            PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods(domain).ToArray();
            Dictionary<string, bool> visibilityDictionary = PaymentMethodManager.TryDeserialize<Dictionary<string, bool>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<string, bool>());
            foreach (PaymentMethod paymentMethod in paymentMethods)
            {
                bool visible;
                if (visibilityDictionary.TryGetValue(paymentMethod.UniqueName, out visible))
                    paymentMethod.IsVisible = visible;
            }

            StringBuilder sb = new StringBuilder();
            foreach (PaymentMethodCategory category in categories)
            {
                sb.AppendLine(category.GetDisplayName(domain, "en"));
                sb.AppendLine("");

                foreach (PaymentMethod paymentMethod in paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal))
                {
                    sb.AppendLine(string.Format("{0}: {1}", paymentMethod.UniqueName, paymentMethod.IsVisible ? "Shown" : "Hidden"));
                }

                sb.AppendLine("");
                sb.AppendLine("");
            }

            return sb.ToString();
        }

        private string GetPaymentMethodsFallbackVisibilityContent(cmSite domain, cmRevision revision)
        {
            PaymentMethodCategory[] categories = PaymentMethodManager.GetCategories(domain, "en");
            PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods(domain).ToArray();
            Dictionary<string, bool> fallbackVisibilityDictionary = PaymentMethodManager.TryDeserialize<Dictionary<string, bool>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<string, bool>());
            foreach (PaymentMethod paymentMethod in paymentMethods)
            {
                bool fallbackVisible;
                if (fallbackVisibilityDictionary.TryGetValue(paymentMethod.UniqueName, out fallbackVisible))
                    paymentMethod.IsVisibleDuringFallback = fallbackVisible;
            }

            StringBuilder sb = new StringBuilder();
            foreach (PaymentMethodCategory category in categories)
            {
                sb.AppendLine(category.GetDisplayName(domain, "en"));
                sb.AppendLine("");

                foreach (PaymentMethod paymentMethod in paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal))
                {
                    sb.AppendLine(string.Format("{0}: {1}", paymentMethod.UniqueName, paymentMethod.IsVisibleDuringFallback ? "Shown" : "Hidden"));
                }

                sb.AppendLine("");
                sb.AppendLine("");
            }

            return sb.ToString();
        }

        private string GetPaymentMethodsFallbackModeContent(cmRevision revision)
        {
            var domain = SiteManager.GetSiteByDistinctName("Shared");

            var fallbackMode = PaymentMethodManager.TryDeserialize(domain, Revisions.GetBaseDirectory() + revision.FilePath, false);

            var sb = new StringBuilder();

            sb.AppendLine("Fallback Mode");
            sb.AppendLine("");
            sb.AppendLine(fallbackMode ? "Enabled" : "Disabled");
            sb.AppendLine("");

            return sb.ToString();
        }

        private string GetBankWithdrawalConfigurationContent(cmSite domain, cmRevision revision)
        {
            Dictionary<long, BankWithdrawalCountryConfig> configDictionary = PaymentMethodManager.TryDeserialize<Dictionary<long, BankWithdrawalCountryConfig>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<long, BankWithdrawalCountryConfig>());

            List<CountryInfo> countries = CountryManager.GetAllCountries(domain.DistinctName).Where(c => c.InternalID > 0).ToList();

            StringBuilder sb = new StringBuilder();
            foreach (CountryInfo country in countries)
            {
                BankWithdrawalCountryConfig config;
                if (!configDictionary.TryGetValue(country.InternalID, out config))
                    continue;

                sb.AppendLine(string.Format("{0}: {1}", country.EnglishName, config.Type.ToString()));
            }
            return sb.ToString();
        }

        private PaymentMethod GetPaymentMethod(cmSite domain, string item)
        {
            var paymentMethods = PaymentMethodManager.GetPaymentMethods(domain);
            foreach (var paymentMethod in paymentMethods)
            {
                if (item.StartsWith(paymentMethod.UniqueName + "."))
                    return paymentMethod;
            }
            return null;
        }

        private string GetPaymentMethodContent(cmSite domain, cmRevision revision)
        {
            string name = revision.RelativePath.Substring(revision.RelativePath.LastIndexOf(".") + 1);
            switch (name)
            {
                case "CountryList":
                    {
                        var supportedCountries = PaymentMethodManager.TryDeserialize<CountryList>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new CountryList());
                        return FormatCountryList(domain, supportedCountries);
                    }

                case "CurrencyList":
                    {
                        var supportedCurrencies = PaymentMethodManager.TryDeserialize<CurrencyList>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new CurrencyList());
                        return FormatCurrencyList(supportedCurrencies);
                    }

                case "ProcessTime":
                    {
                        var processTime = PaymentMethodManager.TryDeserialize<ProcessTime>(domain, Revisions.GetBaseDirectory() + revision.FilePath, ProcessTime.Variable);
                        return processTime.ToString();
                    }

                case "DepositLimitations":
                    {
                        var depositLimitations = PaymentMethodManager.TryDeserialize<Dictionary<string, Range>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<string, Range>(StringComparer.InvariantCultureIgnoreCase));
                        return FormatLimitation(depositLimitations);
                    }

                case "WithdrawLimitations":
                    {
                        var withdrawLimitations = PaymentMethodManager.TryDeserialize<Dictionary<string, Range>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<string, Range>(StringComparer.InvariantCultureIgnoreCase));
                        return FormatLimitation(withdrawLimitations);
                    }

                case "DepositProcessFee":
                    {
                        var depositProcessFee = PaymentMethodManager.TryDeserialize<ProcessFee>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new ProcessFee() { ProcessFeeType = ProcessFeeType.Free });
                        return depositProcessFee.GetText("EUR");
                    }

                case "WithdrawProcessFee":
                    {
                        var withdrawProcessFee = PaymentMethodManager.TryDeserialize<ProcessFee>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new ProcessFee() { ProcessFeeType = ProcessFeeType.Free });
                        return withdrawProcessFee.GetText("EUR");
                    }

                case "SupportWithdraw":
                    {
                        var supportWithdraw = PaymentMethodManager.TryDeserialize<bool>(domain, Revisions.GetBaseDirectory() + revision.FilePath, true);
                        return supportWithdraw ? "Yes" : "No";
                    }

                case "WithdrawCountryList":
                    {
                        var withdrawCountryList = PaymentMethodManager.TryDeserialize<CountryList>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new CountryList());
                        return FormatCountryList(domain, withdrawCountryList);
                    }

                case "RepulsivePaymentMethods":
                    {
                        var repulsivePaymentMethods = PaymentMethodManager.TryDeserialize<List<string>>(domain, Revisions.GetBaseDirectory() + revision.FilePath, new List<string>());
                        return FormatList(repulsivePaymentMethods);
                    }
            }

            return null;
        }

        private string FormatCountryList(cmSite domain, CountryList countryList)
        {
            //List<CountryInfo> countries = CountryManager.GetAllCountries(domain.DistinctName);

            //StringBuilder text = new StringBuilder();
            //if (countryList.Type == CountryList.FilterType.Exclude)
            //{
            //    if (countryList.List == null ||
            //        countryList.List.Count == 0)
            //    {
            //        text.Append("All");
            //    }
            //    else
            //    {
            //        text.Append("Exclude ");
            //    }
            //}
            //else
            //{
            //    if (countryList.List == null ||
            //        countryList.List.Count == 0)
            //    {
            //        text.Append("None");
            //    }
            //}

            //if (countryList.List != null)
            //{
            //    foreach (int countryID in countryList.List)
            //    {
            //        CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
            //        if (country != null)
            //            text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", country.EnglishName);
            //    }
            //    if (text.Length > 0)
            //        text.Remove(text.Length - 1, 1);
            //}
            //return text.ToString();

            var countries = CountryManager.GetAllCountries(domain.DistinctName)
                                        .Select(c => new
                                        {
                                            Name = string.Format("{0} - {1}", c.ISO_3166_Alpha2Code, c.EnglishName),
                                            Value = c.InternalID
                                        }).ToList();
            StringBuilder sb = new StringBuilder();
            if (countryList.List == null)
            {
                if (countryList.Type == FilteredListBase<int>.FilterType.Exclude)
                    sb.AppendLine("All");
                else
                    sb.AppendLine("None");
            }
            else
            {
                if (countryList.Type == FilteredListBase<int>.FilterType.Exclude)
                    sb.AppendLine("Only the below country(s) are NOT supported for this payment method.");
                else
                    sb.AppendLine("Only the selected country(s) are supported for this payment method.");
                foreach (var countryID in countryList.List)
                {
                    var country = countries.FirstOrDefault(c => c.Value == countryID);
                    if (country != null)
                        sb.AppendLine(country.Name);
                }
            }
            return sb.ToString();
        }

        private string FormatCurrencyList(CurrencyList currencyList)
        {

            //StringBuilder text = new StringBuilder();
            //if (currencyList.Type == CurrencyList.FilterType.Exclude)
            //{
            //    if (currencyList.List == null ||
            //        currencyList.List.Count == 0)
            //    {
            //        text.Append("All");
            //    }
            //    else
            //    {
            //        text.Append("Exclude ");
            //    }
            //}
            //else
            //{
            //    if (currencyList.List == null ||
            //        currencyList.List.Count == 0)
            //    {
            //        text.Append("None");
            //    }
            //}

            //if (currencyList.List != null)
            //{
            //    foreach (string currency in currencyList.List)
            //    {
            //        text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", currency);
            //    }
            //    if (text.Length > 0)
            //        text.Remove(text.Length - 1, 1);
            //}
            //return text.ToString();

            var currencies = GmCore.GamMatrixClient.GetSupportedCurrencies()
                                         .Select(c => new
                                         {
                                             Name = string.Format("{0} - {1}", c.ISO4217_Alpha, c.Name),
                                             Value = c.ISO4217_Alpha
                                         }).ToList();
            StringBuilder sb = new StringBuilder();
            if (currencyList.List == null)
            {
                if (currencyList.Type == FilteredListBase<string>.FilterType.Exclude)
                    sb.AppendLine("All");
                else
                    sb.AppendLine("None");
            }
            else
            {
                if (currencyList.Type == FilteredListBase<string>.FilterType.Exclude)
                    sb.AppendLine("Only the selected currency(s) are NOT supported for this payment method.");
                else
                    sb.AppendLine("Only the selected currency(s) are supported for this payment method.");
                foreach (var currencyCode in currencyList.List)
                {
                    var currency = currencies.FirstOrDefault(c => c.Value == currencyCode);
                    if (currency != null)
                        sb.AppendLine(currency.Name);
                }
            }
            return sb.ToString();
        }

        private string FormatLimitation(Dictionary<string, Range> limitations)
        {
            StringBuilder sb = new StringBuilder();
            foreach (var limitation in limitations)
            {
                sb.AppendFormat("{0}:", limitation.Key);
                var range = limitation.Value;
                if (range.MinAmount > 0.00M)
                {
                    sb.AppendFormat(CultureInfo.InvariantCulture, " Min {0:N2},", range.MinAmount);
                }
                if (range.MaxAmount > 0.00M)
                {
                    sb.AppendFormat(CultureInfo.InvariantCulture, " Max {0:N2},", range.MaxAmount);
                }
                if (sb.Length > 0)
                    sb.Remove(sb.Length - 1, 1);
                else
                    sb.Append("Variable");
                sb.AppendLine("");
            }
            return sb.ToString();
        }

        private string FormatList(List<string> list)
        {
            if (list == null || list.Count == 0)
                return "None";

            StringBuilder html = new StringBuilder();
            foreach (string item in list)
            {
                html.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", item);
            }
            if (html.Length > 0)
                html.Remove(html.Length - 1, 1);
            return html.ToString();
        }
        #endregion


        #region Site Manager

        private string GetSiteDomainAccessContent(cmRevision revision)
        {
            SiteRestrictDomainRule srdr = ObjectHelper.BinaryDeserialize<SiteRestrictDomainRule>(Revisions.GetBaseDirectory() + revision.FilePath, new SiteRestrictDomainRule());

            //.BinaryDeserialize<SiteRestrictDomainRule>(revision, null);
            if (srdr == null)
                throw new Exception("Error, can't deserialize the Site Restrict Domain Rule file.");

            StringBuilder sb = new StringBuilder();

            sb.AppendLine(string.Format("Is Domain Restricted Mode: {0}", srdr.IsDomainRestrictedMode.ToString()));
            sb.AppendLine(string.Format("Main Domain Name: {0}", srdr.MainDomainName.ToString()));
            sb.AppendLine("Disabled Domain List:");
            for (int i = 0; i < srdr.DisabledDomainList.Count; i++)
            {
                sb.AppendLine(string.Format("     {0}", srdr.DisabledDomainList[i]));

            }
            sb.AppendLine("Enabled Domain List:");
            for (int i = 0; i < srdr.EnabledDomainList.Count; i++)
            {
                sb.AppendLine(string.Format("     {0}", srdr.EnabledDomainList[i]));

            }

            //sb.AppendLine(string.Format("Display name: {0}", site.DisplayName));
            //sb.AppendLine(string.Format("Default page: {0}", site.DefaultUrl));
            //sb.AppendLine(string.Format("Default language: {0}", site.DefaultCulture));

            return sb.ToString();
        }
        private string GetSitePropertiesContent(cmRevision revision)
        {
            cmSite site = Revisions.TryToDeserialize<cmSite>(revision, null);
            if (site == null)
                throw new Exception("Error, can't deserialize the file.");

            StringBuilder sb = new StringBuilder();

            sb.AppendLine(string.Format("Display name: {0}", site.DisplayName));
            sb.AppendLine(string.Format("Default page: {0}", site.DefaultUrl));
            sb.AppendLine(string.Format("Default language: {0}", site.DefaultCulture));

            return sb.ToString();
        }

        private string GetSiteHostNameContent(cmRevision revision)
        {
            Dictionary<string, string> hostNames = Revisions.TryToDeserialize<Dictionary<string, string>>(revision, new Dictionary<string, string>());

            StringBuilder sb = new StringBuilder();

            foreach (var hostName in hostNames)
            {
                sb.AppendLine(string.Format("{0}, Language: {1}", hostName.Key, hostName.Value));
            }

            return sb.ToString();
        }

        private string GetSiteFilesContent(cmRevision revision)
        {
            return WinFileIO.ReadWithoutLock(Revisions.GetBaseDirectory() + revision.FilePath);
        }

        private string GetSiteAccessControlContent(cmRevision revision)
        {
            SiteAccessRule rule = ObjectHelper.BinaryDeserialize<SiteAccessRule>(Revisions.GetBaseDirectory() + revision.FilePath, new SiteAccessRule());

            StringBuilder sb = new StringBuilder();

            if (rule.AccessMode == SiteAccessRule.AccessModeType.NotSet)
            {
                if (rule.IsWhitelistMode)
                    sb.AppendLine("Whitelist mode (restricted mode) -- only allow the following IP address(es) to access.");
                else
                    sb.AppendLine("Blacklist mode (live mode) -- only disallow the following IP address(es) to access.");
            }
            else
            {
                if (rule.AccessMode == SiteAccessRule.AccessModeType.Whitelist)
                    sb.AppendLine("Whitelist mode (restricted mode) -- only allow the following IP address(es) to access.");
                else if (rule.AccessMode == SiteAccessRule.AccessModeType.Blacklist)
                    sb.AppendLine("Blacklist mode (live mode) -- only disallow the following IP address(es) to access.");
                else
                    sb.AppendLine(string.Format("Soft-Launch, No: {0}", rule.SoftLaunchNumber));
            }

            sb.AppendLine("IP Address(es):");

            foreach (var ipAddress in rule.IPAddresses)
                sb.AppendLine("    " + ipAddress.Key);

            CountryList countryList = new CountryList();

            sb.AppendLine(string.Format("Country Filter Type: {0}", rule.CountriesFilterType.ToString()));
            countryList.Type = rule.CountriesFilterType == SiteAccessRule.FilterType.Include ? Finance.CountryList.FilterType.Include : Finance.CountryList.FilterType.Exclude;
            countryList.List = rule.CountriesList;

            List<CountryInfo> countries = CountryManager.GetAllCountries(revision.DomainDistinctName);
            sb.AppendLine("Selected Country(Countries):");
            if (countryList.List != null)
            {
                foreach (int countryID in countryList.List)
                {
                    CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
                    if (country != null)
                        sb.AppendLine("    " + country.EnglishName);
                }
            }

            sb.AppendLine(string.Format("Blocked Message: {0}", rule.BlockedMessage));

            return sb.ToString();
        }

        private string GetSiteCDNAccessControlContent(cmRevision revision)
        {
            SiteCDNAccessRule rule = ObjectHelper.BinaryDeserialize<SiteCDNAccessRule>(Revisions.GetBaseDirectory() + revision.FilePath, new SiteCDNAccessRule());

            StringBuilder sb = new StringBuilder();

            sb.AppendLine("IP Address(es):");

            foreach (var ipAddress in rule.IPAddresses)
                sb.AppendLine(ipAddress.Key);

            return sb.ToString();
        }

        private string GetSiteHostMappingContent(cmRevision revision)
        {
            Dictionary<string, string> mapping = ObjectHelper.BinaryDeserialize<Dictionary<string, string>>(Revisions.GetBaseDirectory() + revision.FilePath, new Dictionary<string, string>());

            StringBuilder sb = new StringBuilder();

            foreach (var key in mapping.Keys)
                sb.AppendLine(string.Format("{0} <<==>> {1}", key, mapping[key]));

            return sb.ToString();
        }
        #endregion

        #region Route Table
        private string GetHttpRedirectionContent(cmRevision revision)
        {
            Dictionary<string, string> rules = Revisions.TryToDeserialize<Dictionary<string, string>>(revision, new Dictionary<string, string>());

            StringBuilder sb = new StringBuilder();

            foreach (var rule in rules)
            {
                sb.AppendLine(string.Format("{0} >>> {1}", rule.Key, rule.Value));
            }

            return sb.ToString();
        }

        private string GetUrlRewrittingContent(cmRevision revision)
        {
            Dictionary<string, string> rules = Revisions.TryToDeserialize<Dictionary<string, string>>(revision, new Dictionary<string, string>());

            StringBuilder sb = new StringBuilder();

            foreach (var rule in rules)
            {
                sb.AppendLine(string.Format("{0} >>> {1}", rule.Key, rule.Value));
            }

            return sb.ToString();
        }
        #endregion

        #region Region / Language
        private string GetLanguagesContent(cmRevision revision)
        {
            Language[] languages = Revisions.TryToDeserialize<Language[]>(revision, null);

            if (languages == null)
                return string.Empty;

            var cultures = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
               .Where(r => Regex.IsMatch(r.Name, @"^([a-z]{2}(\-[a-z]{2})?)$", RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant))
               .OrderBy(r => r.DisplayName)
               .Select(r => new { @Name = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), @LanguageCode = r.Name.ToLowerInvariant(), r.NativeName })
               .ToArray();

            cmSite site = SiteManager.GetSites().FirstOrDefault(s => s.ID == revision.SiteID);
            var countries = CountryManager.GetAllCountries(site.DistinctName);

            StringBuilder sb = new StringBuilder();

            foreach (var language in languages)
            {
                var culture = cultures.FirstOrDefault(c => c.LanguageCode == language.LanguageCode);
                var temp = string.Empty;
                foreach (var countryID in language.CountryIds)
                {
                    var country = countries.FirstOrDefault(c => c.InternalID == countryID);
                    temp += (country == null ? countryID.ToString(CultureInfo.InvariantCulture) : country.EnglishName) + ",";
                }
                if (!string.IsNullOrWhiteSpace(temp))
                    temp = temp.Substring(0, temp.Length - 1);
                else
                    temp = "None";

                sb.AppendLine(string.Format("Language: {0}", culture == null ? language.LanguageCode : culture.Name));
                sb.AppendLine(string.Format("Display name: {0}", language.DisplayName));
                sb.AppendLine(string.Format("Countries: {0}", temp));
                sb.AppendLine(string.Format("Country flag: {0}", language.CountryFlagName));
                sb.AppendLine("");
            }

            return sb.ToString();
        }

        private string GetCountriesContent(cmRevision revision)
        {
            cmSite site = SiteManager.GetSites().FirstOrDefault(s => s.ID == revision.SiteID);
            var countries = CountryManager.GetAllCountries(site.DistinctName);

            #region Load overriding configration
            try
            {
                string path = Revisions.GetBaseDirectory() + revision.FilePath;
                if (global::System.IO.File.Exists(path))
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    Hashtable table = null;
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                    {
                        table = (Hashtable)bf.Deserialize(fs);
                    }

                    foreach (CountryInfo country in countries)
                    {
                        Hashtable innerTable = table[country.InternalID] as Hashtable;
                        if (innerTable != null)
                        {
                            foreach (DictionaryEntry entry in innerTable)
                            {
                                ObjectHelper.SetFieldValue(country, entry.Key as string, entry.Value);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            #endregion

            StringBuilder sb = new StringBuilder();

            foreach (var country in countries)
            {
                sb.AppendFormat("English name: {0}, ", country.EnglishName);
                sb.AppendFormat("Currency: {0}, ", country.CurrencyCode);
                sb.AppendFormat("Phone code: {0}, ", country.PhoneCode);
                sb.AppendFormat("Personal ID - Visible: {0}, ", country.IsPersonalIdVisible ? "Yes" : "No");
                if (country.IsPersonalIdVisible)
                {
                    sb.AppendFormat("Max length: {0}, ", country.PersonalIdMaxLength.ToString(CultureInfo.InvariantCulture));
                    sb.AppendFormat("Validation Regular Expression: {0}, ", country.PersonalIdValidationRegularExpression);
                }
                sb.AppendFormat("Personal ID - Required: {0}, ", country.IsPersonalIdMandatory ? "Yes" : "No");
                sb.AppendFormat("User selectable in form : {0}, ", country.UserSelectable ? "Yes" : "No");
                sb.AppendFormat("Restrict registration by IP : {0}, ", country.RestrictRegistrationByIP ? "Yes" : "No");
                sb.AppendFormat("Restrict login by IP : {0}, ", country.RestrictLoginByIP ? "Yes" : "No");
                sb.AppendFormat("Restrict CC Withdrawal : {0}, ", country.RestrictCreditCardWithdrawal ? "Yes" : "No");
                sb.AppendFormat("Admin lock: {0}", country.AdminLock ? "Yes" : "No");
                sb.AppendLine("");
            }

            return sb.ToString();
        }
        #endregion

        #region Casino Games
        private string GetCasinoCategoriesContent(cmRevision revision)
        {
            string xml = WinFileIO.ReadWithoutLock(Revisions.GetBaseDirectory() + revision.FilePath);
            XDocument xDoc = XDocument.Parse(xml);

            StringBuilder sb = new StringBuilder();

            var categoryNodes = xDoc.Element("root").Elements("node");
            foreach (XElement categoryNode in categoryNodes)
            {
                sb.AppendLine(categoryNode.Attribute("label").Value);
                var gameOrGroupNodes = categoryNode.Elements("node");
                foreach (XElement gameOrGroupNode in gameOrGroupNodes)
                {
                    if (gameOrGroupNode.Attribute("type").Value == "group")
                        sb.AppendLine(string.Format("|---{0}", gameOrGroupNode.Attribute("label").Value));
                    else
                        sb.AppendLine(string.Format("|---{0} ({1})", gameOrGroupNode.Attribute("label").Value, gameOrGroupNode.Attribute("platforms").Value));
                    var gameNodes = gameOrGroupNode.Elements("node");
                    foreach (XElement gameNode in gameNodes)
                    {
                        sb.AppendLine(string.Format("|-------{0} ({1})", gameNode.Attribute("label").Value, gameNode.Attribute("platforms").Value));
                    }
                }
                sb.AppendLine("");
            }

            return sb.ToString();
        }

        private string GetLiveCasinoTablesContent(cmRevision revision)
        {
            return GetCasinoCategoriesContent(revision);
        }
        #endregion

        #region Operator Management
        private string GetOperatorUpdateContent(cmRevision revision)
        {
            cmSite site = Revisions.TryToDeserialize<cmSite>(revision, null);
            if (site == null)
                throw new Exception("Error, can't find the file.");

            StringBuilder sb = new StringBuilder();

            sb.AppendLine(string.Format("Pwd Encryption Mode: {0}", site.PasswordEncryptionMode.ToString()));
            sb.AppendLine(string.Format("Template Site: {0}", site.TemplateDomainDistinctName));
            sb.AppendLine(string.Format("Default Theme: {0}", site.DefaultTheme));
            sb.AppendLine(string.Format("Default Culture: {0}", site.DefaultCulture));
            sb.AppendLine(string.Format("Email Host: {0}", site.EmailHost));
            sb.AppendLine(string.Format("Session Cookie Name: {0}", site.SessionCookieDomainInDatabase));
            sb.AppendLine(string.Format("Session Cookie Domain: {0}", site.SessionCookieDomain));
            sb.AppendLine(string.Format("Session Timeout Seconds: {0}", site.SessionTimeoutSeconds.ToString(CultureInfo.InvariantCulture)));
            sb.AppendLine(string.Format("HTTP Port: {0}", site.HttpPort.ToString(CultureInfo.InvariantCulture)));
            sb.AppendLine(string.Format("HTTPS Port: {0}", site.HttpsPort.ToString(CultureInfo.InvariantCulture)));
            sb.AppendLine(string.Format("Static File Server Domain: {0}", site.StaticFileServerDomainName));
            if (site.UseRemoteStylesheet)
                sb.AppendLine("Use Remote Stylesheet");
            else
                sb.AppendLine("Use Local Stylesheet");

            return sb.ToString();
        }
        #endregion


    }// class
}// namespace
