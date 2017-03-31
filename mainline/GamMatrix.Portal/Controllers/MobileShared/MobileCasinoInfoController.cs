using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "CasinoInfoSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileCasinoInfoController : ControllerEx
	{
		public ViewResult Index()
		{
			return View();
		}

		public ViewResult BonusContribution()
		{
			return View();
		}
	}
}
