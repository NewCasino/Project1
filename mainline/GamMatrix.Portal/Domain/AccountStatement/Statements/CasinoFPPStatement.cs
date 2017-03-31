using System;
using System.Collections.Generic;
using GamMatrixAPI;

namespace GamMatrix.CMS.Domain.AccountStatement.Statements
{
	public class CasinoFPPStatement : TransactionStatement
	{
		protected override TransSelectParams GetFilterParams(DateTime fromDate, DateTime toDate)
		{
			TransSelectParams transSelectParams = InitFilterParams(
				new List<TransType> { TransType.Vendor2User },
				new List<TransStatus> { TransStatus.Success },
				fromDate,
				toDate
				);

			transSelectParams.ByDebitVendorOwnedPayItemVendorID = true;
			transSelectParams.ParamDebitVendorOwnedPayItemVendorID = VendorID.NetEnt;
			transSelectParams.ByDebitPayableTypes = true;
			transSelectParams.ParamDebitPayableTypes = new List<PayableType> { PayableType.CasinoFPP };

			return transSelectParams;
		}
	}
}
