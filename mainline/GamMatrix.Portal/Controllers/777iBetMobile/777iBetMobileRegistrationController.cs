using System;
using System.Collections.Generic;
using System.Web.Mvc;
using CM.Content;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrixAPI;
using GmCore;
using System.Web;

namespace GamMatrix.CMS.Controllers._777iBetMobile
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Step1")]
    public class _777iBetMobileRegistrationController : RegistrationController
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [CompressFilter]
        public ActionResult Step1()
        {
            return View("Step1");
        }

        [HttpGet]
        public RedirectResult Step2()
        {
            return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
        }

        [HttpPost]
        [CompressFilter]
        public ViewResult Step2(
            string username
            , string alias
            , string password)
        {
            this.ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "username", username },
				{ "alias", alias },
				{ "password", password },
			};

            return View("Step2");
        }

        [HttpGet]
        public RedirectResult Step3()
        {
            return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
        }

        [HttpPost]
        [CompressFilter]
        public ViewResult Step3(
            string username
            , string alias
            , string password
            , string email
            , string mobilePrefix
            , string mobile
            , string additionalInfo
            )
        {
            this.ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "username", username },
                { "alias", alias },
                { "password", password },
                { "email", email },
                { "mobilePrefix", mobilePrefix },
                { "mobile", mobile },
                { "address2", additionalInfo }
			};

            return View("Step3");
        }

        [HttpGet]
        public ActionResult CountryBlocked()
        {
            return this.View("CountryBlockedView");
        }

        [HttpGet]
        public ActionResult MaxSameIPRegistrationExceeded()
        {
            return this.View("MaxSameIPRegistrationExceededView");
        }

        public ViewResult Complete()
        {
            //this.RegisterPayCard(VendorID.LocalBank
            return View("CompleteView");
        }

        public string GetRandomString(int length)
        {
            int rep = 0;
            string str = string.Empty;
            long num2 = DateTime.Now.Ticks + rep;
            rep++;
            Random random = new Random(((int)(((ulong)num2) & 0xffffffffL)) | ((int)(num2 >> rep)));
            for (int i = 0; i < length; i++)
            {
                char ch;
                int num = random.Next();
                if ((num % 2) == 0)
                {
                    ch = (char)(0x30 + ((ushort)(num % 10)));
                }
                else
                {
                    ch = (char)(0x41 + ((ushort)(num % 0x1a)));
                }
                str = str + ch.ToString();
            }
            return str;
        }


        /// <summary>
        /// Register user
        /// </summary>
        /// <returns></returns>
        [HttpPost]
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
            if (Settings.Registration.UsenameAsAlias && !string.IsNullOrWhiteSpace(username))
            {
                alias = username;
            }

            #region init data
            if (string.IsNullOrWhiteSpace(title)) title = "Mr.";
            if (string.IsNullOrWhiteSpace(language)) language = "ko";
            if (!country.HasValue) country = 202;
            if (string.IsNullOrWhiteSpace(currency)) currency = "KRW";
            if (!allowNewsEmail.HasValue) allowNewsEmail = false;
            if (!allowSmsOffer.HasValue) allowSmsOffer = false;

            string random1 = GetRandomString(6).ToLower();
            string random2 = GetRandomString(6).ToLower();
            string random3 = GetRandomString(6).ToLower();
            //string 
            if (string.IsNullOrWhiteSpace(firstname))
            {
                firstname = "firstname" + random1;
            }
            if (string.IsNullOrWhiteSpace(surname))
            {
                surname = "surname" + random2;
            }

            if (string.IsNullOrWhiteSpace(email))
                email = random1 + "@email";

            if (string.IsNullOrWhiteSpace(birth))
                birth = "1990-01-01";

            if (string.IsNullOrWhiteSpace(address1))
                address1 = "address1" + random2;

            if (string.IsNullOrWhiteSpace(city))
                city = "city" + random3;

            if (string.IsNullOrWhiteSpace(postalCode))
                postalCode = "100-000";

            if (string.IsNullOrWhiteSpace(securityQuestion))
            {
                securityQuestion = Metadata.Get("Metadata/SecurityQuestion/MyFavouriteBet.Text");
                if (string.IsNullOrWhiteSpace(securityQuestion))
                    securityQuestion = Metadata.Get(Metadata.GetChildrenPaths("Metadata/SecurityQuestion")[0] + ".Text");
            }
            if (string.IsNullOrWhiteSpace(securityAnswer))
                securityAnswer = "football";

            #endregion

            username = InitUsername(username, email);

            if (!country.HasValue)
                country = 0;

            AsyncManager.Parameters["title"] = title;
            AsyncManager.Parameters["firstname"] = firstname;
            AsyncManager.Parameters["surname"] = surname;
            AsyncManager.Parameters["email"] = email;
            AsyncManager.Parameters["birth"] = birth;
            AsyncManager.Parameters["personalId"] = personalId;
            AsyncManager.Parameters["country"] = country;
            AsyncManager.Parameters["regionID"] = regionID;
            AsyncManager.Parameters["address1"] = address1;
            AsyncManager.Parameters["address2"] = address2;
            AsyncManager.Parameters["streetname"] = streetname;
            AsyncManager.Parameters["streetnumber"] = streetnumber;
            AsyncManager.Parameters["city"] = city;
            AsyncManager.Parameters["postalCode"] = postalCode;
            AsyncManager.Parameters["mobilePrefix"] = mobilePrefix;
            AsyncManager.Parameters["mobile"] = mobile;
            AsyncManager.Parameters["phonePrefix"] = phonePrefix;
            AsyncManager.Parameters["phone"] = phone;
            AsyncManager.Parameters["avatar"] = avatar;
            AsyncManager.Parameters["username"] = username;
            AsyncManager.Parameters["alias"] = alias;
            AsyncManager.Parameters["password"] = password;
            AsyncManager.Parameters["currency"] = currency;
            AsyncManager.Parameters["securityQuestion"] = securityQuestion;
            AsyncManager.Parameters["securityAnswer"] = securityAnswer;
            AsyncManager.Parameters["language"] = language;
            AsyncManager.Parameters["allowNewsEmail"] = allowNewsEmail.HasValue ? allowNewsEmail.Value : false;
            AsyncManager.Parameters["allowSmsOffer"] = allowSmsOffer.HasValue ? allowSmsOffer.Value : false;
            AsyncManager.Parameters["taxCode"] = taxCode;
            AsyncManager.Parameters["referrerID"] = referrerID;
            AsyncManager.Parameters["intendedVolume"] =  intendedVolume;
            AsyncManager.Parameters["dOBPlace"]=  dOBPlace;
            AsyncManager.Parameters["isUsernameAvailable"] = true;
            AsyncManager.Parameters["isEmailAvailable"] = true;
            AsyncManager.Parameters["isAliasAvailable"] = true;
            AsyncManager.Parameters["registerCaptcha"] = registerCaptcha;
            AsyncManager.Parameters["passport"] = passport;
            AsyncManager.Parameters["contractValidity"] = contractValidity;

            if (Request.Cookies["btag"] != null)
                AsyncManager.Parameters["affiliateMarker"] = Request.Cookies["btag"].Value;

            List<VendorRec> vendors = GamMatrixClient.GetGamingVendors();
            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.BingoNetwork))
            {
                if (!string.IsNullOrEmpty(alias))
                {
                    AsyncManager.OutstandingOperations.Increment();
                    GamMatrixClient.IsAliasAvailableAsync(alias, OnAliasAvailableVerifyCompleted);
                }
            }

            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.EverleafNetwork))
            {
                if (!string.IsNullOrEmpty(alias))
                {
                    AsyncManager.OutstandingOperations.Increment();
                    GamMatrixClient.IsEverleafPokerUserNameEmailAndAliasAvailableAsync(username
                        , email
                        , alias
                        , OnEverleafPokerUsernameEmailAndAliasAvailableVerifyCompleted
                        );
                }
            }
        }

        private bool RegisterLocalBankPayCard(VendorID vendorID
            , string bankName
            , string nameOnAccount
            , string bankAccountNo
            , out string error
            )
        {
            error = string.Empty;

            if (string.IsNullOrWhiteSpace(bankName)
                || string.IsNullOrWhiteSpace(nameOnAccount)
                || string.IsNullOrWhiteSpace(bankAccountNo))
                throw new ArgumentException();

            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            if (CustomProfile.Current.UserCountryID != 223 && CustomProfile.Current.UserCountryID != 202)
                throw new ArgumentException("your country did not allowed the bank.");

            string displayNumber = "";
            string identityNumber = "";
            if (CustomProfile.Current.UserCountryID == 202) // Korea
            {
                displayNumber = bankAccountNo;
                identityNumber = bankAccountNo;
            }

            List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.LocalBank);
            if (payCards.Exists(p => p.OwnerName.Equals(nameOnAccount, StringComparison.InvariantCultureIgnoreCase)
                && p.BankName.Equals(bankName, StringComparison.InvariantCultureIgnoreCase)
                && (p.BankAccountNo.Equals(bankAccountNo, StringComparison.InvariantCultureIgnoreCase))))
            {
                //return this.Json(new { @success = false, @error = "Multi card with same details is not allowed" });
                error = "Multi card with same details is not allowed";
                return false;
            }

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = vendorID;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;
            payCard.BankAccountNo = bankAccountNo;
            payCard.IdentityNumber = identityNumber;
            payCard.DisplayNumber = displayNumber;
            payCard.DisplayName = displayNumber;
            payCard.OwnerName = nameOnAccount;
            payCard.BankName = bankName;
            payCard.BankCountryID = CustomProfile.Current.UserCountryID;

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard);

            //return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
            return true;
        }

        public override ViewResult RegisterCompleted(string title, string firstname, string surname, string email, string birth, string personalId, int country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city, string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar, string username, string alias, string password, string currency, string securityQuestion, string securityAnswer, string language, bool allowNewsEmail, bool allowSmsOffer, string affiliateMarker, bool? isUsernameAvailable, bool? isAliasAvailable, bool? isEmailAvailable, string taxCode, string referrerID
            , string intendedVolume
            , string dOBPlace, string registerCaptcha = null, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {

            string bank = Request.Form["bank"];
            string bankAccountNo = Request.Form["bankAccountNo"];
            string bankAccountName = Request.Form["nameOfAccount"];

            var registerCompltedViewResult =
                base.RegisterCompleted(title, firstname, surname, email, birth, personalId, country, regionID, address1, address2, streetname, streetnumber, city, postalCode
                , mobilePrefix, mobile, phonePrefix, phone, avatar, username, alias, password, currency, securityQuestion, securityAnswer, language
                , allowNewsEmail, allowSmsOffer, affiliateMarker, isUsernameAvailable, isAliasAvailable, isEmailAvailable, taxCode, referrerID
            ,   intendedVolume
            , dOBPlace, registerCaptcha, passport, contractValidity);

            string registerLocalBankErr;
            if (this.RegisterLocalBankPayCard(VendorID.LocalBank, bank, bankAccountName, bankAccountNo, out registerLocalBankErr) == false)
            {

            }

            return registerCompltedViewResult;//base.RegisterCompleted(title, firstname, surname, email, birth, personalId, country, regionID, address1, address2, city, postalCode, mobilePrefix, mobile, phonePrefix, phone, avatar, username, alias, password, currency, securityQuestion, securityAnswer, language, allowNewsEmail, allowSmsOffer, affiliateMarker, isUsernameAvailable, isAliasAvailable, isEmailAvailable, taxCode);
        }
    }
}
