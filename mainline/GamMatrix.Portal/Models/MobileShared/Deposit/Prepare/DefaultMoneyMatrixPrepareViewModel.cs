using System.Collections.Generic;
using System.Linq;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class DefaultMoneyMatrixPrepareViewModel : PayCardTransaction
    {
        public string PaymentSolutionName { get; set; }
        
        public DefaultMoneyMatrixPrepareViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars) {}

        public DefaultMoneyMatrixPrepareViewModel(PaymentMethod paymentMethod, string paymentSolutionName, Dictionary<string, string> stateVars)
            : this(paymentMethod, stateVars)
        {
            this.PaymentSolutionName = paymentSolutionName;
        }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            if (string.IsNullOrEmpty(this.PaymentSolutionName))
            {
                return GamMatrixClient.GetMoneyMatrixPayCards();
            }

            return GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy(this.PaymentSolutionName);
        }
    }
}
