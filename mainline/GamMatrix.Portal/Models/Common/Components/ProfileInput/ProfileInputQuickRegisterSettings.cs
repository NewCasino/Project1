using System.Collections.Generic;

namespace GamMatrix.CMS.Models.Common.Components.ProfileInput
{
	public class ProfileInputQuickRegisterSettings : ProfileInputRegisterSettings
	{
		public override bool IsTitleVisible
		{
			get { return Settings.QuickRegistration.IsTitleVisible; }
		}

		public override bool IsFirstnameVisible
		{
			get { return Settings.QuickRegistration.IsFirstnameVisible; }
		}

		public override bool IsSurnameVisible
		{
			get { return Settings.QuickRegistration.IsSurnameVisible; }
		}

		public override bool IsBirthDateVisible
		{
			get { return Settings.QuickRegistration.IsBirthDateVisible; }
		}

		public override bool IsCountryVisible
		{
			get { return Settings.QuickRegistration.IsCountryVisible; }
		}

		public override bool IsAddress1Visible
		{
			get { return Settings.QuickRegistration.IsAddress1Visible; }
		}

		public override bool IsAddress2Visible
		{
			get { return false; }
		}

		public override bool IsCityVisible
		{
			get { return Settings.QuickRegistration.IsCityVisible; }
		}

		public override bool IsPostalCodeVisible
		{
			get { return Settings.QuickRegistration.IsPostalCodeVisible; }
		}

		public override bool IsMobileVisible
		{
			get { return Settings.QuickRegistration.IsMobileVisible; }
		}

        //public override bool IsCurrencyVisible
        //{
        //    get { return Settings.QuickRegistration.IsCurrencyVisible; }
        //}

		public override bool IsUsernameVisible
		{
			get { return Settings.QuickRegistration.IsUserNameVisible; }
		}

		public override bool IsSecurityQuestionVisible
		{
			get { return Settings.QuickRegistration.IsSecurityQuestionVisible; }
		}

		public override bool IsLanguageVisible
		{
			get { return Settings.QuickRegistration.IsLanguageVisible; }
		}

		public override bool IsAllowNewsEmailVisible
		{
			get
			{
				return Settings.QuickRegistration.IsAllowNewsEmailVisible;
			}
		}

		public override bool IsAllowSmsOffersVisible
		{
			get
			{
				return Settings.QuickRegistration.IsAllowSmsOfferVisible;
			}
		}

		public override bool IsTermsConditionsVisible
		{
			get { return Settings.QuickRegistration.IsTermsConditionsVisible; }
		}

		public override bool IsPersonalIDVisible
		{
			get { return Settings.QuickRegistration.IsPersonalIDVisible; }
		}



		public ProfileInputQuickRegisterSettings() : base() { }

		public ProfileInputQuickRegisterSettings(Dictionary<string, string> initialValues)
			: base(initialValues) { }
	}
}
