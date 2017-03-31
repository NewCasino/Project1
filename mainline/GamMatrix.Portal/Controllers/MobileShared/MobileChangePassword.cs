using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
	[RequireLogin]
    [ControllerExtraInfo(DefaultAction = "Index")]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "ChangePasswordSection")]
	public class MobileChangePasswordController : ChangePwdController
    {

    }
}