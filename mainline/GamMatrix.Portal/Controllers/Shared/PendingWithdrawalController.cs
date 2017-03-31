using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl="{sid}")]
    public class PendingWithdrawalController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            List<TransInfoRec> transactions = GetTransactions();
            if( transactions.Count > 0 )
                return View("Index", transactions);

            return View("NoPendingWithdrawal");
        }

        private List<TransInfoRec> GetTransactions()
        {
            TransSelectParams transSelectParams = new TransSelectParams()
            {
                ByTransTypes = true,
                ParamTransTypes = new List<TransType> { TransType.Withdraw },
                ByUserID = true,
                ParamUserID = CustomProfile.Current.UserID,
                ByTransStatuses = true,
                ParamTransStatuses = new List<TransStatus>
                {
                    TransStatus.Pending,
                }
            };

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                GetTransRequest getTransRequest = client.SingleRequest<GetTransRequest>(new GetTransRequest()
                {
                    SelectionCriteria = transSelectParams,
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
                    return getTransRequest.PagedData.Records
                        .ToList();
                }
            }

            return new List<TransInfoRec>();
        }// GetTransactions

        /// <summary>
        /// Rollback withdraw request
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        public ActionResult Rollback(string sid)
        {
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    GetTransInfoRequest getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });

                    bool isAllowed = false;
                    if (getTransInfoRequest.TransData.TransStatus == TransStatus.Pending && getTransInfoRequest.TransData.TransType == TransType.Withdraw)
                    {
                        if (Settings.PendingWithdrawal_EnableApprovement)
                            isAllowed = !getTransInfoRequest.TransData.ApprovalStatus;
                        else
                            isAllowed = true;/*getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PaymentTrust
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PayPoint
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Envoy
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Bank
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PaymentTrust
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PayPoint
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Envoy
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Bank;*/
                    }

                    if (!isAllowed)
                    {
                        throw new InvalidOperationException();
                    }

                    if (getTransInfoRequest.TransData.TransStatus == TransStatus.Pending)
                    {
                        
                        DivertTransRequest divertTransRequest = client.SingleRequest<DivertTransRequest>(new DivertTransRequest()
                        {
                            SID = sid,
                            DivertAccountID = getTransInfoRequest.TransData.DebitAccountID
                        });
                    }

                    if (getTransInfoRequest.TransData.TransStatus == TransStatus.Pending ||
                        getTransInfoRequest.TransData.TransStatus == TransStatus.RollBack)
                    {
                        return View("Receipt", getTransInfoRequest);
                    }
                    throw new InvalidOperationException();
                }                
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }
    }
}
