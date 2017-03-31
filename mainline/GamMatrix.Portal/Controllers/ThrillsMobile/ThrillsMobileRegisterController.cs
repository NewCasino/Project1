using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;
using System.Web;

namespace GamMatrix.CMS.Controllers.ThrillsMobile
{
    [HandleError]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "RegisterSection")]
    [ControllerExtraInfo(DefaultAction = "Step1")]
    public class ThrillsMobileRegisterController : MobileRegisterController
    {
        public override void RegisterAsync(string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string personalId
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
            , string avatar
            , string username
            , string alias
            , string password
            , string currency
            , string securityQuestion
            , string securityAnswer
            , string language
            , bool? allowNewsEmail
            , bool? allowSmsOffer
            , string taxCode
            , string referrerID
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha = null
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
            )
        {
            base.RegisterAsync(
                title
                , firstname
                , surname
                , email
                , birth
                , personalId
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
                , avatar
                , username
                , alias
                , password
                , currency
                , string.IsNullOrWhiteSpace(securityQuestion) ? "Security question" : securityQuestion
                , string.IsNullOrWhiteSpace(securityAnswer) ? "Security answer" : securityAnswer
                , language
                , allowNewsEmail
                , allowSmsOffer
                , taxCode
                , referrerID,   intendedVolume
            , dOBPlace, registerCaptcha, iovationBlackBox, passport, contractValidity);
        }
    }
}
