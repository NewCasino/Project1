using System;
using System.Linq;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[RequireLogin]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "TransferSection")]
	[ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{sid}")]
	public class MobileTransferController : TransferController
	{
		public override ActionResult PrepareTransactionCompleted(PrepareTransRequest prepareTransRequest
			, Exception exception
			, string paymentMethodName
			, long debitGammingAccountID
			)
		{
			try
			{
				if (!CustomProfile.Current.IsAuthenticated)
					throw new UnauthorizedAccessException();

				try
				{
					if (exception != null)
						throw exception;

					cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
						, "PrepareTransRequest"
						, prepareTransRequest
						);

					string url = this.Url.Action("Confirmation", new { sid = prepareTransRequest.Record.Sid });
					return this.Redirect(url);
				}
				catch (GmException gex)
				{
					// Withdrawals from $ACCOUNT_NAME$ are not allowed while you have an active bonus. 
					// In order to make a transfer or withdrawal from your $ACCOUNT_NAME$ account, 
					// the remaining bonus wagering requirements must be met.
					if (string.Equals(gex.ReplyResponse.ErrorCode, "SYS_1114", StringComparison.InvariantCulture))
					{
						string message = Metadata.Get("/Metadata/GmCoreErrorCodes/SYS_1114.UserMessage");
						var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.ID == debitGammingAccountID);
						if (account != null)
						{
							string accountName = Metadata.Get(string.Format("/Metadata/GammingAccount/{0}.Display_Name", account.Record.VendorID));
							message = message.Replace("$ACCOUNT_NAME$", accountName);

							ViewData["ErrorMessage"] = message;
							return this.Redirect(this.Url.Action("Error"));
						}
					}
					throw;
				}
			}
			catch (Exception ex)
			{
				Logger.Exception(ex);

				ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
				return View("Error");
			}
		}
	}
}
