using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;
using Finance;
using Notification;

namespace GamMatrix.CMS.Controllers.System
{
    public enum PaymentChangeType
    {
        SupportedCountry,
        SupportWithdraw,
        WithdrawSupportedCountry,
        RepulsivePaymentMethods
    }

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class PaymentMethodMgtController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var domain = SiteManager.GetSiteByDistinctName(distinctName);
            if (domain == null)
                throw new ArgumentException("distinctName");
            return View("Index", domain);
        }

        [HttpGet]
        public ActionResult TabProperties(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            return View("TabProperties", this.ViewData.Merge(new { cmSite = site }));
        }

        [HttpGet]
        public ActionResult TabFallbackVisibilityOrder(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            return View("TabFallbackVisibilityOrder", this.ViewData.Merge(new { cmSite = site }));
        }
        
        [HttpGet]
        public ActionResult TabVisibilityOrder(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            return View("TabVisibilityOrder", this.ViewData.Merge(new { cmSite = site }));
        }
        
        [HttpGet]
        public ActionResult SupportedCountryView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("SupportedCountry", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult SupportedCurrencyView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("SupportedCurrency", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult DepositLimitationView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod });
            return View("DepositLimitation", paymentMethod.DepositLimitations);
        }

        [HttpGet]
        public ActionResult WithdrawLimitationView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod });
            return View("WithdrawLimitation", paymentMethod.WithdrawLimitations);
        }

        [HttpGet]
        public ActionResult ProcessTimeView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            return View("ProcessTime", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult DepositProcessFeeView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("DepositProcessFee", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult WithdrawProcessFeeView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("WithdrawProcessFee", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult WithdrawSupportView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("WithdrawSupport", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult RepulsivePaymentMethodsView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("RepulsivePaymentMethods", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult WithdrawSupportedCountryView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("WithdrawSupportedCountry", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpGet]
        public ActionResult SimultaneousDepositLimitView(string distinctName, string paymentMethodName)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            return View("SimultaneousDepositLimit", this.ViewData.Merge(new { cmSite = site, @paymentMethod = paymentMethod }));
        }

        [HttpPost]
        public JsonResult SaveSupportedCountry(string distinctName, string paymentMethodName, CountryList.FilterType filterType, List<int> list)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            PaymentMethodManager.SaveSupportCountry(distinctName
                , paymentMethodName
                , new CountryList()
                {
                    Type = filterType,
                    List = list
                }
                );

            List<FilteredListBase<int>.FilterType> listExtra = new List<FilteredListBase<int>.FilterType>();
            listExtra.Add(paymentMethod.SupportedCountries.Type);
            listExtra.Add(filterType);

            SendChangeNotificationEmail(distinctName, paymentMethodName, PaymentChangeType.SupportedCountry, paymentMethod.SupportedCountries.List, list, listExtra);

            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveSupportedCurrency(string distinctName, string paymentMethodName, CurrencyList.FilterType filterType, List<string> list)
        {
            PaymentMethodManager.SaveSupportCurrency(distinctName.DefaultDecrypt()
                , paymentMethodName
                , new CurrencyList()
                {
                    Type = filterType,
                    List = list
                }
                );
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveDepositLimitation(string distinctName
            , string paymentMethodName
            )
        {
            Dictionary<string, Range> limitations = new Dictionary<string, Range>(StringComparer.OrdinalIgnoreCase);

            foreach (string keyName in Request.Form.AllKeys)
            {
                Match m = Regex.Match(keyName
                    , @"^(?<type>(depositLimitMax_)|(depositLimitMin_))(?<currency>[A-Z]{3,3})$"
                    , RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                    );
                if (m.Success)
                {
                    decimal amount;
                    if (decimal.TryParse(Request.Form[keyName], out amount) && amount > 0.00M)
                    {
                        if (!limitations.ContainsKey(m.Groups["currency"].Value))
                            limitations[m.Groups["currency"].Value] = new Range() { Currency = m.Groups["currency"].Value };

                        if (m.Groups["type"].Value == "depositLimitMax_")
                            limitations[m.Groups["currency"].Value].MaxAmount = amount;
                        else
                            limitations[m.Groups["currency"].Value].MinAmount = amount;
                    }
                }
            }

            PaymentMethodManager.SaveDepositLimitations(distinctName.DefaultDecrypt()
                , paymentMethodName
                , limitations
                );
            return this.Json(new { @success = true });
        }


        [HttpPost]
        public JsonResult SaveWithdrawLimitation(string distinctName
            , string paymentMethodName
            )
        {
            Dictionary<string, Range> limitations = new Dictionary<string, Range>(StringComparer.OrdinalIgnoreCase);

            foreach (string keyName in Request.Form.AllKeys)
            {
                Match m = Regex.Match(keyName
                    , @"^(?<type>(withdrawLimitMax_)|(withdrawLimitMin_))(?<currency>[A-Z]{3,3})$"
                    , RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                    );
                if (m.Success)
                {
                    decimal amount;
                    if (decimal.TryParse(Request.Form[keyName], out amount) && amount > 0.00M)
                    {
                        if (!limitations.ContainsKey(m.Groups["currency"].Value))
                            limitations[m.Groups["currency"].Value] = new Range() { Currency = m.Groups["currency"].Value };

                        if (m.Groups["type"].Value == "withdrawLimitMax_")
                            limitations[m.Groups["currency"].Value].MaxAmount = amount;
                        else
                            limitations[m.Groups["currency"].Value].MinAmount = amount;
                    }
                }
            }

            PaymentMethodManager.SaveWithdrawLimitations(distinctName.DefaultDecrypt()
                , paymentMethodName
                , limitations
                );
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveProcessTime(string distinctName
            , string paymentMethodName
            , ProcessTime processTime
            )
        {
            PaymentMethodManager.SaveProcessTime(distinctName.DefaultDecrypt()
                , paymentMethodName
                , processTime
                );
            return this.Json(new { @success = true });
        }

        private ProcessFee PopulateProcessFee()
        {
            ProcessFee processFee = new ProcessFee();
            ProcessFeeType processFeeType;
            if (!Enum.TryParse<ProcessFeeType>(Request["processFeeType"], out processFeeType))
                processFeeType = ProcessFeeType.Free;

            processFee.ProcessFeeType = processFeeType;

            switch (processFeeType)
            {
                case ProcessFeeType.Free:
                    return processFee;

                case ProcessFeeType.Percent:
                    {
                        decimal percentage;
                        if (!decimal.TryParse(Request["percentage"], out percentage))
                            percentage = 0.00M;
                        processFee.Percentage = percentage;
                        return processFee;
                    }

                case ProcessFeeType.Fixed:
                    {
                        foreach (string item in Request.Form.Keys)
                        {
                            Match m = Regex.Match(item, @"^fixed_(?<currency>[A-Z]+)$", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                            if (!m.Success) continue;

                            decimal fee;
                            if (!decimal.TryParse(Request.Form[item], out fee))
                                fee = 0.00M;
                            processFee.Currency2FixedFee[m.Groups["currency"].Value] = fee;
                        }
                        return processFee;
                    }

                case ProcessFeeType.Bank:
                    {
                        foreach (string item in Request.Form.Keys)
                        {
                            Match m = Regex.Match(item, @"^international_(?<currency>[A-Z]+)$", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                            if (!m.Success) continue;

                            decimal localFee, internationalFee;
                            if (!decimal.TryParse(Request.Form[item], out internationalFee))
                                internationalFee = 0.00M;
                            if (!decimal.TryParse(Request.Form["local_" + m.Groups["currency"].Value], out localFee))
                                localFee = 0.00M;
                            processFee.Currency2BankFee[m.Groups["currency"].Value] = new KeyValuePair<decimal, decimal>(localFee, internationalFee);
                        }
                        return processFee;
                    }
            }

            return processFee;
        }

        [HttpPost]
        public JsonResult SaveDepositProcessFee(string distinctName
            , string paymentMethodName
            , string processFee
            )
        {
            PaymentMethodManager.SaveDepositProcessFee(distinctName.DefaultDecrypt()
                , paymentMethodName
                , PopulateProcessFee()
                );
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveWithdrawProcessFee(string distinctName
            , string paymentMethodName
            , string processFee
            )
        {
            PaymentMethodManager.SaveWithdrawProcessFee(distinctName.DefaultDecrypt()
                , paymentMethodName
                , PopulateProcessFee()
                );
            return this.Json(new { @success = true });
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="distinctName"></param>
        /// <param name="paymentMethodName"></param>
        /// <param name="withdrawSupport"></param>
        /// <returns></returns>
        [HttpPost]
        public JsonResult SaveSupportWithdraw(string distinctName
            , string paymentMethodName
            , bool supportWithdraw)
        {

            if (!CM.State.CustomProfile.Current.IsAuthenticated || !CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                return this.Json(new { @success = false });

            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            PaymentMethodManager.SaveSupportWithdraw(distinctName
                , paymentMethodName
                , supportWithdraw
                );

            SendChangeNotificationEmail(distinctName, paymentMethodName, PaymentChangeType.SupportWithdraw, paymentMethod.SupportWithdraw, supportWithdraw, null);
            return this.Json(new { @success = true });
        }


        [HttpPost]
        public JsonResult SaveRepulsivePaymentMethods(string distinctName
            , string paymentMethodName
            , List<string> repulsivePaymentMethods
            )
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            PaymentMethodManager.SaveRepulsivePaymentMethods(distinctName
                , paymentMethodName
                , repulsivePaymentMethods
                );

            SendChangeNotificationEmail(distinctName, paymentMethodName, PaymentChangeType.RepulsivePaymentMethods, paymentMethod.RepulsivePaymentMethods, repulsivePaymentMethods, null);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveFallbackVisibilityAndOrder(string distinctName)
        {
            return this.SaveVisibilityAndOrder(distinctName, isFallbackVisibility: true);
        }

        [HttpPost]
        public JsonResult SaveVisibilityAndOrder(string distinctName, bool isFallbackVisibility = false)
        {
            distinctName = distinctName.DefaultDecrypt();
            {
                Dictionary<string, int> ordinalDictionary = new Dictionary<string, int>();
                Dictionary<string, bool> visibilityDictionary = new Dictionary<string, bool>();
                foreach (string key in Request.Form.AllKeys)
                {
                    Match match = Regex.Match(key, @"^ordinal_(?<UniqueName>.+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                    if (match.Success)
                    {
                        int ordinal;
                        if (!int.TryParse(Request.Form[key], out ordinal))
                            continue;
                        ordinalDictionary[match.Groups["UniqueName"].Value] = ordinal;
                        continue;
                    }

                    match = Regex.Match(key, @"^enabled_(?<UniqueName>.+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                    if (match.Success && !string.IsNullOrWhiteSpace(Request.Form[key]))
                    {
                        bool visible = Request.Form[key].IndexOf("true", StringComparison.OrdinalIgnoreCase) >= 0;

                        visibilityDictionary[match.Groups["UniqueName"].Value] = visible;
                        continue;
                    }
                }

                if (!string.IsNullOrEmpty(Request.Form.AllKeys.FirstOrDefault(x => x == "fallbackMode")))
                {
                    var fallbackMode = Request.Form["fallbackMode"].IndexOf("true", StringComparison.OrdinalIgnoreCase) >= 0;

                    PaymentMethodManager.SaveFallbackMode(fallbackMode);
                }

                var domain = SiteManager.GetSiteByDistinctName(distinctName);
                var oldPaymentMethods = PaymentMethodManager.GetPaymentMethods(domain, false);

                if (isFallbackVisibility)
                {
                    PaymentMethodManager.SaveFallbackVisibilityDictionary(distinctName, visibilityDictionary);
                }
                else
                {
                    PaymentMethodManager.SaveOrdinalDictionary(distinctName, ordinalDictionary);
                    PaymentMethodManager.SaveVisibilityDictionary(distinctName, visibilityDictionary);
                }
                
                var newPaymentMethods = PaymentMethodManager.GetPaymentMethods(domain, false);

                if (isFallbackVisibility)
                {
                    PaymentMethodNotification.SendFallbackVisibilityChangeEmail(domain, oldPaymentMethods, newPaymentMethods);
                }
                else
                {
                    PaymentMethodNotification.SendVisibilityAndOrderChangeEmail(domain, oldPaymentMethods, newPaymentMethods);
                }
            }

            return this.Json(new { @success = true });
        }


        [HttpPost]
        public JsonResult SaveBankWithdrawalConfiguration(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            {
                Dictionary<long, BankWithdrawalCountryConfig> dictionary = new Dictionary<long, BankWithdrawalCountryConfig>();
                foreach (string key in Request.Form.AllKeys)
                {
                    Match match = Regex.Match(key, @"^bank_withdrawal_type_(?<InternalID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                    if (match.Success)
                    {
                        long internalID = long.Parse(match.Groups["InternalID"].Value);
                        BankWithdrawalType type;
                        if (Enum.TryParse<BankWithdrawalType>(Request.Form[key], out type))
                        {
                            BankWithdrawalCountryConfig config = new BankWithdrawalCountryConfig()
                            {
                                InternalID = internalID,
                                Type = type,
                            };
                            dictionary[internalID] = config;
                        }
                    }
                }

                var domain = SiteManager.GetSiteByDistinctName(distinctName);
                var oldConfigs = PaymentMethodManager.GetBankWithdrawalConfiguration(domain);

                PaymentMethodManager.SaveBankWithdrawalConfiguration(distinctName, dictionary);

                var newConfigs = PaymentMethodManager.GetBankWithdrawalConfiguration(domain);
                PaymentMethodNotification.SendBankWithdrawalChangeEmail(domain, oldConfigs, newConfigs);
            }

            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveWithdrawSupportedCountry(string distinctName, string paymentMethodName, CountryList.FilterType filterType, List<int> list)
        {
            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            PaymentMethodManager.SaveWithdrawSupportCountry(distinctName
                , paymentMethodName
                , new CountryList()
                {
                    Type = filterType,
                    List = list
                }
                );

            List<FilteredListBase<int>.FilterType> listExtra = new List<FilteredListBase<int>.FilterType>();
            listExtra.Add(paymentMethod.WithdrawSupportedCountries.Type);
            listExtra.Add(filterType);

            SendChangeNotificationEmail(distinctName, paymentMethodName, PaymentChangeType.WithdrawSupportedCountry, paymentMethod.WithdrawSupportedCountries.List, list, listExtra);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveSimultaneousDepositLimit(string distinctName, string paymentMethodName, int simultaneousDepositLimit)
        {
            if (!CM.State.CustomProfile.Current.IsAuthenticated || !CM.State.CustomProfile.Current.IsInRole("CMS System Admin"))
                return this.Json(new { @success = false });

            distinctName = distinctName.DefaultDecrypt();
            var site = SiteManager.GetSiteByDistinctName(distinctName);
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods(site, false).First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            PaymentMethodManager.SaveSimultaneousDepositLimit(distinctName
                , paymentMethodName
                , simultaneousDepositLimit
                );

            return this.Json(new { @success = true });
        }

        private void SendChangeNotificationEmail(string distinctName, string paymentMethodName, PaymentChangeType changeType, object oldValue, object newValue, object extra)
        {
            try
            {
                StringBuilder sb = new StringBuilder();
                #region Compare
                switch (changeType)
                {
                    case PaymentChangeType.SupportWithdraw:
                        {
                            sb.AppendFormat(@"<b>{0}</b> changed <b>[Support Withdraw]</b> from <b>{1}</b> to <b>{2}</b> of <b>{3}</b> for [{4}]",
                                CM.State.CustomProfile.Current.UserName,
                                oldValue.ToString(),
                                newValue.ToString(),
                                paymentMethodName,
                                distinctName
                                );
                            break;
                        }
                    case PaymentChangeType.SupportedCountry:
                    case PaymentChangeType.WithdrawSupportedCountry:
                        {
                            sb.AppendFormat(@"<b>{0}</b> changed <b>[{1}]</b> of <b>{2}</b> for [{3}]: <br />",
                                CM.State.CustomProfile.Current.UserName,
                                changeType.ToString(),
                                paymentMethodName,
                                distinctName
                                );

                            List<FilteredListBase<int>.FilterType> listExtra = extra as List<FilteredListBase<int>.FilterType>;
                            if (listExtra != null)
                            {
                                CountryList.FilterType oldFilterType = (FilteredListBase<int>.FilterType)listExtra[0];
                                CountryList.FilterType newFilterType = (FilteredListBase<int>.FilterType)listExtra[1];
                                if (oldFilterType != newFilterType)
                                {
                                    sb.AppendFormat("<b>Filter Type:</b> from <b>[{0}]</b> to <b>[{1}]</b> <br />", oldFilterType.ToString(), newFilterType.ToString());
                                }
                            }

                            List<CountryInfo> countries = CountryManager.GetAllCountries();

                            List<int> oldList = oldValue as List<int>;
                            List<int> newList = newValue as List<int>;
                            if (oldList == null)
                            {
                                oldList = new List<int>();
                                oldList.Add(0);
                            };
                            if (newList == null)
                            {
                                newList = new List<int>();
                                newList.Add(0);
                            }
                            List<int> allList = oldList.Union(newList).ToList();

                            sb.Append(@"<b>Countries:</b>  <br />");
                            sb.Append(@"<table>");
                            sb.Append(@"<thead><tr> <th style=""border:1px  solid #333333; padding:5px 10px;"">From: </th> <th style=""border:1px  solid #333333;padding:5px 10px;"">To: </th> </tr></thead>");
                            sb.Append(@"<tbody>");

                            string cname;
                            string template = @"<tr style=""border:1px  solid #333333;"">
<td style=""border:1px  solid #333333; color:{0};"">{1}</td>
<td style=""border:1px  solid #333333; color:{2};"">{3}</td>
<tr>";
                            string leftColor = "black", leftText = string.Empty, rightColor = "black", rightText = string.Empty;
                            foreach (int id in allList)
                            {
                                cname = id == 0 ? "All" : countries.Exists(c => c.InternalID == id) ? countries.FirstOrDefault(c => c.InternalID == id).EnglishName : "unfound";

                                //sb.Append(@"<tr style=""border:1px  solid #333333;""> </tr>");

                                if (oldList.Exists(i => i == id))
                                {
                                    if (newList.Exists(i => i == id))
                                    {
                                        leftColor = "black";
                                        leftText = string.Format("[{0}-{1}]", id, cname);
                                        //sb.AppendFormat(@"<td style=""border:1px  solid #333333;"">[{0} - {1}]</td>", id, cname);
                                    }
                                    else
                                    {
                                        leftColor = "red";
                                        leftText = string.Format("[{0}-{1}]", id, cname);
                                        //sb.AppendFormat(@"<td style=""border:1px  solid #333333; color:red;"">[{0} - {1}]</td>", id, cname);
                                    }
                                }
                                else
                                {
                                    leftColor = "black";
                                    leftText = "&nbsp;";
                                    //sb.Append(@"<td style=""border:1px  solid #333333;""> &nbsp; </td>");
                                }

                                if (newList.Exists(i => i == id))
                                {
                                    if (oldList.Exists(i => i == id))
                                    {
                                        rightColor = "black";
                                        rightText = string.Format("[{0}-{1}]", id, cname);
                                        //sb.AppendFormat(@"<td style=""border:1px  solid #333333;"">[{0} - {1}]</td>", id, cname);
                                    }
                                    else
                                    {
                                        rightColor = "green";
                                        rightText = string.Format("[{0}-{1}]", id, cname);
                                        //sb.AppendFormat(@"<td style=""border:1px  solid #333333;color:green;"">[{0} - {1}]</td>", id, cname);
                                    }
                                }
                                else
                                {
                                    rightColor = "black";
                                    rightText = "&nbsp;";
                                    //sb.Append(@"<td style=""border:1px  solid #333333;""> &nbsp; </td>");
                                }
                                //sb.Append(@"<tr>");

                                sb.AppendFormat(template, leftColor, leftText, rightColor, rightText);
                            }
                            sb.Append(@"</tbody>");
                            sb.Append(@"</table>");

                            break;
                        }

                    case PaymentChangeType.RepulsivePaymentMethods:
                        {
                            sb.AppendFormat(@"<b>{0}</b> changed <b>[Auto-hide if these methods available]</b> of <b>{1}</b> for [{2}]",
                                CM.State.CustomProfile.Current.UserName,
                                paymentMethodName,
                                distinctName
                                );

                            List<string> oldList = oldValue as List<string>;
                            List<string> newList = newValue as List<string>;

                            if (oldList == null)
                            {
                                oldList = new List<string>();
                            };
                            if (oldList.Count == 0)
                                oldList.Add("none");

                            if (newList == null)
                            {
                                newList = new List<string>();
                            }
                            if (newList.Count == 0)
                                newList.Add("none");

                            List<string> allList = oldList.Union(newList).ToList();

                            sb.Append(@"<b>Payment methods:</b>  <br />");
                            sb.Append(@"<table>");
                            sb.Append(@"<thead><tr> <th style=""border:1px  solid #333333; padding:5px 10px;"">From: </th> <th style=""border:1px  solid #333333;padding:5px 10px;"">To: </th> </tr></thead>");
                            sb.Append(@"<tbody>");
                            foreach (string payment in allList)
                            {
                                sb.Append(@"<tr> ");

                                if (oldList.Exists(p => p == payment))
                                {
                                    if (newList.Exists(p => p == payment))
                                        sb.AppendFormat(@"<td style=""border:1px  solid #333333;"">[{0}]</td>", payment);
                                    else
                                        sb.AppendFormat(@"<td style=""border:1px  solid #333333; color:red;"">[{0}]</td>", payment);
                                }
                                else
                                    sb.Append(@"<td style=""border:1px  solid #333333;""> &nbsp; </td>");


                                if (newList.Exists(p => p == payment))
                                {
                                    if (oldList.Exists(p => p == payment))
                                        sb.AppendFormat(@"<td style=""border:1px  solid #333333;"">[{0}]</td>", payment);
                                    else
                                        sb.AppendFormat(@"<td style=""border:1px  solid #333333;color:green;"">[{0}]</td>", payment);
                                }
                                else
                                    sb.Append(@"<td style=""border:1px  solid #333333;""> &nbsp; </td>");

                                sb.Append(@" </tr> ");
                            }
                            sb.Append(@"</tbody>");
                            sb.Append(@"</table>");
                            break;
                        }

                    default:
                        return;
                }
                if (SiteManager.IsSiteRootTemplate(distinctName))
                {
                    PaymentMethodCoverage[] paymentMethodsCoverageList = PaymentMethodManager.LoadPaymentMethodsOperatorCoverage().ToArray();
                    var operators = paymentMethodsCoverageList.Where(p => p.MethodUniqueName == paymentMethodName).ToList();
                    sb.Append(@"<b>Affected Operators:</b>  <br />");
                    operators.ForEach(op => {
                        sb.AppendFormat(@"<p>{0}</P>", op.SiteDisplayName);
                    });
                }
                #endregion

                #region Send Email
                using (MailMessage message = new MailMessage())
                {
                    string[] addresses = ConfigurationManager.AppSettings["PaymentMethod.ChangeNotification.EmailAddress"].Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);

                    if (addresses.Length == 0)
                        return;

                    message.Subject = "Payment method change notification";
                    message.SubjectEncoding = Encoding.UTF8;
                    foreach (string address in addresses)
                    {
                        message.To.Add(new MailAddress(address));
                    }
                    message.IsBodyHtml = true;
                    message.From = new MailAddress("noreply@everymatrix.com");
                    message.BodyEncoding = Encoding.UTF8;
                    message.Body = sb.ToString();



                    SmtpClient client = new SmtpClient("10.0.10.7", 25);
                    client.Send(message);
                }
                #endregion
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        

    }
}
