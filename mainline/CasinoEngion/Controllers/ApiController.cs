using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web.Helpers;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.Integration.TransferMoneyBetweenWallets;
using CE.Integration.TransferMoneyBetweenWallets.Models;
using CE.Integration.VendorApi.Models;
using CE.Utils;
using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public class ApiController : ServiceControllerBase
    {
        private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );


        // POST: /Api/TransferMoney
        [HttpPost]
        public JsonResult TransferMoney(CashTransporterRequest request)
        {            
            CashTransporterResponse response = new CashTransporterResponse();
             if (string.IsNullOrWhiteSpace(request.Sid) || string.IsNullOrEmpty(request.VendorName) ||
                request.DomainId == 0)
            {
                response.Success = false;
                response.ErrorMessage = string.Format("Parameter requied. Received parameters: Sid: {0}, DomainId: {1}, VendorName: {2}, Language: {3}",
                        request.Sid, request.DomainId, request.VendorName, request.Language);

                return Json(response, JsonRequestBehavior.AllowGet);
            }

            SessionPayload session = _agentClient.GetSessionByGuid(request.Sid);
            try
            {
                if (session != null && session.IsAuthenticated == true && session.DomainID == request.DomainId)
                {
                    VendorID vendor = (VendorID) Enum.Parse(typeof (VendorID), request.VendorName, true);

                    CashTransporter cashTransporter = new CashTransporter(session, request.DomainId, vendor);

                    string language = VendorLanguageSelector.GetLanguage(vendor, request.Language);
                    cashTransporter.TransferMoney(language);
                    response.Success = true;
                }
                else
                {
                    response.ErrorMessage = "Session expired";
                }
            }
            catch (Exception ex)
            {
                response.ErrorMessage = ex.Message;
            }


            return Json(response, JsonRequestBehavior.AllowGet);
        }     

        // GET: /Api/GetFrequentPlayerPoints

        [HttpGet]
        public ActionResult GetFrequentPlayerPoints(string apiUsername, string apiPassword, string _sid)
        {
            try 
            {
                if (string.IsNullOrWhiteSpace(apiUsername))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "OperatorKey cannot be empty!");

                if (string.IsNullOrWhiteSpace(apiPassword))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "API password cannot be empty!");

                if (string.IsNullOrWhiteSpace(_sid))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Session ID cannot be empty!");

                var domains = DomainManager.GetApiUsername_DomainDictionary();
                ceDomainConfigEx domain;
                if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Invalid OperatorKey!");

                if( !string.Equals( domain.ApiPassword, apiPassword.MD5Hash(), StringComparison.InvariantCulture) )
                    return WrapResponse(ResultCode.Error_InvalidParameter, "API password is incorrect!");

                if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                    return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

                SessionPayload sessionPayload = _agentClient.GetSessionByGuid(_sid);

                if (sessionPayload == null || sessionPayload.IsAuthenticated != true )
                    return WrapResponse(ResultCode.Error_InvalidSession, "Session ID is not available!");


                ////////////////////////////////////////////////////////////////////////
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    CasinoFPPGetClaimDetailsRequest request = new CasinoFPPGetClaimDetailsRequest()
                    {
                        UserID = sessionPayload.UserID,
                    };

                    request = client.SingleRequest<CasinoFPPGetClaimDetailsRequest>(sessionPayload.DomainID, request);

                    StringBuilder data = new StringBuilder();
                    data.AppendLine("<getFrequentPlayerPoints>");

                    if (request != null && request.ClaimRec != null)
                    {
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<points>{0:f2}</points>\n", Math.Truncate( request.ClaimRec.Points * 100 ) / 100.00M );
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionMinClaimPoints>{0:f0}</convertionMinClaimPoints>\n", request.ClaimRec.CfgConvertionMinClaimPoints);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionPoints>{0}</convertionPoints>\n", request.ClaimRec.CfgConvertionPoints);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionCurrency>{0}</convertionCurrency>\n", request.ClaimRec.CfgConvertionCurrency.SafeHtmlEncode());
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionAmount>{0}</convertionAmount>\n", request.ClaimRec.CfgConvertionAmount);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionType>{0}</convertionType>\n", request.ClaimRec.CfgConvertionType);
                    }
                    data.AppendLine("</getFrequentPlayerPoints>");
                    return WrapResponse(ResultCode.Success, null, data);
                }
            
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        [HttpGet]
        public ActionResult ClaimFrequentPlayerPoints(string apiUsername, string apiPassword, string _sid)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(apiUsername))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "OperatorKey cannot be empty!");

                if (string.IsNullOrWhiteSpace(apiPassword))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "API password cannot be empty!");

                if (string.IsNullOrWhiteSpace(_sid))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Session ID cannot be empty!");

                var domains = DomainManager.GetApiUsername_DomainDictionary();
                ceDomainConfigEx domain;
                if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Invalid OperatorKey!");

                if (!string.Equals(domain.ApiPassword, apiPassword.MD5Hash(), StringComparison.InvariantCulture))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "API password is incorrect!");

                if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                    return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

                SessionPayload sessionPayload = _agentClient.GetSessionByGuid(_sid);

                if (sessionPayload == null || sessionPayload.IsAuthenticated != true )
                    return WrapResponse(ResultCode.Error_InvalidSession, "Session ID is not available!");


                ////////////////////////////////////////////////////////////////////////
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    CasinoFPPClaimRequest request = new CasinoFPPClaimRequest()
                    {
                        ClaimedByUserID = sessionPayload.UserID,
                        UserID = sessionPayload.UserID,
                    };
                    request = client.SingleRequest<CasinoFPPClaimRequest>(sessionPayload.DomainID, request);

                    StringBuilder data = new StringBuilder();
                    data.AppendLine("<claimFrequentPlayerPoints>");
                    if (request.ClaimRec != null)
                    {
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionMinClaimPoints>{0:f0}</convertionMinClaimPoints>\n", request.ClaimRec.CfgConvertionMinClaimPoints);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionPoints>{0}</convertionPoints>\n", request.ClaimRec.CfgConvertionPoints);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionCurrency>{0}</convertionCurrency>\n", request.ClaimRec.CfgConvertionCurrency.SafeHtmlEncode());
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionAmount>{0}</convertionAmount>\n", request.ClaimRec.CfgConvertionAmount);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<convertionType>{0}</convertionType>\n", request.ClaimRec.CfgConvertionType);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<converted>{0:f0}</converted>\n", request.ClaimRec.Converted);
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<remainder>{0:f2}</remainder>\n", Math.Truncate( request.ClaimRec.Remainder * 100 ) / 100.00M );
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<rewardCurrency>{0}</rewardCurrency>\n", request.ClaimRec.RewardCurrency.SafeHtmlEncode());
                        data.AppendFormat(CultureInfo.InvariantCulture, "\t<rewardAmount>{0}</rewardAmount>\n", request.ClaimRec.RewardAmount);
                    }
                    data.AppendLine("</claimFrequentPlayerPoints>");
                    return WrapResponse(ResultCode.Success, null, data);
                }

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

    }
}
