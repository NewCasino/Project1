using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareMoneyMatrixTLNakitViewModel : PayCardTransaction
    {
        public PayCardInfoRec ExistingPayCard { get; protected set; }

        public PrepareMoneyMatrixTLNakitViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars)
        {
            this.ExistingPayCard = PayCards.FirstOrDefault();
        }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy("TlNakit");
        }
    }
}