using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[RequireLogin]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "SelfExclusionSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileSelfExclusionController : SelfExclusionController
	{

	}
}