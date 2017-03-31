using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.BetAdonis;

namespace GamMatrix.CMS.Controllers.BetAdonisMobile
{
    [HandleError]
    [MasterPageViewData(Name = "RequestBonusSectionMarkup", Value = "RequestBonusSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}")]
    public class MobileSendEmailController : SendEmailController
    {
    }
}
