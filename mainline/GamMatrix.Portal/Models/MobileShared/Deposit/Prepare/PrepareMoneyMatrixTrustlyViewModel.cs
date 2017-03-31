using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareMoneyMatrixTrustlyViewModel : PayCardTransaction
    {
        public PayCardInfoRec ExistingPayCard { get; protected set; }

        public PrepareMoneyMatrixTrustlyViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars)
        {
            ExistingPayCard = PayCards.FirstOrDefault();
        }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy("Trustly");
        }
    }
}