using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Script.Serialization;
using CM.Content;
using CM.State;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.HttpHandlers
{
    
    /// <summary>
    /// Summary description for BonusHandler
    /// </summary>
    public class GetBonusInfoHandler : IHttpAsyncHandler
    {
        private HttpContext HttpContext { get; set; }
        public IAsyncResult BeginProcessRequest(HttpContext context, AsyncCallback cb, Object extraData)
        {

            this.HttpContext = context;
            CustomProfile.Current.Init(context);
            long accountID = 0L;
            if (!long.TryParse(context.Request["AccountID"], NumberStyles.Integer, CultureInfo.InvariantCulture, out accountID))
                accountID = 0L;

            TransType transType;
            if (!Enum.TryParse<TransType>(context.Request["TransType"], true, out transType))
                transType = TransType.Deposit;


            return new GetBonusInfoOperation(cb, context, CustomProfile.Current.UserID, accountID, transType, this);
        }

        private object[] FormatBonus(AvailableCasinoBonusData bonus)
        {
            HttpContext.Current = this.HttpContext;
            List<object> list = new List<object>();
            int count = Math.Min(bonus.PredefinedDeposit.Count, bonus.ExpectedBonus.Count);
            for (int i = 0; i < count; i++)
            {
                list.Add(new
                {
                    depositCurrency = bonus.PredefinedDeposit[i].Value,
                    depositAmount = bonus.PredefinedDeposit[i].Key,
                    depositMoney = MoneyHelper.FormatWithCurrencySymbol(bonus.PredefinedDeposit[i].Value, bonus.PredefinedDeposit[i].Key),
                    expectedBonus = MoneyHelper.FormatWithCurrencySymbol(bonus.ExpectedBonus[i].Value, bonus.ExpectedBonus[i].Key),
                });
            }

            return list.ToArray();
        }


        public void EndProcessRequest(IAsyncResult result)
        {
            GetBonusInfoOperation async = result as GetBonusInfoOperation;
            HttpContext.Current = async.Context;

            JavaScriptSerializer jss = new JavaScriptSerializer();
            string script = null;
            if (async.Account == null 
                || (async.GetUserAvailableCasinoBonusDetailsRequest == null && async.GetUserAvailableBonusDetailsRequest == null && async.GetUserAvailableBetConstructBonusDetailsRequest == null))
            {
                script = jss.Serialize(new
                {
                    @success = false,
                    @error = string.Empty,
                });
            }
            else
            {
                Dictionary<string,int> bonusMetadataOrder = new Dictionary<string,int>();
                int _index = 1;
                foreach(string p in Metadata.GetChildrenPaths("/Metadata/Bonus/"))
                {
                    bonusMetadataOrder.Add(p.Substring(p.LastIndexOf("/")+1).ToLowerInvariant(), _index);
                    _index++;
                }
                                
                string accountID = async.Account.Record.ID.ToString(CultureInfo.InvariantCulture);
                Dictionary<string, Array> dicBonuses = new Dictionary<string, Array>();

                int defaultOrder = 1000;
                Func<string,int> funcGetOrder = (bonusCode) => {
                    bonusCode = bonusCode.ToLowerInvariant();
                    if (bonusMetadataOrder.Keys.Contains(bonusCode))
                        return bonusMetadataOrder[bonusCode];
                    
                    defaultOrder += 1;
                    return defaultOrder;
                };

                if (async.GetUserAvailableCasinoBonusDetailsRequest != null &&
                    async.GetUserAvailableCasinoBonusDetailsRequest.Data != null &&
                    async.GetUserAvailableCasinoBonusDetailsRequest.Data.Count > 0 )
                {
                    var bonuses = async.GetUserAvailableCasinoBonusDetailsRequest.Data
                        .Select(b => new
                        {
                            code = b.Code,
                            name = b.Name,
                            type = b.Type.ToString(),
                            predefinedList = FormatBonus(b),
                            backgroundImage = GetBackgroundImage(b.Code),// ContentHelper.ParseFirstImageSrc(Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/Bonus/{0}.BackgroundImage", b.Code))),
                            bannerHTML = GetBannerHTML(b.Code),//Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/Bonus/{0}.BannerHTML", b.Code)),
                            order = funcGetOrder(b.Code),
                        }).ToArray();
                    dicBonuses.Add(VendorID.CasinoWallet.ToString(),bonuses);
                }

                if (async.Account.Record.VendorID == VendorID.CasinoWallet && 
                    async.GetUserAvailableBonusDetailsRequest != null && 
                    async.GetUserAvailableBonusDetailsRequest.Data != null &&
                    async.GetUserAvailableBonusDetailsRequest.Data.Count >0 )
                {
                    var bonuses = async.GetUserAvailableBonusDetailsRequest.Data
                        .Select(b => new
                        {
                            code = b.BonusID,
                            name = b.Name,
                            type = b.Type.ToString(),
                            amount = b.Amount,
                            currency = b.Currency,
                            percentage = b.Percentage,
                            percentageMaxAmount = b.PercentageMaxAmount,
                            isMinDepositRequirement = b.IsMinDepositRequirement,
                            minDepositAmount = b.MinDepositAmount,
                            minDepositCurrency = b.MinDepositCurrency,
                            redeemPeriodDays = b.RedeemPeriodDays,
                            pointsToCollect = b.PointsToCollect,
                            backgroundImage = GetBackgroundImage(b.BonusID),
                            bannerHTML = GetBannerHTML(b.BonusID),
                            //tcUrl = b.TermsAndConditions,
                            order = funcGetOrder(b.BonusID),
                        }).ToArray();
                    dicBonuses.Add(VendorID.OddsMatrix.ToString(), bonuses);
                }

                if (dicBonuses.Keys.Count > 0)
                {
                    script = jss.Serialize(new
                    {
                        @success = true,
                        @accountID = async.Account.Record.ID.ToString(CultureInfo.InvariantCulture),
                        @bonuses = dicBonuses,
                    });
                }
                else
                {
                    script = jss.Serialize(new
                    {
                        @success = false,
                        @accountID = accountID,
                    });
                }
            }

            this.HttpContext.Response.ContentType = "application/json";
            this.HttpContext.Response.AddHeader("Access-Control-Allow-Origin", "*");
            string jsonCallback = this.HttpContext.Request.QueryString["jsoncallback"];
            if (!string.IsNullOrEmpty(jsonCallback))
                script = string.Format("{0}({1});", jsonCallback, script);

            this.HttpContext.Response.Write(script);
        }

        public void ProcessRequest(HttpContext context)
        {
            throw new InvalidOperationException();
        }

        private string GetBackgroundImage(string bonusID)
        {
            string html = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/Bonus/{0}.BackgroundImage", bonusID));
            if (Settings.IsUKLicense)
            {
                string temp = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/Bonus/{0}.BackgroundImage_UKLicense", bonusID));
                if (!string.IsNullOrWhiteSpace(temp))
                    html = temp;
            }
            return ContentHelper.ParseFirstImageSrc(html);
        }

        private string GetBannerHTML(string bonusID)
        {
            string html = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/Bonus/{0}.BannerHTML", bonusID));
            if (Settings.IsUKLicense)
            {
                string temp = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/Bonus/{0}.BannerHTML_UKLicense", bonusID));
                if (!string.IsNullOrWhiteSpace(temp))
                    html = temp;
            }
            return html;
        }


        public bool IsReusable
        {
            get
            {
                return false;
            }
        }

        internal sealed class GetBonusInfoOperation : IAsyncResult
        {
            private bool _completed;
            private GetBonusInfoHandler _handler;
            private long _outstandingOperation;
            private long AccountID { get; set; }
            private long UserID { get; set; }
            
            private AsyncCallback Callback { get; set; }
            public AccountData Account { get; private set; }
            public GetUserAvailableCasinoBonusDetailsRequest GetUserAvailableCasinoBonusDetailsRequest { get; set; }
            public GetUserAvailableBonusDetailsRequest GetUserAvailableBonusDetailsRequest { get; set; }
            public GetUserAvailableBonusDetailsRequest GetUserAvailableBetConstructBonusDetailsRequest { get; set; }
            public HttpContext Context { get; set; }

            bool IAsyncResult.IsCompleted { get { return _completed; } }
            WaitHandle IAsyncResult.AsyncWaitHandle { get { return null; } }
            Object IAsyncResult.AsyncState { get { return _handler; } }
            bool IAsyncResult.CompletedSynchronously { get { return false; } }

            public GetBonusInfoOperation(AsyncCallback callback, HttpContext context, long userID, long accountID, TransType transType, Object state)
            {
                Context = context;

                Callback = callback;
                AccountID = accountID;
                UserID = userID;
                _handler = state as GetBonusInfoHandler;
                _completed = false;
                _outstandingOperation = 0;

                bool callUserAvailableBonusDetailsRequest = (this.UserID > 0 && Settings.IsOMSeamlessWalletEnabled);
                bool callUserAvailableBetConstructBonusDetailsRequest = (this.UserID > 0 && Settings.IsBetConstructWalletEnabled);

                if (accountID <= 0L)
                    Callback(this);
                else
                {
                    _outstandingOperation = 2;
                    if (callUserAvailableBonusDetailsRequest)
                        _outstandingOperation++;
                    if (callUserAvailableBetConstructBonusDetailsRequest)
                        _outstandingOperation++;

                    GamMatrixClient.GetUserGammingAccountsAsync(CustomProfile.Current.UserID, this.OnGetGammingAccounts, true);

                    GetUserAvailableCasinoBonusDetailsRequest request = new GetUserAvailableCasinoBonusDetailsRequest()
                            {
                                AccountID = accountID,
                                TransType = transType,
                            };

                    GamMatrixClient.SingleRequestAsync<GetUserAvailableCasinoBonusDetailsRequest>(request
                        , OnGetUserAvailableCasinoBonusDetails
                        );

                    if (callUserAvailableBonusDetailsRequest)
                    {
                        GetUserAvailableBonusDetailsRequest requestABD = new GetUserAvailableBonusDetailsRequest()
                        {
                            UserID = this.UserID,
                            VendorID = VendorID.OddsMatrix
                        };

                        GamMatrixClient.SingleRequestAsync<GetUserAvailableBonusDetailsRequest>(requestABD
                        , OnGetUserAvailableBonusDetailsRequest
                        );
                    }

                    /*if (callUserAvailableBetConstructBonusDetailsRequest)
                    {
                        GetUserAvailableBonusDetailsRequest requestBC = new GetUserAvailableBonusDetailsRequest()
                        {
                            UserID = this.UserID,
                            VendorID = VendorID.BetConstruct
                        };

                        GamMatrixClient.SingleRequestAsync<GetUserAvailableBonusDetailsRequest>(requestBC
                        , OnGetUserAvailableBetConstructBonusDetailsRequest
                        );
                    }*/
                }
            }

            private void OnGetGammingAccounts(List<AccountData> accounts)
            {
                this.Account = accounts.FirstOrDefault(a => a.ID == AccountID);

                if (Interlocked.Decrement(ref _outstandingOperation) == 0L)
                {
                    _completed = true;
                    Callback(this);
                }
            }

            private void OnGetUserAvailableCasinoBonusDetails(AsyncResult result)
            {
                try
                {
                    this.GetUserAvailableCasinoBonusDetailsRequest
                        = result.EndSingleRequest().Get<GetUserAvailableCasinoBonusDetailsRequest>();
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                finally
                {
                    if (Interlocked.Decrement(ref _outstandingOperation) == 0L)
                    {
                        _completed = true;
                        Callback(this);
                    }
                }
            }

            private void OnGetUserAvailableBonusDetailsRequest(AsyncResult result)
            {
                try
                {
                    this.GetUserAvailableBonusDetailsRequest
                        = result.EndSingleRequest().Get<GetUserAvailableBonusDetailsRequest>();
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                finally
                {
                    if (Interlocked.Decrement(ref _outstandingOperation) == 0L)
                    {
                        _completed = true;
                        Callback(this);
                    }
                }
            }

            private void OnGetUserAvailableBetConstructBonusDetailsRequest(AsyncResult result)
            {
                try
                {
                    this.GetUserAvailableBetConstructBonusDetailsRequest
                        = result.EndSingleRequest().Get<GetUserAvailableBonusDetailsRequest>();
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                finally
                {
                    if (Interlocked.Decrement(ref _outstandingOperation) == 0L)
                    {
                        _completed = true;
                        Callback(this);
                    }
                }
            }

            
        }
    }
}