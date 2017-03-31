using System.Text;
using System.Web.Mvc;
using System.Web.Routing;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Models.MobileShared.Components;
using GamMatrix.CMS.Models.MobileShared.Menu;
using GamMatrix.Infrastructure.Utility;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "MainMenuSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileMainMenuController : ControllerEx
	{
		[HttpGet]
		public ActionResult Index()
		{
			return View("Index", new MenuBuilder());
		}

		public ContentResult GeneralNav()
		{
			return RenderExternalComponent("GeneralNav");
		}

		public ActionResult UserNav()
		{
			if (!CustomProfile.Current.IsAuthenticated)
				return new HttpUnauthorizedResult();

			return RenderExternalComponent("UserNav");
		}

		private ContentResult RenderExternalComponent(string path)
		{
			string componentHtml = ExternalViewComponent.AbsoluteAnchorHref
				(
					ExternalViewComponent.RenderComponent(path, this.ViewData, this.ControllerContext, new MenuBuilder()),
					new UrlHelper(new RequestContext()).GetAbsoluteBaseUrl()
				);

			this.HttpContext.Response.AddHeader("Access-Control-Allow-Origin", "*");
			return this.Content(componentHtml, "text/html", Encoding.UTF8);
        }

        #region MobileV2
        private void AddAccessControlAllowOriginHeader()
        {
            this.HttpContext.Response.AddHeader("Access-Control-Allow-Origin"
                , Settings.OddsMatrix_HomePage.StartsWith("//") ?
                    Request.Url.Scheme + ":" + Settings.OddsMatrix_HomePage
                    : Settings.OddsMatrix_HomePage);
            this.HttpContext.Response.AddHeader("Access-Control-Allow-Credentials"
                , "true");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ActionResult AccountMenuPartial()
        {
            AddAccessControlAllowOriginHeader();
            return PartialView("/Components/AccountMenu", new MenuV2ViewModel(this.Url
                , showSections: false
                , showMainMenuEntries: false
                , showAccountEntries: true));
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ActionResult ViewProfilePartial()
        {
            AddAccessControlAllowOriginHeader();
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            return PartialView("/Profile/DisplayView", user);
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ActionResult SettingsV2Partial()
        {
            AddAccessControlAllowOriginHeader();
            return PartialView("/Components/SettingsV2");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ActionResult AccountSettingsPartial()
        {
            AddAccessControlAllowOriginHeader();
            return PartialView("/AccountSettings/InputView");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ActionResult SelfExclusionPartial()
        {
            AddAccessControlAllowOriginHeader();
            return PartialView("/SelfExclusion/InputView");
        }

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ActionResult DepositLimitPartial()
        {
            AddAccessControlAllowOriginHeader();

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
        #endregion
    }
}
