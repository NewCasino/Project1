using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;

namespace GamMatrix.CMS.Controllers.ThrillsMobile
{
    [HandleError]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "ProfileSection")]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
    [RequireLogin]
    public class ThrillsMobileProfileController : MobileProfileController
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
            return base.UpdateProfile(avatar
                , alias
                , currency
                , "Security question"
                , "Security answer"
                , language
                , country
                , regionID
                , address1
                , address2
                , streetname
                , streetnumber
                , city
                , postalCode
                , mobilePrefix
                , mobile
                , phonePrefix
                , phone
                , allowNewsEmail
                , allowSmsOffer
                , title
                , firstname
                , surname
                , birth
                , preferredCurrency
                , taxCode
                , affiliateMarker
                , intendedVolume);
        }
    }
}
