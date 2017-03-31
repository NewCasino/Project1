using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Models.MobileShared.Home;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "HomeSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
    public class MobileOriginalHomeController : MobileHomeController
	{
		public override  ActionResult Index()
		{
			CheckNativeApp();

			var model = new HomeViewModel();

			if (model.ActiveSections == 1)
			{
				var redirectRoute = model.EnableSports ? "Sports_Home"
					: model.EnableLiveCasino ? "LiveCasinoLobby"
					: "CasinoLobby";

				return Redirect(Url.RouteUrl(redirectRoute, new { btag = Request.QueryString["btag"] }));
			}

			return View(model);
		}
	}
}
