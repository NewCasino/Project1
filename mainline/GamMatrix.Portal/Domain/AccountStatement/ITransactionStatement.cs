using System;
using System.Collections.Generic;
using GamMatrixAPI;

namespace GamMatrix.CMS.Domain.AccountStatement
{
	public interface ITransactionStatement
	{
		List<TransInfoRec> GetTransactions(DateTime fromDate, DateTime toDate);
	}
}
