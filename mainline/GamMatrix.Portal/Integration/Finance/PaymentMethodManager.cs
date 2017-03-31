using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.IO;
using System.Text.RegularExpressions;
using System.Runtime.Serialization.Formatters.Binary;

using GamMatrix.Infrastructure;
using GamMatrixAPI;
using GmCore;

using CM.Content;
using CM.db;
using CM.Sites;

namespace Finance
{
    /// <summary>
    /// Summary description for PaymentMethodManager
    /// </summary>
    public static class PaymentMethodManager
    {
        private const string PaymentMethod_PT_VISA = "PT_VISA";

        public static PaymentMethodCategory[] GetCategories(cmSite domain = null, string culture = null)
        {
            List<PaymentMethodCategory> categories = new List<PaymentMethodCategory>();
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();
            string[] paths = Metadata.GetChildrenPaths(domain, "/Metadata/PaymentMethodCategory");
            foreach (string path in paths)
            {
                string name = Path.GetFileNameWithoutExtension(path);
                PaymentMethodCategory category;
                if (Enum.TryParse<PaymentMethodCategory>(name, true, out category))
                    categories.Add(category);
            }
            return categories.ToArray();
        }

        public static List<PaymentMethod> GetPaymentMethods(cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format("site_payment_methods_list_{0}", site.ID);
            List<PaymentMethod> paymentMethods = HttpRuntime.Cache[cacheKey] as List<PaymentMethod>;

            if (useCache && paymentMethods != null)
                return paymentMethods;

            #region payment methods
            paymentMethods = new List<PaymentMethod>();
            // VISA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = PaymentMethod_PT_VISA,
                ResourceKey = "VISA",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });
            
            // VISA Electron
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_VISA_Electron",
                ResourceKey = "VISA_Electron",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // VISA Debit
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_VISA_Debit",
                ResourceKey = "VISA_Debit",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // MasterCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_MasterCard",
                ResourceKey = "MasterCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // Switch
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_Switch",
                ResourceKey = "Switch",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // Solo
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_Solo",
                ResourceKey = "Solo",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // Maestro
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_Maestro",
                ResourceKey = "Maestro",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // EntroPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_EntroPay",
                ResourceKey = "EntroPay",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // TicketSurf - VISA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_VISA_TicketSurf",
                ResourceKey = "VISA_TicketSurf",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // TicketSurf - MASTER
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PT_MasterCard_TicketSurf",
                ResourceKey = "MasterCard_TicketSurf",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // VISA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "NLB_VISA",
                ResourceKey = "VISA",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.NLB,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // MasterCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "NLB_MasterCard",
                ResourceKey = "MasterCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.NLB,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });


            // Neteller
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller",
                ResourceKey = "Neteller",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Argentina AR-17
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_AR",
                ResourceKey = "Neteller_AR",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Australia AU-20
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_AU",
                ResourceKey = "Neteller_AU",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Austria AT-21
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_AT",
                ResourceKey = "Neteller_AT",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Belgium BE-28
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_BE",
                ResourceKey = "Neteller_BE",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Bolivia BO-33
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_BO",
                ResourceKey = "Neteller_BO",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Brazil BR-37
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_BR",
                ResourceKey = "Neteller_BR",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Bulgaria BG-40
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_BG",
                ResourceKey = "Neteller_BG",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Chile CL-50
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_CL",
                ResourceKey = "Neteller_CL",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Czech Rep CZ-63
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_CZ",
                ResourceKey = "Neteller_CZ",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Denmark DK-64
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_DK",
                ResourceKey = "Neteller_DK",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Estonia EE-74
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_EE",
                ResourceKey = "Neteller_EE",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Finland FI-79
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_FI",
                ResourceKey = "Neteller_FI",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller France FR-80
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_FR",
                ResourceKey = "Neteller_FR",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Germany DE-88
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_DE",
                ResourceKey = "Neteller_DE",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Germany 2 DE-88
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_DE_2",
                ResourceKey = "Neteller_DE_2",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Greece GR-91
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_GR",
                ResourceKey = "Neteller_GR",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Hungary HU-104
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_HU",
                ResourceKey = "Neteller_HU",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Italy IT-122
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_IT",
                ResourceKey = "Neteller_IT",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Italy 2 IT-122
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_IT_2",
                ResourceKey = "Neteller_IT_2",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Japan JP-114
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_JP",
                ResourceKey = "Neteller_JP",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Latvia LV-122
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_LV",
                ResourceKey = "Neteller_LV",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Mexico MX-143
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_MX",
                ResourceKey = "Neteller_MX",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Netherlands NL-155
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_NL",
                ResourceKey = "Neteller_NL",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Norway NO-166
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_NO",
                ResourceKey = "Neteller_NO",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Portugal PT-178
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_PT",
                ResourceKey = "Neteller_PT",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Russia RU-183
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_RU",
                ResourceKey = "Neteller_RU",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Slovakia SK-196
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_SK",
                ResourceKey = "Neteller_SK",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Slovenia SI-197
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_SI",
                ResourceKey = "Neteller_SI",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller South Africa ZA-200
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_ZA",
                ResourceKey = "Neteller_ZA",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Spain ES-203
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_ES",
                ResourceKey = "Neteller_ES",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Sweden SE-211
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_SE",
                ResourceKey = "Neteller_SE",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Sweden 2 SE-211
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_SE_2",
                ResourceKey = "Neteller_SE_2",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Switzerland CH-212
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_CH",
                ResourceKey = "Neteller_CH",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Turkey TR-223
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_TR",
                ResourceKey = "Neteller_TR",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Ukraine UA-228
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_UA",
                ResourceKey = "Neteller_UA",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller UK(United Kingdom) GB-230
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_GB",
                ResourceKey = "Neteller_GB",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller UK(United Kingdom) 2 GB-230
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_GB_2",
                ResourceKey = "Neteller_GB_2",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Neteller Uruguay UY-233
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_UY",
                ResourceKey = "Neteller_UY",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });


            // Neteller 1-Pay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Neteller_1Pay",
                ResourceKey = "Neteller_1Pay",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Neteller,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Neteller Deposit" },
            });

            // Voucher
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Voucher",
                ResourceKey = "Voucher",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.Voucher,
                SupportWithdraw = false,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // QVoucher
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "QVoucher",
                ResourceKey = "QVoucher",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.QVoucher,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ClickandBuy
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ClickandBuy",
                ResourceKey = "ClickandBuy",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ClickandBuy,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Click2Pay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Click2Pay",
                ResourceKey = "Click2Pay",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Click2Pay,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Ukash
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Ukash",
                ResourceKey = "Ukash",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.Ukash,
                SupportWithdraw = true,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Ukash Deposit" },
            });

            // BoCash
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "BoCash",
                ResourceKey = "BoCash",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.BoCash,
                SupportWithdraw = false,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny BoCash Deposit" },
            });

            // IPSToken
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "IPSToken",
                ResourceKey = "IPSToken",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.IPSToken,
                SupportWithdraw = true,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny IPSToken Deposit" },
            });

            // Paysafecard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Paysafecard",
                ResourceKey = "Paysafecard",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.Paysafecard,
                SupportWithdraw = false,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Paysafecard Deposit" },
            });

            // BankTransfer
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "BankTransfer",
                ResourceKey = "BankTransfer",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.Bank,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // CEPBank
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "CEPBank",
                ResourceKey = "CEPBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.Bank,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            #region Moneybookers
            // Moneybookers
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers",
                ResourceKey = "Moneybookers",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Credit Card
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_CreditCard",
                ResourceKey = "Moneybookers_CreditCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "ACC",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - VISA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_VISA",
                ResourceKey = "Moneybookers_VISA",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "VSA",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - MasterCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_MasterCard",
                ResourceKey = "Moneybookers_MasterCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "MSC",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - VISA Debit
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_VISA_Debit",
                ResourceKey = "Moneybookers_VISA_Debit",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "VSD",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - VISA Electron
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_VISA_Electron",
                ResourceKey = "Moneybookers_VISA_Electron",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "VSE",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Diners
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Diners",
                ResourceKey = "Moneybookers_Diners",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "VIN",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Maestro
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Maestro",
                ResourceKey = "Moneybookers_Maestro",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "MAE",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Solo
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Solo",
                ResourceKey = "Moneybookers_Solo",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "SLO",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Laser
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Laser",
                ResourceKey = "Moneybookers_Laser",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "LSR",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - CartaSi
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_CartaSi",
                ResourceKey = "Moneybookers_CartaSi",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "CSI",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - PostePay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_PostePay",
                ResourceKey = "Moneybookers_PostePay",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "PSP",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            /*
            // Moneybookers - 4B
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_4B",
                ResourceKey = "Moneybookers_4B",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "???",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */


            // Moneybookers - Euro6000
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Euro6000",
                ResourceKey = "Moneybookers_Euro6000",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "???",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            // Moneybookers - Dankort
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Dankort",
                ResourceKey = "Moneybookers_Dankort",
                Category = PaymentMethodCategory.DebitCard,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "DNK",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - GiroPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_GiroPay",
                ResourceKey = "Moneybookers_GiroPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "GIR",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - ELV
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_ELV",
                ResourceKey = "Moneybookers_ELV",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "DID",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Sofort
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Sofort",
                ResourceKey = "Moneybookers_Sofort",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "SFT",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Nordea Swedish
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Nordea_Swedish",
                ResourceKey = "Moneybookers_Nordea_Swedish",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "EBT",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Nordea Finland
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Nordea_Finland",
                ResourceKey = "Moneybookers_Nordea_Finland",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "SO2",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Bank
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Bank",
                ResourceKey = "Moneybookers_Bank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "SFT",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - IDeal
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_IDeal",
                ResourceKey = "Moneybookers_IDeal",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "IDL",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - ePayBg
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_ePayBg",
                ResourceKey = "Moneybookers_ePayBg",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "EPY",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - ENets
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_ENets",
                ResourceKey = "Moneybookers_ENets",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "ENT",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Poli
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Poli",
                ResourceKey = "Moneybookers_Poli",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "PLI",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Moneybookers - Przelewy24
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_Przelewy24",
                ResourceKey = "Moneybookers_Przelewy24",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SubCode = "PWY",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
            #endregion Moneybookers

            // Skrill 1-Tap
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Moneybookers_1Tap",
                ResourceKey = "Moneybookers_1Tap",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Moneybookers,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy",
                ResourceKey = "Envoy",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BANKTRANSFER",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - BOLETO
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_BOLETO",
                ResourceKey = "Envoy_BOLETO",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BOLETO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - IDeal
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_IDeal",
                ResourceKey = "Envoy_IDeal",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "IDEAL",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Przelewy24
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Przelewy24",
                ResourceKey = "Envoy_Przelewy24",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "PRZELEWY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Poli
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Poli",
                ResourceKey = "Envoy_Poli",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "POLI",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Poli - NEW ZEALAND 
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Poli_NewZealand",
                ResourceKey = "Envoy_Poli",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "POLINZ",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - ABAQOOS
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_ABAQOOS",
                ResourceKey = "Envoy_ABAQOOS",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "ABAQOOS",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - U|Net
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_UNet",
                ResourceKey = "Envoy_UNet",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BANKLINK",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Swedbank
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Swedbank",
                ResourceKey = "Envoy_Swedbank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BANKLINKSWED",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Sofort
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Sofort",
                ResourceKey = "Envoy_Sofort",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "SOFORT",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Moneta
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Moneta",
                ResourceKey = "Envoy_Moneta",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "MONETA",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - eKonto
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_eKonto",
                ResourceKey = "Envoy_eKonto",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EKONTO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            /*
            // Envoy - eWire - Denmark
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_eWire_Denmark",
                ResourceKey = "Envoy_eWire",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EWIREDK",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */

            /* Removed requested by Ebru Kesvin
            // Envoy - eWire - Norway
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_eWire_Norway",
                ResourceKey = "Envoy_eWire",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EWIRENO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */

            /*
            // Envoy - eWire - Sweden
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_eWire_Sweden",
                ResourceKey = "Envoy_eWire",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EWIRESE",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */

            // Envoy - Euteller
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Euteller",
                ResourceKey = "Envoy_Euteller",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EUTELLER",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - WebMoney
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_WebMoney",
                ResourceKey = "Envoy_WebMoney",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "WEBMONEY",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny WebMoney Deposit" },
            });

            // Envoy - MULTIBANCO
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_MultiBanco",
                ResourceKey = "Envoy_MultiBanco",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "MULTIBANCO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - TELEINGRESO
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Teleingreso",
                ResourceKey = "Envoy_Teleingreso",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "TELEINGRESO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - EPS
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_EPS",
                ResourceKey = "Envoy_EPS",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EPS",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - GiroPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_GiroPay",
                ResourceKey = "Envoy_GiroPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "GIROPAY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Instadebit
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_InstaDebit",
                ResourceKey = "Envoy_InstaDebit",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "INSTADEBIT",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Instadebit Deposit" },
            });

            // Envoy - NORDEA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Nordea",
                ResourceKey = "Envoy_Nordea",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BANKLINKNORDEA",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - NEOSURF
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Neosurf",
                ResourceKey = "Envoy_Neosurf",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "NEOSURF",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - DINEROMAIL
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_DineroMail",
                ResourceKey = "Envoy_DineroMail",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "DINEROMAIL",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - TODITOCARD
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_ToditoCard",
                ResourceKey = "Envoy_ToditoCard",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "TODITOCARD",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - LOBANET
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_LobaNet",
                ResourceKey = "Envoy_LobaNet",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "LOBANET",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - CUENTADIGITAL
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_CuentaDigital",
                ResourceKey = "Envoy_CuentaDigital",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "CUENTADIGITAL",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            /*
            // Envoy - SANTANDER
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Santander",
                ResourceKey = "Envoy_Santander",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BANCOSANTANDER",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */

            // Envoy - GluePay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_GluePay",
                ResourceKey = "Envoy_GluePay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "GLUEPAY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - ePayBg
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_ePayBg",
                ResourceKey = "Envoy_ePayBg",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "EPAY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - CashU
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_CashU",
                ResourceKey = "Envoy_CashU",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "CASHU",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - PAGOFACIL
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_PagoFacil",
                ResourceKey = "Envoy_PagoFacil",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "PAGOFACIL",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            /*
            // Envoy - Swiff
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Swiff",
                ResourceKey = "Envoy_Swiff",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "SWIFF",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */

            // Envoy - FundSend
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_FundSend",
                ResourceKey = "Envoy_FundSend",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "FUNDSEND",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - AGMO
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_AGMO",
                ResourceKey = "Envoy_AGMO",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "AGMO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - TrustPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_TrustPay",
                ResourceKey = "Envoy_TrustPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "TRUSTPAY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            /* Removed on 2013-03-29, requested by Catalin.R
            // Envoy - Baloto
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Baloto",
                ResourceKey = "Envoy_Baloto",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "BALOTO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             * */

            // Envoy - SpeedCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_SpeedCard",
                ResourceKey = "Envoy_SpeedCard",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "SPEEDCARD",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny SpeedCard Deposit" },
            });

            // Envoy - Qiwi
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_Qiwi",
                ResourceKey = "Envoy_Qiwi",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "QIWI",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - AstroPayCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_AstroPayCard",
                ResourceKey = "Envoy_AstroPayCard",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "ASTROPAYCARD",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - PaySafeCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_PaySafeCard",
                ResourceKey = "Envoy_PaySafeCard",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "PAYSAFECARD",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - UkashHosted
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_UkashHosted",
                ResourceKey = "Envoy_UkashHosted",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "UKASHHOSTED",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - UseMyServices
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_UseMyServices",
                ResourceKey = "Envoy_UseMyServices",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "USEMYBANK",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - PayU
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_PayU",
                ResourceKey = "Envoy_PayU",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "PAYU",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - SafetyPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_SafetyPay",
                ResourceKey = "Envoy_SafetyPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "SAFETYPAY_PPRO",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - SporoPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_SporoPay",
                ResourceKey = "Envoy_SporoPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "SPOROPAY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Envoy - Yandex.Money 
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_YANDEXMONEY",
                ResourceKey = "Envoy_YANDEXMONEY",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "YANDEXMONEY",
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // Envoy - Mister Cash
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Envoy_MisterCash",
                ResourceKey = "Envoy_MisterCash",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Envoy,
                SubCode = "MISTERCASH",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // DotPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "DotPay",
                ResourceKey = "DotPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Dotpay,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // DotpaySMS
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "DotpaySMS",
                ResourceKey = "DotpaySMS",
                Category = PaymentMethodCategory.MobilePayment,
                VendorID = GamMatrixAPI.VendorID.DotpaySMS,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // DotpaySMS - PlayCoins
            /*
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Dotpay_PlayCoins",
                ResourceKey = "Dotpay_PlayCoins",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.DotpaySMS,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });
             */

            // DotpaySMS - Ukash
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Dotpay_Ukash",
                ResourceKey = "Dotpay_Ukash",
                SubCode = "22",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.Dotpay,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Intercash
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Intercash",
                ResourceKey = "Intercash",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.Intercash,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // EcoCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "EcoCard",
                ResourceKey = "EcoCard",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.EcoCard,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            ///////////////////////////////////////////////////////////
            // ICEPAY - IDeal
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_IDeal",
                ResourceKey = "ICEPAY_IDeal",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            // ICEPAY - AMEX
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_AMEX",
                ResourceKey = "ICEPAY_AMEX",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                SubCode = "AMEX",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - MASTER
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_MASTER",
                ResourceKey = "ICEPAY_MASTER",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                SubCode = "MASTER",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - VISA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_VISA",
                ResourceKey = "ICEPAY_VISA",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                SubCode = "VISA",
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - GIROPAY
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_GIROPAY",
                ResourceKey = "ICEPAY_GIROPAY",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - PAYSAFECARD
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PAYSAFECARD",
                ResourceKey = "ICEPAY_PAYSAFECARD",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - PAYPAL
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PAYPAL",
                ResourceKey = "ICEPAY_PAYPAL",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_MISTERCASH
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_MISTERCASH",
                ResourceKey = "ICEPAY_MISTERCASH",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_DDEBIT
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_DDEBIT",
                ResourceKey = "ICEPAY_DDEBIT",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            // ICEPAY - ICEPAY_WIRE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_WIRE",
                ResourceKey = "ICEPAY_WIRE",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - DIRECTEBANK
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_DIRECTEBANK",
                ResourceKey = "ICEPAY_DIRECTEBANK",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_SMS
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_SMS",
                ResourceKey = "ICEPAY_SMS",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE AT
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_AT",
                ResourceKey = "ICEPAY_PHONE_AT",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE AU
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_AU",
                ResourceKey = "ICEPAY_PHONE_AU",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE BE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_BE",
                ResourceKey = "ICEPAY_PHONE_BE",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE CA
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_CA",
                ResourceKey = "ICEPAY_PHONE_CA",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_CZ",
                ResourceKey = "ICEPAY_PHONE_CZ",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_DE",
                ResourceKey = "ICEPAY_PHONE_DE",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_ES",
                ResourceKey = "ICEPAY_PHONE_ES",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_FR",
                ResourceKey = "ICEPAY_PHONE_FR",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_IT",
                ResourceKey = "ICEPAY_PHONE_IT",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_LU",
                ResourceKey = "ICEPAY_PHONE_LU",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_NL",
                ResourceKey = "ICEPAY_PHONE_NL",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_PL",
                ResourceKey = "ICEPAY_PHONE_PL",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_PT",
                ResourceKey = "ICEPAY_PHONE_PT",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_GB",
                ResourceKey = "ICEPAY_PHONE_GB",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ICEPAY - ICEPAY_PHONE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ICEPAY_PHONE_US",
                ResourceKey = "ICEPAY_PHONE_US",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.ICEPAY,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            // GeorgianCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "GeorgianCard",
                ResourceKey = "GeorgianCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.GeorgianCard,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // GeorgianCard ATM
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "GeorgianCard_ATM",
                ResourceKey = "GeorgianCard_ATM",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.GeorgianCard,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Pay.GE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PayGE",
                ResourceKey = "PayGE",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PayGE,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // TODITOCARD
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ToditoCard",
                ResourceKey = "ToditoCard",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.ToditoCard,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PayAnyWay_Moneta",
                ResourceKey = "PayAnyWay_Moneta",
                SubCode = "1015",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.PayAnyWay,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PayAnyWay_Yandex",
                ResourceKey = "PayAnyWay_Yandex",
                SubCode = "1020",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.PayAnyWay,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PayAnyWay_WebMoney",
                ResourceKey = "PayAnyWay_WebMoney",
                SubCode = "1017",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.PayAnyWay,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TLNakit",
                ResourceKey = "TLNakit",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.TLNakit,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny TLNakit" },
            });

            ///////////////////////////////////////////////////////////
            // ArtemisBet special payment methods
            /*
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ArtemisCard",
                ResourceKey = "ArtemisCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.ArtemisCard,
                SupportWithdraw = false,
            });
             * */

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ArtemisSMS_Akbank",
                ResourceKey = "ArtemisSMS_Akbank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ArtemisSMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ArtemisSMS_Garanti",
                ResourceKey = "ArtemisSMS_Garanti",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ArtemisSMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ArtemisSMS_Isbank",
                ResourceKey = "ArtemisSMS_Isbank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ArtemisSMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ArtemisSMS_YapiKredi",
                ResourceKey = "ArtemisSMS_YapiKredi",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.ArtemisSMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // ArtemisBank is only for withdrawal
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "ArtemisBank",
                ResourceKey = "ArtemisBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.ArtemisBank,
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeySMS_Akbank",
                ResourceKey = "TurkeySMS_Akbank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.TurkeySMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeySMS_Garanti",
                ResourceKey = "TurkeySMS_Garanti",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.TurkeySMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeySMS_Isbank",
                ResourceKey = "TurkeySMS_Isbank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.TurkeySMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeySMS_Yapikredi",
                ResourceKey = "TurkeySMS_Yapikredi",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.TurkeySMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeySMS_Havalesi",
                ResourceKey = "TurkeySMS_Havalesi",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.TurkeySMS,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeyBankWire",
                ResourceKey = "TurkeyBankWire",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.TurkeyBankWire,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TurkeyBank",
                ResourceKey = "TurkeyBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.TurkeyBank,
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            //EnterCash
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "EnterCash_OnlineBank",
                ResourceKey = "EnterCash_OnlineBank",
                SubCode = "ONLINEBANK",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.EnterCash,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "EnterCash_WyWallet",
                ResourceKey = "EnterCash_WyWallet",
                SubCode = "WYWALLET",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.EnterCash,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "EnterCash_Siru",
                ResourceKey = "EnterCash_Siru",
                SubCode = "SIRU",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.EnterCash,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "EnterCashBank",
                ResourceKey = "EnterCashBank",
                SubCode = "BANK",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.EnterCash,
                SupportDeposit = false,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //Local Bank
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "LocalBank",
                ResourceKey = "LocalBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.LocalBank,
                SupportDeposit = true,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // Euteller
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Euteller",
                ResourceKey = "Euteller",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Euteller,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //UIPAS
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "UIPAS",
                ResourceKey = "UIPAS",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = GamMatrixAPI.VendorID.UiPas,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //InPay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "InPay",
                ResourceKey = "InPay",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.InPay,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //Trustly
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Trustly",
                ResourceKey = "Trustly",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.Trustly,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //IPG
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "IPG",
                ResourceKey = "IPG",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.IPG,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //APX
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "APX",
                ResourceKey = "APX",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.APX,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // APX_BankTransfer is only for withdrawal
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "APX_BankTransfer",
                ResourceKey = "APX_BankTransfer",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.APX,
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //GCE
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "GCE",
                ResourceKey = "GCE",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.GCE,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // AstroPayCard
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "AstroPayCard",
                ResourceKey = "AstroPayCard",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = GamMatrixAPI.VendorID.AstroPay,
                SupportWithdraw = false,
                IsCurrencyChangable = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //PugglePay
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PugglePay",
                ResourceKey = "PugglePay",
                Category = PaymentMethodCategory.MobilePayment,
                VendorID = GamMatrixAPI.VendorID.PugglePay,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //PaymentInside
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "PaymentInside",
                ResourceKey = "PaymentInside",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = GamMatrixAPI.VendorID.PaymentInside,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //TxtNation
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "TxtNation",
                ResourceKey = "TxtNation",
                Category = PaymentMethodCategory.MobilePayment,
                VendorID = GamMatrixAPI.VendorID.TxtNation,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            //E-pro
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Epro",
                ResourceKey = "Epro",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = GamMatrixAPI.VendorID.PaymentTrust,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix",
                ResourceKey = "MoneyMatrix",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "CreditCard",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit", "Deny Card Deposit" },
            });

            // Nets is only for withdrawal
            paymentMethods.Add(new PaymentMethod()
            {
                UniqueName = "Nets",
                ResourceKey = "Nets",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = GamMatrixAPI.VendorID.Nets,
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Trustly
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Trustly",
                ResourceKey = "MoneyMatrix_Trustly",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Trustly",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });


            // MoneyMatrix Epro_Cashlib
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Epro_Cashlib",
                ResourceKey = "MoneyMatrix_Epro_Cashlib",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "E-Pro.CashLib",
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - PayKasa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PayKasa",
                ResourceKey = "MoneyMatrix_PayKasa",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PayKasa",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - PayKwik
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PayKwik",
                ResourceKey = "MoneyMatrix_PayKwik",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PayKwik",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Ochapay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Ochapay",
                ResourceKey = "MoneyMatrix_Ochapay",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "OchaPay",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Otopay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_OtoPay",
                ResourceKey = "MoneyMatrix_OtoPay",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "OtoPay",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - i-Banq
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_IBanq",
                ResourceKey = "MoneyMatrix_IBanq",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "i-Banq",
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Visa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_Visa",
                ResourceKey = "MoneyMatrix_GPaySafe_Visa",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.Visa",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Mastercard
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_Mastercard",
                ResourceKey = "MoneyMatrix_GPaySafe_Mastercard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.Mastercard",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Paykasa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_PayKasa",
                ResourceKey = "MoneyMatrix_GPaySafe_PayKasa",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.PayKasa",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Cashixir
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_CashIxir",
                ResourceKey = "MoneyMatrix_GPaySafe_CashIxir",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.CashIxir",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Epaycode
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_EPayCode",
                ResourceKey = "MoneyMatrix_GPaySafe_EPayCode",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.EPayCode",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe GScash
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_GsCash",
                ResourceKey = "MoneyMatrix_GPaySafe_GsCash",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.GsCash",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Jeton
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_Jeton",
                ResourceKey = "MoneyMatrix_GPaySafe_Jeton",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.Jeton",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe InstantBankTransfer
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_InstantBankTransfer",
                ResourceKey = "MoneyMatrix_GPaySafe_InstantBankTransfer",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.InstantBankTransfer",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe Cepbank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_CepBank",
                ResourceKey = "MoneyMatrix_GPaySafe_CepBank",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.CepBank",
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix GPaysafe BankTransfer
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_GPaySafe_BankTransfer",
                ResourceKey = "MoneyMatrix_GPaySafe_BankTransfer",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "GPaySafe.BankTransfer",
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Offline Nordea
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Offline_Nordea",
                ResourceKey = "MoneyMatrix_Offline_Nordea",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Offline.Nordea",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Offline LocalBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Offline_LocalBank",
                ResourceKey = "MoneyMatrix_Offline_LocalBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Offline.LocalBank",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Skrill
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Skrill",
                ResourceKey = "MoneyMatrix_Skrill",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Skrill",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Skrill 1Tap
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Skrill_1Tap",
                ResourceKey = "MoneyMatrix_Skrill_1Tap",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Skrill",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix EcoPayz
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_EcoPayz",
                ResourceKey = "MoneyMatrix_EcoPayz",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "EcoPayz",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix PaySafeCard
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PaySafeCard",
                ResourceKey = "MoneyMatrix_PaySafeCard",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PaySafeCard",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Neteller
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Neteller",
                ResourceKey = "MoneyMatrix_Neteller",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Neteller",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera LithuanianCreditUnion
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_LithuanianCreditUnion",
                ResourceKey = "MoneyMatrix_Paysera_LithuanianCreditUnion",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.LithuanianCreditUnion",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera Dnb
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_Dnb",
                ResourceKey = "MoneyMatrix_Paysera_Dnb",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.Dnb",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera MedicinosBankas
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_MedicinosBankas",
                ResourceKey = "MoneyMatrix_Paysera_MedicinosBankas",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.MedicinosBankas",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SiauliuBankas
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SiauliuBankas",
                ResourceKey = "MoneyMatrix_Paysera_SiauliuBankas",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SiauliuBankas",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera Wallet
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_Wallet",
                ResourceKey = "MoneyMatrix_Paysera_Wallet",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.Wallet",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera CreditCards
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_CreditCards",
                ResourceKey = "MoneyMatrix_Paysera_CreditCards",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.CreditCards",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera WebMoney
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_WebMoney",
                ResourceKey = "MoneyMatrix_Paysera_WebMoney",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.WebMoney",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera InternationalPaymentInEuros
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_InternationalPaymentInEuros",
                ResourceKey = "MoneyMatrix_Paysera_InternationalPaymentInEuros",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.InternationalPaymentInEuros",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SwedbankLithuania
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SwedbankLithuania",
                ResourceKey = "MoneyMatrix_Paysera_SwedbankLithuania",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SwedbankLithuania",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SebLithuania
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SebLithuania",
                ResourceKey = "MoneyMatrix_Paysera_SebLithuania",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SebLithuania",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera NordeaLithuania
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_NordeaLithuania",
                ResourceKey = "MoneyMatrix_Paysera_NordeaLithuania",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.NordeaLithuania",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera CitadeleLithuania
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_CitadeleLithuania",
                ResourceKey = "MoneyMatrix_Paysera_CitadeleLithuania",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.CitadeleLithuania",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera DanskeLithuania
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_DanskeLithuania",
                ResourceKey = "MoneyMatrix_Paysera_DanskeLithuania",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.DanskeLithuania",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera Perlas
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_Perlas",
                ResourceKey = "MoneyMatrix_Paysera_Perlas",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.Perlas",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SwedbankLatvia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SwedbankLatvia",
                ResourceKey = "MoneyMatrix_Paysera_SwedbankLatvia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SwedbankLatvia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SebLatvia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SebLatvia",
                ResourceKey = "MoneyMatrix_Paysera_SebLatvia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SebLatvia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera NordeaLatvia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_NordeaLatvia",
                ResourceKey = "MoneyMatrix_Paysera_NordeaLatvia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.NordeaLatvia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera CitadeleLatvia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_CitadeleLatvia",
                ResourceKey = "MoneyMatrix_Paysera_CitadeleLatvia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.CitadeleLatvia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SwedbankEstonia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SwedbankEstonia",
                ResourceKey = "MoneyMatrix_Paysera_SwedbankEstonia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SwedbankEstonia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera SebEstonia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_SebEstonia",
                ResourceKey = "MoneyMatrix_Paysera_SebEstonia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.SebEstonia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera DanskeEstonia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_DanskeEstonia",
                ResourceKey = "MoneyMatrix_Paysera_DanskeEstonia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.DanskeEstonia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera NordeaEstonia
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_NordeaEstonia",
                ResourceKey = "MoneyMatrix_Paysera_NordeaEstonia",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.NordeaEstonia",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera Krediidipank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_Krediidipank",
                ResourceKey = "MoneyMatrix_Paysera_Krediidipank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.Krediidipank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera LhvBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_LhvBank",
                ResourceKey = "MoneyMatrix_Paysera_LhvBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.LhvBank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera BzwbkBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_BzwbkBank",
                ResourceKey = "MoneyMatrix_Paysera_BzwbkBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.BzwbkBank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera PekaoBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_PekaoBank",
                ResourceKey = "MoneyMatrix_Paysera_PekaoBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.PekaoBank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera PkoBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_PkoBank",
                ResourceKey = "MoneyMatrix_Paysera_PkoBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.PkoBank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera mBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_mBank",
                ResourceKey = "MoneyMatrix_Paysera_mBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.mBank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera AliorBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_AliorBank",
                ResourceKey = "MoneyMatrix_Paysera_AliorBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.AliorBank",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera Easypay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_Easypay",
                ResourceKey = "MoneyMatrix_Paysera_Easypay",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.Easypay",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix - Paysera BankTransfer
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Paysera_BankTransfer",
                ResourceKey = "MoneyMatrix_Paysera_BankTransfer",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Paysera.BankTransfer",
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Adyen Sofort
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Adyen_Sofort",
                ResourceKey = "MoneyMatrix_Adyen_Sofort",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Adyen.Sofort",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Adyen Giropay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Adyen_Giropay",
                ResourceKey = "MoneyMatrix_Adyen_Giropay",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Adyen.Giropay",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Adyen iDeal
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Adyen_iDeal",
                ResourceKey = "MoneyMatrix_Adyen_iDeal",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Adyen.iDeal",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Adyen ELV
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Adyen_ELV",
                ResourceKey = "MoneyMatrix_Adyen_ELV",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Adyen.ELV",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Adyen PayPal
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Adyen_PayPal",
                ResourceKey = "MoneyMatrix_Adyen_PayPal",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Adyen.PayPal",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Adyen SEPA
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Adyen_SEPA",
                ResourceKey = "MoneyMatrix_Adyen_SEPA",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Adyen.SEPA",
                SupportWithdraw = true,
                SupportDeposit = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix TLNakit
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_TLNakit",
                ResourceKey = "MoneyMatrix_TLNakit",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "TlNakit",
                SupportWithdraw = true,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix Zimpler
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Zimpler",
                ResourceKey = "MoneyMatrix_Zimpler",
                Category = PaymentMethodCategory.MobilePayment,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "Zimpler",
                SupportWithdraw = false,
                SupportDeposit = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix EnterPays Visa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_EnterPays_Visa",
                ResourceKey = "MoneyMatrix_EnterPays_Visa",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "EnterPays.Visa",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix EnterPays PayKasa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_EnterPays_PayKasa",
                ResourceKey = "MoneyMatrix_EnterPays_PayKasa",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "EnterPays.PayKasa",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix EnterPays InstantBankTransfer
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_EnterPays_InstantBankTransfer",
                ResourceKey = "MoneyMatrix_EnterPays_InstantBankTransfer",
                Category = PaymentMethodCategory.InstantBanking,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "EnterPays.InstantBankTransfer",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix EnterPays BankTransfer
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_EnterPays_BankTransfer",
                ResourceKey = "MoneyMatrix_EnterPays_BankTransfer",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "EnterPays.BankTransfer",
                SupportDeposit = false,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" },
            });

            // MoneyMatrix PPro EPS
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_EPS",
                ResourceKey = "MoneyMatrix_PPro_EPS",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Eps",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro GiroPay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_GiroPay",
                ResourceKey = "MoneyMatrix_PPro_GiroPay",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.GiroPay",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Ideal
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Ideal",
                ResourceKey = "MoneyMatrix_PPro_Ideal",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Ideal",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Sofort
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Sofort",
                ResourceKey = "MoneyMatrix_PPro_Sofort",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Sofort",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Bancontact
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Bancontact",
                ResourceKey = "MoneyMatrix_PPro_Bancontact",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.BanContact",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Multibanco
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Multibanco",
                ResourceKey = "MoneyMatrix_PPro_Multibanco",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.MultiBanco",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Przelewy24
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Przelewy24",
                ResourceKey = "MoneyMatrix_PPro_Przelewy24",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Przelewy24",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Qiwi
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Qiwi",
                ResourceKey = "MoneyMatrix_PPro_Qiwi",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Qiwi",
                SupportDeposit = true,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro TrustPay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_TrustPay",
                ResourceKey = "MoneyMatrix_PPro_TrustPay",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.TrustPay",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro MyBank
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_MyBank",
                ResourceKey = "MoneyMatrix_PPro_MyBank",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.MyBank",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Paysafecard
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Paysafecard",
                ResourceKey = "MoneyMatrix_PPro_Paysafecard",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.PaySafeCard",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro SafetyPay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_SafetyPay",
                ResourceKey = "MoneyMatrix_PPro_SafetyPay",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.SafetyPay",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Boleto
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Boleto",
                ResourceKey = "MoneyMatrix_PPro_Boleto",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Boleto",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro AstropayCard
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_AstropayCard",
                ResourceKey = "MoneyMatrix_PPro_AstropayCard",
                Category = PaymentMethodCategory.PrePaidCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.AstroPayCard",
                SupportDeposit = true,
                SupportWithdraw = false,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix PPro Sepa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_PPro_Sepa",
                ResourceKey = "MoneyMatrix_PPro_Sepa",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "PPro.Sepa",
                SupportDeposit = false,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix UPayCard
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_UPayCard",
                ResourceKey = "MoneyMatrix_UPayCard",
                Category = PaymentMethodCategory.Ewallet,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "UPayCard",
                SupportDeposit = true,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix Visa
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Visa",
                ResourceKey = "MoneyMatrix_Visa",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "CreditCard",
                SupportDeposit = true,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix MasterCard
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_MasterCard",
                ResourceKey = "MoneyMatrix_MasterCard",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "CreditCard",
                SupportDeposit = true,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            // MoneyMatrix Dankort
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_Dankort",
                ResourceKey = "MoneyMatrix_Dankort",
                Category = PaymentMethodCategory.CreditCard,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "CreditCard",
                SupportDeposit = true,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });


            // MoneyMatrix InPay
            paymentMethods.Add(new PaymentMethod
            {
                UniqueName = "MoneyMatrix_InPay",
                ResourceKey = "MoneyMatrix_InPay",
                Category = PaymentMethodCategory.BankTransfer,
                VendorID = VendorID.MoneyMatrix,
                SubCode = "InPay",
                SupportDeposit = false,
                SupportWithdraw = true,
                DenyAccessRoleNames = new string[] { "Deny Deposit" }
            });

            ////////////////////////////////////////////////////////////

            #endregion

            paymentMethods = LoadProperties(site, paymentMethods);

            bool enableCorePaymentVendorsCheck = SafeParseBoolString(Metadata.Get("/Metadata/Settings.EnableCorePaymentVendorsCheck"), false);
            if (enableCorePaymentVendorsCheck)
            {
                List<VendorID> activePaymentVendorIDs = GamMatrixClient.GetActivePaymentVendors(site).Where(pvi => pvi.Enable == true).Select(pvi => pvi.VendorID).ToList();
                paymentMethods = paymentMethods.Where(pm => activePaymentVendorIDs.Contains(pm.VendorID)).ToList();
            }

            List<string> dependedFiles = new List<string>();
            dependedFiles.Add(string.Format("~/Views/{0}/.config", site.DistinctName));
            if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                dependedFiles.Add(string.Format("~/Views/{0}/.config", site.TemplateDomainDistinctName));

            dependedFiles.Add(string.Format("~/Views/{0}/Metadata/Settings", site.DistinctName));
            if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                dependedFiles.Add(string.Format("~/Views/{0}/Metadata/Settings", site.TemplateDomainDistinctName));

            HttpRuntime.Cache.Insert(cacheKey
                , paymentMethods
                , new CacheDependencyEx(dependedFiles.ToArray(), true)
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );

            return paymentMethods;
        }

        private static List<PaymentMethod> LoadProperties(cmSite domain, List<PaymentMethod> paymentMethods)
        {
            var templateDomainExists = !string.IsNullOrEmpty(domain.TemplateDomainDistinctName);

            Func<string, string, Dictionary<string, bool>> getPaymentMethodsVisibility = (domainName, keyName) =>
            {
                if (string.IsNullOrEmpty(domainName))
                {
                    return null;
                }

                return TryDeserialize(
                    domain,
                    string.Format("~/Views/{0}/.config/{1}", domainName, keyName),
                    null,
                    new Dictionary<string, bool>());
            };

            var ordinalDictionary = TryDeserialize<Dictionary<string, int>>(domain, "~/Views/{0}/.config/PaymentMethods.Ordinal", null, new Dictionary<string, int>());
            
            var enableDictionary = getPaymentMethodsVisibility(domain.TemplateDomainDistinctName, "PaymentMethods.Visibility");
            var fallbackEnableDictionary = getPaymentMethodsVisibility(domain.TemplateDomainDistinctName, "PaymentMethods.FallbackVisibility");

            var visibilityDictionary = getPaymentMethodsVisibility(domain.DistinctName, "PaymentMethods.Visibility");
            var fallbackVisibilityDictionary = getPaymentMethodsVisibility(domain.DistinctName, "PaymentMethods.FallbackVisibility");

            foreach (var paymentMethod in paymentMethods)
            {
                int ordinal;
                if (ordinalDictionary.TryGetValue(paymentMethod.UniqueName, out ordinal))
                    paymentMethod.Ordinal = ordinal;

                #region Enability

                if (templateDomainExists)
                {
                    paymentMethod.IsDisabled = paymentMethod.VendorID == VendorID.MoneyMatrix;
                }
                
                bool enabled;
                if (templateDomainExists && enableDictionary.TryGetValue(paymentMethod.UniqueName, out enabled))
                {
                    paymentMethod.IsDisabled = !enabled;
                }

                bool fallbackEnabled;
                if (templateDomainExists && fallbackEnableDictionary.TryGetValue(paymentMethod.UniqueName, out fallbackEnabled))
                {
                    paymentMethod.IsDisabledDuringFallback = !fallbackEnabled;
                }
                else
                {
                    paymentMethod.IsDisabledDuringFallback = paymentMethod.IsDisabled;
                }

                #endregion

                #region Visibility

                paymentMethod.IsVisible = paymentMethod.VendorID != VendorID.MoneyMatrix;

                if (templateDomainExists)
                {
                    paymentMethod.IsVisible = !paymentMethod.IsDisabled;
                }

                bool visible;
                if (visibilityDictionary.TryGetValue(paymentMethod.UniqueName, out visible))
                {
                    paymentMethod.IsVisible = visible;
                }
                
                bool fallbackVisible;
                if (fallbackVisibilityDictionary.TryGetValue(paymentMethod.UniqueName, out fallbackVisible))
                {
                    paymentMethod.IsVisibleDuringFallback = fallbackVisible;
                }
                else
                {
                    paymentMethod.IsVisibleDuringFallback = paymentMethod.IsVisible;
                }

                #endregion

                paymentMethod.SupportedCountries = TryDeserialize<CountryList>(domain, "~/Views/{0}/.config/{1}.CountryList", paymentMethod, new CountryList());
                paymentMethod.SupportedCurrencies = TryDeserialize<CurrencyList>(domain, "~/Views/{0}/.config/{1}.CurrencyList", paymentMethod, new CurrencyList());
                paymentMethod.ProcessTime = TryDeserialize<ProcessTime>(domain, "~/Views/{0}/.config/{1}.ProcessTime", paymentMethod, ProcessTime.Variable);
                paymentMethod.DepositProcessFee = TryDeserialize<ProcessFee>(domain, "~/Views/{0}/.config/{1}.DepositProcessFee", paymentMethod, new ProcessFee() { ProcessFeeType = ProcessFeeType.Free });
                paymentMethod.WithdrawProcessFee = TryDeserialize<ProcessFee>(domain, "~/Views/{0}/.config/{1}.WithdrawProcessFee", paymentMethod, new ProcessFee() { ProcessFeeType = ProcessFeeType.Free });
                paymentMethod.SupportWithdraw = TryDeserialize<bool>(domain, "~/Views/{0}/.config/{1}.SupportWithdraw", paymentMethod, paymentMethod.SupportWithdraw);
                paymentMethod.RepulsivePaymentMethods = TryDeserialize<List<string>>(domain, "~/Views/{0}/.config/{1}.RepulsivePaymentMethods", paymentMethod, new List<string>());

                paymentMethod.WithdrawSupportedCountries = TryDeserialize<CountryList>(domain, "~/Views/{0}/.config/{1}.WithdrawCountryList", paymentMethod, new CountryList());

                paymentMethod.WithdrawLimitations = TryDeserialize<Dictionary<string, Range>>(domain, "~/Views/{0}/.config/{1}.WithdrawLimitations", paymentMethod, new Dictionary<string, Range>(StringComparer.InvariantCultureIgnoreCase));
                if (paymentMethod.WithdrawLimitations.Count == 0)
                {
                    Range range = TryDeserialize<Range>(domain, "~/Views/{0}/.config/{1}.WithdrawLimitation", paymentMethod, new Range() { Currency = "EUR" });
                    if (range.MaxAmount > 0.00M || range.MinAmount > 0.00M)
                        paymentMethod.WithdrawLimitations["EUR"] = range;
                }

                paymentMethod.DepositLimitations = TryDeserialize<Dictionary<string, Range>>(domain, "~/Views/{0}/.config/{1}.DepositLimitations", paymentMethod, new Dictionary<string, Range>(StringComparer.InvariantCultureIgnoreCase));
                if (paymentMethod.DepositLimitations.Count == 0)
                {
                    Range range = TryDeserialize<Range>(domain, "~/Views/{0}/.config/{1}.DepositLimitation", paymentMethod, new Range() { Currency = "EUR" });
                    if (range.MaxAmount > 0.00M || range.MinAmount > 0.00M)
                        paymentMethod.DepositLimitations["EUR"] = range;
                }

                paymentMethod.SimultaneousDepositLimit = TryDeserialize<int>(domain, "~/Views/{0}/.config/{1}.SimultaneousDepositLimit", paymentMethod, 0);
                paymentMethod.SupportWithdraw = TryDeserialize<bool>(domain, "~/Views/{0}/.config/{1}.SupportWithdraw", paymentMethod, paymentMethod.SupportWithdraw);
            }
            return paymentMethods;
        }

        public static List<PaymentMethodCoverage> LoadPaymentMethodsOperatorCoverage()
        {
            var sites = SiteManager.GetSites().Where(s => !SiteManager.IsSiteRootTemplate(s.DistinctName) && s.DistinctName != "System").OrderBy(s => s.DisplayName).ToList();
            var paymentMethods = GetPaymentMethods();
            var paymentsOperatorVisibility = new List<PaymentMethodCoverage>();

            foreach (var site in sites)
            {
                string path = string.Format("~/Views/{0}/.config/PaymentMethods.Visibility", site.DistinctName);
                var paymentsVisibility = TryDeserialize(site, path, null, new Dictionary<string, bool>());

                foreach (PaymentMethod paymentMethod in paymentMethods)
                {
                    bool visible;
                    if (paymentsVisibility.TryGetValue(paymentMethod.UniqueName, out visible) && visible)
                    {
                        paymentsOperatorVisibility.Add(new PaymentMethodCoverage(){
                            MethodUniqueName = paymentMethod.UniqueName,
                            SiteDisplayName = site.DisplayName,
                            SiteDistinctName = site.DistinctName,
                        });
                    }
                }
            }
            return paymentsOperatorVisibility;
        }

        private static T TryDeserialize<T>(cmSite domain, string pathFormat, PaymentMethod paymentMethod, T defaultValue)
        {
            BinaryFormatter bf = new BinaryFormatter();
            string path = HostingEnvironment.MapPath(string.Format(pathFormat
                , domain.DistinctName
                , paymentMethod == null ? string.Empty : paymentMethod.UniqueName)
                );
            if (File.Exists(path))
            {
                try
                {
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                    {
                        return (T)bf.Deserialize(fs);
                    }
                }
                catch
                {
                }
            }

            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
            {
                path = HostingEnvironment.MapPath(string.Format(pathFormat
                    , domain.TemplateDomainDistinctName
                    , paymentMethod == null ? string.Empty : paymentMethod.UniqueName)
                    );
                if (File.Exists(path))
                {
                    try
                    {
                        using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                        {
                            return (T)bf.Deserialize(fs);
                        }
                    }
                    catch
                    {
                    }
                }
            }
            return defaultValue;
        }

        public static T TryDeserialize<T>(cmSite domain, string path, T defaultValue)
        {
            BinaryFormatter bf = new BinaryFormatter();

            if (File.Exists(path))
            {
                try
                {
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                    {
                        return (T)bf.Deserialize(fs);
                    }
                }
                catch
                {
                }
            }

            return defaultValue;
        }

        private static bool GetRevisionInfo(string path, out string relativePath, out string name)
        {
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.CountryList"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.CurrencyList"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.ProcessTime"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.DepositLimitations"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.WithdrawLimitations"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.DepositProcessFee"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.WithdrawProcessFee"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.SupportWithdraw"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.WithdrawCountryList"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.RepulsivePaymentMethods"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/PaymentMethods.Ordinal"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/PaymentMethods.Visibility"
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/BankWithdrawalConfiguration"
            relativePath = null;
            name = null;

            string config = path.Substring(path.LastIndexOf("\\") + 1);
            relativePath = "/.config/" + config;
            if (config == "PaymentMethods.Ordinal")
            {
                name = "Payment Methods Ordinal";
                return true;
            }
            else if (config == "PaymentMethods.Visibility")
            {
                name = "Payment Methods Visibility";
                return true;
            }
            else if (config == "PaymentMethods.FallbackMode")
            {
                name = "Fallback Mode";
                return true;
            }
            else if (config == "PaymentMethods.FallbackVisibility")
            {
                name = "Payment Methods Fallback Visibility";
                return true;
            }
            else if (config == "BankWithdrawalConfiguration")
            {
                name = "Bank Withdrawal Configuration";
                return true;
            }
            else
            {
                string configName = config.Substring(config.LastIndexOf(".") + 1);
                switch (configName)
                {
                    case "CountryList":
                        name = "Supported Countries";
                        break;
                    case "CurrencyList":
                        name = "Supported Currencies";
                        break;
                    case "ProcessTime":
                        name = "Deposit Process Time";
                        break;
                    case "DepositLimitations":
                        name = "Deposit Limitation";
                        break;
                    case "WithdrawLimitations":
                        name = "Withdraw Limitation";
                        break;
                    case "DepositProcessFee":
                        name = "Deposit Process Fee";
                        break;
                    case "WithdrawProcessFee":
                        name = "Withdraw Process Fee";
                        break;
                    case "SupportWithdraw":
                        name = "Support Withdraw";
                        break;
                    case "WithdrawCountryList":
                        name = "Withdrawal Supported Countries";
                        break;
                    case "RepulsivePaymentMethods":
                        name = "Auto-hide if these methods available";
                        break;
                    default:
                        return false;
                }
                return true;
            }
        }

        private static void SaveObject(string path, object obj, string distinctName)
        {
            string relativePath;
            string name;
            GetRevisionInfo(path, out relativePath, out name);

            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            Revisions.BackupIfNotExists(site, path, relativePath, name);

            BinaryFormatter bf = new BinaryFormatter();
            using (FileStream fs = new FileStream(path, FileMode.OpenOrCreate, FileAccess.Write, FileShare.Delete | FileShare.ReadWrite))
            {
                fs.SetLength(0);
                bf.Serialize(fs, obj);
                fs.Flush();
            }

            Revisions.Backup(site, path, relativePath, name);
        }

        public static void SaveSupportCountry(string distinctName
            , string paymentMethodName
            , CountryList countryList
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.CountryList"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, countryList, distinctName);
        }


        public static void SaveSupportCurrency(string distinctName
            , string paymentMethodName
            , CurrencyList currencyList
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.CurrencyList"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, currencyList, distinctName);
        }

        public static void SaveDepositLimitations(string distinctName
            , string paymentMethodName
            , Dictionary<string, Range> depositLimits
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.DepositLimitations"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, depositLimits, distinctName);
        }


        public static void SaveWithdrawLimitations(string distinctName
            , string paymentMethodName
            , Dictionary<string, Range> withdrawLimits
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.WithdrawLimitations"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, withdrawLimits, distinctName);
        }


        public static void SaveProcessTime(string distinctName
            , string paymentMethodName
            , ProcessTime processTime
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.ProcessTime"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, processTime, distinctName);
        }


        public static void SaveDepositProcessFee(string distinctName
            , string paymentMethodName
            , ProcessFee processFee
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.DepositProcessFee"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, processFee, distinctName);
        }

        public static void SaveWithdrawProcessFee(string distinctName
            , string paymentMethodName
            , ProcessFee processFee
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.WithdrawProcessFee"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, processFee, distinctName);
        }

        public static void SaveSupportWithdraw(string distinctName
            , string paymentMethodName
            , bool withdrawSupport
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.SupportWithdraw"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, withdrawSupport, distinctName);
        }

        public static void SaveRepulsivePaymentMethods(string distinctName
            , string paymentMethodName
            , List<string> repulsivePaymentMethods
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.RepulsivePaymentMethods"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, repulsivePaymentMethods ?? new List<string>(), distinctName);
        }


        public static void SaveOrdinalDictionary(string distinctName
             , Dictionary<string, int> ordinalDictionary
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/PaymentMethods.Ordinal"
                , distinctName
                )
                );
            SaveObject(path, ordinalDictionary, distinctName);
        }
        
        public static void SaveVisibilityDictionary(string distinctName
             , Dictionary<string, bool> visibilityDictionary
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/PaymentMethods.Visibility"
                , distinctName
                )
                );
            SaveObject(path, visibilityDictionary, distinctName);
        }

        public static void SaveFallbackVisibilityDictionary(string distinctName
             , Dictionary<string, bool> visibilityDictionary
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/PaymentMethods.FallbackVisibility"
                , distinctName
                )
                );
            SaveObject(path, visibilityDictionary, distinctName);
        }

        public static void SaveBankWithdrawalConfiguration(string distinctName
             , Dictionary<long, BankWithdrawalCountryConfig> dic
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/BankWithdrawalConfiguration"
                , distinctName
                ));
            SaveObject(path, dic, distinctName);
        }


        public static Dictionary<long, BankWithdrawalCountryConfig> GetBankWithdrawalConfiguration(cmSite site = null)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format("PaymentMethodManager.GetBankWithdrawalConfiguration.{0}", site.DistinctName);
            Dictionary<long, BankWithdrawalCountryConfig> config = HttpRuntime.Cache[cacheKey] as Dictionary<long, BankWithdrawalCountryConfig>;
            if (config != null)
                return config;

            config = TryDeserialize<Dictionary<long, BankWithdrawalCountryConfig>>(site, "~/Views/{0}/.config/BankWithdrawalConfiguration", null, new Dictionary<long, BankWithdrawalCountryConfig>());

            List<string> dependencyFiles = new List<string>();
            dependencyFiles.Add(string.Format("~/Views/{0}/.config/BankWithdrawalConfiguration", site.DistinctName));
            if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                dependencyFiles.Add(string.Format("~/Views/{0}/.config/BankWithdrawalConfiguration", site.TemplateDomainDistinctName));

            HttpRuntime.Cache.Insert(cacheKey, config, new CacheDependencyEx(dependencyFiles.ToArray(), true));
            return config;
        }


        public static void SaveWithdrawSupportCountry(string distinctName
            , string paymentMethodName
            , CountryList countryList
            )
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.WithdrawCountryList"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, countryList, distinctName);
        }

        public static void SaveSimultaneousDepositLimit(string distinctName, string paymentMethodName, int simultaneousDepositLimit)
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}.SimultaneousDepositLimit"
                , distinctName
                , paymentMethodName)
                );
            SaveObject(path, simultaneousDepositLimit, distinctName);
        }

        public static bool GetFallbackMode(bool useCache = true)
        {
            var fallbackModeKey = "PaymentMethods.FallbackMode";

            var configValue = HttpRuntime.Cache[fallbackModeKey];
            if (useCache && configValue != null)
            {
                return (bool)configValue;
            }

            var site = SiteManager.GetSiteByDistinctName("Shared");
            if (site == null)
            {
                Logger.Warning(typeof(PaymentMethodManager).Name, "Site with name \"Shared\" does not exist. This will affect fallback mode");

                return false;
            }

            var fallbackMode = TryDeserialize(site, string.Format("~/Views/{0}/.config/{1}", site.DistinctName, fallbackModeKey), null, false);
            
            List<string> dependedFiles = new List<string>();
            dependedFiles.Add(string.Format("~/Views/{0}/.config", site.DistinctName));
            if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                dependedFiles.Add(string.Format("~/Views/{0}/.config", site.TemplateDomainDistinctName));

            Logger.Information(typeof(PaymentMethodManager).Name, "Caching fallback mode: \"{0}\"", fallbackMode);

            HttpRuntime.Cache.Insert(fallbackModeKey
               , fallbackMode
               , new CacheDependencyEx(dependedFiles.ToArray(), true)
               , DateTime.Now.AddHours(1)
               , Cache.NoSlidingExpiration
               );

            return fallbackMode;
        }

        public static void SaveFallbackMode(bool fallbackMode)
        {
            var site = SiteManager.GetSiteByDistinctName("Shared");
            if (site == null)
            {
                Logger.Warning(typeof(PaymentMethodManager).Name, "Site with name \"Shared\" does not exist. This will affect fallback mode");

                return;
            }

            var fallbackModeKey = "PaymentMethods.FallbackMode";
            
            SaveObject(
                HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/{1}", site.DistinctName, fallbackModeKey)),
                fallbackMode,
                site.DistinctName);
        }

        private static bool SafeParseBoolString(string text, bool defValue)
        {
            if (string.IsNullOrWhiteSpace(text))
                return defValue;

            text = text.Trim();

            if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return true;

            if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return false;

            return defValue;
        }
    }
}