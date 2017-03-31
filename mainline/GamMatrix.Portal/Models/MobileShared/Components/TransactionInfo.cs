using System.Collections.Generic;
using Finance;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class TransactionInfo
	{
		public PaymentMethod PaymentMethod { get; private set; }
		public Dictionary<string, string> StateVars { get; private set; }

		public TransactionInfo(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
		{
			PaymentMethod = paymentMethod;
			StateVars = stateVars;
		}
	}
}
