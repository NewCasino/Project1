using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [SystemAuthorize(Roles = "CMS System Admin")]
    public class LogViewerController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index()
        {
            return View("Index");
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SearchLog(DateTime startTime
            , DateTime endTime
            , int logType
            , int pageSize
            , string userID
            , string sessionGuid
            , string source
            , string ip)
        {
            using (DbManager dbManager = new DbManager("Log"))
            {
                LogAccessor la = DataAccessor.CreateInstance<LogAccessor>(dbManager);
                int intUserID = 0;
                int.TryParse(userID, out intUserID);

                List<cmLog> list = la.QueryLog( logType
                    , intUserID
                    , sessionGuid ?? string.Empty
                    , source ?? string.Empty
                    , ip ?? string.Empty
                    , startTime
                    , endTime
                    , pageSize
                    );

                return this.Json(new { @success = true, @data = list.Select( l => new 
                {
                    ID = l.ID,
                    l.ServerName,
                    l.Message,
                    Ins = l.Ins.ToString("dd/MM/yyyy HH:mm:ss"),
                    l.SessionID,
                    l.IP,
                    l.Url,
                    l.UserID,
                    l.OperatorName,
                    l.Source,
                    LogType = l.LogType.ToString().ToLowerInvariant(),
                }).ToArray() });
            }            
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetStackTrace( long id )
        {
            using (DbManager dbManager = new DbManager("Log"))
            {
                LogAccessor la = DataAccessor.CreateInstance<LogAccessor>(dbManager);
                return this.Json(new { success = true, data = la.GetStackTrace(id) }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public ActionResult AccessLog(long minuteStamp, string server, string op)
        {
            using (DbManager dbManager = new DbManager("Log"))
            {
                LogAccessor la = DataAccessor.CreateInstance<LogAccessor>(dbManager);
                return this.View("AccessLog", la.QueryAccessLog(minuteStamp, server ?? string.Empty, op ?? string.Empty));
            }
        }


        [HttpGet]
        public ActionResult Details(long id)
        {
            using (DbManager dbManager = new DbManager("Log"))
            {
                LogAccessor la = DataAccessor.CreateInstance<LogAccessor>(dbManager);
                return this.View("Details", la.QueryLog(id));
            }
        }
        
    }



}
