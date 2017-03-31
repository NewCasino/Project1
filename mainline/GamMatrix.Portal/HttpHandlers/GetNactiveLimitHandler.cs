using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Script.Serialization;
using CM.Content;
using CM.Sites;
using CM.State;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.HttpHandlers
{
    /// <summary>
    /// Summary description for GetNactiveLimitHandler
    /// </summary>
    public class GetNactiveLimitHandler : IHttpAsyncHandler
    {
        public IAsyncResult BeginProcessRequest(HttpContext context, AsyncCallback cb, Object extraData)
        {
            try
            {

                bool separateBonus = false;
                if (!string.IsNullOrWhiteSpace(context.Request["separateBonus"]))
                    bool.TryParse(context.Request["separateBonus"], out separateBonus);

                CustomProfile.Current.Init(context);
                bool useCache = !string.Equals(context.Request.QueryString["useCache"], "false", StringComparison.InvariantCultureIgnoreCase);
                GetBalanceOperation async = new GetBalanceOperation(cb, context, extraData, useCache, separateBonus);
                return async;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return null;
            }
        }

        public void EndProcessRequest(IAsyncResult result)
        {
            try
            {
                GetBalanceOperation async = result as GetBalanceOperation;
                HttpContext.Current = async.Context;

                JavaScriptSerializer jss = new JavaScriptSerializer();
                string script;
                /*if (async.Accounts == null)
                {*/
                    script = jss.Serialize(new
                    {
                        @success = false,
                        @isLoggedIn = async.IsLoggedIn,
                        @error = string.Empty,
                    });
                /*}
                else
                {
                    var separateBonus = async.SeparateBonus;

                    var account = async.Accounts.Where(a => a.Record.ActiveStatus == GamMatrixAPI.ActiveStatus.Active && a.Record.VendorID == VendorID.CasinoWallet)
                            .Select(a => new
                            {
                                ID = a.Record.ID,
                                IsBalanceAvailable = a.IsBalanceAvailable,
                                VendorID = a.Record.VendorID.ToString(),
                                DisplayName = a.Record.VendorID.GetDisplayName(),
                                EnglishName = a.Record.CmsDisplayName,
                                BalanceCurrency = a.BalanceCurrency,
                                BalanceCurrencySymbol = Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", a.BalanceCurrency)).DefaultIfNullOrEmpty(a.BalanceCurrency),
                                BalanceAmount = Math.Truncate(a.BalanceAmount * 100.00M) / 100.00M,
                                BonusAmount = a.BonusAmount,
                                OMBonusAmount = a.OMBonusAmount,
                                BetConstructBonusAmount = a.BetConstructBonusAmount,
                                FormattedAmount = a.FormatBalanceAmount(!separateBonus)
                            }).FirstOrDefault();

                    NegativeBalanceLimitRec negativelimitrecord = null;

                    if (account != null && account.BalanceAmount <= 0.00M)
                    {
                        using (GamMatrixClient client = GamMatrixClient.Get())
                        {
                            NegativeBalanceLimitRequest negativeBalanceLimitRequest = new NegativeBalanceLimitRequest()
                            {
                                UserID = CustomProfile.Current.UserID,
                                ContextDomainID = SiteManager.Current.DomainID
                            };

                            negativeBalanceLimitRequest = client.SingleRequest<NegativeBalanceLimitRequest>(negativeBalanceLimitRequest);
                            if (negativeBalanceLimitRequest != null)
                            {
                                negativelimitrecord = negativeBalanceLimitRequest.Record;
                            }
                        }


                    }

                    script = jss.Serialize(new
                    {
                        @success = true,
                        @isLoggedIn = true,
                        @account = account,
                        @negativelimitrecord = (negativelimitrecord == null ? null : new { @State = negativelimitrecord.State, @CreditLimitAmount = negativelimitrecord.CreditLimitAmount, @Currency = negativelimitrecord.Currency })
                    });
                }*/

                async.Context.Response.ContentType = "application/json";
                async.Context.Response.AddHeader("Access-Control-Allow-Origin", "*");
                string jsonCallback = async.Context.Request.QueryString["jsoncallback"];
                if (!string.IsNullOrEmpty(jsonCallback))
                    script = string.Format("{0}({1});", jsonCallback, script);

                async.Context.Response.Write(script);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public void ProcessRequest(HttpContext context)
        {
            throw new InvalidOperationException();
        }


        public bool IsReusable
        {
            get
            {
                return false;
            }
        }


        internal sealed class GetBalanceOperation : IAsyncResult
        {
            private bool _completed;
            private Object _userState;
            private AsyncCallback Callback { get; set; }
            public HttpContext Context { get; set; }
            public bool IsLoggedIn { get; private set; }
            public List<AccountData> Accounts { get; private set; }
            public bool SeparateBonus { get; set; }
            bool IAsyncResult.IsCompleted { get { return _completed; } }
            WaitHandle IAsyncResult.AsyncWaitHandle { get { return null; } }
            Object IAsyncResult.AsyncState { get { return _userState; } }
            bool IAsyncResult.CompletedSynchronously { get { return false; } }

            public GetBalanceOperation(AsyncCallback callback, HttpContext context, Object state, bool useCache, bool separateBonus)
            {
                Callback = callback;
                Context = context;
                SeparateBonus = separateBonus;
                _userState = state;
                _completed = false;
                IsLoggedIn = CustomProfile.Current.IsAuthenticated;

                if (CustomProfile.Current.IsAuthenticated)
                    GamMatrixClient.GetUserGammingAccountsAsync(CustomProfile.Current.UserID, this.OnGetGammingAccounts, useCache);
                else
                {
                    Callback(this);
                }
            }

            private void OnGetGammingAccounts(List<AccountData> accounts)
            {
                this.Accounts = accounts;
                _completed = true;
                Callback(this);
            }
        }
    }
}
