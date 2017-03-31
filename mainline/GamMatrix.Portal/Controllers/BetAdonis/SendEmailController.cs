using System;
using System.Collections.Generic;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.BetAdonis
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}")]
    public class SendEmailController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index()
        {
            return this.View();
        }

        [HttpGet]
        public ActionResult SendEmail()
        {
            bool isSuccess = false;
            string error = string.Empty;
            string username = string.Empty;
            string email = string.Empty;

            try
            {
                using (DbManager dbManager = new DbManager())
                {
                    UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    string source = ControllerContext.RouteData.Values["parameter"].ToString();

                    // send the email
                    Email mail = new Email();
                    if (source.ToLowerInvariant() == "casino")
                    {
                        mail.LoadFromMetadata("CasinoCompensationBonus", user.Language);
                    }
                    else
                    {
                        mail.LoadFromMetadata("SportsCompensationBonus", user.Language);
                    }

                    mail.ReplaceDirectory["EMAIL"] = email = user.Email;
                    mail.ReplaceDirectory["USERNAME"] = username = user.Username;
                    mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                    mail.ReplaceDirectory["LASTNAME"] = user.Surname;
                    foreach (KeyValuePair<string, string> item in mail.ReplaceDirectory)
                    {
                        mail.Subject = mail.Subject.Replace(string.Format("${0}$", item.Key), item.Value);
                    }

                    mail.Send(Metadata.Get("RequestBonus/_Index_aspx.Email_Receiver"));

                    isSuccess = true;
                }


            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
            var result = Json(new
            {
                @success = isSuccess,
                @username = username,
                @email = email,
                @error = error,
            });
            result.JsonRequestBehavior = JsonRequestBehavior.AllowGet;

            return result;
        }
    }
}
