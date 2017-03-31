using System;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class SettingsNavigatorViewModel
	{
		public enum Sections { SelfExclusion, DepositLimit, OtherSettings }

		public Sections CurrentTab = Sections.OtherSettings;

        public bool HideSubHeading { get; set; }

		public string HasActive(Sections tab, string property)
		{
			return tab == CurrentTab ? property : string.Empty;
		}

		public string GetActiveTabId()
		{
			return Enum.GetName(typeof(Sections), CurrentTab);
		}
	}
}
