using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}/{path}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class ViewEditorController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index(string distinctName, string path)
        {
            distinctName = distinctName.DefaultDecrypt();
            path = path.DefaultDecrypt();
            cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
            if (domain != null)
            {
                ContentTree tree = ContentTree.GetByDistinctName(distinctName, domain.TemplateDomainDistinctName, false);
                if (tree != null)
                {
                    ContentNode node;
                    if (tree.AllNodes.TryGetValue(path, out node))
                    {
                        this.ViewData["MasterPages"] = tree.AllNodes
                            .Where(n => n.Value.NodeType == ContentNode.ContentNodeType.PageTemplate)
                            .Select(n => new { @Text = Regex.Replace(n.Key, @"(\.master)$", string.Empty, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant), @Value = n.Key })
                            .ToArray();

                        string metadataPath = Regex.Replace(path
                            , @"(\/[^\/]+)$"
                            , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_")); }
                            );
                        ContentNode metadataNode;
                        if (tree.AllNodes.TryGetValue(metadataPath, out metadataNode))
                        {
                            this.ViewData["MetadataNode"] = metadataNode;
                        }
                        return View(node);
                    }
                }
            }
            throw new ArgumentException("Can't find the file.");    
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [ValidateInput(false)]
        public JsonResult Save(string distinctName, string path, string relativePath, string content, string comments)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();
                relativePath = relativePath.DefaultDecrypt();

                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                comments = comments.DefaultIfNullOrEmpty(string.Empty);
                comments = comments.Replace("$USERNAME$", CustomProfile.Current.UserName);

                /////////////////////////////////////////////////////////////
                string filePath;
                string localFile;
                cmRevision revision;
                SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

                // if last revision not exist, backup first
                {
                    RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                    revision = ra.GetLastRevision(site.ID, relativePath);
                    if (revision == null || !global::System.IO.File.Exists(Revisions.GetLocalPath(revision.FilePath)))
                    {
                        localFile = Revisions.GetNewFilePath(out filePath);
                        global::System.IO.File.Copy(path, localFile);

                        revision = new cmRevision();
                        revision.Comments = "No revision found, make a backup.";
                        revision.SiteID = site.ID;
                        revision.FilePath = filePath;
                        revision.Ins = DateTime.Now;
                        revision.RelativePath = relativePath;
                        revision.UserID = CustomProfile.Current.UserID;
                        query.Insert(revision);
                    }
                }

                // save the file
                using (StreamWriter sw = new StreamWriter(path, false, Encoding.UTF8))
                {
                    sw.Write(content);
                }

                // copy the file to backup
                localFile = Revisions.GetNewFilePath(out filePath);
                global::System.IO.File.Copy(path, localFile);

                // save to cmRevision
                {
                    revision = new cmRevision();
                    revision.Comments = comments;
                    revision.SiteID = site.ID;
                    revision.FilePath = filePath;
                    revision.Ins = DateTime.Now;
                    revision.RelativePath = relativePath;
                    revision.UserID = CustomProfile.Current.UserID;
                    query.Insert(revision);
                }

                site.ReloadCache(Request.RequestContext, CacheManager.CacheType.PageTemplatePathCache);
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
        public ActionResult Override(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = path.DefaultDecrypt();

                cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain == null)
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName);
                if( contentTree == null )
                    throw new Exception("Error, invalid parameter [distinctName].");

                ContentNode node;
                if( !contentTree.AllNodes.TryGetValue( path, out node) )
                    throw new Exception("Error, invalid parameter [path].");

                if (node.NodeStatus != ContentNode.ContentNodeStatus.Inherited)
                    throw new Exception("Error, the node status must be inherited for overriding.");

                ContentTree.EnsureDirectoryExistsForFile( domain, node.RealPhysicalPath);
                global::System.IO.File.Copy(node.PhysicalPath, node.RealPhysicalPath);

                Revisions.Create(domain, node.RelativePath, "Override the common template", null);

                string url = this.Url.RouteUrl(this.RouteData.DataTokens["RouteName"] as string, new { action = "Index", distinctName = distinctName.DefaultEncrypt(), path = path.DefaultEncrypt() });
                return this.Redirect(url);
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Unoverride(string distinctName, string path)
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

                if (node.NodeStatus != ContentNode.ContentNodeStatus.Overrode)
                    throw new Exception("Error, the node status must be overridden for restore.");

                global::System.IO.File.Delete(node.RealPhysicalPath);

                Revisions.Create(domain, node.RelativePath, "Restore to use the common template", null);

                string url = this.Url.RouteUrl(this.RouteData.DataTokens["RouteName"] as string, new { action = "Index", distinctName = distinctName.DefaultEncrypt(), path = path.DefaultEncrypt() });
                return this.Redirect(url);
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }
    }// class
}// namespace
