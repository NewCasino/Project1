using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using CM.Content;
using CM.State;
using Finance;
using GamMatrix.CMS.Models.Common.Base;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class GamingAccountSelectorViewModel : MultiuseView
	{
		public bool EnableBonus = true;
		public string SelectorLabel = string.Empty;
        public bool EnableDisplayAmount = false; 
        private int _userId = CustomProfile.Current.UserID;
        public int UserId
        {
            get
            {
                return _userId ;  
            }
            set{
                _userId = value ;            
            }
        }

        private List<AccountData> _accounts;
        public List<AccountData> Accounts
        {
            private set { }
            get
            {
                if (_accounts == null)
                {
                    _accounts = GetDebitAccounts(this.UserId);
                }
                return _accounts;
            }
        }

        public List<AccountData> GetDebitAccounts(int userId)
        {
            return GetAccounts(userId);
        }

        private List<AccountData> GetAccounts(int userId)
        {
            List<AccountData> allAccounts = GamMatrixClient.GetUserGammingAccounts(userId, false);
            List<AccountData> vendorAccounts = new List<AccountData>();

            string[] paths = Metadata.GetChildrenPaths("/Metadata/GammingAccount/");
            for (var i = paths.Length - 1; i >= 0; i--)
            {
                string name = Path.GetFileName(paths[i]);

                VendorID vendorId;
                if (Enum.TryParse<VendorID>(name, out vendorId))
                {
                    AccountData account = allAccounts.FirstOrDefault(a => a.Record.VendorID == vendorId);
                    if (account != null)
                        vendorAccounts.Insert(0, account);
                }
            }
            return vendorAccounts
                .Where(a => a.Record.ActiveStatus == ActiveStatus.Active && a.IsBalanceAvailable)
                .ToList();
        }

        public GamingAccountSelectorViewModel() { }

        public string GetDebitAccountDetailsJson(AccountData account)
        {
            return string.Format(CultureInfo.InvariantCulture, "{{\"ID\":\"{0}\",\"Currency\":\"{1}\",\"Amount\":{2:F2},\"Bonus\":{3:F2},\"FormattedAmount\":\"{4}\"}}"
                , account.Record.ID
                , account.Record.Currency.SafeJavascriptStringEncode()
                , "0"
                , "0"
                , "0"
                );
        }
		public string GetAccountDetailsJson(AccountData account)
		{
			return string.Format(CultureInfo.InvariantCulture, "{{\"ID\":\"{0}\",\"Currency\":\"{1}\",\"Amount\":{2:F2},\"Bonus\":{3:F2},\"FormattedAmount\":\"{4}\"}}"
				, account.Record.ID
				, account.Record.Currency.SafeJavascriptStringEncode()
				, Math.Truncate(account.BalanceAmount * 100.00M) / 100.00M
				, account.BonusAmount
				, account.FormatBalanceAmount()
				);
		}

		public string GetBonusDetailsJson(AccountData account)
		{
			if (!EnableBonus)
				return String.Empty;

			VendorID vendor = account.Record.VendorID;
			return string.Format(CultureInfo.InvariantCulture, "{{\"inputBonus\":{{\"enabled\":{1}}}, \"selectBonus\":{{\"enabled\":{2}, \"config\":\"{3}\"}}}}",
				(Settings.IsBonusCodeInputEnabled(vendor) || Settings.IsBonusSelectorEnabled(vendor)).ToString().ToLower(),
				Settings.IsBonusCodeInputEnabled(vendor).ToString().ToLower(),
				Settings.IsBonusSelectorEnabled(vendor).ToString().ToLower(),
				account.Record.ID
			);
		}

		public List<string> GetAccountNames()
		{
			return Accounts.Select(a => a.Record.VendorID.GetDisplayName()).ToList();
		}

		public List<Dictionary<string, string>> GetAccountData()
		{
			return Accounts
				.Select(a => new Dictionary<string, string>
				{
					{ "account", GetAccountDetailsJson(a) },
					{ "bonus", GetBonusDetailsJson(a) }
				})
				.ToList();
		}
	}
}
