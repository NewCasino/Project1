﻿using System.Collections.Generic;
using System.Linq;
using Finance;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
	public class PrepareMoneybookersViewModel : SinglePayCardTransaction
	{
		public PrepareMoneybookersViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
			: base(paymentMethod, stateVars)  { }

		protected override IEnumerable<GamMatrixAPI.PayCardInfoRec> RetrievePayCards()
		{
			return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Moneybookers)
				.OrderByDescending(p => p.LastSuccessDepositDate);
		}
	}
}
