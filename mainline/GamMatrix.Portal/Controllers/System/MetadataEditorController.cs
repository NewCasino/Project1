using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.Web;
using CM.State;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}/{path}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class MetadataEditorController : ControllerEx
    {
        private KeyValuePair<string, string>[] GetAllowedNodeTypes()
        {
            List<KeyValuePair<string, string>> types = new List<KeyValuePair<string, string>>();

            types.Add(new KeyValuePair<string, string>("Metadata", "Metadata"));

            return types.ToArray();
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index(string distinctName, string path, string language, string key)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain != null)
                {
                    ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                    ContentNode node;
                    if (contentTree.AllNodes.TryGetValue(path, out node))
                    {
                        this.ViewData["Key"] = key;
                        this.ViewData["Language"] = language;
                        this.ViewData["NodeTypes"] = this.GetAllowedNodeTypes();
                        this.ViewData["HistorySearchPattner"] = "/.%";
                        return View(node);
                    }
                }
                throw new Exception("Error, invalid parameter[path].");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }       
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult AdvancedEditor(string distinctName, string path, string id)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if( domain == null )
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(path, out node))
                    throw new Exception("Error, invalid parameter [path].");

                LanguageInfo[] languages = MultilingualMgr.GetSupporttedLanguages(domain);
                this.ViewData["Languages"] = languages;

                foreach (LanguageInfo lang in languages)
                {
                    this.ViewData[lang.LanguageCode] = Metadata.ReadRawValue(domain, path + "." + id, lang.LanguageCode);
                }
                this.ViewData["Default"] = Metadata.ReadRawValue(domain, path + "." + id, null);
                this.ViewData["EntryName"] = id;
                return View("AdvancedEditor", node);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }            
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetSpecialLanguageEntries(string distinctName, string path, string lang)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                var data = Metadata.GetSpecialLanguageEntries(domain, path, lang);
                return this.Json(new { @success = true, @data = data }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetEntryValue(string distinctName, string path, string id)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                var data = new Dictionary<string, string>();
                data["Default"] = Metadata.ReadRawValue(domain, path + "." + id, null);
                LanguageInfo[] languages = MultilingualMgr.GetSupporttedLanguages(domain);
                foreach (LanguageInfo langInfo in languages)
                {
                    data[langInfo.LanguageCode] = Metadata.ReadRawValue(domain, path + "." + id, langInfo.LanguageCode);
                }

                return this.Json(new { @success = true, @data = data }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        [ValidateInput(false)]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveAll(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");
                if (!CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                {
                    if (path.StartsWith("/Metadata/Settings/Registration", StringComparison.OrdinalIgnoreCase)
                    || path.StartsWith("/Metadata/Settings/QuickRegistration", StringComparison.OrdinalIgnoreCase))
                    {
                        return this.Json(new { @success = false, @error = "No permission" });
                    }
                }
                foreach (string key in Request.Form.AllKeys)
                {
                    string lang = null;
                    // default_value_LOGIN-MESSAGE
                    Match match = Regex.Match(key, @"^(default_value_)(?<name>[\w_\-]+)$", RegexOptions.ECMAScript | RegexOptions.Compiled);
                    if (!match.Success)
                    {
                        // translation_zh-cn_LOGIN-MESSAGE
                        match = Regex.Match(key, @"^(translation_)(?<lang>[^_]+)_(?<name>[\w_\-]+)$", RegexOptions.ECMAScript | RegexOptions.Compiled);
                        if (!match.Success)
                            continue;
                        lang = match.Groups["lang"].Value;
                    }
                    Metadata.Save(domain, path, lang, match.Groups["name"].Value, Request.Form[key]);
                }

                return this.Json(new { @success = true,  } );
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message } );
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetAllEntries(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                Dictionary<string, ContentNode.ContentNodeStatus> entries = Metadata.GetAllEntries(domain, path);
                bool isSystemAdmin = CustomProfile.Current.IsInRole("CMS System Admin");
                if (!isSystemAdmin && path.StartsWith("/Metadata/Settings"))
                {
                    entries = entries.Where(o => !string.Equals(o.Key, "WhiteList_EMUserIPs", StringComparison.InvariantCultureIgnoreCase)).ToDictionary(k => k.Key, v => v.Value);
                } 
                return this.Json(new
                {
                    @success = true,
                    @entries = entries.Select(e => new
                    {
                        @Path = path.DefaultEncrypt(),
                        EntryPath = path + "." + e.Key,
                        Name = e.Key,
                        Status = e.Value.ToString().ToLowerInvariant(),
                        Default = Metadata.ReadRawValue(domain, path + "." + e.Key)
                    })
                .Where(e => !string.Equals(e.Name, "InlineCSS", StringComparison.InvariantCultureIgnoreCase))
                .ToArray()
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult CreateEntry(string distinctName, string path, string entryName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(path, out node))
                    throw new Exception("Error, invalid parameter [path].");

                string phisicalPath = Path.Combine(node.RealPhysicalPath, "." + entryName);

                ContentTree.EnsureDirectoryExistsForFile( domain, phisicalPath);

                if (ContentTree.CheckFileExists(phisicalPath))
                    throw new Exception("Error, Metadata already exists.");  

                using (StreamWriter sw = new StreamWriter(phisicalPath, false, Encoding.UTF8))
                    {
                        sw.Write("");
                        sw.Close();
                    }

                Revisions.Create(domain, string.Format("{0}/.{1}", path.TrimEnd('/'), entryName), string.Format("Create new metadata [{0}]", entryName), null);

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
        public ActionResult Preview(string distinctName, string path, string id)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(path, out node))
                    throw new Exception("Error, invalid parameter [path].");

                LanguageInfo[] languages = MultilingualMgr.GetSupporttedLanguages(domain);
                this.ViewData["Languages"] = languages;

                foreach (LanguageInfo lang in languages)
                {
                    this.ViewData[lang.LanguageCode] = Metadata.Get(domain, path + "." + id, lang.LanguageCode, false);
                }

                this.ViewData["Default"] = Metadata.Get(domain, path + "." + id, null, false);

                this.ViewData["Title"] = string.Format("Preview - {0}", id);

                return View("Preview", node);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult PreviewHtml(string distinctName, string path, string lang, string id)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(path, out node))
                    throw new Exception("Error, invalid parameter [path].");

                this.ViewData["Html"] = Metadata.Get(domain, path + "." + id, lang, false);

                return View("PreviewHtml");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Delete(string distinctName, string path, string id)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                Metadata.Delete(domain, path, id);

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                ContentNode contentNode;

                if (contentTree != null && contentTree.AllNodes.TryGetValue(path, out contentNode))
                    Revisions.Create(domain, string.Format("{0}/.{1}", contentNode.RelativePath.TrimEnd('/'), id), string.Format("Delete metadata [{0}]", id), null);

                return this.Json(new { @success = true, @name = id }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult MetadataSelector(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(path, out node))
                    throw new Exception("Error, invalid parameter [path].");

                string metadataPath;

                if (node.NodeType != ContentNode.ContentNodeType.Metadata)
                {
                    metadataPath = Regex.Replace(path
                            , @"(\/[^\/]+)$"
                            , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_")); }
                            );
                }
                else
                {
                    metadataPath = path;
                }
                this.ViewData["PrivateMetadata"] = metadataPath;
                return View("MetadataSelector", node);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveProperties(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                ContentNode contentNode;

                DateTime? validFrom = ConvertHelper.ToDateTime(Request["validFrom"], DateTime.MinValue);
                DateTime? expiryTime = ConvertHelper.ToDateTime(Request["expiryTime"], DateTime.MinValue);
                if (validFrom == DateTime.MinValue)
                    validFrom = null;
                if (expiryTime == DateTime.MinValue)
                    expiryTime = null;
                bool availableForUKLicense = ConvertHelper.ToBoolean(Request["isUKLicense"], true);
                bool availableForNonUKLicense = ConvertHelper.ToBoolean(Request["notUKLicense"], true);

                bool validFromChanged = false;
                bool expiryTimeChanged = false;
                bool availableForUKLicenseChanged = false;
                bool availableForNonUKLicenseChanged = false;

                if (contentTree != null && contentTree.AllNodes.TryGetValue(path, out contentNode))
                {
                    MetadataNode metadataNode = new MetadataNode(contentNode);
                    if (metadataNode.ValidFrom != validFrom)
                    {
                        metadataNode.ValidFrom = validFrom;
                        validFromChanged = true;
                    }
                    if (metadataNode.ExpiryTime != expiryTime)
                    {
                        metadataNode.ExpiryTime = expiryTime;
                        expiryTimeChanged = true;
                    }
                    if (metadataNode.AvailableForUKLicense != availableForUKLicense)
                    {
                        metadataNode.AvailableForUKLicense = availableForUKLicense;
                        availableForUKLicenseChanged = true;
                    }
                    if (metadataNode.AvailableForNonUKLicense != availableForNonUKLicense)
                    {
                        metadataNode.AvailableForNonUKLicense = availableForNonUKLicense;
                        availableForNonUKLicenseChanged = true;
                    }
                    metadataNode.Save();
                }
                else
                    throw new Exception("Error, can't locate the path.");

                if (validFromChanged)
                {
                    if (validFrom.HasValue)
                        Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), string.Format("Update the valid from to [{0}]", validFrom.Value.ToString("dd/MM/yyyy HH:mm:ss")), null);
                    else
                        Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), "Remove the config for valid from", null);
                }

                if (expiryTimeChanged)
                {
                    if (expiryTime.HasValue)
                        Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), string.Format("Update the expiry time to [{0}]", expiryTime.Value.ToString("dd/MM/yyyy HH:mm:ss")), null);
                    else
                        Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), "Remove the config for expiry time", null);
                }

                if (availableForUKLicenseChanged)
                    Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), string.Format("Update the visibility for UK License to [{0}]", availableForUKLicense), null);

                if (availableForNonUKLicenseChanged)
                    Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), string.Format("Update the visibility for Non UK License to [{0}]", availableForNonUKLicense), null);

                //domain.ReloadRouteTable(Request.RequestContext);
                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }     
    }
}
