using System;
using System.Collections.Generic;
using System.Linq;
using CM.Content;
using CM.db;
using CM.Sites;
using GamMatrixAPI;

namespace Finance
{
    /// <summary>
    /// Summary description for PaymentMethod
    /// </summary>
    public sealed class PaymentMethod
    {
        public string UniqueName { get; set; }
        public string ResourceKey { get; set; }
        public PaymentMethodCategory Category { get; set; }
        public GamMatrixAPI.VendorID VendorID { get; set; }        
        public CountryList SupportedCountries { get; set; }
        public CurrencyList SupportedCurrencies { get; set; }
        public ProcessTime ProcessTime { get; set; }
        public ProcessFee DepositProcessFee { get; set; }
        public ProcessFee WithdrawProcessFee { get; set; }
        public bool SupportWithdraw { get; set; }
        public bool SupportDeposit { get; set; }
        public bool IsCurrencyChangable { get; set; }
        public Dictionary<string, Range> DepositLimitations { get; set; }
        public Dictionary< string, Range> WithdrawLimitations { get; set; }
        public List<string> RepulsivePaymentMethods { get; set; }
        public int Ordinal { get; set; }
        public bool IsDisabled { get; set; }
        public bool IsDisabledDuringFallback { get; set; }
        public bool IsVisible { get; set; }
        public bool IsVisibleDuringFallback { get; set; }

        public bool IsAvailable
        {
            get
            {
                if (PaymentMethodManager.GetFallbackMode())
                {
                    return this.IsVisibleDuringFallback;
                }
                else
                {
                    return this.IsVisible;
                }
            }
        }

        public string SubCode { get; set; }
        public string [] DenyAccessRoleNames { get; set; }

        public CountryList WithdrawSupportedCountries { get; set; }

        public int SimultaneousDepositLimit { get; set; }
        
        public PaymentMethod()
        {
            this.SupportDeposit = true;
        }

        public string GetImageUrl( cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethod/{0}.Image", this.ResourceKey);
            string html = Metadata.Get(domain, path, culture);
            return ContentHelper.ParseFirstImageSrc(html);
        }

        public string GetTitleHtml(cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethod/{0}.Title", this.ResourceKey);
            return Metadata.Get(domain, path, culture);
        }

        public string GetDescriptionHtml(cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethod/{0}.Description", this.ResourceKey);
            return Metadata.Get(domain, path, culture);
        }

        public string GetWithdrawMessage(cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethod/{0}.Withdraw_Message", this.ResourceKey);
            return Metadata.Get(domain, path, culture);
        }

        public Range GetWithdrawLimitation(string currency)
        {
            if (this.WithdrawLimitations.Count == 0)
                return new Range() { Currency = currency, MaxAmount = 0.00M, MinAmount = 0.00M };

            Range range;
            if (this.WithdrawLimitations.TryGetValue(currency, out range))
                return range;

            if (!this.WithdrawLimitations.TryGetValue("EUR", out range))
            {
                range = this.WithdrawLimitations.First().Value;
            }

            return new Range()
            {
                Currency = currency,
                MinAmount = MoneyHelper.TransformCurrency(range.Currency, currency, range.MinAmount),
                MaxAmount = MoneyHelper.TransformCurrency(range.Currency, currency, range.MaxAmount),
            };
        }

        public Range GetDepositLimitation(string currency)
        {
            if (this.DepositLimitations.Count == 0)
                return new Range() { Currency = currency, MaxAmount = 0.00M, MinAmount = 0.00M };

            Range range;
            if (this.DepositLimitations.TryGetValue(currency, out range))
                return range;

            if (!this.DepositLimitations.TryGetValue("EUR", out range))
            {
                range = this.DepositLimitations.First().Value;
            }

            return new Range()
            {
                Currency = currency,
                MinAmount = MoneyHelper.TransformCurrency(range.Currency, currency, range.MinAmount),
                MaxAmount = MoneyHelper.TransformCurrency(range.Currency, currency, range.MaxAmount),
            };
        }


        public bool HasPromotion(cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethod/{0}.PromotionHtml", this.ResourceKey);
            return !string.IsNullOrWhiteSpace(Metadata.Get(domain, path, culture));
        }

        public string GetPromotionHtml(cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethod/{0}.PromotionHtml", this.ResourceKey);
            return Metadata.Get(domain, path, culture);
        }    
    }
}