using System;
using System.Collections.Generic;
using GamMatrixAPI;

namespace GamMatrix.CMS.Domain.AccountStatement.Statements
{
	public class WithdrawalStatement : TransactionStatement
	{
		protected override TransSelectParams GetFilterParams(DateTime fromDate, DateTime toDate)
		{
			TransSelectParams transSelectParams = InitFilterParams(
				new List<TransType> 
				{ 
					TransType.Withdraw, 
					TransType.User2Vendor, 
					TransType.Refund 
				}
				, new List<TransStatus>
				{
					TransStatus.Success,
					TransStatus.Failed,
					TransStatus.Pending,
					TransStatus.RollBack,
					TransStatus.Cancelled,
					TransStatus.PendingNotification,
					TransStatus.Processing,
					TransStatus.CreditFailed,
					TransStatus.DebitFailed,
				}
				, fromDate
				, toDate
				);

			return transSelectParams;
		}
	}
}
