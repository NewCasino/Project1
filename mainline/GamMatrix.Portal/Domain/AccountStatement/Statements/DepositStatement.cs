using System;
using System.Collections.Generic;
using System.Linq;
using GamMatrixAPI;

namespace GamMatrix.CMS.Domain.AccountStatement.Statements
{
	public class DepositStatement : TransactionStatement
	{
		protected override TransSelectParams GetFilterParams(DateTime fromDate, DateTime toDate)
		{
			TransSelectParams transSelectParams = InitFilterParams(
				new List<TransType> { TransType.Deposit, TransType.Vendor2User },
				new List<TransStatus> { TransStatus.Success },
				fromDate,
				toDate
				);

			transSelectParams.ByDebitPayableTypes = true;
			transSelectParams.ParamDebitPayableTypes = Enum.GetNames(typeof(PayableType))
				.Select(t => (PayableType)Enum.Parse(typeof(PayableType), t))
				.Where(t => t != PayableType.AffiliateFee && t != PayableType.CasinoFPP)
				.ToList();

			return transSelectParams;
		}
	}
}
