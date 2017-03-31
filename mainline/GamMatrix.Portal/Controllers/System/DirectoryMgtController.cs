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
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    public sealed class DirectoryMgtParam
    {
        public string DistinctName { get; set; }
        public string RelativePath { get; set; }
        public KeyValuePair<string, string>[] AllowedNodeTypes { get; set; }
        public KeyValuePair<string, string>[] AllowedTemplates { get; set; }
    }

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}/{relativePath}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class DirectoryMgtController : ControllerEx
    {
        private KeyValuePair<string, string>[] GetAllowedNodeTypes()
        {
            List<KeyValuePair<string, string>> types = new List<KeyValuePair<string, string>>();

            types.Add(new KeyValuePair<string, string>("Directory", "Directory"));
            types.Add(new KeyValuePair<string, string>("Page Template", "PageTemplate"));
            types.Add(new KeyValuePair<string, string>("Page", "Page"));
            types.Add(new KeyValuePair<string, string>("View", "View"));
            types.Add(new KeyValuePair<string, string>("Partial View", "PartialView"));
            types.Add(new KeyValuePair<string, string>("HTML Snippet", "HtmlSnippet"));
            types.Add(new KeyValuePair<string, string>("Metadata", "Metadata"));
            types.Add(new KeyValuePair<string, string>("Classic Page", "ClassicPage"));

            return types.ToArray();
        }

        [Serializable]
        public sealed class ClipboardData
        {
            // true = copy; false = cut
            public bool IsCopy { get; set; }
            // the DistinctName of the source
            public string DistinctName { get; set; }
            // the RelativePath array
            public string[] RelativePaths { get; set; }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index(string distinctName, string relativePath)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain != null)
                {
                    ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                    ContentNode node;
                    if (contentTree.AllNodes.TryGetValue(relativePath, out node))
                    {
                        this.ViewData["Path"] = relativePath;
                        this.ViewData["ContentNode"] = node;
                        this.ViewData["HistorySearchPattner"] = "/.%";

                        return View(new DirectoryMgtParam()
                        {
                            DistinctName = distinctName
                            ,
                            RelativePath = relativePath,
                            AllowedNodeTypes = GetAllowedNodeTypes()
                        });
                    }
                }

                throw new Exception("Error, invalid parameter [relativePath].");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetMetadataOrderList(string distinctName, string relativePath)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
                return this.Json(new
                {
                    @success = true,
                    @children = Metadata.GetChildrenPaths(site, relativePath, false, true)
                        .Select(i => Path.GetFileName(i))
                }
                    , JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveMetadataOrderList(string distinctName, string relativePath, string list)
        {
            distinctName = distinctName.DefaultDecrypt();
            relativePath = relativePath.DefaultDecrypt();

            if (!string.IsNullOrEmpty(list))
            {
                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain != null)
                {
                    ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                    ContentNode node;
                    if (contentTree.AllNodes.TryGetValue(relativePath, out node))
                    {
                        string orderFile = Path.Combine(node.RealPhysicalPath, "_orderlist");
                        ContentTree.EnsureDirectoryExistsForFile(domain, orderFile);

                        string comments = "Change the ordinary";

                        Revisions.BackupIfNotExists(domain, orderFile, string.Format("{0}/.orderlist", relativePath.TrimEnd('/')), comments, true);

                        using (StreamWriter sw = new StreamWriter(orderFile, false, Encoding.UTF8))
                        {
                            sw.Write(list);
                            sw.Flush();
                        }

                        Revisions.Backup(domain, orderFile, string.Format("{0}/.orderlist", relativePath.TrimEnd('/')), comments, true);
                    }
                }
            }

            return this.Json(new { @success = true });
        }



        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetChildren(string distinctName, string relativePath)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain != null)
                {
                    ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                    ContentNode node;
                    if (contentTree.AllNodes.TryGetValue(relativePath, out node))
                    {
                        var children = node.Children.Values.Where(c => !c.Name.StartsWith("_")).OrderByDescending(c => c.NodeType).Select(c => new
                        {
                            @DisplayName = c.DisplayName,
                            @RelativePath = c.RelativePath.DefaultEncrypt(),
                            @ActionUrl = Url.GetActionUrl(c),
                            @NodeStatus = Enum.GetName(c.NodeStatus.GetType(), c.NodeStatus).ToLowerInvariant(),
                            @NodeType = Enum.GetName(c.NodeType.GetType(), c.NodeType).ToLowerInvariant(),
                            @IsDisabled = c.IsDisabled,
                        }).ToArray();
                        return this.Json(new { @success = true, @children = children }, JsonRequestBehavior.AllowGet);
                    }
                }

                throw new Exception("Error, can't locate the path.");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult GotoParent(string distinctName, string relativePath)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new ArgumentException("Invalid distinctName.");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new ArgumentException("Invalid distinctName.");

                ContentNode node;
                if (!contentTree.AllNodes.TryGetValue(relativePath, out node))
                    throw new ArgumentException("Invalid relativePath.");

                if (node.Parent != null)
                    return this.Redirect(Url.GetActionUrl(node.Parent));

                return this.Redirect(Url.GetActionUrl(node));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }


        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Copy(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                this.SaveToClipboard(distinctName, true);

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }


        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Cut(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                this.SaveToClipboard(distinctName, false);

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Paste(string distinctName, string relativePath, bool confirmed)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                ClipboardData clipboardData = CustomProfile.Current.GetPropertyValue("ClipboardData") as ClipboardData;
                if (clipboardData == null)
                    throw new Exception("The clipboard is empty, nothing to paste!");

                if (!confirmed)
                    return this.Json(new { @success = true, @status = "pending", @items = clipboardData.RelativePaths });

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }


        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Delete(string distinctName, string[] selectedItems)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                for (int i = 0; i < selectedItems.Length; i++)
                {
                    selectedItems[i] = selectedItems[i].DefaultDecrypt();
                }

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new ArgumentException("Invalid distinctName.");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new ArgumentException("Invalid distinctName.");

                foreach (string relativePath in selectedItems)
                {
                    ContentNode node = null;
                    if (contentTree.AllNodes.TryGetValue(relativePath, out node))
                    {
                        // TO DO: what about inherited node?
                        FileSystemUtility.Delete(node.RealPhysicalPath);
                        Revisions.Create(domain, string.Format("{0}/.{1}", node.Parent.RelativePath.TrimEnd('/'), node.Name), string.Format("Delete [{0}]", node.Name), null);

                        if (node.NodeType == ContentNode.ContentNodeType.View ||
                            node.NodeType == ContentNode.ContentNodeType.PartialView ||
                            node.NodeType == ContentNode.ContentNodeType.PageTemplate ||
                            node.NodeType == ContentNode.ContentNodeType.HtmlSnippet)
                        {
                            string metadataPath = Regex.Replace(relativePath
                                , @"(\/[^\/]+)$"
                                , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_")); }
                                );
                            ContentNode metadataNode;
                            if (contentTree.AllNodes.TryGetValue(metadataPath, out metadataNode))
                            {
                                FileSystemUtility.Delete(metadataNode.RealPhysicalPath);
                            }
                        }
                    }
                }

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        private void SaveToClipboard(string distinctName, bool isCopy)
        {
            ClipboardData clipboardData = new ClipboardData()
            {
                IsCopy = isCopy,
                DistinctName = distinctName,
            };

            string selectedItems = Request["selectedItems"];
            if (!string.IsNullOrEmpty(selectedItems))
            {
                clipboardData.RelativePaths = selectedItems.Split(',')
                    .Where(s => !string.IsNullOrEmpty(s))
                    .Select(s => s.DefaultDecrypt())
                    .ToArray();
            }

            CustomProfile.Current.SetPropertyValue("ClipboardData", clipboardData);
        }


        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult EnableMetadata(string distinctName, bool enable, string[] selectedItems)
        {
            try
            {
                if (selectedItems == null || selectedItems.Length == 0)
                    return this.Json(new { @success = true });

                distinctName = distinctName.DefaultDecrypt();

                for (int i = 0; i < selectedItems.Length; i++)
                {
                    selectedItems[i] = selectedItems[i].DefaultDecrypt();
                }

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new ArgumentException("Invalid distinctName.");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                if (contentTree == null)
                    throw new ArgumentException("Invalid distinctName.");

                List<string> originalOrderList = new List<string>();
                string strPhysicalPath = string.Empty,
                    strOrderList = string.Empty;
                bool? isOrdered = null;

                foreach (string relativePath in selectedItems)
                {
                    ContentNode node = null;
                    if (contentTree.AllNodes.TryGetValue(relativePath, out node) &&
                        node.NodeType == ContentNode.ContentNodeType.Metadata &&
                        node.IsDisabled == enable)
                    {
                        if (node.NodeStatus == ContentNode.ContentNodeStatus.Inherited)
                        {
                            ContentTree.EnsureDirectoryExists(domain, node.RealPhysicalPath);
                        }
                        PropertyFileHelper.Save(Path.Combine(node.RealPhysicalPath, ".properties.xml")
                            , new { @IsDisabled = !enable, @IsInherited = false });

                        string comment = string.Format("{0} the metadata [{1}]", enable ? "Enable" : "Disable", node.Name);
                        Revisions.Create(domain, string.Format("{0}/.{1}", node.Parent.RelativePath.TrimEnd('/'), node.Name), comment, null);

                        if (!isOrdered.HasValue)
                        {
                            strPhysicalPath = node.Parent.RealPhysicalPath.TrimEnd('/') + "/_orderlist";
                            strOrderList = WinFileIO.ReadWithoutLock(strPhysicalPath);
                            if (strOrderList ==  null)
                            {
                                isOrdered = true;
                                originalOrderList = strOrderList.Split(',').Where(i =>
                                {
                                    return !string.IsNullOrWhiteSpace(i);
                                }).ToList();
                                if (originalOrderList == null)
                                    originalOrderList = new List<string>();
                            }
                            else
                                isOrdered = false;
                        }

                        if (isOrdered.Value)
                        {                          
                            if (enable)
                            {
                                if (!originalOrderList.Contains<string>(node.Name))
                                    originalOrderList.Add(node.Name);
                            }
                            else
                            {
                                if (originalOrderList.Contains<string>(node.Name))
                                    originalOrderList.Remove(node.Name);
                            }
                        }
                    }

                }
                if (isOrdered.Value)
                {
                    strOrderList = string.Empty;
                    foreach (string item in originalOrderList)
                    {
                        strOrderList += item + ",";
                    }
                    if (!string.IsNullOrWhiteSpace(strOrderList))
                        strOrderList = strOrderList.Substring(0, strOrderList.Length - 1);
                    using (StreamWriter sw = new StreamWriter(strPhysicalPath, false, Encoding.UTF8))
                    {
                        sw.Write(strOrderList);
                        sw.Flush();
                    }
                }
                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult CreateChild(string distinctName, string relativePath, ContentNode.ContentNodeType childType, string childName,
            bool childCopy = false, string childCopyFrom = null)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();
                if (childCopy)
                    childCopyFrom = childCopyFrom.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new ArgumentException("Invalid distinctName.");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if (contentTree == null)
                    throw new ArgumentException("Invalid distinctName.");

                ContentNode parent;
                if (!contentTree.AllNodes.TryGetValue(relativePath, out parent))
                    throw new ArgumentException("Invalid relativePath.");

                if (parent.NodeStatus == ContentNode.ContentNodeStatus.Inherited)
                    ContentTree.EnsureDirectoryExists(domain, parent.RealPhysicalPath);

                if (!Directory.Exists(parent.RealPhysicalPath))
                    throw new ArgumentException("Invalid relativePath.");

                // check duplicate name
                string path = Path.Combine(parent.RealPhysicalPath, childName);
                {
                    if (parent.Children.Values.FirstOrDefault(c => string.Compare(c.DisplayName, childName, true) == 0 || string.Compare(c.Name, childName, true) == 0) != null)
                        throw new Exception("The child with this name already exists, please try another name.");
                    if (childName.StartsWith("_"))
                        throw new Exception("The child name can not start with a '_' charactor.");
                    if (Directory.Exists(path))
                        throw new Exception("The child with this name already exists, please try another name.");
                    if (global::System.IO.File.Exists(path))
                        throw new Exception("The child with this name already exists, please try another name.");
                    var dirs = Directory.EnumerateDirectories(parent.RealPhysicalPath, string.Format("{0}.*", childName), SearchOption.TopDirectoryOnly);
                    foreach (var dir in dirs)
                    {
                        throw new Exception("The child with this name already exists, please try another name.");
                    }
                    var files = Directory.EnumerateFiles(parent.RealPhysicalPath, string.Format("{0}.*", childName), SearchOption.TopDirectoryOnly);
                    foreach (var file in files)
                    {
                        throw new Exception("The child with this name already exists, please try another name.");
                    }
                }

                switch (childType)
                {
                    case ContentNode.ContentNodeType.Directory:
                        Directory.CreateDirectory(path);
                        break;

                    case ContentNode.ContentNodeType.View:
                        {
                            string template = Server.MapPath("~/App_Data/view_source");
                            string dest = path + ".aspx";
                            global::System.IO.File.Copy(template, dest, false);
                            string dir = CreatePrivateMetadata(dest);
#pragma warning disable 0642
                            using (new StreamWriter(Path.Combine(dir, ".Title"))) ;
                            using (new StreamWriter(Path.Combine(dir, ".Keywords"))) ;
                            using (new StreamWriter(Path.Combine(dir, ".Description"))) ;
#pragma warning restore 0642
                        }
                        break;

                    case ContentNode.ContentNodeType.PartialView:
                        {
                            string template = Server.MapPath("~/App_Data/partial_view_source");
                            string dest = path + ".ascx";
                            global::System.IO.File.Copy(template, dest, false);
                            CreatePrivateMetadata(dest);
                        }
                        break;

                    case ContentNode.ContentNodeType.PageTemplate:
                        {
                            string template = Server.MapPath("~/App_Data/page_template_source");
                            string dest = path + ".master";
                            global::System.IO.File.Copy(template, dest, false);
                            string dir = CreatePrivateMetadata(dest);
#pragma warning disable 0642
                            using (new StreamWriter(Path.Combine(dir, ".Title"))) ;
                            using (new StreamWriter(Path.Combine(dir, ".Keywords"))) ;
                            using (new StreamWriter(Path.Combine(dir, ".Description"))) ;
#pragma warning restore 0642
                        }
                        break;

                    case ContentNode.ContentNodeType.Page:
                        {
                            Directory.CreateDirectory(path);
                            string template = Server.MapPath("~/App_Data/page_source");
                            string dest = Path.Combine(path, ".properties.xml");
                            global::System.IO.File.Copy(template, dest, false);
                        }
                        break;

                    case ContentNode.ContentNodeType.Metadata:
                        {
                            if (childCopy)
                            {
                                string fromPath = childCopyFrom;
                                string toPath = fromPath.TrimEnd('/');
                                toPath = toPath.Substring(0, toPath.LastIndexOf("/"));
                                toPath += "/" + childName;

                                CopyItem(domain, contentTree, fromPath, toPath);
                            }
                            else
                            {
                                Directory.CreateDirectory(path);
                                string template = Server.MapPath("~/App_Data/metadata_source");
                                string dest = Path.Combine(path, ".properties.xml");
                                global::System.IO.File.Copy(template, dest, false);
                            }
                        }
                        break;

                    case ContentNode.ContentNodeType.HtmlSnippet:
                        {
                            string template = Server.MapPath("~/App_Data/htmlsnippet_source");
                            string dest = path + ".snippet";
                            global::System.IO.File.Copy(template, dest, false);
                            CreatePrivateMetadata(dest);
                        }
                        break;

                    case ContentNode.ContentNodeType.ClassicPage:
                        {
                            Directory.CreateDirectory(path);
                            string template = Server.MapPath("~/App_Data/page_source");
                            string dest = Path.Combine(path, ".properties.xml");
                            global::System.IO.File.Copy(template, dest, false);

                            PropertyFileHelper.Save(dest, new
                            {
                                @Controller = "GamMatrix.CMS.Controllers.Shared.NonSecurePageController"
                                ,
                                @RouteName = Guid.NewGuid().ToString()
                                ,
                                @IsInherited = false
                            });

                            template = Server.MapPath("~/App_Data/classicpage_view_source");
                            dest = Path.Combine(path, "Index.aspx");
                            global::System.IO.File.Copy(template, dest, false);
                            string dir = CreatePrivateMetadata(dest);

                            using (new StreamWriter(Path.Combine(dir, ".Title")))
                            using (new StreamWriter(Path.Combine(dir, ".Keywords")))
                            using (new StreamWriter(Path.Combine(dir, ".Description")))
                            using (new StreamWriter(Path.Combine(dir, ".HTML")))
                            {
                            }

                            domain.ReloadRouteTable(this.Request.RequestContext);
                        }
                        break;

                }

                {
                    string comments = null;
                    bool isValid = true;
                    switch (childType)
                    {
                        case ContentNode.ContentNodeType.Directory:
                            comments = string.Format("Create new directory [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.PageTemplate:
                            comments = string.Format("Create new page template [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.Page:
                            comments = string.Format("Create new page [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.View:
                            comments = string.Format("Create new view [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.PartialView:
                            comments = string.Format("Create new partial view [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.HtmlSnippet:
                            comments = string.Format("Create new html snippet [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.Metadata:
                            comments = string.Format("Create new metadata [{0}]", childName);
                            break;
                        case ContentNode.ContentNodeType.ClassicPage:
                            comments = string.Format("Create new classic page [{0}]", childName);
                            break;
                        default:
                            isValid = false;
                            break;
                    }

                    if (isValid)
                        Revisions.Create(domain, string.Format("{0}/.{1}", relativePath.TrimEnd('/'), childName), comments, null);
                }

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        private string CreatePrivateMetadata(string file)
        {
            string filename = Path.GetFileName(file);
            string metadataName = "_" + Regex.Replace(filename, @"[^\w\-_]", "_");
            string dir = Path.Combine(Path.GetDirectoryName(file), metadataName);
            if (!Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            string template = Server.MapPath("~/App_Data/metadata_source");
            string dest = Path.Combine(dir, ".properties.xml");
            global::System.IO.File.Copy(template, dest, false);
            return dir;
        }

        private void CopyItem(cmSite domain, ContentTree contentTree, string fromPath, string toPath)
        {
            ContentNode node;
            if (contentTree.AllNodes.TryGetValue(fromPath, out node))
            {
                switch (node.NodeType)
                {
                    case ContentNode.ContentNodeType.Directory:
                        //CopyDirectory();
                        break;

                    case ContentNode.ContentNodeType.Page:
                        //CopyPage();
                        break;

                    case ContentNode.ContentNodeType.View:
                    case ContentNode.ContentNodeType.StaticContent:
                    case ContentNode.ContentNodeType.PartialView:
                    case ContentNode.ContentNodeType.PageTemplate:
                    case ContentNode.ContentNodeType.HtmlSnippet:
                        //CopyView();
                        break;

                    case ContentNode.ContentNodeType.Metadata:
                        Metadata.CopyMetadata(domain, fromPath, toPath);
                        break;
                }

                var children = node.Children.Values.Where(c => !c.Name.StartsWith("_"));

                foreach (var child in children)
                {
                    CopyItem(domain, contentTree, child.RelativePath, child.RelativePath.Replace(fromPath, toPath));
                }
            }
        }

        
    }
}
