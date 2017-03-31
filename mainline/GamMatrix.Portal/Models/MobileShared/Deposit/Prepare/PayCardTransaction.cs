using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrix.CMS.Models.MobileShared.Components;
using GamMatrixAPI;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
	public abstract class PayCardTransaction : TransactionInfo
	{
		public IEnumerable<PayCardInfoRec> PayCards { get; private set; }

		public PayCardTransaction(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
			: base(paymentMethod, stateVars) 
		{
			PayCards = RetrievePayCards();
		}

		protected abstract IEnumerable<PayCardInfoRec> RetrievePayCards();

		public bool HasPayCards()
		{
			return PayCards.Count() > 0;
		}
	}
}
