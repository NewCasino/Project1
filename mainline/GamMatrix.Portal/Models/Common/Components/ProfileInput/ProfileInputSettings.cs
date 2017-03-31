using System;
using System.Collections.Generic;

namespace GamMatrix.CMS.Models.Common.Components.ProfileInput
{
	public abstract class ProfileInputSettings
	{
		public abstract bool IsTitleVisible { get; }
		public abstract bool IsTitleRequired { get; }
		public abstract bool IsFirstnameVisible { get; }
		public abstract bool IsFirstnameRequired { get; }
		public abstract bool IsSurnameVisible { get; }
		public abstract bool IsSurnameRequired { get; }
		public abstract bool IsEmailVisible { get; }
		public abstract bool IsBirthDateVisible { get; }
		public abstract bool IsBirthDateRequired { get; }

		public abstract bool IsCountryVisible { get; }
		public abstract bool IsAddress1Visible { get; }
		public abstract bool IsAddress1Required { get; }
		public abstract bool IsAddress2Visible { get; }
        public abstract bool IsStreetVisible { get; }
        public abstract bool IsStreetRequired { get; }
		public abstract bool IsCityVisible { get; }
		public abstract bool IsCityRequired { get; }
		public abstract bool IsPostalCodeVisible { get; }
		public abstract bool IsPostalCodeRequired { get; }
		public abstract bool IsMobileVisible { get; }
		public abstract bool IsMobileRequired { get; }

		public abstract bool IsCurrencyVisible { get; }
		public abstract bool IsUsernameVisible { get; }
		public abstract bool IsPasswordVisible { get; }
		public abstract bool IsSecurityQuestionVisible { get; }
		public abstract bool IsSecurityQuestionRequired { get; }
		public abstract bool IsLanguageVisible { get; }
		public abstract bool IsAllowNewsEmailVisible { get; }
		public abstract bool IsAllowSmsOffersVisible { get; }
		public abstract bool IsTermsConditionsVisible { get; }

		public abstract bool IsPersonalIDVisible { get; }

        public abstract bool IsRegionIDVisible { get; }
        public abstract bool IsRegionIDRequired { get; }

        public abstract bool IsPassportVisible { get; }
        public abstract bool IsPassportRequired { get; }

        public string Title
			, FirstName
			, Surname
			, Email
			, Country
			, Address1
			, Address2
            , StreetName
            , StreetNumber
			, City
			, Zip
			, Mobile
			, MobilePrefix
			, Currency
			, Username
			, SecurityQuestion
			, SecurityAnswer
			, PersonalID
            , RegionID
            , PassportID;
		public bool? AllowNewsEmail
			, AllowSmsOffer;
		public DateTime? Birth;



		public ProfileInputSettings() { }

		public ProfileInputSettings(Dictionary<string, string> initialValues)
			: this()
		{
			if (initialValues == null)
				return;

			initialValues.TryGetValue("Title", out Title);
			initialValues.TryGetValue("FirstName", out FirstName);
			initialValues.TryGetValue("Surname", out Surname);
			initialValues.TryGetValue("Email", out Email);
			initialValues.TryGetValue("Country", out Country);
			initialValues.TryGetValue("Address1", out Address1);
			initialValues.TryGetValue("Address2", out Address2);
            initialValues.TryGetValue("StreetName", out StreetName);
            initialValues.TryGetValue("StreetNumber", out StreetNumber);
			initialValues.TryGetValue("City", out City);
			initialValues.TryGetValue("Zip", out Zip);
			initialValues.TryGetValue("Mobile", out Mobile);
			initialValues.TryGetValue("MobilePrefix", out MobilePrefix);
			initialValues.TryGetValue("Currency", out Currency);
			initialValues.TryGetValue("Username", out Username);
			initialValues.TryGetValue("SecurityQuestion", out SecurityQuestion);
			initialValues.TryGetValue("SecurityAnswer", out SecurityAnswer);
			initialValues.TryGetValue("PersonalID", out PersonalID);
            initialValues.TryGetValue("RegionID", out RegionID);
            initialValues.TryGetValue("PassportID", out PassportID);

            string rawPromoFlag; bool promoFlag;
			if (initialValues.TryGetValue("AllowNewsEmail", out rawPromoFlag) && bool.TryParse(rawPromoFlag, out promoFlag))
				AllowNewsEmail = promoFlag;
			if (initialValues.TryGetValue("AllowSmsOffer", out rawPromoFlag) && bool.TryParse(rawPromoFlag, out promoFlag))
				AllowSmsOffer = promoFlag;

			string rawBirthDate; DateTime birthDate;
			if (initialValues.TryGetValue("BirthDate", out rawBirthDate) && DateTime.TryParse(rawBirthDate, out birthDate))
				Birth = birthDate;
		}
	}
}
