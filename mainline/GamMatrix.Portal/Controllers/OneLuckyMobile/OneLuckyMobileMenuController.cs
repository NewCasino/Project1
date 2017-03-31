using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;
using GamMatrix.CMS.Models.MobileShared.Menu;

namespace GamMatrix.CMS.Controllers.OneLuckyMobile
{
	[HandleError]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class OneLuckyMobileMenuController : MobileMainMenuController
	{
		public ActionResult AccountMenu()
		{
			return View(new MenuBuilder());
		}
	}
}
