using System;
using System.Collections.Generic;
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
    /// Summary description for GetBalanceHandler
    /// </summary>
    public sealed class GetBalanceHandler : IHttpAsyncHandler
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
            catch(Exception ex)
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
                if (async.Accounts == null)
                {
                    script = jss.Serialize(new
                    {
                        @success = false,
                        @isLoggedIn = async.IsLoggedIn,
                        @error = string.Empty,
                    });
                }
                else
                {
                    //ObjectHelper.XmlSerialize(async.Accounts, "G:\\GetUserAccountsRequest.xml");
                    var separateBonus = async.SeparateBonus;

                    var list = async.Accounts.Where(a => a.Record.ActiveStatus == GamMatrixAPI.ActiveStatus.Active)
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
                                FormattedAmount = a.FormatBalanceAmount(!separateBonus),
                            }).ToList();

                    // reorder the account
                    List<object> accounts = new List<object>();
                    string[] paths = Metadata.GetChildrenPaths("/Metadata/GammingAccount/");
                    for (int i = 0; i < paths.Length; i++)
                    {
                        string name = global::System.IO.Path.GetFileName(paths[i]);
                        var account = list.FirstOrDefault(a => a.VendorID == name);
                        if (account != null)
                        {
                            accounts.Add(account);

                            #region Bonus
                            if (separateBonus)
                            {
                                if (account.BonusAmount > 0.00M)
                                {
                                    var nAccount = new
                                    {
                                        ID = account.ID,
                                        IsBalanceAvailable = account.IsBalanceAvailable,
                                        VendorID = account.VendorID,
                                        DisplayName = Metadata.Get(string.Format("/Metadata/GammingAccount/{0}.Bonus_Display_Name", account.VendorID)),
                                        EnglishName = account.EnglishName,
                                        BalanceCurrency = account.BalanceCurrency,
                                        BalanceCurrencySymbol = account.BalanceCurrencySymbol,
                                        BalanceAmount = account.BonusAmount,
                                        FormattedAmount = string.Format("{0:n2}", account.BonusAmount)
                                    };
                                    accounts.Add(nAccount);
                                }

                                if (account.OMBonusAmount > 0.00M && account.VendorID.Equals(VendorID.CasinoWallet.ToString(), StringComparison.OrdinalIgnoreCase))
                                {
                                    var nAccount = new
                                    {
                                        ID = account.ID,
                                        IsBalanceAvailable = account.IsBalanceAvailable,
                                        VendorID = account.VendorID,
                                        DisplayName = Metadata.Get(string.Format("/Metadata/GammingAccount/{0}.Bonus_OM_Display_Name", account.VendorID)),
                                        EnglishName = account.EnglishName,
                                        BalanceCurrency = account.BalanceCurrency,
                                        BalanceCurrencySymbol = account.BalanceCurrencySymbol,
                                        BalanceAmount = account.OMBonusAmount,
                                        FormattedAmount = string.Format("{0:n2}", account.OMBonusAmount)
                                    };
                                    accounts.Add(nAccount);
                                }

                                if (account.BetConstructBonusAmount > 0.00M)
                                {
                                    var nAccount = new
                                    {
                                        ID = account.ID,
                                        IsBalanceAvailable = account.IsBalanceAvailable,
                                        VendorID = account.VendorID,
                                        DisplayName = Metadata.Get(string.Format("/Metadata/GammingAccount/{0}.Bonus_BC_Display_Name", account.VendorID)),
                                        EnglishName = account.EnglishName,
                                        BalanceCurrency = account.BalanceCurrency,
                                        BalanceCurrencySymbol = account.BalanceCurrencySymbol,
                                        BalanceAmount = account.BonusAmount,
                                        FormattedAmount = string.Format("{0:n2}", account.BetConstructBonusAmount)
                                    };
                                    accounts.Add(nAccount);
                                }
                            }
                            #endregion Bonus
                        }
                    }

                    script = jss.Serialize(new
                    {
                        @success = true,
                        @isLoggedIn = true,
                        @accounts = accounts.ToArray()
                    });
                }

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