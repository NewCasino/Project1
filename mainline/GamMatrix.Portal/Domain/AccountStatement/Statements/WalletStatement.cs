using System;
using System.Collections.Generic;
using System.Linq;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Domain.AccountStatement.Statements
{
	public class WalletStatement : TransactionStatement
	{
		private VendorID WalletID { get; set; }

		public WalletStatement(VendorID walletId)
		{
			WalletID = walletId;
		}

		protected override TransSelectParams GetFilterParams(DateTime fromDate, DateTime toDate)
		{
			var transSelectParams = InitFilterParams(
				new List<TransType> { TransType.WalletCredit, TransType.WalletDebit }
				, new List<TransStatus> { TransStatus.Success }
				, fromDate
				, toDate
				);

			return transSelectParams;
		}

		protected override List<TransInfoRec> GetFilteredTransactions(TransSelectParams parameters)
		{
			var records = new List<TransInfoRec>();

			using (GamMatrixClient client = GamMatrixClient.Get())
			{
				GetTransRequest getTransRequest1 = new GetTransRequest()
				{
					SelectionCriteria = parameters,
					PagedData = new PagedDataOfTransInfoRec
					{
						PageSize = int.MaxValue,
						PageNumber = 0,
					}
				};
				GetTransRequest getTransRequest2 = ObjectHelper.DeepClone<GetTransRequest>(getTransRequest1);
				getTransRequest1.SelectionCriteria.ByCreditPayItemVendorID = true;
				getTransRequest1.SelectionCriteria.ParamCreditPayItemVendorID = WalletID;
				getTransRequest2.SelectionCriteria.ByDebitPayItemVendorID = true;
				getTransRequest2.SelectionCriteria.ParamDebitPayItemVendorID = WalletID;

				List<GetTransRequest> resp = client.MultiRequest<GetTransRequest>(new List<HandlerRequest>()
				{
					getTransRequest1,
					getTransRequest2,
				});
				getTransRequest1 = resp[0];
				getTransRequest2 = resp[1];

				if (getTransRequest1.PagedData.Records != null &&
					getTransRequest2.PagedData.Records != null)
				{
					records = getTransRequest1.PagedData.Records.Union(getTransRequest2.PagedData.Records)
								.OrderByDescending(r => r.ID)
								.ToList();
				}
				else if (getTransRequest1.PagedData.Records != null)
					records = getTransRequest1.PagedData.Records;
				else if (getTransRequest2.PagedData.Records != null)
					records = getTransRequest2.PagedData.Records;
			}

			return records;
		}
	}
}
