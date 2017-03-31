using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;
using GamMatrix.CMS.Models.MobileShared.Components;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.JetbullMobileDev
{
    public class JetbullMobileMenuController : MobileMainMenuController
    {
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public new ActionResult AccountMenuPartial()
        {
            //if (!Request.IsAjaxRequest())
            //{
            //}
            return PartialView("/Components/AccountMenu", new MenuV2ViewModel(this.Url
                , showSections: false
                , showMainMenuEntries: false
                , showAccountEntries: true));
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public new ActionResult ViewProfilePartial()
        {
            //if (!Request.IsAjaxRequest())
            //{
            //}

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            return PartialView("/Profile/DisplayView", user);
        }
        
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public new ActionResult SettingsV2Partial()
        {
            //if (!Request.IsAjaxRequest())
            //{
            //}
            return PartialView("/Components/SettingsV2");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public new ActionResult AccountSettingsPartial()
        {
            //if (!Request.IsAjaxRequest())
            //{
            //}
            return PartialView("/AccountSettings/InputView");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public new ActionResult SelfExclusionPartial()
        {
            //if (!Request.IsAjaxRequest())
            //{
            //}
            return PartialView("/SelfExclusion/InputView");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public new ActionResult DepositLimitPartial()
        {
            //if (!Request.IsAjaxRequest())
            //{
            //}

            RgDepositLimitInfoRec record;

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRgDepositLimitRequest getUserRgDepositLimitRequest = 
                    client.SingleRequest<GetUserRgDepositLimitRequest>(new GetUserRgDepositLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    });

                record = getUserRgDepositLimitRequest.Record;
            }

            return PartialView("/DepositLimit/InputView", record);
        }

    }
}
