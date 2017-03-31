using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}/{path}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class PageEditorController : ControllerEx
    {
        private KeyValuePair<string, string>[] GetAllowedNodeTypes()
        {
            List<KeyValuePair<string, string>> types = new List<KeyValuePair<string, string>>();

            types.Add(new KeyValuePair<string, string>("Page Template", "PageTemplate"));
            types.Add(new KeyValuePair<string, string>("View", "View"));
            types.Add(new KeyValuePair<string, string>("Partial View", "PartialView"));
            types.Add(new KeyValuePair<string, string>("Http Handler", "HttpHandler"));

            return types.ToArray();
        }

        private void PrepareControllers(string distinctName)
        {
            cmSite domain = CM.Sites.SiteManager.GetSiteByDistinctName(distinctName);
            if (domain == null)
                return;

            Assembly assembly = ControllerEx.GetControllerAssembly();

            Type[] types = assembly.GetTypes();

            string local = distinctName;
            Regex reg = new Regex(@"^[_\|a-zA-z]+[\w]*$");
            if (!reg.Match(local).Success)
            {
                local = "_" + local;
            }

            var query1 = from t in types.Where(t => typeof(ControllerEx).IsAssignableFrom(t) || typeof(AsyncControllerEx).IsAssignableFrom(t))
                         where t.FullName.StartsWith(string.Format("GamMatrix.CMS.Controllers.{0}", local))
                         select new KeyValuePair<string, string>(t.FullName, string.Format("{0} > {1}", distinctName, t.Name));

            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
            {
                var query2 = from t in types.Where(t => typeof(ControllerEx).IsAssignableFrom(t) || typeof(AsyncControllerEx).IsAssignableFrom(t))
                             where t.FullName.StartsWith(string.Format("GamMatrix.CMS.Controllers.{0}", domain.TemplateDomainDistinctName))
                             select new KeyValuePair<string, string>( t.FullName, string.Format("{0} > {1}", domain.TemplateDomainDistinctName, t.Name) );
                query1 = query1.Union(query2);
            }

            this.ViewData["PageControllers"] = query1.ToList();
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index(string distinctName, string path)
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
                        this.PrepareControllers(distinctName);
                        this.ViewData["NodeTypes"] = this.GetAllowedNodeTypes();
                        this.ViewData["HistorySearchPattner"] = "/.%";
                        return View(node);
                    }
                }
                throw new Exception("Error, invalid parameter[distinctName].");
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

                if (contentTree != null && contentTree.AllNodes.TryGetValue(path, out contentNode))
                {
                    bool controllerChanged = false;
                    bool routeNameChanged = false;

                    PageNode pageNode = new PageNode(contentNode);
                    if (pageNode.Controller != Request["Controller"])
                    {
                        pageNode.Controller = Request["Controller"];
                        controllerChanged = true;
                    }
                    if (pageNode.RouteName != Request["RouteName"])
                    {
                        pageNode.RouteName = Request["RouteName"];
                        routeNameChanged = true;
                    }
                    pageNode.Save();

                    if (controllerChanged)
                        Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), string.Format("Update the controller to [{0}]", Request["Controller"]), null);

                    if (routeNameChanged)
                        Revisions.Create(domain, string.Format("{0}/.properties", contentNode.RelativePath.TrimEnd('/')), string.Format("Update the route name to [{0}]", Request["RouteName"]), null);
                }
                else
                    throw new Exception("Error, can't locate the path.");

                domain.ReloadRouteTable(Request.RequestContext);
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
