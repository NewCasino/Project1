using System;
using CM.db;

namespace GamMatrix.CMS.Models.Common.Components.ProfileInput
{
	public class ProfileInputEditSettings : ProfileInputSettings
	{
		public cmUser UserProfile { get; private set; }

		public override bool IsTitleVisible
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.Title); }
		}

		public override bool IsTitleRequired
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.Title); }
		}

		public override bool IsFirstnameVisible
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.FirstName); }
		}

		public override bool IsFirstnameRequired
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.FirstName); }
		}

		public override bool IsSurnameVisible
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.Surname); }
		}

		public override bool IsSurnameRequired
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.Surname); }
		}

		public override bool IsEmailVisible
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.Email); }
		}

		public override bool IsBirthDateVisible
		{
			get { return UserProfile.Birth == null; }
		}

		public override bool IsBirthDateRequired
		{
			get { return UserProfile.Birth == null; }
		}

		public override bool IsCountryVisible
		{
			get { return UserProfile.CountryID < 1; }
		}

		public override bool IsAddress1Visible
		{
			get { return true; }
		}

		public override bool IsAddress1Required
		{
			get { return true; }
		}

		public override bool IsAddress2Visible
		{
			get { return true; }
		}

        public override bool IsStreetVisible
        {
            get { return false; }
        }

        public override bool IsStreetRequired
        {
            get { return false; }
        }

		public override bool IsCityVisible
		{
			get { return true; }
		}

		public override bool IsCityRequired
		{
			get { return true; }
		}

		public override bool IsPostalCodeVisible
		{
			get { return true; }
		}

		public override bool IsPostalCodeRequired
		{
			get { return true; }
		}

		public override bool IsMobileVisible
		{
			get { return true;  }
		}

		public override bool IsMobileRequired
		{
			get { return true; }
		}

		public override bool IsCurrencyVisible
		{
			get { return string.IsNullOrWhiteSpace(UserProfile.Currency); }
		}

		public override bool IsUsernameVisible
		{
			get { return false; }
		}

		public override bool IsPasswordVisible
		{
			get { return false; }
		}

		public override bool IsSecurityQuestionVisible
		{
			get { return true; }
		}

		public override bool IsSecurityQuestionRequired
		{
			get { return true; }
		}

		public override bool IsLanguageVisible
		{
			get { return true; }
		}

		public override bool IsAllowNewsEmailVisible
		{
			get { return true; }
		}

		public override bool IsAllowSmsOffersVisible
		{
			get { return true; }
		}

		public override bool IsTermsConditionsVisible
		{
			get { return false; }
		}

		public override bool IsPersonalIDVisible
		{
			get { return false; }
		}

        public override bool IsRegionIDVisible
        {
            get { return false; }
        }

        public override bool IsRegionIDRequired
        {
            get { return false; }
        }

        public override bool IsPassportVisible
        {
            get { return Settings.Registration.IsPassportVisible; }
        }

        public override bool IsPassportRequired
        {
            get { return Settings.Registration.IsPassportRequired; }
        }


        public ProfileInputEditSettings(cmUser userProfile)
			: base()
		{
			if (userProfile == null)
				throw new ArgumentNullException("userProfile");

			UserProfile = userProfile;

			Title = UserProfile.Title;
			FirstName = UserProfile.FirstName;
			Surname = UserProfile.Surname;
			Email = UserProfile.Email;
			Country = UserProfile.CountryID.ToString();
			Address1 = UserProfile.Address1;
			Address2 = UserProfile.Address2;
			City = UserProfile.City;
			Zip = UserProfile.Zip;
			Mobile = UserProfile.Mobile;
			MobilePrefix = UserProfile.MobilePrefix;
			Currency = UserProfile.Currency;
			Username = UserProfile.Username;
			SecurityQuestion = UserProfile.SecurityQuestion;
			SecurityAnswer = UserProfile.SecurityAnswer;
			Birth = UserProfile.Birth;
			PersonalID = UserProfile.PersonalID;
			AllowNewsEmail = UserProfile.AllowNewsEmail;
			AllowSmsOffer = UserProfile.AllowSmsOffer;
            RegionID = UserProfile.RegionID.ToString();
            PassportID = userProfile.PassportID.ToString();
        }
	}
}
