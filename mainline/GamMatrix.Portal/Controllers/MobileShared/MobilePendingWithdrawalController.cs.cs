using System.Web.Mvc;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [RequireLogin]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "PendingWithdrawalSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "")]
    public class MobilePendingWithdrawalController : GamMatrix.CMS.Controllers.Shared.PendingWithdrawalController
    {
    }
}