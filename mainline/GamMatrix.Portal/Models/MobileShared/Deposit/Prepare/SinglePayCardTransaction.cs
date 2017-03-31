using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using Finance;
using GamMatrixAPI;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
	public abstract class SinglePayCardTransaction : PayCardTransaction
	{
		public PayCardInfoRec PayCard { get; private set; }

		public SinglePayCardTransaction(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
			: base(paymentMethod, stateVars) 
		{
			if (!HasPayCards())
				throw new ConfigurationErrorsException("This payment method is not configured correctly.");

			PayCard = PayCards.FirstOrDefault();
		}
	}
}
