using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Text;
using System.Text.RegularExpressions;
using System.Linq;
using System.Security.Principal;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Security;
using System.Globalization;
using System.Reflection;
using System.Net;
using System.Configuration;

using CM.Web;
using CM.Sites;

using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;

using Finance;
using GamMatrixAPI;
using GmCore;
using CM.State;

/// <summary>
/// Summary description for MegaVinnTCController
/// </summary>
namespace GamMatrix.CMS.Controllers.MegaVinn
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "")]
    public class MegaVinnTCController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [ProtocolAttribute(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            //db connect ...
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            string cacheKey = string.Format("IsTCAcceptRequired_{0}", CustomProfile.Current.UserID);
            HttpRuntime.Cache[cacheKey] = user.IsTCAcceptRequired.ToString();
            if (user.IsTCAcceptRequired)
            {
                return View("Index");
            }
            else
            {
                return this.Redirect("/TermsConditions");
            }
        } 

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult AcceptTC()
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            SqlQuery<cmUser> query = new SqlQuery<cmUser>();
            user.IsTCAcceptRequired = false;
            query.Update(user);
            //cache
            string cacheKey = string.Format("IsTCAcceptRequired_{0}", CustomProfile.Current.UserID);
            HttpRuntime.Cache[cacheKey] = false;
            return this.Redirect("/");
        } 

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult RejectTC()
        {
            //blockUser

            string BlockNote = "T&C rejected";
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                UpdateUserStatusRequest userUpdateStatusDate = client.SingleRequest<UpdateUserStatusRequest>(new UpdateUserStatusRequest()
                {
                    BlockNote = BlockNote,
                    BlockType = UserBlockType.TCDeclined,   // need oleg 's msg
                    UserID = CustomProfile.Current.UserID,
                    NewStatus = ActiveStatus.Blocked,
                });
            } 
 
            //logout


            try
            {

                OddsMatrix.OddsMatrixProxy.Logoff();
                CustomProfile.Current.AsCustomProfile().Logoff();
                //cache remove 
                string cacheKey = string.Format("IsTCAcceptRequired_{0}", CustomProfile.Current.UserID);
                HttpRuntime.Cache.Remove(cacheKey);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            //redirect 
            return this.Redirect("/");
        }
    }
}