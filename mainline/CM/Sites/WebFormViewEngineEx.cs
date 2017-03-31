using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.Web.Routing;

namespace CM.Sites
{
    internal sealed class WebFormViewEngineEx : WebFormViewEngine
    {
        /*
        base.MasterLocationFormats = new string[] { "~/Views/{1}/{0}.master", "~/Views/Shared/{0}.master" };
        base.AreaMasterLocationFormats = new string[] { "~/Areas/{2}/Views/{1}/{0}.master", "~/Areas/{2}/Views/Shared/{0}.master" };
        base.ViewLocationFormats = new string[] { "~/Views/{1}/{0}.aspx", "~/Views/{1}/{0}.ascx", "~/Views/Shared/{0}.aspx", "~/Views/Shared/{0}.ascx" };
        base.AreaViewLocationFormats = new string[] { "~/Areas/{2}/Views/{1}/{0}.aspx", "~/Areas/{2}/Views/{1}/{0}.ascx", "~/Areas/{2}/Views/Shared/{0}.aspx", "~/Areas/{2}/Views/Shared/{0}.ascx" };
        base.PartialViewLocationFormats = base.ViewLocationFormats;
        base.AreaPartialViewLocationFormats = base.AreaViewLocationFormats;
         * */

        private static string[] ViewPathFormats
        {
            get
            {
                var domain = SiteManager.Current;
                if (domain != null)
                {
                    string templateDistinctName = domain.TemplateDomainDistinctName;
                    if (!string.IsNullOrWhiteSpace(templateDistinctName))
                    {
                        return new string[] { "~/Views/{2}{1}/{0}.aspx"
                            , "~/Views/{2}{1}/{0}.ascx"
                            , string.Format( "~/Views/{0}{{1}}/{{0}}.aspx", templateDistinctName)
                            , string.Format( "~/Views/{0}{{1}}/{{0}}.ascx", templateDistinctName)
                        };
                    }
                }
                return new string[] { "~/Views/{2}{1}/{0}.aspx" , "~/Views/{2}{1}/{0}.ascx" };
            }
        }

        private static string[] MasterPathFormats
        {
            get
            {
                var domain = SiteManager.Current;
                if (domain != null)
                {
                    string templateDistinctName = domain.TemplateDomainDistinctName;
                    if (!string.IsNullOrWhiteSpace(templateDistinctName))
                    {
                        return new string[] { "~/Views/{2}{1}/{0}.master"
                            , string.Format( "~/Views/{0}{{1}}/{{0}}.master", templateDistinctName)
                        };
                    }
                }
                return new string[] { "~/Views/{2}{1}/{0}.master" };
            }
        }

        public override ViewEngineResult FindView(ControllerContext controllerContext, string viewName, string masterName, bool useCache)
        {
            string[] strArray1;
            string[] strArray2;
            if (controllerContext == null)
            {
                throw new ArgumentNullException("controllerContext");
            }
            if (string.IsNullOrEmpty(viewName))
            {
                throw new ArgumentException( "Incorrect argument.", "viewName");
            }

            string requiredString = controllerContext.RouteData.GetRequiredString("controller");
            string str2 = this.GetPath(controllerContext.RouteData.Route, viewName, ViewPathFormats, useCache, out strArray1);
            string str3 = this.GetPath(controllerContext.RouteData.Route, masterName, MasterPathFormats, useCache, out strArray2);
            if (!string.IsNullOrEmpty(str2) && (!string.IsNullOrEmpty(str3) || string.IsNullOrEmpty(masterName)))
            {
                return new ViewEngineResult(this.CreateView(controllerContext, str2, str3), this);
            }
            if( strArray1 != null )
                return new ViewEngineResult(strArray1.Union<string>(strArray2));
            else
                return new ViewEngineResult(strArray2);
        }

        public override ViewEngineResult FindPartialView(ControllerContext controllerContext, string partialViewName, bool useCache)
        {
            string[] strArray;
            if (controllerContext == null)
            {
                throw new ArgumentNullException("controllerContext");
            }
            if (string.IsNullOrEmpty(partialViewName))
            {
                throw new ArgumentException("Incorrect argument.", "partialViewName");
            }
            string requiredString = controllerContext.RouteData.GetRequiredString("controller");
            string str2 = this.GetPath(controllerContext.RouteData.Route, partialViewName, ViewPathFormats, useCache, out strArray);
            if (string.IsNullOrEmpty(str2))
            {
                return new ViewEngineResult(strArray);
            }
            return new ViewEngineResult(this.CreatePartialView(controllerContext, str2), this);
        }


        private string GetPath( RouteBase route, string viewName, string[] formats, bool useCache, out string[] strArray)
        {
            strArray = null;
       
            List<string> pathes = new List<string>(); 
            string virtualPath;
            foreach (string format in formats)
            {
                string path = SiteManager.Current.GetUrlByRoute(route);
                virtualPath = string.Format(format
                    , viewName
                    , viewName.StartsWith("/") ? string.Empty : path
                    , SiteManager.Current.DistinctName
                    ).Replace("//", "/");
                pathes.Add(virtualPath);
                if (base.VirtualPathProvider.FileExists(virtualPath))
                {
                    return virtualPath;
                }
            }

            strArray = pathes.ToArray();
            return null;
        }


        protected override IView CreateView(ControllerContext controllerContext, string viewPath, string masterPath)
        {
            return new WebFormViewEx(viewPath, masterPath);
        }


        protected override IView CreatePartialView(ControllerContext controllerContext, string partialPath)
        {
            return new WebFormViewEx(partialPath, null);
        }
 

    }
}
