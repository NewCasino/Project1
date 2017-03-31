using System.Collections.Generic;
using GamMatrix.CMS.Models.Common.Components.ProfileInput;

namespace GamMatrix.CMS.Models.PlayHippoMobile.QuickRegister
{
	public class SecondaryInputSettings : ProfileInputQuickRegisterSettings
	{
		public SecondaryInputSettings(object initialValues)
			: base((Dictionary<string, string>) initialValues) {  }

		public override bool IsUsernameVisible
		{
			get
			{
				return false;
			}
		}

		public override bool IsPasswordVisible
		{
			get
			{
				return false;
			}
		}

		public override bool IsEmailVisible
		{
			get
			{
				return false;
			}
		}

		public override bool IsPersonalIDVisible
		{
			get
			{
				return false;
			}
		}
	}
}
