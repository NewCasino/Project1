using System;
using System.Collections.Generic;
using CM.State;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Domain.AccountStatement.Statements
{
	public abstract class TransactionStatement : ITransactionStatement
	{
		public List<TransInfoRec> GetTransactions(DateTime fromDate, DateTime toDate)
		{
			return GetFilteredTransactions(GetFilterParams(fromDate, toDate));
		}

		protected abstract TransSelectParams GetFilterParams(DateTime fromDate, DateTime toDate);

		protected TransSelectParams InitFilterParams(List<TransType> transTypes
			, List<TransStatus> transStatuses
			, DateTime fromDate
			, DateTime toDate
			)
		{
			var filterParams = new TransSelectParams
			{
				ByUserID = true,
				ParamUserID = CustomProfile.Current.UserID,
				ByTransTypes = true,
				ParamTransTypes = transTypes,
				ByTransStatuses = true,
				ParamTransStatuses = transStatuses,
				ByCompleted = true,
				ParamCompletedFrom = fromDate,
				ParamCompletedTo = toDate
			};

			return filterParams;
		}

		protected virtual List<TransInfoRec> GetFilteredTransactions(TransSelectParams parameters)
		{
			if (parameters.ParamCompletedTo < parameters.ParamCompletedFrom)
				return new List<TransInfoRec>();

			using (GamMatrixClient client = GamMatrixClient.Get())
			{
				GetTransRequest getTransRequest = client.SingleRequest<GetTransRequest>(new GetTransRequest()
				{
					SelectionCriteria = parameters,
					PagedData = new PagedDataOfTransInfoRec
					{
						PageSize = int.MaxValue,
						PageNumber = 0,
					}
				});

				if (getTransRequest != null &&
					getTransRequest.PagedData != null &&
					getTransRequest.PagedData.Records != null &&
					getTransRequest.PagedData.Records.Count > 0)
				{
					return getTransRequest.PagedData.Records;
				}
			}

			return new List<TransInfoRec>();
		}
	}
}
