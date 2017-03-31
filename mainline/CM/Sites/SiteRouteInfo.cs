using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Web.Routing;
using CM.Content;
using CM.db;
using CM.Web;

namespace CM.Sites
{
    [Serializable]
    public sealed class SiteRouteInfo
    {
        public cmSite Domain { get; private set; }
        public RouteCollection RouteCollection { get; private set; }
        public Dictionary<string, RouteExtraInfo> RouteExtraInfos { get; private set; }
        private const string ROUTE_CACHE_FILE = @"~/App_Data/{0}/route_info.cache";

        [Serializable]
        public sealed class RouteExtraInfo
        {
            public string Url { get; set; }
            public Type ControllerType { get; set; }
            public string RouteName { get; set; }
            public string RouteUrl { get; set; }
            public string Action { get; set; }
            public string Controller { get; set; }
            public List<string> Parameters { get; private set; }

            public RouteExtraInfo()
            {
                this.Parameters = new List<string>();
            }
        }

        public SiteRouteInfo(cmSite domain)
        {
            Domain = domain;
            RouteCollection = new RouteCollection();


            Dictionary<string, RouteExtraInfo> routeExtraInfos = ObjectHelper.BinaryDeserialize<Dictionary<string, RouteExtraInfo>>(GetCacheFilePath()
                , new Dictionary<string, RouteExtraInfo>(StringComparer.InvariantCultureIgnoreCase)
                );

            Load(routeExtraInfos);
        }

        public void Load(byte [] buffer)
        {
            using (MemoryStream ms = new MemoryStream(buffer))
            {
                BinaryFormatter bf = new BinaryFormatter();
                Dictionary<string, RouteExtraInfo> routeExtraInfos = (Dictionary<string, RouteExtraInfo>)bf.Deserialize(ms);

                if (routeExtraInfos == null)
                    throw new Exception("Invalid Object");

                Load(routeExtraInfos);

                ObjectHelper.BinarySerialize<Dictionary<string, RouteExtraInfo>>(routeExtraInfos, GetCacheFilePath());
            }
        }

        private void Load(Dictionary<string, RouteExtraInfo> routeExtraInfos)
        {
            if (routeExtraInfos.Count > 0)
            {
                RouteCollection routeCollection = new RouteCollection();
                foreach (RouteExtraInfo extraInfo in routeExtraInfos.Values)
                {
                    Route route = routeCollection.MapRoute(extraInfo.RouteName, extraInfo.RouteUrl);
                    route.Defaults.Add("action", extraInfo.Action);
                    route.Defaults.Add("controller", extraInfo.Controller);

                    foreach (string parameter in extraInfo.Parameters)
                    {
                        route.Defaults.Add(parameter, UrlParameter.Optional);
                    }
                    route.DataTokens["RouteName"] = extraInfo.RouteName;
                }
                this.RouteExtraInfos = routeExtraInfos;
                this.RouteCollection = routeCollection;
            }
        }

        public void LoadConfigration()
        {
            try
            {
                Logger.Information("SiteRouteInfo", "{0} LoadConfigration start", this.Domain.DistinctName);
                ContentTree tree = ContentTree.GetByDistinctName(this.Domain.DistinctName, this.Domain.TemplateDomainDistinctName, false);
                if (tree != null)
                {
                    RouteCollection routeCollection = new RouteCollection();
                    Dictionary<string, RouteExtraInfo> routeExtraInfos = new Dictionary<string, RouteExtraInfo>(StringComparer.InvariantCultureIgnoreCase);

                    Type[] types = ControllerEx.GetControllerAssembly().GetTypes();

                    foreach (KeyValuePair<string, ContentNode> item in tree.AllNodes)
                    {
                        ContentNode node = item.Value;
                        if (node.NodeType == ContentNode.ContentNodeType.Page)
                        {
                            PageNode pageNode = new PageNode(node);

                            if (string.IsNullOrWhiteSpace(pageNode.Controller))
                                continue;

                            // Get the controller class
                            Type controllerType = types.FirstOrDefault(t => t.FullName == pageNode.Controller);

                            if (controllerType == null)
                            {
                                Logger.Error("CMS", "Error, can't find the type [{0}].", pageNode.Controller);
                                continue;
                            }
                            else
                            {
                                object[] attributes = controllerType.GetCustomAttributes(typeof(ControllerExtraInfoAttribute), false);
                                ControllerExtraInfoAttribute attribute = null;
                                if (attributes.Length > 0)
                                    attribute = attributes[0] as ControllerExtraInfoAttribute;
                                else
                                    attribute = new ControllerExtraInfoAttribute() { DefaultAction = "Index" };

                                string url = pageNode.ContentNode.RelativePath;
                                if (!url.StartsWith("/")) url = "/" + url;
                                url = url.TrimEnd('/');

                                RouteExtraInfo extraInfo = new RouteExtraInfo();
                                extraInfo.RouteName = pageNode.RouteName;
                                extraInfo.RouteUrl = string.Format("{0}/{{action}}/{1}", url.TrimStart('/').TrimEnd('/'), attribute.ParameterUrl);
                                Route route = routeCollection.MapRoute(extraInfo.RouteName, extraInfo.RouteUrl);
                                extraInfo.Action = attribute.DefaultAction.DefaultIfNullOrEmpty("Index");
                                route.Defaults.Add("action", extraInfo.Action);
                                extraInfo.Controller = Regex.Replace(controllerType.Name, "(Controller)$", string.Empty, RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                                route.Defaults.Add("controller", extraInfo.Controller);

                                if (!string.IsNullOrEmpty(attribute.ParameterUrl))
                                {
                                    string[] parameters = attribute.ParameterUrl.Split('/');
                                    foreach (string parameter in parameters)
                                    {
                                        string p = parameter.TrimStart('{').TrimEnd('}');
                                        extraInfo.Parameters.Add(p);
                                        route.Defaults.Add(p, UrlParameter.Optional);
                                    }
                                }
                                extraInfo.Url = url;
                                extraInfo.ControllerType = controllerType;
                                route.DataTokens["RouteName"] = extraInfo.RouteName;

                                routeExtraInfos[extraInfo.RouteName] = extraInfo;
                            }// if_else
                        }// if
                    }// foreach

                    this.RouteExtraInfos = routeExtraInfos;
                    this.RouteCollection = routeCollection;                        

                    ObjectHelper.BinarySerialize<Dictionary<string, RouteExtraInfo>>(routeExtraInfos, GetCacheFilePath());
                }// if

                Logger.Information("SiteRouteInfo", "{0} LoadConfigration completed", this.Domain.DistinctName);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }// LoadConfigration

        public string GetCacheFilePath()
        {
            string filePath = string.Format(CultureInfo.InvariantCulture, ROUTE_CACHE_FILE, Domain.DistinctName);
            return HostingEnvironment.MapPath(filePath);
        }
    }
}
