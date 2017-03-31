using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "ProfileSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	[Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
	[RequireLogin]
    public class MobileProfileController : ProfilePageController
	{
        [HttpGet]
        public override ActionResult Index()
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            return View("Index", user);
        }

		[HttpGet]
		public ActionResult Edit()
		{
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            return View("Edit", user);
		}
	}
}