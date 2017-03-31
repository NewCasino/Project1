using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "CasinoFPPSection")]
	[ControllerExtraInfo(DefaultAction = "LearnMore")]
    public class MobileCasinoFPPController : ControllerEx
	{
		public ViewResult Index()
		{
			return View();
		}

		public ViewResult Rates()
		{
			return View();
		}

		public ViewResult LearnMore()
		{
			return View();
		}

        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [RequireLogin]
        public ViewResult Claim()
        {
            return View();
        }
	}
}
