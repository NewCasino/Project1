using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [RequireLogin]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "BuddyTransferSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{sid}")]
    public class MobileBuddyTransferController : BuddyTransferController
    {
 
    }
}
