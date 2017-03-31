using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.Mvc;
using CE.db.Accessor;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{   

    [SystemAuthorize]
    public class GameHistoryController : Controller
    {
        public ActionResult Index()
        {
            this.ViewData["pageSize"] = 5;
            return View();
        }

        [HttpPost]
        public ActionResult GameHistoryList(long domainID
            , VendorID? filteredVendorID
            , DateTime? filteredDateFrom
            , DateTime? filteredDateTo 
            , long? filteredUserID
            , int? pageIndex
            , int pageSize
            )
        {
            if (!pageIndex.HasValue) pageIndex = 1;

            Dictionary<string, object> parameters = new Dictionary<string, object>();

            if (filteredVendorID.HasValue && filteredVendorID.Value != VendorID.Unknown )
                parameters.Add("VendorID", filteredVendorID.Value);

            if (filteredDateFrom.HasValue)
                parameters.Add("DateFrom", filteredDateFrom.Value);
            if (filteredDateTo.HasValue)
                parameters.Add("DateTo", filteredDateTo.Value);

            if (filteredUserID.HasValue)
                parameters.Add("UserID", filteredUserID.Value);

            int totalCount = 0;
            //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.SearchGames(pageIndex.Value, pageSize, domainID, parameters, out totalCount, false, CurrentUserSession.UserDomainID != Constant.SystemDomainID);
            DataTable dt = CasinoGameAccessor.SearchUpdatedGames(pageIndex.Value, pageSize, domainID, parameters, out totalCount);

            int totalPageCount = (int)Math.Ceiling(totalCount / (1.0f * pageSize));
            if (pageIndex.Value > totalPageCount)
                pageIndex = totalPageCount;

            this.ViewData["filteredVendorID"] = filteredVendorID;
            this.ViewData["filteredDateFrom"] = filteredDateFrom;
            this.ViewData["filteredDateTo"] = filteredDateTo;
            this.ViewData["filteredUserID"] = filteredUserID;
            this.ViewData["pageIndex"] = pageIndex.Value;
            this.ViewData["pageSize"] = pageSize;
            this.ViewData["pageCount"] = totalPageCount;
            this.ViewData["totalRecords"] = totalCount; //games.Count;

            int _temp = pageSize * pageIndex.Value;
            if (_temp > totalCount) _temp = totalCount;
            this.ViewData["currentRecords"] = _temp;

            return this.View("GameList",dt);
        }

        public ActionResult GameChangeLog(long gameID)
        {
            return this.View("GameChangeLog", gameID);
        }

        public ActionResult GameChangeDetails(long gameID)
        {
            List<GameLog> list = new List<GameLog>();

            CasinoGameAccessor cga = CasinoGameAccessor.CreateInstance<CasinoGameAccessor>();

            DataTable dtBase = cga.QueryCasinoGameBase(gameID);
            if (dtBase == null || dtBase.Rows.Count == 0)
                throw new AggregateException();

            string gameName = (string)dtBase.Rows[0]["GameName"]; ;

            GameLog log = new GameLog();
            log.GameID = (long)dtBase.Rows[0]["ID"];
            log.DomainID = (long)dtBase.Rows[0]["DomainID"];
            log.Time = (DateTime)dtBase.Rows[0]["Ins"];
            log.UserID = (long)dtBase.Rows[0]["SessionUserID"];
            log.Changes = null;
            log.OperationType = GameLogOperationType.Create;
            list.Add(log);

            DataColumnCollection clsBase = dtBase.Columns;

            DataTable dtBaseHis = CasinoGameAccessor.QueryBaseGameHistory(gameID);
            
            if (dtBaseHis != null && dtBaseHis.Rows.Count > 0)
            {
                DataColumnCollection cls = dtBaseHis.Columns;
                list.AddRange(Compare(cls, dtBaseHis.Rows));
            }

            if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
            {                
                DataTable dtGame = cga.QueryCasinoGame(DomainManager.CurrentDomainID, gameID);
                if (dtGame != null && dtGame.Rows.Count > 0)
                {
                    DataTable dtGameHis = CasinoGameAccessor.QueryDomainGameHistory(DomainManager.CurrentDomainID, gameID);
                    if (dtGameHis != null && dtGameHis.Rows.Count > 0)
                    {
                        DataColumnCollection cls = dtGameHis.Columns;
                        DataTable dtNearest = CasinoGameAccessor.QueryNearestBaseGameHistory(gameID, (DateTime)dtGameHis.Rows[0]["Ins"]);
                        DataRow drFirstBase = dtNearest != null ? dtNearest.Rows.Count>0 ? dtNearest.Rows[0] : null : null;
                        list.AddRange(Compare(cls, dtGameHis.Rows, false, drFirstBase));
                    }
                }
            }

            if (list.Count > 0)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                foreach (GameLog gl in list)
                {
                    gl.Username = ua.GetUsername(gl.UserID);
                }
            }

            this.ViewData["GameName"] = gameName;
            return this.View("GameChangeDetails", list.OrderByDescending(l=>l.Time).ToList());
        }

        private List<GameLog> Compare(DataColumnCollection cls, DataRowCollection rows, bool isBase = true, DataRow drFirstBase=null)
        {
            List<GameLog> list = new List<GameLog>();
            Dictionary<string, object[]> dicChanges;
            GameLog log;
            DataRow lastRow = drFirstBase;
            int loop = 0;
            foreach (DataRow dr in rows)
            {
                if (loop > 0 || lastRow != null)
                {
                    dicChanges = new Dictionary<string, object[]>();
                    foreach (DataColumn dc in cls)
                    {
                        object[] objs = CompareColumn(lastRow, dr, dc.ColumnName, dc.DataType, isBase);
                        if (objs != null)
                            dicChanges.Add(dc.ColumnName, objs);
                    }
                    if (dicChanges.Keys.Count > 0)
                    {
                        log = new GameLog();
                        log.GameID = (long)dr["CasinoGameBaseID"];
                        log.DomainID = (long)dr["DomainID"];
                        log.Time = (DateTime)dr["Ins"];
                        log.UserID = (long)dr["SessionUserID"];
                        log.Changes = dicChanges;
                        log.OperationType = GameLogOperationType.Update;
                        if (!isBase && loop == 0)
                            log.OperationType = GameLogOperationType.Create;
                        list.Add(log);
                    }
                }
                lastRow = dr;
                loop++;
            }

            return list;
        }

        private object[] CompareColumn(DataRow dr, DataRow drNew, string cName, Type type, bool isBase)
        {
            if (cName.Equals("ID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("Ins", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("SessionID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("SessionUserID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("DomainID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("HID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("CasinoGameID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("CasinoGameBaseID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("Modified", StringComparison.InvariantCultureIgnoreCase)
                )
                return null;

            if (isBase)
            {
                if (cName.Equals("VendorID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("GameCode", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("GameID", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("RestrictedTerritories", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("Languages", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("ExtraParameter1", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("ExtraParameter2", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("Slug", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("OriginalVendorID", StringComparison.InvariantCultureIgnoreCase)
                )
                    return null;
            }
            else
            {
                if (cName.Equals("Width", StringComparison.InvariantCultureIgnoreCase) ||
                cName.Equals("Height", StringComparison.InvariantCultureIgnoreCase)
                )
                    return null;
            }

            //bool isSame = true;
            //switch (type)
            //{ 
            //    case (typeof(string)):

            //}

            object v = null;
            if(!dr.IsNull(cName))
                v = Convert.ChangeType(dr[cName], type);
            object v1 = null;
            if (!drNew.IsNull(cName))
                v1 =Convert.ChangeType(drNew[cName], type);
            if (v == null && v1 == null)
                return null;
            else if (v == null)
                return new object[2] { null, drNew[cName] };
            else if (v1 == null)
                return new object[2] { dr[cName], null };
            else if (!v.Equals(v1))
            {
                return new object[2] { dr[cName], drNew[cName] };
            }
            return null;
        }
    }
}