using System.Web.Mvc;
using CM.Content;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.GutsMobile
{
	[HandleError]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class GutsMobileCasinoLobbyController : CasinoEngineLobbyController
	{
		public override ActionResult Index()
		{
			return Redirect(Metadata.Get("/Metadata/Settings.CustomHomeUrl"));
		}
	}
}
