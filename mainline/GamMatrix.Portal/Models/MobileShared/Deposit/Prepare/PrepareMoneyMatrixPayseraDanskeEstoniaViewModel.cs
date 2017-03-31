using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareMoneyMatrixPayseraDanskeEstoniaViewModel : PayCardTransaction
    {
        public PayCardInfoRec ExistingPayCard { get; protected set; }

        public PrepareMoneyMatrixPayseraDanskeEstoniaViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars)
        {
            ExistingPayCard = PayCards.FirstOrDefault();
        }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetPayCards(VendorID.MoneyMatrix)
                .Where(c => c.IsDummy)
                .OrderByDescending(c => c.Ins);
        }
    }
}