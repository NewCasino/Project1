using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Xml.Linq;
using CasinoEngine;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.Web;
using GamMatrixAPI;
using System.Configuration;
using System.Web;
using System.Web.Caching;
using BLToolkit.Data;
using CM.db.Accessor;
using BLToolkit.DataAccess;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class CasinoGameMgtController : ControllerEx
    {

        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);

            return View(site);
        }


        [HttpGet]
        public ActionResult GameList(string distinctName, string vendor)
        {
            if (string.IsNullOrWhiteSpace(vendor))
                throw new ArgumentNullException("vendor");

            this.ViewData["VendorID"] = Enum.Parse(typeof(VendorID), vendor);
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            return View("GameList", site);
        }

        [HttpGet]
        public ActionResult EditGameTranslation(string distinctName, string gameID)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            var games = CasinoEngineClient.GetGames(site);

            Game game = null;
            if (!games.TryGetValue(gameID, out game))
                throw new ArgumentException("gameID");

            // verify if the metadata exists; if not presented, then need be created first
            string path = string.Format(Game.GAME_TRANSLATION_PATH, gameID);
            if (Metadata.CreateMetadata(site, path))
            {
                string content;
                if (!string.IsNullOrWhiteSpace(game.ThumbnailUrl))
                {
                    content = string.Format("<img src=\"{0}\" />", game.ThumbnailUrl.SafeHtmlEncode());
                    Metadata.Save(site, path, null, "Thumbnail", content);
                }

                if (!string.IsNullOrWhiteSpace(game.LogoUrl))
                {
                    content = string.Format("<img src=\"{0}\" />", game.LogoUrl.SafeHtmlEncode());
                    Metadata.Save(site, path, null, "Logo", content);
                }

                if (!string.IsNullOrWhiteSpace(game.BackgroundImageUrl))
                {
                    content = string.Format("<img src=\"{0}\" />", game.BackgroundImageUrl.SafeHtmlEncode());
                    Metadata.Save(site, path, null, "BackgroundImage", content);
                }

                Metadata.Save(site, path, null, "Name", game.EnglishName);
                Metadata.Save(site, path, null, "ShortName", game.EnglishShortName);
                Metadata.Save(site, path, null, "Description", game.EnglishDescription);
            }


            string url = this.Url.RouteUrl("MetadataEditor", new
            {
                @action = "Index",
                @distinctName = distinctName.DefaultEncrypt(),
                @path = path.DefaultEncrypt(),
            });
            return this.Redirect(url);
        }

        [HttpGet]
        public ActionResult EditLiveCasinoTableTranslation(string distinctName, string tableID)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            var tables = CasinoEngineClient.GetLiveCasinoTables(site);

            LiveCasinoTable table = null;
            if (!tables.TryGetValue(tableID, out table))
                throw new ArgumentException("tableID");

            // verify if the metadata exists; if not presented, then need be created first
            string path = string.Format(Game.GAME_TRANSLATION_PATH, table.ID);
            if (Metadata.CreateMetadata(site, path))
            {
                Metadata.Save(site, path, null, "Name", table.Name);
                Metadata.Save(site, path, null, "ShortName", table.EnglishShortName);
            }


            string url = this.Url.RouteUrl("MetadataEditor", new
            {
                @action = "Index",
                @distinctName = distinctName.DefaultEncrypt(),
                @path = path.DefaultEncrypt(),
            });
            return this.Redirect(url);
        }

        /*
<root>
	<node type="category" label="Classic Slots" isBranch="true">
		<node label="Microgaming" vendor="Microgaming" />
		<node label="Microgaming" vendor="Microgaming" />
		<node label="NetEnt" vendor="NetEnt" />
		<node label="NetEnt" vendor="NetEnt" />
		<node label="NetEnt" vendor="NetEnt" />
		<node type="group" label="All American" isBranch="true">
			<node label="CTXM" vendor="CTXM" />
			<node label="NetEnt" vendor="NetEnt" />
			<node label="NetEnt" vendor="NetEnt" />
			<node label="NetEnt" vendor="NetEnt" />
			<node label="NetEnt" vendor="NetEnt" />
		</node>
	</node>
				
	<node type="category" label="Video Slots" isBranch="true">
		<node label="NetEnt" vendor="NetEnt" />
		<node label="IGT" vendor="IGT" />
		<node label="NetEnt" vendor="NetEnt" />
		<node label="NetEnt" vendor="NetEnt" />
		<node label="NetEnt" vendor="NetEnt" />
		<node label="NetEnt" vendor="NetEnt" />
	</node>
	<node type="category" label="Table Games" isBranch="true">
		<node label="IGT" vendor="IGT" />
		<node label="IGT" vendor="IGT"/>
		<node label="IGT" vendor="IGT"/>
		<node label="IGT" vendor="IGT" />
	</node>
	<node type="category" label="Video Poker" isBranch="true">
		<node label="CTXM" vendor="CTXM"/>
		<node label="CTXM" vendor="CTXM" />
		<node label="CTXM" vendor="CTXM"/>
	</node>
	<node type="category" label="Jackpots" isBranch="true" />
</root>
         */

        [HttpGet]
        public ActionResult GetGameCategoryXml(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            string path = HostingEnvironment.MapPath(string.Format(GameMgr.GAME_CATEGORY_XML_PATH, site.DistinctName));

            string xml = WinFileIO.ReadWithoutLock(path);
            if ((xml == null) && (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName)))
            {
                path = HostingEnvironment.MapPath(string.Format(GameMgr.GAME_CATEGORY_XML_PATH, site.TemplateDomainDistinctName));
                xml = WinFileIO.ReadWithoutLock(path);
            }

            if (string.IsNullOrWhiteSpace(xml))
            {
                xml = @"<?xml version=""1.0"" encoding=""utf-8"" ?>
<root>
    <node id=""48238ECC-701D-11E1-8F5A-A9D84724019B"" type=""category"" label=""Table Games"" isBranch=""true""/>
    <node id=""3B487A46-701D-11E1-96CD-8FD84724019B"" type=""category"" label=""Classic Slots"" isBranch=""true""/>
    <node id=""409A2FD0-701D-11E1-B901-91D84724019B"" type=""category"" label=""Video Slots"" isBranch=""true""/>
    <node id=""45411148-701D-11E1-8368-A5D84724019B"" type=""category"" label=""Video Pokers"" isBranch=""true""/>
    <node id=""57EEDE40-755B-11E1-A42F-5B0F4824019B"" type=""category"" label=""Lottery"" isBranch=""true""/>
    <node id=""FBA7628A-C64A-B5BC-A563-29685ED129C4"" type=""category"" label=""Jackpot Games"" isBranch=""true""/>
    <node id=""8B0DA533-5DE7-6F84-FC24-A34916EF5E3D"" type=""category"" label=""Scratch Cards"" isBranch=""true""/>
    <node id=""1F968CA6-BF38-453F-D0B3-A34804101A7F"" type=""category"" label=""Other Games"" isBranch=""true""/>
</root>";
            }

            XDocument xDoc = XDocument.Parse(xml);
            IEnumerable<XElement> elements = xDoc.Descendants("node");
            foreach (XElement element in elements)
            {
                if (element.Attribute("type") == null ||
                    element.Attribute("id") == null)
                    continue;
                string type = element.Attribute("type").Value;
                string id = element.Attribute("id").Value;
                if (string.IsNullOrWhiteSpace(type) || string.IsNullOrWhiteSpace(id))
                    continue;
                string metadataPath = string.Format(GameCategory.NAME_ENTRY_PATH, id);
                string label = Metadata.Get(site, metadataPath, "en");
                if (!string.IsNullOrWhiteSpace(label))
                    element.Attribute("label").Value = label;
            }



            return this.Content(xDoc.ToString(), "text/xml", Encoding.UTF8);
        }

        public List<LiveCasinoCategory> GetLiveCasinoCategoryFromMetadata(string distinctName)
        { 
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            List<LiveCasinoCategory> ctList = new List<LiveCasinoCategory>();
            string[] paths = Metadata.GetChildrenPaths(site,"/Metadata/LiveCasino/GameCategory");
            LiveCasinoCategory ct = new LiveCasinoCategory();
            foreach (string path in paths)
            {
                ct = new LiveCasinoCategory();
                ct.CategoryKey = Regex.Split(path, "/", RegexOptions.IgnoreCase)[Regex.Split(path, "/", RegexOptions.IgnoreCase).Length - 1];
                ct.CategoryName = Metadata.Get(site, string.Format("{0}.Text", path),"en").DefaultIfNullOrEmpty(ct.CategoryKey);
                ct.CategoryTitle = Metadata.Get(site, string.Format("{0}.Title", path), "en").DefaultIfNullOrEmpty(ct.CategoryName);
                if (!ct.CategoryKey.Equals("all", StringComparison.InvariantCultureIgnoreCase))
                {
                    ctList.Add(ct);
                }  
            } 
            return ctList;
        }

        [HttpGet]
        public ActionResult GetLiveCasinoTableCategoryXml(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            string path = HostingEnvironment.MapPath(string.Format(GameMgr.TABLE_CATEGORY_XML_PATH, site.DistinctName));

            string xml = WinFileIO.ReadWithoutLock(path);
            if((xml == null) && (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName)))
            {
                path = HostingEnvironment.MapPath(string.Format(GameMgr.TABLE_CATEGORY_XML_PATH, site.TemplateDomainDistinctName));
                xml = WinFileIO.ReadWithoutLock(path);
            }
            List<LiveCasinoCategory> ctList = GetLiveCasinoCategoryFromMetadata(distinctName);
            if (string.IsNullOrWhiteSpace(xml))
            {
                if (ctList.Count > 0)
                { 
            StringBuilder sb = new StringBuilder();
            sb.Append(@"<?xml version=""1.0"" encoding=""utf-8"" ?><root>");
            for (int i = 0; i < ctList.Count; i++)
            {
                sb.Append(string.Format(@"<node id=""{0}"" type=""category"" label=""{1}"" isBranch=""true""/>",
                ctList[i].CategoryKey,
                ctList[i].CategoryName
                ));
            }
            sb.Append(@"</root>");
            xml = sb.ToString();
                }
                else
                {
                    xml = @"<?xml version=""1.0"" encoding=""utf-8"" ?>
<root>
    <node id=""BACCARAT"" type=""category"" label=""Baccarat"" isBranch=""true""/>
    <node id=""BLACKJACK"" type=""category"" label=""Blackjack"" isBranch=""true""/>
    <node id=""HOLDEM"" type=""category"" label=""Hold`em"" isBranch=""true""/>
    <node id=""ROULETTE"" type=""category"" label=""Roulette"" isBranch=""true""/>
    <node id=""POKER"" type=""category"" label=""Poker"" isBranch=""true""/>
    <node id=""SICBO"" type=""category"" label=""Sic Bo"" isBranch=""true""/> 
    <node id=""LOTTERY"" type=""category"" label=""Lottery"" isBranch=""true""/> 
</root>";
                }
            }

            XDocument xDoc = XDocument.Parse(xml);
            IEnumerable<XElement> elements = xDoc.Descendants("node");       
            for (int i = 0; i < ctList.Count; i++)
            {
                bool isUsed = false;
                foreach (XElement element in elements)
                {
                    if (element.Attribute("type") != null
                        &&
                        element.Attribute("type").Value.ToString().Equals("category", StringComparison.InvariantCultureIgnoreCase)
                        &&
                        element.Attribute("id").Value.ToString().Equals(ctList[i].CategoryKey, StringComparison.InvariantCultureIgnoreCase)
                        )
                    {
                        isUsed = true;
                    }
                }
                if (!isUsed)
                {
                    XElement xtm = new XElement(
                        "node", new XAttribute("id", ctList[i].CategoryKey),
                        new XAttribute("type", "category"),
                        new XAttribute("label", ctList[i].CategoryName),
                        new XAttribute("isBranch", "true")
                    );
                    xDoc.Root.Add(xtm);
                }

            } 
            elements = xDoc.Descendants("node"); 
            foreach (XElement element in elements)
            {
 
                if (element.Attribute("type") == null ||
                    element.Attribute("id") == null)
                    continue;
                string type = element.Attribute("type").Value;
                string id = element.Attribute("id").Value;
                if (string.IsNullOrWhiteSpace(type) || string.IsNullOrWhiteSpace(id))
                    continue;
                string metadataPath = string.Format(GameCategory.NAME_ENTRY_PATH, id);
                string label = Metadata.Get(site, metadataPath, "en");
                if (!string.IsNullOrWhiteSpace(label))
                    element.Attribute("label").Value = label;
            }


            return this.Content(xDoc.ToString(), "text/xml", Encoding.UTF8);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="distinctName"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveGameCategoryXml(string distinctName, string xmlStr)
        {
   
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            GameMgr.SaveGameCategoryXml(site, xmlStr);

            return this.Content("OK", "text/plain", Encoding.UTF8);
        }

        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveTableCategoryXml(string distinctName, string xmlStr)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            try
            {
                GameMgr.SaveTableCategoryXml(site, xmlStr);
            }
            catch (Exception ex)
            {
                throw new ArgumentException(ex.Message);
            }
            return this.Content("OK", "text/plain", Encoding.UTF8);
        }


        /// <summary>
        /// Get Game List Xml
        /// </summary>
        /// <param name="distinctName"></param>
        /// <returns></returns>
        [HttpGet]
        public ActionResult GetGameListXml(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            StringBuilder xml = new StringBuilder();
            xml.AppendLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
            xml.AppendLine("<root>");
            Dictionary<string, Game> games = CasinoEngine.CasinoEngineClient.GetGames(site, false);
            foreach (var item in games)
            {
                if (!Regex.IsMatch(item.Key, @"^(\d+)$", RegexOptions.Compiled))
                    continue;
                xml.AppendFormat("<node label=\"{0}\" vendor=\"{1}\" id=\"{2}\" categories=\"{3}\" platforms=\"{4}\" />"
                    , item.Value.EnglishName.SafeHtmlEncode()
                    , item.Value.VendorID.ToString()
                    , item.Value.ID.SafeHtmlEncode()
                    , String.Join(",", item.Value.Categories.Select(c => c.ToString()).ToArray())
                    , String.Join(",", item.Value.Platforms.Select(c => c.ToString()).ToArray())
                    );

            }

            xml.AppendLine("</root>");
            return this.Content(xml.ToString(), "text/xml", Encoding.UTF8);
        }


        /// <summary>
        /// Get Live Caisno Table List Xml
        /// </summary>
        /// <param name="distinctName"></param>
        /// <returns></returns>
        [HttpGet]
        public ActionResult GetLiveCasinoTableListXml(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            StringBuilder xml = new StringBuilder();
            xml.AppendLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
            xml.AppendLine("<root>");
            Dictionary<string, LiveCasinoTable> tables = CasinoEngine.CasinoEngineClient.GetLiveCasinoTables(site, false);
            foreach (var item in tables)
            {
                List<string> platforms = item.Value.Platforms.Select(p => p.ToString()).ToList();

                xml.AppendFormat("<node label=\"{0}\" vendor=\"{1}\" id=\"{2}\" categories=\"{3}\" platforms=\"{4}\" viptable=\"{5}\" newtable=\"{6}\" />"
                    , item.Value.EnglishName.SafeHtmlEncode()
                    , item.Value.VendorID.ToString()
                    , item.Value.ID.SafeHtmlEncode()
                    , item.Value.LiveCasinoCategory.SafeHtmlEncode()
                    , String.Join(",", platforms) 
                    , item.Value.IsVIPTable.ToString()
                    , item.Value.IsNewTable.ToString()
                    );
            }

            xml.AppendLine("</root>");
            return this.Content(xml.ToString(), "text/xml", Encoding.UTF8);
        }

        [HttpGet]
        public ActionResult EditTranslation(string distinctName, bool isCategory, string id, string label)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            string path = string.Format(GameCategory.TRANSLATION_PATH, id);
            if (isCategory)
                GameMgr.EnsureCategoryExist(site, id, label);
            else
                GameMgr.EnsureGroupExist(site, id, label);

            string url = this.Url.RouteUrl("MetadataEditor", new
            {
                @action = "Index",
                @distinctName = distinctName.DefaultEncrypt(),
                @path = path.DefaultEncrypt(),
            });
            return this.Redirect(url);
        }

        [HttpGet]
        public ActionResult EditLiveCasinoTranslation(string distinctName, bool isCategory, string id, string label)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            string path = string.Format(GameCategory.TRANSLATION_PATH, id);

            if (isCategory)
            {
                string url = this.Url.RouteUrl("MetadataEditor", new
                {
                    @action = "Index",
                    @distinctName = distinctName.DefaultEncrypt(),
                    @path = "/LiveCasino/Hall/GameNavWidget/_Main_ascx".DefaultEncrypt(),
                    @key = string.Format("Category_{0}", id)
                });
                return this.Redirect(url);
            }
            else
            {
                string url = this.Url.RouteUrl("CasinoGameMgt", new
                {
                    @action = "EditLiveCasinoTableTranslation",
                    @distinctName = distinctName.DefaultEncrypt(),
                    tableID = id,
                });
                return this.Redirect(url);
            }
        }


        [HttpPost]
        public JsonResult SaveFeedsType(string distinctName, string feedsType)
        {
            if (!CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
            {
                return this.Json(new { @success = false, @error = "No permission" }, JsonRequestBehavior.AllowGet);
            }

            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                return this.Json(new { @success = false, @error = "can't find the distinctname" }, JsonRequestBehavior.AllowGet);

            CasinoEngine.FeedsType type;
            if (!Enum.TryParse<CasinoEngine.FeedsType>(feedsType, out type))
                return this.Json(new { @success = false, @error = "Invalid feeds type" }, JsonRequestBehavior.AllowGet);

            try
            {
                string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/ce_feeds_type.setting", site.DistinctName));

                string relativePath = "/.config/ce_feeds_type.setting";
                string name = "Casino Feeds Configuration";

                Revisions.BackupIfNotExists(site, filePath, relativePath, name);

                ObjectHelper.BinarySerialize<CasinoEngine.FeedsType>(type, filePath);

                using (DbManager dbManager = new DbManager())
                {
                    // begin the transaction
                    dbManager.BeginTransaction();
                    try
                    {
                        SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>(dbManager);
                        da.UpdateFeedType(site.DomainID, (int)type);
                        dbManager.CommitTransaction();
                    }
                    catch
                    {
                        // commit even failed
                        //dbManager.RollbackTransaction();
                    }
                }

                Revisions.Backup(site, filePath, relativePath, name);

                //CasinoEngineClient.GetVendors(site, false);
                //CasinoEngineClient.GetLiveCasinoTables(site, false);
                //CasinoEngineClient.GetGames(site, false);
                //CasinoEngineClient.GetJackpots(site, false);
                //CasinoEngineClient.GetTopWinners(site, true, false);
                //CasinoEngineClient.GetTopWinners(site, false, false);
                //CasinoEngineClient.GetRecentWinners(site, true, false);
                //CasinoEngineClient.GetRecentWinners(site, false, false);
                //CasinoEngineClient.ClearGameInfoCache(site);
                //CasinoEngineClient.GetContentProviders(site, false);

                site.ReloadCache(Request.RequestContext, CacheManager.CacheType.CasinoEngineCache);

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
