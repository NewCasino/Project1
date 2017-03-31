using System;
using System.Collections.Generic;
using GamMatrixAPI;

namespace GamMatrix.CMS.Domain.AccountStatement.Statements
{
	public class TransferStatement : TransactionStatement
	{
		protected override TransSelectParams GetFilterParams(DateTime fromDate, DateTime toDate)
		{
			TransSelectParams transSelectParams = InitFilterParams(
				new List<TransType> { TransType.Transfer }
				, new List<TransStatus> 
				{ 
					TransStatus.Success,
					TransStatus.Failed,
					TransStatus.Pending,
				}
				, fromDate
				, toDate);

			return transSelectParams;
		}
	}
}
