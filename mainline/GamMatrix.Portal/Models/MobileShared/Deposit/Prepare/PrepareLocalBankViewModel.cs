using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareLocalBankViewModel : PayCardTransaction//: SinglePayCardTransaction
    {
        public PrepareLocalBankViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars) 
        {
            PayCard = PayCards.FirstOrDefault();
        }

        public PayCardInfoRec PayCard { get; private set; }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.LocalBank)
                .OrderByDescending(e => e.LastSuccessDepositDate);
        }

        public VendorID VendorID = VendorID.LocalBank;
    }
}
