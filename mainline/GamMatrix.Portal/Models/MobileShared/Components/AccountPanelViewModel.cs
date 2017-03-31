using CM.Sites;
using CM.State;
using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class AccountPanelViewModel : RemoteableView
	{
		public string GetBalanceUrl()
		{
			return string.Format("{0}/_get_balance.ashx?useCache=false&_sid={1}",
				UrlHelper.GetAbsoluteBaseUrl(), CustomProfile.Current.SessionID);
		}
	}
}
