using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using CM.Content;
using CM.State;
using CM.db;
using CM.db.Accessor;
using System.Web;
using Newtonsoft.Json;
using BLToolkit.DataAccess;
using CM.Sites;
namespace GamMatrix.CMS.HttpHandlers
{
    public sealed class UserPromotionHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {

            CustomProfile.Current.Init(context);
            if (!CustomProfile.Current.IsAuthenticated)
            {
                Error("no access");
            }
            else
            {
                var action = context.Request.QueryString["action"];
                if (string.IsNullOrEmpty(action) || !action.Equals("get", StringComparison.InvariantCultureIgnoreCase))
                {
                    Create(context);
                }
                else
                {
                    Search(context);
                }

            }
            
        }

        private void Search(HttpContext context)
        {
            int siteID = SiteManager.Current.ID;
            string startTime = HttpUtility.UrlDecode(context.Request["startTime"]),
                endTime = HttpUtility.UrlDecode(context.Request["endTime"]);
            List<cmUserPromotion> userList;
            try
            {
                UserPromotionAccessor ua = DataAccessor.CreateInstance<UserPromotionAccessor>();
                if (string.IsNullOrEmpty(startTime) && string.IsNullOrEmpty(endTime))
                {
                    userList = ua.GetAllBySiteID(siteID);
                }
                else
                {
                    DateTime time1 = DateTime.Now.AddMonths(-1),
                        time2 = DateTime.Now;
                    if (!string.IsNullOrEmpty(startTime))
                        DateTime.TryParse(startTime, out time1);
                    if (!string.IsNullOrEmpty(endTime))
                        DateTime.TryParse(endTime, out time2);

                    userList = ua.Get(siteID, time1, time2);
                }

                var response = context.Response;

                response.Charset = "UTF-8";
                response.AppendHeader("Content-Disposition", "attachment;filename=promotion-" + System.DateTime.Now.ToString("yyyyMMdd") + ".csv");
                response.ContentEncoding = System.Text.Encoding.GetEncoding("UTF-8");
                response.ContentType = "application/ms-excel";
                response.Write(ToCSV(userList));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                Error(ex.Message);
            }
        }
        private string ToCSV(IEnumerable<cmUserPromotion> list)
        {
            if (list == null)
                return string.Empty;

            StringBuilder sb = new StringBuilder();

            sb.AppendLine("UserID,UserName,Email,Source,Date");
            foreach (var user in list)
            {
                sb.AppendLine(string.Format("{0},{1},{2},{3},{4}", user.UserID, user.UserName, user.Email, user.TargetSource, user.ClickDate.ToString()));
            }
            return sb.ToString();
        }
        private void Create(HttpContext context)
        {
            int userId = CustomProfile.Current.UserID,
                siteId = SiteManager.Current.ID;
            Func<string> getSource = () => {
                var refUrl = HttpUtility.UrlDecode(context.Request["source"].DefaultIfNullOrEmpty(string.Empty));
                if (string.IsNullOrEmpty(refUrl))
                {
                    if (context.Request.UrlReferrer != null)
                        refUrl = context.Request.UrlReferrer.ToString();
                }

                return refUrl;
                
            };
            string source = getSource();

            if (userId == 0 || siteId == 0 || string.IsNullOrWhiteSpace(source))
            {
                Error("parameters missing!");
                return;
            }

            try
            {
                UserPromotionAccessor ua = DataAccessor.CreateInstance<UserPromotionAccessor>();
                ua.Create(userId, siteId, source);
                Success();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                Error(ex.Message);
            }

        }

        private int GetInt(HttpContext context, string key)
        {
            int v = 0;
            int.TryParse(context.Request[key], out v);
            return v;
        }

        private void Error(string errorMessage)
        {
            ResponseJson( new { @success = false, @error = errorMessage });
        }
        private void Success(string msg = "")
        {
            ResponseJson(new { @success = true, msg = msg });
        }

        private void ResponseJson(dynamic obj)
        {
            var context = HttpContext.Current;
            var json = JsonConvert.SerializeObject(obj);
            context.Response.ClearHeaders();
            context.Response.ContentType = "application/json";
            context.Response.AddHeader("Content-Length", json.Length.ToString());
            context.Response.Write(json);
        }



        public bool IsReusable
        {
            get
            {
                return true;
            }
        }

      

       
    }
}
