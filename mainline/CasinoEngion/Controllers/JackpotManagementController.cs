using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CE.db;
using GamMatrixAPI;
using Jackpot;
using CasinoEngine.Models;
using Newtonsoft.Json;
using CE.db.Accessor;
using CE.Utils;

namespace CasinoEngine.Controllers
{
    [SystemAuthorize]
    public class JackpotManagementController : Controller
    {
        //
        // GET: /JackpotManagement/

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult JackpotList(VendorID[] filteredVendorIDs)
        {
            List<ceCasinoJackpotBaseEx> jackpots = new List<ceCasinoJackpotBaseEx>();
            long domainID = DomainManager.CurrentDomainID;

            int total = -1;

            jackpots = CasinoJackpotAccessor.SearchJackpots(domainID, filteredVendorIDs);
            total = jackpots.Count;
            return View("JackpotList", jackpots);
        }

        [HttpGet]
        public ActionResult JackpotEditorDialog(long? baseId, long? jackpotId)
        {
            ceCasinoJackpotBaseEx jackpot = null;
            if ( (baseId.HasValue && baseId.Value > 0) || (jackpotId.HasValue && jackpotId.Value > 0) )
            {
                long domainID = DomainManager.CurrentDomainID;
                long ceJackpotId = jackpotId.Value;
                if (baseId.HasValue && baseId.Value > 0)
                {
                    ceCasinoJackpot domainJackpot = CasinoJackpotAccessor.QueryDomainJackpot(DomainManager.CurrentDomainID, baseId.Value);
                    if (domainJackpot != null)
                    {
                        ceJackpotId = domainJackpot.ID;
                    }
                }
                jackpot = CasinoJackpotAccessor.GetByKey(DomainManager.CurrentDomainID, baseId.Value, ceJackpotId);
            }
            if (jackpot == null)
                jackpot = new ceCasinoJackpotBaseEx();
            return View("JackpotEditorDialog", jackpot);
        }

        [HttpPost]
        public JsonResult SaveJackpot(ceCasinoJackpotBaseEx updatedJackpot)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
            {
                SqlQuery<ceCasinoJackpotBase> query = new SqlQuery<ceCasinoJackpotBase>();
                ceCasinoJackpotBase jackpot = null;
                if (updatedJackpot.BaseID > 0)
                {
                    jackpot = query.SelectByKey(updatedJackpot.BaseID);
                }
                if (jackpot == null)
                    jackpot = new ceCasinoJackpotBase()
                    {
                        VendorID = updatedJackpot.VendorID,
                        Ins = DateTime.Now,
                        DomainID = DomainManager.CurrentDomainID,
                        SessionUserID = CurrentUserSession.UserID,
                    };
                jackpot.ID = updatedJackpot.BaseID;
                jackpot.Name = updatedJackpot.Name;
                jackpot.VendorID = updatedJackpot.VendorID;
                jackpot.GameIDs = updatedJackpot.GameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',');
                jackpot.IsFixedAmount = false;
                jackpot.MappedJackpotID = updatedJackpot.MappedJackpotID;
                jackpot.CustomVendorConfig = InitCustomVendorConfig(updatedJackpot.CustomVendorConfig);
                if (updatedJackpot.BaseID > 0)
                    query.Update(jackpot);
                else
                    query.Insert(jackpot);
            }
            else
            {
                SqlQuery<ceCasinoJackpot> query = new SqlQuery<ceCasinoJackpot>();
                ceCasinoJackpotBaseEx domainJackpot = null;
                ceCasinoJackpot ceCasinoJackpot;
                long ceJackpotId = updatedJackpot.JackpotID;
                if (updatedJackpot.BaseID > 0)
                    ceCasinoJackpot = CasinoJackpotAccessor.QueryDomainJackpot(DomainManager.CurrentDomainID, updatedJackpot.BaseID);
                else
                    ceCasinoJackpot = query.SelectByKey(updatedJackpot.JackpotID);
                if (ceCasinoJackpot != null)
                    ceJackpotId = ceCasinoJackpot.ID;
                if (updatedJackpot.BaseID > 0 || ceJackpotId > 0)
                {
                    domainJackpot = CasinoJackpotAccessor.GetByKey(DomainManager.CurrentDomainID, updatedJackpot.BaseID, ceJackpotId);
                }
                if (ceCasinoJackpot == null) 
                { 
                    ceCasinoJackpot = new ceCasinoJackpot();
                    ceCasinoJackpot.Ins = DateTime.Now;
                    ceCasinoJackpot.DomainID = DomainManager.CurrentDomainID;
                    ceCasinoJackpot.SessionUserID = CurrentUserSession.UserID;
                }
                if (domainJackpot == null)
                {
                    ceCasinoJackpot.CasinoJackpotBaseID = updatedJackpot.BaseID;
                    ceCasinoJackpot.Name = updatedJackpot.Name.Trim(); 
                    ceCasinoJackpot.VendorID = updatedJackpot.VendorID;
                    ceCasinoJackpot.IsDeleted = false;
                    if (!(updatedJackpot.GameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',')).Equals(string.Empty)) 
                    {
                        ceCasinoJackpot.GameIDs = updatedJackpot.GameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',');
                    }
                    if (!string.IsNullOrEmpty(updatedJackpot.MappedJackpotID))
                    {
                        ceCasinoJackpot.MappedJackpotID = updatedJackpot.MappedJackpotID;
                    }
                    if (!string.IsNullOrEmpty(updatedJackpot.CustomVendorConfig))
                    {
                        ceCasinoJackpot.CustomVendorConfig = InitCustomVendorConfig(updatedJackpot.CustomVendorConfig);
                    }
                } 
                else
                {
                    if (updatedJackpot.BaseID != 0) { ceCasinoJackpot.CasinoJackpotBaseID = updatedJackpot.BaseID; }
                    if (!(updatedJackpot.Name.Trim()).Equals(domainJackpot.Name.DefaultIfNullOrEmpty(string.Empty).Trim())) { ceCasinoJackpot.Name = updatedJackpot.Name.Trim(); }
                    if (domainJackpot.VendorID != updatedJackpot.VendorID) { ceCasinoJackpot.VendorID = updatedJackpot.VendorID; }
                    if (!(updatedJackpot.GameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',')).Equals(domainJackpot.GameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',')))
                    {
                        ceCasinoJackpot.GameIDs = updatedJackpot.GameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',');
                    }
                    if (!(updatedJackpot.BaseCurrency.DefaultIfNullOrEmpty(string.Empty).Trim()).Equals(domainJackpot.BaseCurrency))
                    {
                        ceCasinoJackpot.BaseCurrency = updatedJackpot.BaseCurrency.DefaultIfNullOrWhiteSpace(null);
                    }
                    if (!(updatedJackpot.MappedJackpotID.DefaultIfNullOrEmpty(string.Empty)).Equals(domainJackpot.MappedJackpotID))
                    {
                        ceCasinoJackpot.MappedJackpotID = updatedJackpot.MappedJackpotID.DefaultIfNullOrWhiteSpace(null);
                    }
                    if (!(updatedJackpot.HiddenGameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',')).Equals(domainJackpot.HiddenGameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',')))
                    {
                        ceCasinoJackpot.HiddenGameIDs = updatedJackpot.HiddenGameIDs.DefaultIfNullOrEmpty(string.Empty).Trim(',');
                    }
                    if (!(updatedJackpot.CustomVendorConfig.DefaultIfNullOrEmpty(string.Empty)).Equals(domainJackpot.CustomVendorConfig))
                    {
                        ceCasinoJackpot.CustomVendorConfig = InitCustomVendorConfig(updatedJackpot.CustomVendorConfig);
                    }
                }
                ceCasinoJackpot = initJackpot(ceCasinoJackpot);
                if (ceJackpotId > 0)
                    query.Update(ceCasinoJackpot);
                else
                    query.Insert(ceCasinoJackpot);
            }


            CacheManager.ClearLocalCache(Constant.JackpotListCachePrefix);

            return this.Json(new { @success = true });
        }

        [HttpGet]
        public JsonResult DeleteJackpot(long baseId, long jackpotId)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
            {
                SqlQuery<ceCasinoJackpotBase> query = new SqlQuery<ceCasinoJackpotBase>();
                ceCasinoJackpotBase jackpot = null;
                jackpot = query.SelectByKey(baseId);
                jackpot.IsDeleted = true;
                query.Update(jackpot);
            }
            else
            {
                bool insertFlag = false;
                SqlQuery<ceCasinoJackpot> query = new SqlQuery<ceCasinoJackpot>();
                ceCasinoJackpot domainJackpot = null;
                if ( baseId > 0 )
                {
                    domainJackpot = CasinoJackpotAccessor.QueryDomainJackpot(DomainManager.CurrentDomainID, baseId);
                }
                else
                {
                    domainJackpot = query.SelectByKey(jackpotId);
                }
                if (domainJackpot == null)
                {
                    insertFlag = true;
                    domainJackpot = new ceCasinoJackpot()
                    {
                        Ins = DateTime.Now,
                        DomainID = DomainManager.CurrentDomainID,
                        SessionUserID = CurrentUserSession.UserID,
                    };
                }
                domainJackpot = initJackpot(domainJackpot);
                if ( baseId > 0 )
                {
                    domainJackpot.CasinoJackpotBaseID = baseId;
                }
                domainJackpot.IsDeleted = true;

                if (insertFlag)
                    query.Insert(domainJackpot);
                else
                    query.Update(domainJackpot);
            }
            CacheManager.ClearLocalCache(Constant.JackpotListCachePrefix);
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult HideJackpotGame(long baseId, long jackpotId, string gameId)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            bool dbResult = false;
            if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
            {
                dbResult = HideOrShowJackpotGameForSys(baseId, gameId, true);
            }
            else
            {
                dbResult = HideOrShowJackpotGameForOperator(baseId, jackpotId, gameId, true);
            }
            if (!dbResult)
            {
                return this.Json(new { @success = false });
            }
            CacheManager.ClearLocalCache(Constant.JackpotListCachePrefix);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult ShowJackpotGame(long baseId, long jackpotId, string gameId)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            bool dbResult = false;
            if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
            {
                dbResult = HideOrShowJackpotGameForSys(baseId, gameId, false);
            }
            else
            {
                dbResult = HideOrShowJackpotGameForOperator(baseId, jackpotId, gameId, false);
            }
            if (!dbResult)
            {
                return this.Json(new { @success = false });
            }

            CacheManager.ClearLocalCache(Constant.JackpotListCachePrefix);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult LoadCustomJackpots(VendorID vendorId, string url)
        {
            VendorID[] filteredVendorIDs = { vendorId };

            Dictionary<string, JackpotInfo> customJackpots = null;
            var query = new SqlQuery<ceCasinoJackpotBase>();
            long domainID = DomainManager.CurrentDomainID;

            var jackpots = CasinoJackpotAccessor.SearchJackpots(domainID, filteredVendorIDs);

            switch (vendorId)
            {
                case VendorID.Microgaming:
                    customJackpots = JackpotFeeds.GetMicrogamingJackpots(url);

                    break;
                case VendorID.PlaynGO:
                    customJackpots = JackpotFeeds.GetPlaynGOJackpots(Constant.SystemDomainID, url);

                    break;
                case VendorID.IGT:
                    customJackpots = JackpotFeeds.GetIGTJackpots(Constant.SystemDomainID, url);

                    break;
                case VendorID.BetSoft:
                    var dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
                    var config = dca.GetByDomainID(Constant.SystemDomainID);

                    customJackpots = JackpotFeeds.GetBetSoftJackpots(config, url);

                    break;
            }

            var data = new List<SelectListItem>();

            if (customJackpots != null)
            {
                var customVendorForCurrentUrlConfigs = jackpots.Where(x => !string.IsNullOrEmpty(x.CustomVendorConfig))
                .SelectMany(x => JsonConvert.DeserializeObject<List<CustomVendorJackpotConfig>>(x.CustomVendorConfig))
                .Where(x => x.Url == url).ToList();

                //j => !jackpots.Exists(jSaved => jSaved.MappedJackpotID == j.Value.ID
                //&& (this.Model == null || this.Model.MappedJackpotID != jSaved.MappedJackpotID)

                data = customJackpots.Where(x => !customVendorForCurrentUrlConfigs.Exists(cc => cc.MappedJackpotID == x.Value.ID))
                    .Select(j => new SelectListItem
                    {
                        Text = string.Format("{0} ( £ {1:N0} )", j.Value.Name, j.Value.Amounts["GBP"]),
                        Value = j.Key,
                        Selected = false //this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
                    })
                    .OrderBy(j => j.Text)
                    .ToList();
            }

            return this.Json(new 
            { 
                @success = true,
                Data = data
            });
        }

        [HttpGet]
        public JsonResult NotifyChanges()
        {
            CacheManager.ClearLocalCache(Constant.JackpotListCachePrefix);

            string result = CE.BackendThread.ChangeNotifier.SendToAll(CE.BackendThread.ChangeNotifier.ChangeType.JackpotList, DomainManager.CurrentDomainID);

            Logger.Information(string.Format("Jackpot Changed Notification Sent! \n {0}", result));

            return this.Json(new { @success = true, @result = result }, JsonRequestBehavior.AllowGet);
        }

        private static string InitCustomVendorConfig(string value)
        {
            if("[]".Equals(value) || string.IsNullOrEmpty(value) || string.IsNullOrWhiteSpace(value))
            {
                return null;
            }
            else
            {
                return value;
            }
        }

        private bool HideOrShowJackpotGameForSys(long baseId, string gameId, bool hideFlag = true)
        {
            bool result = false;
            SqlQuery<ceCasinoJackpotBase> query = new SqlQuery<ceCasinoJackpotBase>();
            ceCasinoJackpotBase jackpot = query.SelectByKey(baseId);

            if (!jackpot.GameIDs.Contains(gameId))
            {
                return result;
            }
            else
            {
                var hiddenGames = !string.IsNullOrEmpty(jackpot.HiddenGameIDs) ? jackpot.HiddenGameIDs.Split(',').ToList() : new List<string>();

                if (hideFlag && hiddenGames.IndexOf(gameId) < 0)
                {
                    hiddenGames.Add(gameId);
                    jackpot.HiddenGameIDs = string.Join(",", hiddenGames);
                }
                else if (!hideFlag && hiddenGames.IndexOf(gameId) >= 0)
                {
                    hiddenGames.Remove(gameId);
                    jackpot.HiddenGameIDs = string.Join(",", hiddenGames);
                    if (string.IsNullOrEmpty(jackpot.HiddenGameIDs))
                    {
                        jackpot.HiddenGameIDs = null;
                    }
                }
                query.Update(jackpot);

                result = true;
            }
            return result;
        }

        private bool HideOrShowJackpotGameForOperator(long baseId, long jackpotId, string gameId, bool hideFlag = true)
        {
            bool result = false;
            bool insertFlag = false;
            ceCasinoJackpot domainJackpot = new ceCasinoJackpot();
            ceCasinoJackpotBaseEx baseEx = null;
            SqlQuery<ceCasinoJackpot> query = new SqlQuery<ceCasinoJackpot>();

            if ( baseId>0 )
            {
                domainJackpot = CasinoJackpotAccessor.QueryDomainJackpot(DomainManager.CurrentDomainID, baseId);
                if ( domainJackpot != null )
                {
                    jackpotId = domainJackpot.ID;
                }
                baseEx = CasinoJackpotAccessor.GetByKey(DomainManager.CurrentDomainID, baseId, jackpotId);
            }
            else
            {
                domainJackpot = query.SelectByKey(jackpotId);
            }
            if (domainJackpot == null)
            {
                insertFlag = true;
                domainJackpot = new ceCasinoJackpot();
                domainJackpot.Ins = DateTime.Now;
                domainJackpot.DomainID = DomainManager.CurrentDomainID;
                domainJackpot.SessionUserID = CurrentUserSession.UserID;
                if (baseEx != null)
                {
                    domainJackpot.GameIDs = baseEx.GameIDs;
                    domainJackpot.HiddenGameIDs = baseEx.HiddenGameIDs;
                }
            }
            else
            {
                if (baseEx != null)
                {
                    if (string.IsNullOrEmpty(domainJackpot.GameIDs))
                    {
                        domainJackpot.GameIDs = baseEx.GameIDs;
                    }
                    if (string.IsNullOrEmpty(domainJackpot.HiddenGameIDs))
                    { 
                        domainJackpot.HiddenGameIDs = baseEx.HiddenGameIDs; 
                    }
                }
                if (!domainJackpot.GameIDs.Contains(gameId))
                {
                    return result;
                }

            }
            if ( baseId > 0 )
            {
                domainJackpot.CasinoJackpotBaseID = baseId;
            }
            var hiddenGames = !string.IsNullOrEmpty(domainJackpot.HiddenGameIDs) ? domainJackpot.HiddenGameIDs.Split(',').ToList() : new List<string>();

            if (hideFlag && hiddenGames.IndexOf(gameId) < 0)
            {
                hiddenGames.Add(gameId);
                domainJackpot.HiddenGameIDs = string.Join(",", hiddenGames);
            }
            else if (!hideFlag && hiddenGames.IndexOf(gameId) >= 0)
            {
                hiddenGames.Remove(gameId);
                domainJackpot.HiddenGameIDs = string.Join(",", hiddenGames);
                if (string.IsNullOrEmpty(domainJackpot.HiddenGameIDs))
                {
                    domainJackpot.HiddenGameIDs = null;
                }
            }
            domainJackpot = initJackpot(domainJackpot);
            if (insertFlag)
                query.Insert(domainJackpot);
            else
                query.Update(domainJackpot);
            result = true;
            return result;
        }

        private static ceCasinoJackpot initJackpot(ceCasinoJackpot jackpot)
        {
            ceCasinoJackpot casinoJackpot = jackpot;
            if (jackpot.Name != null && "".Equals(jackpot.Name.Trim())) { casinoJackpot.Name = null; }
            if (jackpot.GameIDs != null && "".Equals(jackpot.GameIDs.Trim())) { casinoJackpot.GameIDs = null; }
            if (jackpot.HiddenGameIDs != null && "".Equals(jackpot.HiddenGameIDs.Trim())) { casinoJackpot.HiddenGameIDs = null; }
            if (jackpot.CustomVendorConfig != null && "".Equals(jackpot.CustomVendorConfig.Trim())) { casinoJackpot.CustomVendorConfig = null; }
            if (jackpot.BaseCurrency != null && "".Equals(jackpot.BaseCurrency.Trim())) { casinoJackpot.BaseCurrency = null; }
            if (jackpot.MappedJackpotID != null && "".Equals(jackpot.MappedJackpotID.Trim())) { casinoJackpot.MappedJackpotID = null; }
            return casinoJackpot;
        }
    }
}
