using System.Linq;
using CM.State;
using GamMatrix.CMS.Models.Common.Base;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class ForfeitBonusWarningViewModel : ViewModelBase
	{
		private VendorID VendorId;
		public bool IsEnabled { get; private set; }

		public ForfeitBonusWarningViewModel(VendorID vendorId, decimal debitAmount)
		{
			VendorId = vendorId;

			var accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, true);
			var account = accounts.FirstOrDefault(a => a.Record.VendorID == vendorId);

			IsEnabled = (account != null && account.IsBalanceAvailable && debitAmount > account.MaxWithdrawWithoutBonusLossAmount);
		}

		public string GetWarningMessage(string format)
		{
			string accountName = GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", VendorId.ToString()));
			return string.Format(format, accountName);
		}
	}
}
