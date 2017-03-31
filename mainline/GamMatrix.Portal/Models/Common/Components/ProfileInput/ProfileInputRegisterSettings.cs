using System.Collections.Generic;

namespace GamMatrix.CMS.Models.Common.Components.ProfileInput
{
	public class ProfileInputRegisterSettings : ProfileInputSettings
	{
		public override bool IsTitleVisible
		{
			get { return Settings.Registration.IsTitleVisible; }
		}

		public override bool IsTitleRequired
		{
			get { return Settings.Registration.IsTitleRequired; }
		}

		public override bool IsFirstnameVisible
		{
			get { return Settings.Registration.IsFirstnameVisible; }
		}

		public override bool IsFirstnameRequired
		{
			get { return Settings.Registration.IsFirstnameRequired; }
		}

		public override bool IsSurnameVisible
		{
			get { return Settings.Registration.IsSurnameVisible; }
		}

		public override bool IsSurnameRequired
		{
			get { return Settings.Registration.IsSurnameRequired; }
		}

		public override bool IsEmailVisible
		{
			get { return true; }
		}

		public override bool IsBirthDateVisible
		{
			get { return Settings.Registration.IsBirthDateVisible; }
		}

		public override bool IsBirthDateRequired
		{
			get { return Settings.Registration.IsBirthDateRequired; }
		}

		public override bool IsCountryVisible
		{
			get { return true; }
		}

		public override bool IsAddress1Visible
		{
			get { return Settings.Registration.IsAddress1Visible; }
		}

		public override bool IsAddress1Required
		{
			get { return Settings.Registration.IsAddress1Required; }
		}

		public override bool IsAddress2Visible
		{
			get { return Settings.Registration.IsAddress2Visible; }
		}

        public override bool IsStreetVisible
        {
            get { return Settings.Registration.IsStreetVisible; }
        }

        public override bool IsStreetRequired
        {
            get { return Settings.Registration.IsStreetRequired; }
        }

		public override bool IsCityVisible
		{
			get { return Settings.Registration.IsCityVisible; }
		}

		public override bool IsCityRequired
		{
			get { return Settings.Registration.IsCityRequired; }
		}

		public override bool IsPostalCodeVisible
		{
			get { return Settings.Registration.IsPostalCodeVisible; }
		}

		public override bool IsPostalCodeRequired
		{
			get { return Settings.Registration.IsPostalCodeRequired; }
		}

		public override bool IsMobileVisible
		{
			get { return Settings.Registration.IsMobileVisible; }
		}

		public override bool IsMobileRequired
		{
			get { return Settings.Registration.IsMobileRequired; }
		}

		public override bool IsCurrencyVisible
		{
			get { return true; }
		}

		public override bool IsUsernameVisible
		{
			get { return true; }
		}

		public override bool IsPasswordVisible
		{
			get { return true; }
		}

		public override bool IsSecurityQuestionVisible
		{
			get { return Settings.Registration.IsSecurityQuestionVisible; }
		}

		public override bool IsSecurityQuestionRequired
		{
			get { return Settings.Registration.IsSecurityQuestionRequired; }
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
			get { return Settings.Registration.IsPersonalIDVisible; }
		}

        public override bool IsRegionIDVisible
        {
            get { return Settings.Registration.IsRegionIDVisible; }
        }

        public override bool IsRegionIDRequired
        {
            get { return Settings.Registration.IsRegionIDRequired; }
        }

        public override bool IsPassportVisible
        {
            get { return Settings.Registration.IsPassportVisible; }
        }

        public override bool IsPassportRequired
        {
            get { return Settings.Registration.IsPassportRequired; }
        }


        public ProfileInputRegisterSettings() : base() { }

		public ProfileInputRegisterSettings(Dictionary<string, string> initialValues)
			: base(initialValues) { }
	}
}
