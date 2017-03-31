using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;


namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareMoneyMatrixViewModel : PayCardTransaction
    {
        public PrepareMoneyMatrixViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars)
        {

        }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetPayCards(VendorID.MoneyMatrix)
                .Where(c => !c.IsDummy)
                .OrderByDescending(c => c.Ins);
        }
    }
}
