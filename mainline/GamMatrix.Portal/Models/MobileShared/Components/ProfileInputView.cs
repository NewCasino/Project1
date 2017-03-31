using GamMatrix.CMS.Models.Common.Base;
using GamMatrix.CMS.Models.Common.Components.ProfileInput;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class ProfileInputView : ViewModelBase
	{
		public ProfileInputSettings InputSettings { get; private set; }

		public ProfileInputView(ProfileInputSettings inputSettings)
		{
			InputSettings = inputSettings;
		}
	}
}
