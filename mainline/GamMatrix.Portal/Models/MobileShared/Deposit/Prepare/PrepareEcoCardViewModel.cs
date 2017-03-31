using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareEcoCardViewModel : SinglePayCardTransaction
    {
        public PrepareEcoCardViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars) { }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetPayCards(VendorID.EcoCard)
                .OrderByDescending(e => e.LastSuccessDepositDate);
        }
    }
}
