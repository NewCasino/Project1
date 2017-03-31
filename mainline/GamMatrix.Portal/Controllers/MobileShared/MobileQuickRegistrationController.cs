using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[ControllerExtraInfo(DefaultAction = "Index")]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "QuickRegisterSection")]
	public class MobileQuickRegistrationController : QuickRegistrationController
	{
		
	}
}
