using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "CasinoLobbySection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileCasinoController : CasinoEngineLobbyController
	{
		public new ViewResult Index()
		{
			return View();
		}
	}
}