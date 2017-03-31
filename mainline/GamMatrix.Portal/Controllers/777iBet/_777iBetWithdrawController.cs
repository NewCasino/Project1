using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers._777iBet
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class _777iBetWithdrawController : GamMatrix.CMS.Controllers.Shared.WithdrawController
    {
        public override ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            // if the profile is uncompleted, redirect user to profile page
            if (string.IsNullOrWhiteSpace(user.Address1) ||
                string.IsNullOrWhiteSpace(user.Zip) ||
                string.IsNullOrWhiteSpace(user.Mobile) ||
                string.IsNullOrWhiteSpace(user.SecurityQuestion) ||
                string.IsNullOrWhiteSpace(user.SecurityAnswer) ||
                string.IsNullOrWhiteSpace(user.City) ||
                string.IsNullOrWhiteSpace(user.Title) ||
                string.IsNullOrWhiteSpace(user.FirstName) ||
                string.IsNullOrWhiteSpace(user.Surname) ||
                string.IsNullOrWhiteSpace(user.Currency) ||
                string.IsNullOrWhiteSpace(user.Language) ||
                user.CountryID <= 0 ||
                !user.Birth.HasValue)
            {
                return View("IncompleteProfile");
            }

            return Prepare("LocalBank");
        }
    }
}
