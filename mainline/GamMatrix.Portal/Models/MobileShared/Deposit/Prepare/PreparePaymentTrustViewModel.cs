using System;
using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
	public class PreparePaymentTrustViewModel : PayCardTransaction
	{
		public bool ShowExtraFields { get; private set; }

		public PreparePaymentTrustViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
			: base(paymentMethod, stateVars)  
		{
			ShowExtraFields = 
                string.Equals(PaymentMethod.UniqueName, "PT_Switch", StringComparison.OrdinalIgnoreCase) 
				|| string.Equals(PaymentMethod.UniqueName, "PT_Maestro", StringComparison.OrdinalIgnoreCase);
		}

		protected override IEnumerable<GamMatrixAPI.PayCardInfoRec> RetrievePayCards()
		{
			return GamMatrixClient.GetPayCards(VendorID.PaymentTrust)
				.Where(p => !p.IsDummy);
		}
	}
}
