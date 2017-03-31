using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Web.Script.Serialization;
using Casino;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize( Roles = "CMS Domain Admin,CMS System Admin")]
    public class CasinoMgtController : ControllerEx
    {
        
        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);

            return View(site);
        }


        [HttpGet]
        public JsonResult ClearCache(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
                site.ReloadCache(Request.RequestContext, CacheManager.CacheType.MetadataCache);
                site.ReloadCache(Request.RequestContext, CacheManager.CacheType.CasinoGameCache);
                site.ReloadCache(Request.RequestContext, CacheManager.CacheType.CasinoGameCategoryCache);
                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public ActionResult GameList(string distinctName, string vendor)
        {
            if (string.IsNullOrWhiteSpace(vendor))
                throw new ArgumentNullException("vendor");

            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            this.ViewData["gamePaths"] = Metadata.GetChildrenPaths(site
                , string.Format(GameManager.METADATA_PATH, vendor)
                , false
                );

            return View("GameList", site);
        }


        [HttpGet]
        public ActionResult VendorOperation(string distinctName, string vendor)
        {
            VendorID vendorID;
            if (!Enum.TryParse<VendorID>(vendor, out vendorID))
                throw new ArgumentNullException("vendor");

            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            switch (vendorID)
            {
                case VendorID.NetEnt:
                    return View("VendorOperationNetEnt", site);

                case VendorID.CTXM:
                    return View("VendorOperationCTXM", site);

                default:
                    return this.Content(string.Empty);
            }
            
        }

        
        [HttpGet]
        public ActionResult SyncNetEntGames(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            site.ReloadCache(Request.RequestContext, CacheManager.CacheType.MetadataCache);
            site.ReloadCache(Request.RequestContext, CacheManager.CacheType.CasinoGameCache);
            ConcurrentDictionary<string, Game> existingGames = Casino.GameManager.GetGames(VendorID.NetEnt, site);

            string path = string.Format(GameManager.METADATA_PATH, VendorID.NetEnt);
            path = string.Format("/Views/{0}{1}", site.DistinctName, path);
            path = HttpContext.Server.MapPath(path);

            List<string> updatedList = new List<string>();
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    GetGameIds = true,
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);
                foreach (string gameId in request.GetGameIdsResponse)
                {
                    string directory = Path.Combine(path, Game.NormaliseID(gameId));
                    string dest;
                    if (!existingGames.ContainsKey(gameId) && !gameId.EndsWith("_sw") )
                    {
                        Directory.CreateDirectory(directory);
                        string template = Server.MapPath("~/App_Data/metadata_source");
                        dest = Path.Combine(directory, ".properties.xml");
                        global::System.IO.File.Copy(template, dest, true);

                        dest = Path.Combine(directory, ".Title");
                        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                        {
                            sw.Write(gameId);
                        }

                        dest = Path.Combine(directory, ".Ins");
                        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                        {
                            sw.Write(DateTime.Now.ToFileTime());
                        }
                        updatedList.Add(gameId);

                        dest = Path.Combine(directory, ".ID");
                        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                        {
                            sw.Write(gameId);
                        }

                        dest = Path.Combine(directory, ".Vendor");
                        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                        {
                            sw.Write(VendorID.NetEnt.ToString());
                        }
                        string gameId2 = ObjectHelper.DeepClone<string>(gameId);
                        string directory2 = ObjectHelper.DeepClone<string>(directory);
                        string sessionID = GamMatrixClient.GetSessionIDForCurrentOperator();
                        long sessionUserID = CustomProfile.Current.UserID;
                        Task task = Task.Factory.StartNew(() =>
                        {
                            SyncNetEntTranslations(directory2, gameId2, sessionID, sessionUserID);
                        });
                    }
                    
                }
            }

            this.ViewData["updatedList"] = updatedList;

            return View("VendorOperationNetEnt", site);
        }

        private static void SyncNetEntTranslations(string directory, string gameId, string sessionID, long sessionUserID)
        {
            try
            {
                Dictionary<string, string> param = GameManager.GetNetEntGameParameters(gameId, "en", sessionID, sessionUserID);

                string dest = Path.Combine(directory, ".InitialWidth");
                using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                {
                    sw.Write(param["width"]);
                }

                dest = Path.Combine(directory, ".InitialHeight");
                using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                {
                    sw.Write(param["height"]);
                }

                dest = Path.Combine(directory, ".HelpFile");
                using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                {
                    sw.Write(HttpUtility.UrlDecode(param["helpfile"]));
                }

                string[] languages = { "pt-br", "bg", "hr", "cs", "da", "nl", "en", "et", "fi", "fr", "de", "el", "he",
                                     "hu", "it", "no", "pl", "pt", "ro", "ru", "sk", "es", "sv", "tr" };
                foreach (string language in languages)
                {
                    try
                    {
                        param = GameManager.GetNetEntGameParameters(gameId, language, sessionID, sessionUserID);
                        dest = Path.Combine(directory, string.Format(".HelpFile.{0}", language));
                        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
                        {
                            sw.Write(HttpUtility.UrlDecode(param["helpfile"]));
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.Exception(ex);
                    }
                    
                }
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
            }
        }


        [HttpGet]
        public ActionResult SyncCTXMGames(string distinctName)
        {
            //distinctName = distinctName.DefaultDecrypt();
            //cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            //site.ReloadCache(Request.RequestContext, CacheManager.CacheType.MetadataCache);
            //site.ReloadCache(Request.RequestContext, CacheManager.CacheType.CasinoGameCache);
            //ConcurrentDictionary<string, Game> existingGames = Casino.GameManager.GetGames(VendorID.CTXM, site);

            //string path = string.Format(GameManager.METADATA_PATH, VendorID.CTXM);
            //path = string.Format("/Views/{0}{1}", site.DistinctName, path);
            //path = HttpContext.Server.MapPath(path);

            //List<string> updatedList = new List<string>();
            //using (GamMatrixClient client = GamMatrixClient.Get() )
            //{
            //    CTXMAPIRequest request = new CTXMAPIRequest()
            //    {
            //        GetGameList = true,
            //        GetGameListLanguage = "en",
            //    };
            //    request = client.SingleRequest<CTXMAPIRequest>(request);
            //    foreach (GameType gameType in request.GetGameListResponse.gamesField)
            //    {
            //        string gameId = gameType.gameCodeField;
            //        string directory = Path.Combine(path, Game.NormaliseID(gameId));
            //        string dest;
            //        if (!existingGames.ContainsKey(gameId))
            //        {
            //            Directory.CreateDirectory(directory);
            //            string template = Server.MapPath("~/App_Data/metadata_source");
            //            dest = Path.Combine(directory, ".properties.xml");
            //            global::System.IO.File.Copy(template, dest, true);

            //            dest = Path.Combine(directory, ".Title");
            //            using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
            //            {
            //                sw.Write(gameType.gameTitleField);
            //            }

            //            dest = Path.Combine(directory, ".Category");
            //            using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
            //            {
            //                sw.Write(gameType.gameCategoryField);
            //            }

            //            dest = Path.Combine(directory, ".Description");
            //            using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
            //            {
            //                sw.Write(gameType.descriptionField);
            //            }

            //            dest = Path.Combine(directory, ".Ins");
            //            using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
            //            {
            //                sw.Write(DateTime.Now.ToFileTime());
            //            }
            //            updatedList.Add(gameId);
            //        }
            //        dest = Path.Combine(directory, ".ID");
            //        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
            //        {
            //            sw.Write(gameId);
            //        }

            //        dest = Path.Combine(directory, ".Vendor");
            //        using (StreamWriter sw = new StreamWriter(dest, false, Encoding.UTF8))
            //        {
            //            sw.Write(VendorID.CTXM.ToString());
            //        }
            //    }
            //}

            //this.ViewData["updatedList"] = updatedList;

            return View("VendorOperationCTXM", null);
        }






        [HttpGet]
        public JsonResult SetFlag(string distinctName, string path, string flagName, string flagValue)
        {
            path = path.DefaultDecrypt();
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            Metadata.Save(site, path, null, flagName, flagValue);
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }


        [HttpGet]
        public ActionResult SupportedCountry(string distinctName, string path )
        {
            path = path.DefaultDecrypt();
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            string base64 = Metadata.Get(site, string.Format( "{0}.SupportedCountry", path), null, false);
            Finance.CountryList countryList = null;
            try
            {
                using (MemoryStream ms = new MemoryStream(Convert.FromBase64String(base64)))
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    countryList = (Finance.CountryList)bf.Deserialize(ms);
                }
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
                countryList = new Finance.CountryList();
                countryList.Type = Finance.CountryList.FilterType.Exclude;
            }

            this.ViewData["path"] = path;
            this.ViewData["CountryList"] = countryList;
            return this.View("SupportedCountry", site);
        }


        [HttpPost]
        public JsonResult SaveSupportedCountry(string distinctName, string path, Finance.CountryList.FilterType filterType, List<int> list)
        {
            path = path.DefaultDecrypt();
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            Finance.CountryList countryList = new Finance.CountryList();
            countryList.Type = filterType;
            countryList.List = list;

            
            using( MemoryStream ms = new MemoryStream() )
            {
                BinaryFormatter bf = new BinaryFormatter();
                bf.Serialize(ms, countryList);
                byte[] buffer = ms.ToArray();
                string base64 = Convert.ToBase64String(buffer, 0, buffer.Length);

                Metadata.Save(site, path, null, "SupportedCountry", base64);
            }

            return this.Json(new { @success = true });
        }


        [HttpGet]
        public JsonResult GetVendorGames(string distinctName, string vendor)
        {
            VendorID vendorID;
            if (!Enum.TryParse<VendorID>(vendor, out vendorID))
                throw new ArgumentNullException("vendor");

            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            var data = GameManager.GetGames(vendorID, site)
                .Where(a => !a.Value.IsMiniGame)
                .Select(a => new { @VendorID = a.Value.VendorID.ToString(), @Title = a.Value.Title, @GameID = a.Key })
                .OrderBy( g => g.Title).ToArray();
            return this.Json( new { @success = true, @data = data }, JsonRequestBehavior.AllowGet );
        }


        [HttpGet]
        public ActionResult TreeList(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            return this.View("TreeList", site);
        }


        [HttpPost]
        public JsonResult SaveCategories(string distinctName,string jsonData)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
                if (site == null)
                    throw new ArgumentNullException("distinctName");

                JavaScriptSerializer serializer = new JavaScriptSerializer();
                List<GameCategory> categories = serializer.Deserialize<List<GameCategory>>(jsonData);
                GameManager.SaveCategories(site, categories);
                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = true, @error = ex.Message });
            }
        }


        [HttpPost]
        public ActionResult EditMetadata(string distinctName, string id, string name)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentNullException("distinctName");

            string path = string.Format(GameManager.CATEGORY_METADATA, id);
            string metadataPath = string.Format("{0}.Name", path);
            string temp = Metadata.Get(site, metadataPath, null, false);
            if (string.IsNullOrEmpty(temp))
            {
                // create the metadata and set the default value
                string physicalPath = Server.MapPath(string.Format("~/Views/{0}{1}", site.DistinctName, path));
                if (!Directory.Exists(physicalPath))
                {
                    Directory.CreateDirectory(physicalPath);
                    string template = Server.MapPath("~/App_Data/metadata_source");
                    string dest = Path.Combine(physicalPath, ".properties.xml");
                    global::System.IO.File.Copy(template, dest, false);
                }
                Metadata.Save(site, path, null, "Name", name);
            }

            string url = this.Url.RouteUrl("MetadataEditor", new { @action="Index", @distinctName = distinctName.DefaultEncrypt(), @path = path.DefaultEncrypt() });
            return Redirect(url);
        }

    }
}
