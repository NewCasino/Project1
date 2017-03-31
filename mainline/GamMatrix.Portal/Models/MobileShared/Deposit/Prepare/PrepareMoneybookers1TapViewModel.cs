using System.Collections.Generic;
using System.Linq;
using CM.State;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
	/// <summary>
	/// Note: The Moneybookers 1-Tap payment method has been renamed to Skrill 1-Tap
	/// </summary>
	public class PrepareMoneybookers1TapViewModel : SinglePayCardTransaction
	{
		public bool IsFirstTransaction { get; private set; }

		public PrepareMoneybookers1TapViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
			: base(paymentMethod, stateVars)
		{
			GetTransRequest request = new GetTransRequest()
			{
				SelectionCriteria = new TransSelectParams()
				{
					ByPaymentTypeFromPreTrans = true,
					PaymentTypeFromPreTrans = "Skrill1TapSetup",
					ByTransTypes = true,
					ParamTransTypes = new List<TransType> { TransType.Deposit },
					ByUserID = true,
					ParamUserID = CustomProfile.Current.UserID,
					ByTransStatuses = true,
					ParamTransStatuses = new List<TransStatus> { TransStatus.Success },
					ByDebitPayableTypes = true,
					ParamDebitPayableTypes = new List<PayableType> { PayableType.Ordinary },
					ByDebitPayItemVendorID = true,
					ParamDebitPayItemVendorID = VendorID.Moneybookers,
				},
				PagedData = new PagedDataOfTransInfoRec
				{
					PageSize = 1,
					PageNumber = 0,
				}
			};
			using (GamMatrixClient client = new GamMatrixClient())
			{
				List<TransInfoRec> records = client.SingleRequest<GetTransRequest>(request).PagedData.Records;
				IsFirstTransaction = records == null || records.Count == 0;
			}
		}

		protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
		{
			return GamMatrixClient.GetPayCards(VendorID.Moneybookers)
				.OrderByDescending(e => e.LastSuccessDepositDate);
		}
	}
}
