using System;
using System.Text;
using GamMatrixAPI;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class BonusSelectorViewModel
	{
		public TransType TransferType = TransType.Deposit;
		private const string BonusUrl = "/_get_bonus_info.ashx";


		public string GetBonusUrl()
		{
			var url = new StringBuilder(BonusUrl)
				.Append("?TransType=")
				.Append(Enum.GetName(typeof(TransType), TransferType));

			return url.ToString();
		}
	}
}
