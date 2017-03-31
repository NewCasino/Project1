using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CasinoEngine.Models;
using CE.db;
using CE.db.Accessor;
using CE.Utils;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public enum AvailableEditTableProperty
    {
        Enabled,
        OpVisible,
        VIPTable,
        NewTable,
        TurkishTable,
    }

    [SystemAuthorize]
    public class LiveCasinoTableManagementController : Controller
    {
        public static PropertyInfo[] CeLiveCasinoTableBaseProperties = null;
        public static PropertyInfo[] CeLiveCasinoTableProperties = null;
        //
        // GET: /GameManagement/

        public ActionResult Index()
        {
            return View("Index");
        }

        [HttpGet]
        public ActionResult TablePerprotyEditDialog()
        {
            return View("TablePerprotyEditDialog");
        }

        [HttpPost]
        public ActionResult TableList(long domainID
            , VendorID[] filteredVendorIDs
            , string filteredTableName
            , string filteredGameID
            , string filteredSlug
            , string filteredClientType
            , string[] filteredCategories
            , string filteredTableType
            , string filteredOpeningHour
            , int? pageIndex
            , int pageSize
            )
        {
            if (!pageIndex.HasValue) pageIndex = 1;

            Dictionary<string, object> parameters = new Dictionary<string, object>();

            int totalCount = 0;
            List<ceLiveCasinoTableBaseEx> tables = LiveCasinoTableAccessor.SearchTables(pageIndex.Value, pageSize
                , domainID
                , filteredVendorIDs
                , out totalCount
                , false
                , !CurrentUserSession.IsSystemUser
                , filteredGameID
                , filteredSlug
                , filteredTableName
                , filteredClientType
                , filteredCategories
                , filteredTableType
                , filteredOpeningHour
                );

            int totalPageCount = (int)Math.Ceiling(totalCount / (1.0f * pageSize));
            if (pageIndex.Value > totalPageCount)
                pageIndex = totalPageCount;

            this.ViewData["filteredVendorIDs"] = filteredVendorIDs;
            this.ViewData["filteredGameID"] = filteredGameID;
            this.ViewData["filteredSlug"] = filteredSlug;
            this.ViewData["filteredTableName"] = filteredTableName;
            this.ViewData["filteredClientType"] = filteredClientType;

            this.ViewData["pageIndex"] = pageIndex.Value;
            this.ViewData["pageSize"] = pageSize;
            this.ViewData["pageCount"] = totalPageCount;
            this.ViewData["totalRecords"] = totalCount; //games.Count;

            int _temp = pageSize * pageIndex.Value;
            if (_temp > totalCount) _temp = totalCount;
            this.ViewData["currentRecords"] = _temp;

            return View("TableList", tables);
        }


        public ActionResult RegisterTableDialog(long domainID, long? id)
        {
            ceLiveCasinoTableBaseEx table = null;
            if (id.HasValue && id.Value > 0)
            {
                table = LiveCasinoTableAccessor.GetDomainTable(DomainManager.CurrentDomainID, id.Value);
            }
            if (table == null)
                table = new ceLiveCasinoTableBaseEx()
                {
                    CasinoGameBaseID = 0L,
                    DomainID = 1000L,
                };

            return this.View("RegisterTableDialog", table);
        }

        public ActionResult TableEditorDialog(long domainID, long id)
        {
            ceLiveCasinoTableBaseEx table = LiveCasinoTableAccessor.GetDomainTable(DomainManager.CurrentDomainID, id);
            if (table == null)
                throw new CeException("Table not found by ID [{0}]", id);

            var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
            if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                domain = DomainManager.GetSysDomain();
            this.ViewData["newStatusLiveCasinoGameExpirationDays"] = domain.NewStatusLiveCasinoGameExpirationDays;

            return this.View("TableEditorDialog", table);
        }

        public ActionResult VendorWizards(VendorID vendorID)
        {
            string viewName = string.Format("VendorWizards_{0}", vendorID.ToString());
            ViewEngineResult result = ViewEngines.Engines.FindView(ControllerContext, viewName, null);
            bool exists = (result.View != null);
            if (!exists)
            {
                viewName = "VendorWizards_Basic";
            }
            ViewData["vendorID"] = vendorID;
            return this.View(viewName);
        }

        public ActionResult RegisterTable(long gameID
            , string extraParameter1
            , string extraParameter2
            , string extraParameter3
            , string extraParameter4
            , string ClientCompatibility
            , string launchParams
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            try
            {
                var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
                if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                    domain = DomainManager.GetSysDomain();

                using (DbManager db = new DbManager())
                {
                    ceCasinoGameBaseEx game = CasinoGameAccessor.GetDomainGame(Constant.SystemDomainID, gameID);

                    SqlQuery<ceLiveCasinoTableBase> query = new SqlQuery<ceLiveCasinoTableBase>(db);
                    ceLiveCasinoTableBase table = new ceLiveCasinoTableBase();
                    table.CasinoGameBaseID = gameID;
                    table.Enabled = true;
                    table.NewTableExpirationDate = DateTime.Now.AddDays(domain.NewStatusLiveCasinoGameExpirationDays);
                    table.Ins = DateTime.Now;
                    table.SessionUserID = CurrentUserSession.UserID;
                    table.SessionID = CurrentUserSession.SessionID;
                    table.TableName = game.GameName;
                    table.ExtraParameter1 = extraParameter1;
                    table.ExtraParameter2 = extraParameter2;
                    table.ExtraParameter3 = extraParameter3;
                    table.ExtraParameter4 = extraParameter4;
                    table.LaunchParams = launchParams;
                    table.OpenHoursStart = 0;
                    table.OpenHoursEnd = 0;

                    table.ClientCompatibility = ClientCompatibility ?? ",PC,";

                    #region TableID
                    switch (game.VendorID)
                    {
                        case VendorID.Microgaming:
                            table.ID = gameID;
                            break;

                        case VendorID.XProGaming:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }

                        case VendorID.EvolutionGaming:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }

                        case VendorID.Tombala:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }

                        case VendorID.NetEnt:
                        {
                            table.ID = gameID*1000000 + int.Parse(extraParameter1);
                            table.Limit =
                                NetEntAPI.LiveCasinoTable.Get(DomainManager.CurrentDomainID, game.GameID,
                                    table.ExtraParameter1).Limitation;
                            break;
                        }

                        case VendorID.Ezugi:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }

                        case VendorID.ISoftBet:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }

                        case VendorID.Vivo:
                        {
                            int l = 999999;
                            int.TryParse(extraParameter2, out l);
                            if (l > 1000000)
                                l = l%1000000;

                            Random r = new Random();
                            int i = r.Next(l);


                            table.ID = gameID*1000000 + int.Parse(extraParameter1) + l;
                            break;
                        }

                        case VendorID.BetGames:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }

                        case VendorID.PokerKlas:
                            table.ID = gameID;
                            break;

                        case VendorID.LuckyStreak:
                        {
                            Random r = new Random();

                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }
                        case VendorID.Authentic:
                        {
                            Random r = new Random();
                            table.ID = gameID*1000000 + r.Next(100000);
                            break;
                        }
                        case VendorID.ViG:
                        {
                            Random r = new Random();
                            table.ID = gameID * 1000000 + r.Next(100000);
                            break;
                        }
                        case VendorID.HoGaming:
                        {
                            Random r = new Random();
                            table.ID = gameID * 1000000 + r.Next(100000);
                            break;
                        }
                        case VendorID.TTG:
                        {
                            Random r = new Random();
                            table.ID = gameID * 1000000 + r.Next(100000);
                            break;
                        }
                        case VendorID.LiveGames:
                        {
                            Random r = new Random();
                            table.ID = gameID * 1000000 + r.Next(100000);
                            break;
                        }
                        case VendorID.Entwine:
                            {
                                Random r = new Random();
                                table.ID = gameID * 1000000 + r.Next(100000);
                                break;
                            }
                        default:
                            Random rnd = new Random();
                            table.ID = gameID * 1000000 + rnd.Next(100000);
                            break;
                    }

                    #endregion

                    query.Insert(table);
                }

                return this.Json(new { success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        private LiveCasinoTableLimit ParseLimit()
        {
            LiveCasinoTableLimit limit = new LiveCasinoTableLimit();
            limit.BaseCurrency = Request.Form["baseCurrency"];

            decimal amount;
            if (decimal.TryParse(Request.Form["baseCurrencyMinAmount"], out amount))
                limit.BaseLimit.MinAmount = amount;
            if (decimal.TryParse(Request.Form["baseCurrencyMaxAmount"], out amount))
                limit.BaseLimit.MaxAmount = amount;

            CurrencyData[] currencies = GamMatrixClient.GetSupportedCurrencies();
            foreach (CurrencyData currency in currencies)
            {
                LimitAmount limitAmount = new LimitAmount();
                string key = string.Format("minAmount_{0}", currency.ISO4217_Alpha);
                if (decimal.TryParse(Request.Form[key], out amount))
                    limitAmount.MinAmount = amount;

                key = string.Format("maxAmount_{0}", currency.ISO4217_Alpha);
                if (decimal.TryParse(Request.Form[key], out amount))
                    limitAmount.MaxAmount = amount;

                limit.CurrencyLimits[currency.ISO4217_Alpha] = limitAmount;
            }

            LiveCasinoTableLimitType t;
            if (Enum.TryParse<LiveCasinoTableLimitType>(Request.Form["limitType"], out t))
                limit.Type = t;

            if (limit.Type == LiveCasinoTableLimitType.SameForAllCurrency ||
                limit.Type == LiveCasinoTableLimitType.AutoConvertBasingOnCurrencyRate)
            {
                if (limit.BaseLimit.MinAmount >= limit.BaseLimit.MaxAmount)
                    limit.Type = LiveCasinoTableLimitType.None;
            }

            return limit;
        }

        public ActionResult SaveTable(ceLiveCasinoTableBaseEx updatedTable
            , HttpPostedFileBase thumbnailFile
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }

            try
            {
                string imageFileName;
                byte[] imageBuffer;
                if (ImageAsset.ParseImage(thumbnailFile, out imageFileName, out imageBuffer))
                {
                    imageFileName = ImageAsset.GetImageFtpFilePath(imageFileName);
                    FTP.UploadFile(DomainManager.CurrentDomainID, imageFileName, imageBuffer);
                }

                SqlQuery<ceLiveCasinoTableBase> query = new SqlQuery<ceLiveCasinoTableBase>();
                ceLiveCasinoTableBase baseTable = query.SelectByKey(updatedTable.ID);

                ceCasinoGameBaseEx game = CasinoGameAccessor.GetDomainGame(Constant.SystemDomainID, baseTable.CasinoGameBaseID);

                if (CurrentUserSession.IsSystemUser && DomainManager.CurrentDomainID == Constant.SystemDomainID)
                {
                    baseTable.TableName = updatedTable.TableName;
                    baseTable.Category = updatedTable.Category;
                    baseTable.ExtraParameter1 = updatedTable.ExtraParameter1;
                    baseTable.ExtraParameter2 = updatedTable.ExtraParameter2;
                    baseTable.ExtraParameter3 = updatedTable.ExtraParameter3;
                    baseTable.ExtraParameter4 = updatedTable.ExtraParameter4;
                    baseTable.LaunchParams = updatedTable.LaunchParams;
                    baseTable.OpenHoursStart = updatedTable.OpenHoursStart;
                    baseTable.OpenHoursEnd = updatedTable.OpenHoursEnd;
                    baseTable.OpenHoursTimeZone = updatedTable.OpenHoursTimeZone;
                    baseTable.Limit = ParseLimit();
                    baseTable.VIPTable = updatedTable.VIPTable;
                    baseTable.NewTable = updatedTable.NewTable;
                    baseTable.NewTableExpirationDate = updatedTable.NewTable ? updatedTable.NewTableExpirationDate : DateTime.Now.AddDays(-1);
                    baseTable.ExcludeFromRandomLaunch = updatedTable.ExcludeFromRandomLaunch;
                    baseTable.TurkishTable = updatedTable.TurkishTable;
                    baseTable.BetBehindAvailable = updatedTable.BetBehindAvailable;
                    baseTable.SeatsUnlimited = updatedTable.SeatsUnlimited;
                    baseTable.DealerGender = updatedTable.DealerGender;
                    baseTable.DealerOrigin = updatedTable.DealerOrigin;
                    baseTable.TableStudioUrl = updatedTable.TableStudioUrl;

                    //if (game.VendorID == VendorID.EvolutionGaming)
                    {
                        baseTable.ClientCompatibility = updatedTable.ClientCompatibility;
                    }

                    if (!string.IsNullOrWhiteSpace(imageFileName))
                        baseTable.Thumbnail = imageFileName;

                    query.Update(baseTable);

                    //updating properties that are inherited from basetable and disabled for edit in child tables
                    var propertiesValues = new Dictionary<string, object>
                    {
                        {"BetBehindAvailable", updatedTable.BetBehindAvailable},
                        {"SeatsUnlimited", updatedTable.SeatsUnlimited},
                        {"DealerGender", updatedTable.DealerGender},
                        {"DealerOrigin", updatedTable.DealerOrigin}
                    };
                    LiveCasinoTableAccessor.UpdateChildTablesProperties(propertiesValues, baseTable.ID);
                }
                else if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                {
                    LiveCasinoTableAccessor lta = LiveCasinoTableAccessor.CreateInstance<LiveCasinoTableAccessor>();
                    ceLiveCasinoTable table = lta.GetTable(DomainManager.CurrentDomainID, updatedTable.ID);
                    bool isExist = table != null;
                    bool isModified = false;
                    if (!isExist)
                    {
                        table = new ceLiveCasinoTable() { DomainID = DomainManager.CurrentDomainID, LiveCasinoTableBaseID = updatedTable.ID };
                        table.Ins = DateTime.Now;
                        table.SessionUserID = CurrentUserSession.UserID;
                        table.SessionID = CurrentUserSession.UserSessionID;
                        table.OpVisible = baseTable.OpVisible;
                        table.ClientCompatibility = null;
                        table.NewTableExpirationDate = baseTable.NewTableExpirationDate == DateTime.MinValue ? DateTime.Now.Date.AddDays(-1) : baseTable.NewTableExpirationDate;

                        table.BetBehindAvailable = baseTable.BetBehindAvailable;
                        table.SeatsUnlimited = baseTable.SeatsUnlimited;
                        table.DealerGender = baseTable.DealerGender;
                        table.DealerOrigin = baseTable.DealerOrigin;

                    }
                    table.ShortName = null;
                    table.Logo = null;
                    table.BackgroundImage = null;

                    if (!string.IsNullOrWhiteSpace(updatedTable.ExtraParameter1) &&
                        !string.Equals(baseTable.ExtraParameter1, updatedTable.ExtraParameter1))
                    {
                        isModified = true;
                        table.ExtraParameter1 = updatedTable.ExtraParameter1;
                    }
                    else
                        table.ExtraParameter1 = null;

                    if (!string.IsNullOrWhiteSpace(updatedTable.ExtraParameter2) &&
                        !string.Equals(baseTable.ExtraParameter2, updatedTable.ExtraParameter2))
                    {
                        isModified = true;
                        table.ExtraParameter2 = updatedTable.ExtraParameter2;
                    }
                    else
                        table.ExtraParameter2 = null;

                    if (!string.IsNullOrWhiteSpace(updatedTable.ExtraParameter3) &&
                        !string.Equals(baseTable.ExtraParameter3, updatedTable.ExtraParameter3))
                    {
                        isModified = true;
                        table.ExtraParameter3 = updatedTable.ExtraParameter3;
                    }
                    else
                        table.ExtraParameter3 = null;

                    if (!string.IsNullOrWhiteSpace(updatedTable.ExtraParameter4) &&
                        !string.Equals(baseTable.ExtraParameter4, updatedTable.ExtraParameter4))
                    {
                        isModified = true;
                        table.ExtraParameter4 = updatedTable.ExtraParameter4;
                    }
                    else
                        table.ExtraParameter4 = null;

                    if (!string.IsNullOrEmpty(updatedTable.LaunchParams) &&
                        !string.Equals(baseTable.LaunchParams, updatedTable.LaunchParams))
                    {
                        isModified = true;
                        table.LaunchParams = updatedTable.LaunchParams;
                    }
                    else
                        table.LaunchParams = null;

                    if (!string.IsNullOrWhiteSpace(updatedTable.TableName) &&
                        !string.Equals(baseTable.TableName, updatedTable.TableName))
                    {
                        isModified = true;
                        table.TableName = updatedTable.TableName;
                    }
                    else
                        table.TableName = null;

                    if (!string.IsNullOrWhiteSpace(updatedTable.Category) &&
                        !string.Equals(baseTable.Category, updatedTable.Category))
                    {
                        isModified = true;
                        table.Category = updatedTable.Category;
                    }
                    else
                        table.Category = null;

                    if (!string.IsNullOrWhiteSpace(imageFileName) &&
                        !string.Equals(baseTable.Thumbnail, updatedTable.Thumbnail))
                    {
                        isModified = true;
                        table.Thumbnail = imageFileName;
                    }
                    else
                        table.Thumbnail = null;

                    //if (game.VendorID == VendorID.EvolutionGaming)
                    {
                        if (updatedTable.ClientCompatibility != null && !string.Equals(table.ClientCompatibility, updatedTable.ClientCompatibility))
                        {
                            isModified = true;
                            if (!string.Equals(baseTable.ClientCompatibility, updatedTable.ClientCompatibility))
                                table.ClientCompatibility = updatedTable.ClientCompatibility;
                            else
                                table.ClientCompatibility = null;
                        }
                    }

                    string limitationXml = table.LimitationXml;
                    LiveCasinoTableLimit limit = table.Limit;
                    table.Limit = ParseLimit();
                    if (table.Limit.Equals(baseTable.Limit))
                    {
                        table.LimitationXml = null;
                    }
                    if (!(string.IsNullOrWhiteSpace(table.LimitationXml) && string.IsNullOrWhiteSpace(limitationXml)))
                    {
                        if (table.LimitationXml == null)
                            isModified = true;
                        else if (!table.LimitationXml.Equals(limitationXml, StringComparison.InvariantCultureIgnoreCase))
                            isModified = true;
                    }
                    if (table.VIPTable != updatedTable.VIPTable)
                    {
                        table.VIPTable = updatedTable.VIPTable;
                        isModified = true;
                    }
                    if (table.NewTable != updatedTable.NewTable || table.NewTableExpirationDate.CompareTo(updatedTable.NewTableExpirationDate) != 0)
                    {
                        table.NewTable = updatedTable.NewTable;
                        table.NewTableExpirationDate = updatedTable.NewTable ? updatedTable.NewTableExpirationDate : DateTime.Now.AddDays(-1);
                        isModified = true;
                    }
                    if (table.TurkishTable != updatedTable.TurkishTable)
                    {
                        table.TurkishTable = updatedTable.TurkishTable;
                        isModified = true;
                    }
                    if (table.ExcludeFromRandomLaunch != updatedTable.ExcludeFromRandomLaunch)
                    {
                        table.ExcludeFromRandomLaunch = updatedTable.ExcludeFromRandomLaunch;
                        isModified = true;
                    }

                    if (table.TableStudioUrl != updatedTable.TableStudioUrl)
                    {
                        table.TableStudioUrl = updatedTable.TableStudioUrl;
                        isModified = true;
                    }

                    if (isModified)
                    {
                        SqlQuery<ceLiveCasinoTable> query2 = new SqlQuery<ceLiveCasinoTable>();
                        if (isExist)
                            query2.Update(table);
                        else
                            query2.Insert(table);
                    }
                }

                return this.Json(new { success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        public ActionResult RevertToDefaultTable(long id)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            try
            {
                if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                {
                    LiveCasinoTableAccessor lta = LiveCasinoTableAccessor.CreateInstance<LiveCasinoTableAccessor>();
                    ceLiveCasinoTable table = lta.GetTable(DomainManager.CurrentDomainID, id);
                    bool isExist = table != null;
                    SqlQuery<ceLiveCasinoTable> query2 = new SqlQuery<ceLiveCasinoTable>();
                    if (isExist)
                    {
                        query2.Delete(table);
                        return this.Json(new { success = true }, JsonRequestBehavior.AllowGet);
                    }

                    return this.Json(new { success = false, error = "Table not found!" }, JsonRequestBehavior.AllowGet);
                }

                return this.Json(new { success = false }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        #region Update Property
        [HttpPost]
        public JsonResult UpdateProperty(string ids, AvailableEditTableProperty property, object value, PropertyEditType? editType, bool setToDefault = false)
        {
            setToDefault = false;

            if (value != null)
            {
                try
                {
                    value = ((string[])value)[0];
                }
                catch { }
            }
            if (string.IsNullOrEmpty(ids) || (value == null && !setToDefault))
            {
                return this.Json(new { @success = false, @message = "Error, invalid argument!" });
            }
            string[] strIds = ids.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            if (ids.Length == 0)
            {
                return this.Json(new { @success = false, @message = "Error, invalid argument!" });
            }

            if (!CheckedPermission(property))
            {
                return this.Json(new { @success = false, @message = string.Format("Error, you are not allowed to change [{0}]!", property.ToString()) });
            }

            bool updated = false;

            StringBuilder successedIds = new StringBuilder();
            bool isCommon = DomainManager.CurrentDomainID == Constant.SystemDomainID;
            long id = 0;
            foreach (string strId in strIds)
            {
                if (long.TryParse(strId, out id))
                {
                    if (InternalUpdateProperty(id, property, value, isCommon, editType.HasValue ? editType.Value : PropertyEditType.Add, setToDefault))
                    {
                        updated = true;
                        successedIds.AppendFormat(" {0},", id);
                    }
                }
            }

            if (updated)
            {
                CacheManager.ClearCache(Constant.GameListCachePrefix);
                CacheManager.ClearCache(Constant.DomainGamesCachePrefix);
                CacheManager.ClearCache(Constant.DomainGamesCache2Prefix);
                CacheManager.ClearCache(Constant.TopWinnersCachePrefix);

                return this.Json(new { @success = true, @successedIds = string.Format("[{0}]", successedIds.ToString().TrimEnd(new char[] { ',' })) });
            }

            return this.Json(new { @success = false, @error = "operation failed!" });
        }

        public bool CheckedPermission(AvailableEditTableProperty property)
        {
            if (!CurrentUserSession.IsAuthenticated)
                return false;

            switch (property)
            {

                case AvailableEditTableProperty.Enabled:

                case AvailableEditTableProperty.NewTable:
                case AvailableEditTableProperty.TurkishTable:
                case AvailableEditTableProperty.VIPTable:
                    {
                        return true;
                    }
                case AvailableEditTableProperty.OpVisible:
                    {
                        return CurrentUserSession.IsSystemUser;
                    }
            }

            return false;
        }

        private bool InternalUpdateProperty(long id, AvailableEditTableProperty property, object value, bool updatingBase, PropertyEditType editType, bool setToDefault)
        {
            if (updatingBase && setToDefault)
                return false;
            bool succeed = false;
            using (DbManager db = new DbManager())
            {
                db.BeginTransaction();
                try
                {
                    LiveCasinoTableAccessor lcta = LiveCasinoTableAccessor.CreateInstance<LiveCasinoTableAccessor>(db);
                    SqlQuery<ceLiveCasinoTableBase> query = new SqlQuery<ceLiveCasinoTableBase>(db);
                    ceLiveCasinoTableBase tableBase = null;
                    ceLiveCasinoTable tableDomain = null;

                    if (id > 0)
                    {
                        tableBase = query.SelectByKey(id);
                        if (tableBase != null)
                        {
                            string column = string.Empty;
                            object defaultValue = null;
                            bool useBaseValueAsDefault = false;

                            if (!updatingBase)
                                tableDomain = lcta.GetTable(DomainManager.CurrentDomainID, id);

                            bool isExist = tableDomain != null;

                            #region Resolve and assignment property
                            bool tempBool;

                            column = property.ToString();

                            bool valueVerified = setToDefault;
                            bool changed = true;
                            bool valueResolved = false;
                            switch (property)
                            {
                                #region bool properies
                                case AvailableEditTableProperty.OpVisible:
                                case AvailableEditTableProperty.Enabled:
                                case AvailableEditTableProperty.NewTable:
                                case AvailableEditTableProperty.TurkishTable:
                                case AvailableEditTableProperty.VIPTable:
                                    useBaseValueAsDefault = true;
                                    if (!setToDefault)
                                    {
                                        if (bool.TryParse(value as string, out tempBool))
                                        {
                                            valueVerified = true;
                                            value = tempBool;
                                        }
                                    }
                                    break;
                                #endregion bool properies

                                default:
                                    column = null;
                                    changed = false;
                                    break;
                            }

                            if (!valueResolved && !string.IsNullOrWhiteSpace(column))
                            {
                                value = ResolveValue(updatingBase, setToDefault, tableBase, tableDomain, column, value, defaultValue, useBaseValueAsDefault, out changed);
                            }
                            #endregion Resolve and assignment property

                            if (changed)
                            {
                                succeed = true;
                                if (updatingBase)
                                {
                                    LiveCasinoTableAccessor.UpdateTableBaseProperty(column, value, tableBase.ID);
                                }
                                else
                                {
                                    SqlQuery<ceCasinoGame> query2 = new SqlQuery<ceCasinoGame>(db);
                                    if (isExist)
                                    {
                                        LiveCasinoTableAccessor.UpdateTableProperty(column, value, tableDomain.ID);
                                    }
                                    else
                                    {
                                        LiveCasinoTableAccessor.InsertNewTableWithSpecificProperty(DomainManager.CurrentDomainID
                                            , tableBase.ID
                                            , CurrentUserSession.SessionID
                                            , CurrentUserSession.UserID
                                            , column
                                            , value
                                            , tableBase.Enabled
                                            , tableBase.OpVisible
                                            );
                                    }
                                }
                            }
                        }
                    }

                    db.CommitTransaction();

                    return succeed;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    db.RollbackTransaction();
                }
            }
            return false;
        }

        private object ResolveValue(bool updatingBase, bool setToDefaultValue, ceLiveCasinoTableBase tableBase, ceLiveCasinoTable tableDomain, string column, object value, object defaultValue, bool useBaseValueAsDefault, out bool changed, PropertyEditType editType = PropertyEditType.Override)
        {
            changed = false;

            if (CeLiveCasinoTableBaseProperties == null)
            {
                Type typeGameBase = typeof(ceLiveCasinoTableBase);
                CeLiveCasinoTableBaseProperties = typeGameBase.GetProperties(BindingFlags.Instance | BindingFlags.DeclaredOnly | BindingFlags.Public);
            }
            if (CeLiveCasinoTableProperties == null)
            {
                Type typeGameDomain = typeof(ceLiveCasinoTable);
                CeLiveCasinoTableProperties = typeGameDomain.GetProperties(BindingFlags.Instance | BindingFlags.DeclaredOnly | BindingFlags.Public);
            }

            PropertyInfo propertyGameBase = CeLiveCasinoTableBaseProperties.FirstOrDefault(f => f.Name.Equals(column));
            if (propertyGameBase != null)
            {
                if (updatingBase)
                {
                    object sourcesValue = propertyGameBase.GetValue(tableBase, null);
                    if (sourcesValue == null || !sourcesValue.ToString().Equals(value.ToString(), StringComparison.OrdinalIgnoreCase))
                        changed = true;
                }
                else
                {
                    PropertyInfo propertyGameDomain = CeLiveCasinoTableProperties.FirstOrDefault(f => f.Name.Equals(column));
                    if (propertyGameDomain != null)
                    {
                        object sourcesValue = propertyGameBase.GetValue(tableBase, null);
                        if (setToDefaultValue)
                        {
                            value = sourcesValue;
                            changed = true;
                        }
                        else if (sourcesValue != null && sourcesValue.ToString().Equals(value.ToString(), StringComparison.OrdinalIgnoreCase))
                        {
                            value = useBaseValueAsDefault ? sourcesValue : defaultValue;
                            changed = true;
                        }
                        else
                        {
                            if (tableDomain != null)
                            {
                                sourcesValue = propertyGameDomain.GetValue(tableDomain, null);
                                if (sourcesValue == null || !sourcesValue.ToString().Equals(value.ToString(), StringComparison.OrdinalIgnoreCase))
                                    changed = true;
                            }
                            else
                                changed = true;
                        }
                    }
                }
            }
            return value;
        }
        #endregion Update Property

        [HttpGet]
        public JsonResult NotifyChanges()
        {
            //CacheManager.ClearCache(Constant.LiveCasinoTableListCachePrefix);
            //CacheManager.ClearCache(Constant.DomainLiveCasinoTableCachePrefix);

            //NetEntAPI.LiveCasinoTable.ClearCache(DomainManager.CurrentDomainID);
            string[] cachePrefixKeys = new string[] 
            {
                Constant.LiveCasinoTableListCachePrefix,
                Constant.DomainLiveCasinoTableCachePrefix,

                NetEntAPI.LiveCasinoTable.GetCachePrefixKey(DomainManager.CurrentDomainID),
            };
            CacheManager.ClearCache(cachePrefixKeys);

            CacheManager.ClearLocalCache(cachePrefixKeys);

            string result = CE.BackendThread.ChangeNotifier.SendToAll(CE.BackendThread.ChangeNotifier.ChangeType.LiveCasinoTableList, DomainManager.CurrentDomainID);

            Logger.Information(string.Format("GameList Changed Notification Sent! \n {0}", result));

            return this.Json(new { @success = true, @result = result }, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        public JsonResult ReloadOriginalFeeds()
        {
            Thread t = new Thread(CE.BackendThread.ChangeNotifier.ReloadOriginalFeeds);
            t.Start();
            return this.Json(new { @success = true, @result = "The relaoding has been started!" }, JsonRequestBehavior.AllowGet);
        }


        public JsonResult EnableTables(long[] tableIDs, bool enable)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            try
            {
                if (!CurrentUserSession.IsSystemUser)
                    throw new CeException("You are not allowed to perform this operation.");

                SqlQuery<ceLiveCasinoTableBase> query1 = new SqlQuery<ceLiveCasinoTableBase>();
                SqlQuery<ceLiveCasinoTable> query2 = new SqlQuery<ceLiveCasinoTable>();
                LiveCasinoTableAccessor lta = LiveCasinoTableAccessor.CreateInstance<LiveCasinoTableAccessor>();
                foreach (long tableID in tableIDs)
                {
                    if (CurrentUserSession.IsSystemUser && DomainManager.CurrentDomainID == Constant.SystemDomainID)
                    {
                        ceLiveCasinoTableBase baseTable = query1.SelectByKey(tableID);
                        baseTable.Enabled = enable;
                        query1.Update(baseTable);
                    }
                    else
                    {
                        ceLiveCasinoTable table = lta.GetTable(DomainManager.CurrentDomainID, tableID);
                        if (table == null)
                        {
                            table = new ceLiveCasinoTable() { DomainID = DomainManager.CurrentDomainID, LiveCasinoTableBaseID = tableID };
                            table.Ins = DateTime.Now;
                            table.SessionUserID = CurrentUserSession.UserID;
                            table.SessionID = CurrentUserSession.UserSessionID;
                            table.Enabled = enable;

                            table.ClientCompatibility = null;
                            table.TableName = null;
                            table.ShortName = null;
                            table.Category = null;
                            table.Thumbnail = null;
                            table.Logo = null;
                            table.BackgroundImage = null;
                            table.ExtraParameter1 = null;
                            table.ExtraParameter2 = null;
                            table.ExtraParameter3 = null;
                            table.ExtraParameter4 = null;
                            table.LaunchParams = null;
                            table.LimitationXml = null;
                            query2.Insert(table);
                        }
                        else
                        {
                            if (string.IsNullOrWhiteSpace(table.ClientCompatibility))
                                table.ClientCompatibility = null;
                            if (string.IsNullOrWhiteSpace(table.TableName))
                                table.TableName = null;
                            if (string.IsNullOrWhiteSpace(table.ShortName))
                                table.ShortName = null;
                            if (string.IsNullOrWhiteSpace(table.Category))
                                table.Category = null;
                            if (string.IsNullOrWhiteSpace(table.Thumbnail))
                                table.Thumbnail = null;
                            if (string.IsNullOrWhiteSpace(table.Logo))
                                table.Logo = null;
                            if (string.IsNullOrWhiteSpace(table.BackgroundImage))
                                table.BackgroundImage = null;
                            if (string.IsNullOrWhiteSpace(table.ExtraParameter1))
                                table.ExtraParameter1 = null;
                            if (string.IsNullOrWhiteSpace(table.ExtraParameter2))
                                table.ExtraParameter2 = null;
                            if (string.IsNullOrWhiteSpace(table.ExtraParameter3))
                                table.ExtraParameter3 = null;
                            if (string.IsNullOrWhiteSpace(table.ExtraParameter4))
                                table.ExtraParameter4 = null;
                            if (string.IsNullOrWhiteSpace(table.LaunchParams))
                                table.LaunchParams = null;
                            if (string.IsNullOrWhiteSpace(table.LimitationXml))
                                table.LimitationXml = null;

                            table.Enabled = enable;
                            query2.Update(table);
                        }
                    }
                }
                return this.Json(new { success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
    }
}
