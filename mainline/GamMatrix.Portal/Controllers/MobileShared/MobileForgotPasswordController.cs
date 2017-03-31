using System.Web.Mvc;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "ForgotPasswordSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{key}")]
    public class MobileForgotPasswordController : GamMatrix.CMS.Controllers.Shared.ForgotPasswordController
    {
        
    }
}