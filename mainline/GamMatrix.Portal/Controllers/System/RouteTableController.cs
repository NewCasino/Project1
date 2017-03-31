using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class RouteTableController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                var site = SiteManager.GetSiteByDistinctName(distinctName);
                this.ViewData["distinctName"] = distinctName;
                return View("Index", site);
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetUrlRewriteRules(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                var site = SiteManager.GetSiteByDistinctName(distinctName);
                var data = site.GetUrlRewriteRules().Select(r => new { Key = r.Key, Value = r.Value } ).ToArray();
                return this.Json(new { @success = true, @data = data }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        private static void VerifyUrlInput(string path)
        {
            string expression = @"^(\/((en)|(sq)|(zh\-cn)|(zh\-tw)|(cs)|(nl)|(da)|(fr)|(el)|(de)|(he)|(hu)|(it)|(ja)|(ko)|(lv)|(no)|(pl)|(pt)|(ro)|(ru)|(sr)|(es)|(sv)|(uk)|(tr)|(ro)|(sq)|(et))\/)";
            if (Regex.IsMatch(path, expression, RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase))
                throw new Exception(string.Format("[{0}] is not an available url!\nPlease don't prepend the url with language code.", path));
        }

        private Dictionary<string, string> PopulateDictionary()
        {
            int total = int.Parse(Request["total"]);
            if (total < 0)
                throw new Exception("Error! invalid parameter [total].");

            Dictionary<string, string> rules = new Dictionary<string, string>();
            for (int i = 0; i < total; i++)
            {
                string keyName = string.Format("Key_{0:D}", i);
                string valueName = string.Format("Value_{0:D}", i);

                string key = Request[keyName];
                string value = Request[valueName];

                if (string.IsNullOrWhiteSpace(key) ||
                    string.IsNullOrWhiteSpace(value))
                {
                    continue;
                }

                if (key == "/")
                    throw new Exception("You can't rewrite the root url [/]\n The default page can be changed in Site Manager.");
                //&& !key.StartsWith("http") && !key.StartsWith("ftp")
                if (!key.StartsWith("/")) key = "/" + key;
                if (!value.StartsWith("/") && !value.StartsWith("http") && !value.StartsWith("ftp")) value = "/" + value;
                VerifyUrlInput(key);
                if (!value.StartsWith("http") && !value.StartsWith("ftp"))
                {
                    VerifyUrlInput(value);
                }

                rules[key.ToLowerInvariant()] = value;
            }// for

            return rules;
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveUrlRewriteRules(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                var site = SiteManager.GetSiteByDistinctName(distinctName);



                site.SaveUrlRewriteRules(PopulateDictionary());

                return this.Json(new { @success = true  });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetHttpRedirectionRules(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                var site = SiteManager.GetSiteByDistinctName(distinctName);
                var data = site.GetHttpRedirectionRules().Select(r => new { Key = r.Key, Value = r.Value }).ToArray();
                return this.Json(new { @success = true, @data = data }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveHttpRedirectionRules(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                var site = SiteManager.GetSiteByDistinctName(distinctName);

                site.SaveHttpRedirectionRules(PopulateDictionary());

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
