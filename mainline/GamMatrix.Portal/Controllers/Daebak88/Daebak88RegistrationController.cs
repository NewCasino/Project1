using System;
using System.Collections.Generic;
using CM.Content;
using GamMatrixAPI;
using GmCore;
using System.Web;

namespace GamMatrix.CMS.Controllers.Daebak88
{
    public class Daebak88RegistrationController: GamMatrix.CMS.Controllers.Shared.RegistrationController
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
            string random3 = GetRandomString(6).ToLower() ;
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
                email = random1+"@email";

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
                    securityQuestion = Metadata.Get(Metadata.GetChildrenPaths("Metadata/SecurityQuestion")[0]+".Text");
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
            AsyncManager.Parameters["intendedVolume"] = intendedVolume;
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
    }
}
