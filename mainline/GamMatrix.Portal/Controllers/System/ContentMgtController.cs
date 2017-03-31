using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Globalization;
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
    [ControllerExtraInfo(DefaultAction = "Index")]
    [SystemAuthorize( Roles = "CMS Domain Admin,CMS System Admin")]
    public class ContentMgtController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult TreeView()
        {
            List<cmSite> sites = this.GetDomainList().OrderBy( d => d.DisplayName ).ToList();

            cmSite site = sites.FirstOrDefault( s => string.Equals( s.DistinctName, "System") );
            if( site != null )
            {
                sites.Remove(site);
                sites.Insert( 0, site);
            }

            site = sites.FirstOrDefault(s => string.Equals(s.DistinctName, "MobileShared"));
            if (site != null)
            {
                sites.Remove(site);
                sites.Insert(0, site);
            }

            site = sites.FirstOrDefault( s => string.Equals( s.DistinctName, "Shared") );
            if( site != null )
            {
                sites.Remove(site);
                sites.Insert( 0, site);
            }




            this.ViewData["Domains"] = sites.Select(d => new { @DisplayName = d.DisplayName, @DistinctName = d.DistinctName.DefaultEncrypt() }).ToArray();
            return View("Tree");
        }

        [HttpGet]
        [CompressFilter]
        public ContentResult GetTreeJson(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            StringBuilder sb = new StringBuilder();
            sb.Append("[");
            var domain = SiteManager.GetSiteByDistinctName(distinctName);

            if( domain != null )
                GetDomainJsonStr(domain, ref sb);
            
            sb.Append("]");

            return this.Content(sb.ToString(), "application/json");
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ContentResult GetMetadataTreeJson(string distinctName, string privateMetadata)
        {
            distinctName = distinctName.DefaultDecrypt();
            privateMetadata = privateMetadata.DefaultDecrypt();

            StringBuilder sb = new StringBuilder();
            sb.Append("[");

            cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
            if( domain != null )
            {
                ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                if (contentTree != null)
                {
                    sb.Append("{");
                    {
                        sb.Append("\"data\":{\"title\":\"Metadata\"},\"type\":\"directory\",");
                        sb.Append("\"state\":\"open\",");
                        sb.Append("\"children\":[");

                        if (!string.IsNullOrWhiteSpace(privateMetadata))
                        {
                            sb.AppendFormat("{{\"data\":{{\"title\":\"<Internal metadata>\"}},\"type\":\"metadata\",\"children\":[],\"action\":\"{0}\"}},"
                                , privateMetadata.DefaultEncrypt()
                                );
                        }

                        GetMetadataJsonStr(contentTree.Root.Children, ref sb);
                        sb.Append("]");
                    }
                    sb.Append("}");
                }
            }

            sb.Append("]");


            return this.Content(sb.ToString(), "application/json");
        }

        private void GetDomainJsonStr(cmSite domain, ref StringBuilder sb)
        {
            sb.Append("{");
            {
                
                sb.AppendFormat("\"data\":{{\"title\":\"{0}\"}},\"type\":\"site\", \"action\":\"{1}\","
                    , domain.DisplayName.SafeJavascriptStringEncode()
                    , this.Url.RouteUrl("SiteManager", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() })
                    );

                sb.Append("\"state\":\"open\",");
                sb.Append("\"children\":[");
                {
                    sb.AppendFormat("{{\"data\":{{\"title\":\"Site Manager\"}}, \"type\":\"site-manager\", \"action\":\"{0}\"}},", this.Url.RouteUrl("SiteManager", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                    sb.AppendFormat("{{\"data\":{{\"title\":\"Route Table\"}}, \"type\":\"site-route\", \"action\":\"{0}\"}},",
                        this.Url.RouteUrl("RouteTable", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                    sb.AppendFormat("{{\"data\":{{\"title\":\"Region / Language\"}}, \"type\":\"site-region\", \"action\":\"{0}\"}},",
                        this.Url.RouteUrl("RegionLanguage", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                    if (!string.Equals(domain.DistinctName, "System", StringComparison.InvariantCultureIgnoreCase))
                    {
                        sb.AppendFormat("{{\"data\":{{\"title\":\"Search Code\"}}, \"type\":\"search-code\", \"action\":\"{0}\"}},",
                        this.Url.RouteUrl("SearchCode", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                        sb.AppendFormat("{{\"data\":{{\"title\":\"Search Metadata\"}}, \"type\":\"search-metadata\", \"action\":\"{0}\"}},",
                        this.Url.RouteUrl("SearchMetadata", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                        sb.AppendFormat("{{\"data\":{{\"title\":\"Payment Methods\"}}, \"type\":\"payment-methods\", \"action\":\"{0}\"}},",
                            this.Url.RouteUrl("PaymentMethodMgt", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));

                        if (string.Equals(domain.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase) ||
                            string.Equals(domain.DistinctName, "ArtemisBet", StringComparison.InvariantCultureIgnoreCase) )
                        {
                            sb.AppendFormat("{{\"data\":{{\"title\":\"Casino Games\"}}, \"type\":\"casino\", \"action\":\"{0}\"}},",
                                this.Url.RouteUrl("CasinoGameMgt", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                            sb.AppendFormat("{{\"data\":{{\"title\":\"Casino\"}}, \"type\":\"casino\", \"action\":\"{0}\"}},",
                                this.Url.RouteUrl("CasinoMgt", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                        }
                        else if (!string.Equals(domain.DistinctName, "StarVenusCasino", StringComparison.InvariantCultureIgnoreCase) &&
                            !string.Equals(domain.DistinctName, "IntraGame", StringComparison.InvariantCultureIgnoreCase) &&
                            !string.Equals(domain.DistinctName, "BingoInferno", StringComparison.InvariantCultureIgnoreCase) &&
                            !string.Equals(domain.DistinctName, "TowerGaming", StringComparison.InvariantCultureIgnoreCase) )
                        {
                            sb.AppendFormat("{{\"data\":{{\"title\":\"Casino Games\"}}, \"type\":\"casino\", \"action\":\"{0}\"}},",
                                this.Url.RouteUrl("CasinoGameMgt", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                        }
                        else
                        {
                            sb.AppendFormat("{{\"data\":{{\"title\":\"Casino\"}}, \"type\":\"casino\", \"action\":\"{0}\"}},",
                                this.Url.RouteUrl("CasinoMgt", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                        }
                    }
                    /*
                    if (!string.Equals(domain.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase) &&
                        !string.Equals(domain.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase) &&
                        !string.Equals(domain.DistinctName, "System", StringComparison.InvariantCultureIgnoreCase) &&
                        CustomProfile.Current.IsInRole("CMS System Admin") )
                    {
                        sb.AppendFormat("{{\"data\":{{\"title\":\"Terms & Conditions\"}}, \"type\":\"terms-conditions\", \"action\":\"{0}\"}},",
                            this.Url.RouteUrl("TermsConditionsManager", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt() }));
                    }
                    */
                    sb.Append("{");
                    sb.Append("\"data\":{\"title\":\"Content\",\"id\":\"root-content\"},\"state\":\"open\",\"type\":\"site-content\",");
                    sb.AppendFormat("\"action\":\"{0}\",", this.Url.RouteUrl("DirectoryMgt", new { @action = "Index", @distinctName = domain.DistinctName.DefaultEncrypt(), @relativePath = "/".DefaultEncrypt() }) );
                    sb.Append("\"children\":[");

                    if (!string.Equals( domain.DistinctName, "System", StringComparison.OrdinalIgnoreCase) )
                    {
                        ContentTree tree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                        if(tree != null && tree.Root.Children.Count > 0)
                            GetContentJsonStr(tree.Root.Children, ref sb);
                    }
                    sb.Append("]}");
                }
                sb.Append("]");
            }
            sb.Append("}");
        }

        private void GetContentJsonStr(ConcurrentDictionary<string, ContentNode> children, ref StringBuilder sb)
        {
            ContentNode[] nodes = children.Values.ToArray();
            nodes = nodes.OrderBy(n => n.Name).OrderByDescending(n => n.NodeType).ToArray();

            foreach (ContentNode child in nodes)
            {
                if (child.Name.StartsWith("_"))
                    continue;
                sb.Append("{");
                sb.AppendFormat("\"data\":{{\"title\":\"{0}\", \"id\":\"{1}\"}},"
                    , child.DisplayName.SafeJavascriptStringEncode()
                    , Convert.ToString(child.PhysicalPath.GetHashCode(), 16)
                    );
                sb.AppendFormat("\"type\":\"{0}\",", Enum.GetName( typeof(ContentNode.ContentNodeType), child.NodeType).ToLowerInvariant().SafeJavascriptStringEncode());

                sb.AppendFormat("\"action\":\"{0}\",", Url.GetActionUrl(child).SafeJavascriptStringEncode());
                sb.AppendFormat("\"inherited\":{0},", (child.NodeStatus == ContentNode.ContentNodeStatus.Inherited).ToString().ToLowerInvariant());
                sb.AppendFormat("\"overrode\":{0},", (child.NodeStatus == ContentNode.ContentNodeStatus.Overrode).ToString().ToLowerInvariant());
                sb.AppendFormat("\"disabled\":{0},", child.IsDisabled.ToString().ToLowerInvariant());
                sb.Append("\"state\":\"close\",");
                sb.Append("\"children\":[");
                GetContentJsonStr(child.Children, ref sb);
                sb.Append("]");
                sb.Append("},");
            }
            if (sb[sb.Length - 1] == ',')
                sb.Remove(sb.Length - 1, 1);
        }


        private void PrepareCountries()
        {
            var cultures = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
               .Where(r => Regex.IsMatch(r.Name, @"^([a-z]{2}(\-[a-z]{2})?)$", RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant))
               .OrderBy(r => r.DisplayName)
               .Select(r => new SelectListItem() { Text = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), Value = r.Name });
            this.ViewData["CultureList"] = cultures;
        }

        private List<cmSite> GetDomainList()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return new List<cmSite>();

            SiteAccessor ua = DataAccessor.CreateInstance<SiteAccessor>();
            List<cmSite> sites = new List<cmSite>();

            if (CustomProfile.Current.IsInRole("CMS System Admin"))
                sites = ua.GetAll().ToList();
            else if (CustomProfile.Current.IsInRole("CMS Domain Admin"))
                sites = ua.GetByDomainID(CustomProfile.Current.DomainID);

            return sites;
        }


        private void GetMetadataJsonStr(ConcurrentDictionary<string, ContentNode> children, ref StringBuilder sb)
        {
            ContentNode[] nodes = children.Values.OrderBy(n => n.Name).ToArray();
            foreach (ContentNode child in nodes)
            {
                if (child.Name.StartsWith("_"))
                    continue;

                if (child.NodeType != ContentNode.ContentNodeType.Directory &&
                    child.NodeType != ContentNode.ContentNodeType.Metadata)
                {
                    continue;
                }
                sb.Append("{");
                sb.AppendFormat("\"data\":{{\"title\":\"{0}\", \"id\":\"me-{1}\"}},"
                    , child.DisplayName.SafeJavascriptStringEncode()
                    , Convert.ToString(child.PhysicalPath.GetHashCode(), 16)
                    );
                sb.AppendFormat("\"type\":\"{0}\",", Enum.GetName(typeof(ContentNode.ContentNodeType), child.NodeType).ToLowerInvariant().SafeJavascriptStringEncode());

                if( child.NodeType == ContentNode.ContentNodeType.Metadata )
                    sb.AppendFormat("\"action\":\"{0}\",", child.RelativePath.DefaultEncrypt().SafeJavascriptStringEncode() );
                sb.AppendFormat("\"inherited\":{0},", (child.NodeStatus == ContentNode.ContentNodeStatus.Inherited).ToString().ToLowerInvariant());
                sb.AppendFormat("\"overrode\":{0},", (child.NodeStatus == ContentNode.ContentNodeStatus.Overrode).ToString().ToLowerInvariant());
                sb.Append("\"state\":\"close\",");
                sb.Append("\"children\":[");
                GetMetadataJsonStr(child.Children, ref sb);
                sb.Append("]");
                sb.Append("},");
            }
            if (sb.Length > 0 && sb[sb.Length - 1] == ',')
                sb.Remove(sb.Length - 1, 1);
        }
    }
}
