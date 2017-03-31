using System;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;
using GmCore;

namespace GamMatrix.CMS.Controllers._777iBetMobile
{
    [HandleError]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "ProfileSection")]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
    [RequireLogin]
    public class _777iBetMobileProfileController : MobileProfileController
    {
        public override ActionResult UpdateProfile(string avatar
          , string alias
          , string currency
          , string securityQuestion
          , string securityAnswer
          , string language
          , int? country
          , int? regionID
          , string address1
          , string address2
          , string streetname
          , string streetnumber
          , string city
          , string postalCode
          , string mobilePrefix
          , string mobile
          , string phonePrefix
          , string phone
          , bool allowNewsEmail
          , bool allowSmsOffer
          , string title
          , string firstname
          , string surname
          , string birth
          , string preferredCurrency
          , string taxCode
          , string affiliateMarker, int? intendedVolume, string personalID = null, string favoriteTeam = null, string passport = null)
        {

            try
            {

                try
                {


                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    bool IsProfileAlreadyCompleted = true;

                    if (!string.IsNullOrWhiteSpace(language))
                        user.Language = language.Trim();
                    else IsProfileAlreadyCompleted = false;

                    user.AllowNewsEmail = allowNewsEmail;
                    user.AllowSmsOffer = allowSmsOffer;

                    if (intendedVolume.HasValue)
                        user.intendedVolume = intendedVolume.Value;

                    if (!IsProfileAlreadyCompleted)
                        user.CompleteProfile = DateTime.Now;

                    if (!string.IsNullOrWhiteSpace(streetname) && !string.IsNullOrWhiteSpace(streetnumber))
                    {
                        user.Address1 = string.Format("{0} {1}", streetname, streetnumber);
                    }
                    GamMatrixClient.UpdateUserDetails(user);

                    //update role string of session
                    if (!IsProfileAlreadyCompleted)
                    {
                        string roleString = GamMatrixClient.GetRoleString(user.ID, SiteManager.Current);
                        CustomProfile.Current.RoleString = roleString;
                    }

                    //CustomProfile.Current.PreferredCurrency = user.PreferredCurrency;
                    //CustomProfile.ClearSessionCache(CustomProfile.Current.SessionID);
                    CustomProfile.ReloadSessionCache(user.ID);

                }
                catch (GmException gex)
                {
                    // ignore the error SYS_1034
                    if (gex.ReplyResponse.ErrorCode != "SYS_1034")
                        throw;
                }

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }

            return this.View("Success");
        }
    }
}
