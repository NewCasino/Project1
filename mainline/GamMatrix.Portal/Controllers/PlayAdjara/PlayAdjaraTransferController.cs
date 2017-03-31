using System;
using System.Web.Mvc;
using CM.db;
using CM.State;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.PlayAdjara
{
    public class PlayAdjaraTransferController : GamMatrix.CMS.Controllers.Shared.TransferController
    {
        public override ActionResult ConfirmCompleted(string sid
            , ProcessTransRequest processTransRequest
            , Exception exception
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                return this.Json(new
                {
                    @success = false,
                    @sid = sid,
                    @errorType = 0,
                });
            }

            if (exception != null)
            {
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(exception);
                return this.Json(new
                {
                    @success = false,
                    @sid = sid,
                    @errorType = 1,
                    @error = GmException.TryGetFriendlyErrorMsg(exception),
                });
            }
            cmTransParameter.SaveObject<ProcessTransRequest>(sid
                , "ProcessTransRequest"
                , processTransRequest
                );
            return this.Json(new
            {
                @success = true,
                @sid = sid,
            });
            //string url = this.Url.Action("Receipt", new { @sid = sid });
            //return this.Redirect(url);
        }
        
        [HttpGet]
        public override ActionResult Receipt(string sid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                //return View("Anonymous");
                return this.Json(new
                {
                    @success = false,
                    @errorType = 0,
                    @error = "anonymous",
                }, JsonRequestBehavior.AllowGet);
            }
            try
            {
                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
                if (processTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                GetTransInfoRequest getTransInfoRequest;
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });
                }

                this.ViewData["prepareTransRequest"] = prepareTransRequest;
                this.ViewData["processTransRequest"] = processTransRequest;
                this.ViewData["getTransInfoRequest"] = getTransInfoRequest;

                return this.Json(new 
                {
                    @success = true,
                    @transID = prepareTransRequest.TransData.Sid,
                    @debitRealCurrency = processTransRequest.Record.DebitRealCurrency,
                    @debitRealAmount = processTransRequest.Record.DebitRealAmount,
                    @creditRealCurrency = processTransRequest.Record.CreditRealCurrency,
                    @creditRealAmount = processTransRequest.Record.CreditRealAmount,
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);                

                return this.Json(new
                {
                    @success = false,
                    @errorType = 1,
                    @error = GmException.TryGetFriendlyErrorMsg(ex),
                }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public ActionResult Result()
        {
            return View("Result");
        }

        [HttpGet]
        public ActionResult Anonymous()
        {
            return View("Anonymous");
        }

        [HttpGet]
        public ActionResult Error(string id = null)
        {
            this.ViewData["ID"] = id;
            return View("Error");
        }
    }
}