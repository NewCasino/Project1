using System;
using System.Linq;
using CM.Content;
using CM.db;
using CM.Sites;
using GamMatrixAPI;
using GmCore;

namespace Finance
{
    /// <summary>
    /// Summary description for FinanceExtension
    /// </summary>
    public static class FinanceExtension
    {
        public static string GetDisplayName(this PaymentMethodCategory paymentMethodCategory, cmSite domain = null, string culture = null)
        {
            if( domain == null )
                domain = SiteManager.Current;
            if( string.IsNullOrWhiteSpace(culture) )
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/PaymentMethodCategory/{0}.Display_Name", Enum.GetName(paymentMethodCategory.GetType(), paymentMethodCategory));
            return Metadata.Get( domain, path, culture);
        }

        public static string GetDisplayName(this ProcessTime processTime, cmSite domain = null, string culture = null)
        {
            if (domain == null)
                domain = SiteManager.Current;
            if (string.IsNullOrWhiteSpace(culture))
                culture = MultilingualMgr.GetCurrentCulture();

            string path = string.Format("/Metadata/ProcessTime.{0}", Enum.GetName(processTime.GetType(), processTime));
            return Metadata.Get(domain, path, culture);
        }

        /// <summary>
/* select distinct cardName from GmPayCard order by CardName
ENTROPAY
ELECTRON
MAESTRO
MAESTRO DOM
MAESTRO DOMESTIC
MAESTRO INTERNATIONAL
MASTERCARD CREDIT
MASTERCARD DEBIT
MCI CREDIT
MCI DEBIT
SOLO
VISA CREDIT
VISA DEBIT
VISA ELECTRON */


        /// </summary>
        /// <param name="payCard"></param>
        /// <param name="paymentMethodName"></param>
        /// <returns></returns>
        public static bool IsBelongsToPaymentMethod(this PayCardInfoRec payCard, string paymentMethodName)
        {
            if (payCard.VendorID == VendorID.PaymentTrust)
            {
                // determine by card name first
                if (!string.IsNullOrWhiteSpace(payCard.CardName))
                {
                    switch (payCard.CardName.ToUpperInvariant())
                    {
                        case "ENTROPAY":
                            return string.Equals(paymentMethodName, "PT_EntroPay", StringComparison.InvariantCultureIgnoreCase);
                        case "VISA CREDIT":
                            return string.Equals(paymentMethodName, "PT_VISA", StringComparison.InvariantCultureIgnoreCase);
                        case "VISA DEBIT":
                            return string.Equals(paymentMethodName, "PT_VISA_Debit", StringComparison.InvariantCultureIgnoreCase);
                        case "VISA ELECTRON":
                        case "ELECTRON":
                            return string.Equals(paymentMethodName, "PT_VISA_Electron", StringComparison.InvariantCultureIgnoreCase);
                        case "SOLO":
                            return string.Equals(paymentMethodName, "PT_Solo", StringComparison.InvariantCultureIgnoreCase) ||
                                string.Equals(paymentMethodName, "PT_Switch", StringComparison.InvariantCultureIgnoreCase);
                        default:
                            break;
                    }

                    if (payCard.CardName.StartsWith("MASTERCARD", StringComparison.InvariantCultureIgnoreCase) ||
                        payCard.CardName.StartsWith("MCI", StringComparison.InvariantCultureIgnoreCase))
                    {
                        return string.Equals(paymentMethodName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase);
                    }

                    if (payCard.CardName.StartsWith("MAESTRO", StringComparison.InvariantCultureIgnoreCase))
                    {
                        return string.Equals(paymentMethodName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase);
                    }
                }

                // if card name not match, check the BrandType
                if( !string.IsNullOrWhiteSpace(payCard.BrandType) )
                {
                    switch (payCard.BrandType.ToUpperInvariant())
                    {
                        case "VI":
                            return string.Equals(paymentMethodName, "PT_VISA", StringComparison.InvariantCultureIgnoreCase);
                        case "VE":
                            return string.Equals(paymentMethodName, "PT_VISA_Electron", StringComparison.InvariantCultureIgnoreCase);
                        case "VD":
                            return string.Equals(paymentMethodName, "PT_VISA_Debit", StringComparison.InvariantCultureIgnoreCase);
                        case "MC":
                        case "MD":
                            return string.Equals(paymentMethodName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase);
                        case "SO":
                            return string.Equals(paymentMethodName, "PT_Solo", StringComparison.InvariantCultureIgnoreCase);
                        case "SW":
                            return string.Equals(paymentMethodName, "PT_Switch", StringComparison.InvariantCultureIgnoreCase);
                    }
                }

                
                return string.Equals(paymentMethodName, "PT_VISA", StringComparison.InvariantCultureIgnoreCase);
            }

            return false;
        }
        
        public static string FormatBalanceAmount(this GamMatrixAPI.AccountData account)
        {
            return FormatBalanceAmount(account, true);
        }
        public static string FormatBalanceAmount(this GamMatrixAPI.AccountData account, bool displayBonusAmount)
        {
            string formatted = string.Format("{0:n2}", account.BalanceAmount);
            if (displayBonusAmount)
            {
                if(account.BonusAmount > 0.00M)
                    formatted += string.Format(" + {0:n2}", account.BonusAmount);
                if (account.OMBonusAmount > 0.00M)
                    formatted += string.Format(" + {0:n2}", account.OMBonusAmount);
                if (account.BetConstructBonusAmount > 0.00M)
                    formatted += string.Format(" + {0:n2}", account.BetConstructBonusAmount);
            }
            return formatted;
        }

        public static PaymentMethod GetPaymentMethod(this PayCardInfoRec payCard)
        {
            PaymentMethod paymentMethod = null;

            if (payCard.VendorID == VendorID.PaymentTrust)
            {
                string paymentMethodName = null;
                switch (payCard.CardName.ToUpper())
                {
                    case "ENTROPAY":
                        paymentMethodName = "PT_EntroPay";
                        break;
                    case "VISA CREDIT":
                        paymentMethodName = "PT_VISA";
                        break;
                    case "VISA DEBIT":
                        paymentMethodName = "PT_VISA_Debit";
                        break;
                    case "VISA ELECTRON":
                    case "ELECTRON":
                        paymentMethodName = "PT_VISA_Electron";
                        break;
                    case "SOLO":
                        paymentMethodName = "PT_Solo";
                        break;
                    default:
                        break;
                }

                if (payCard.CardName.StartsWith("MASTERCARD", StringComparison.InvariantCultureIgnoreCase) ||
                    payCard.CardName.StartsWith("MCI", StringComparison.InvariantCultureIgnoreCase))
                {
                    paymentMethodName = "PT_MasterCard";
                }

                if (payCard.CardName.StartsWith("MAESTRO", StringComparison.InvariantCultureIgnoreCase))
                {
                    paymentMethodName = "PT_Maestro";
                }
                paymentMethod = PaymentMethodManager.GetPaymentMethods().FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName));
            }
            else if (payCard.VendorID == VendorID.MoneyMatrix)
            {
                var paymentMethods = PaymentMethodManager.GetPaymentMethods();

                var uniqueName = payCard.GetMoneyMatrixMethodUniqueName();

                if (!string.IsNullOrEmpty(uniqueName))
                {
                    paymentMethod = paymentMethods.FirstOrDefault(p => p.UniqueName.Equals(uniqueName, StringComparison.CurrentCultureIgnoreCase));
                }
            }

            if (paymentMethod == null)
                paymentMethod = PaymentMethodManager.GetPaymentMethods().FirstOrDefault(p => p.VendorID == payCard.VendorID);

            return paymentMethod;
        }

        private const string MoneyMatrixPaymentMethodNamePrefix = "MoneyMatrix_";

        public static string ToCmsPaymentMethodName(this string moneyMatrixPaymentMethodName)
        {
            if (string.IsNullOrEmpty(moneyMatrixPaymentMethodName) || moneyMatrixPaymentMethodName.IndexOf(MoneyMatrixPaymentMethodNamePrefix, StringComparison.InvariantCultureIgnoreCase) > -1)
            {
                return null;
            }
            
            return string.Format("{0}{1}", MoneyMatrixPaymentMethodNamePrefix, moneyMatrixPaymentMethodName.Replace(".", "_"));
        }

        public static string ToMoneyMatrixPaymentMethodName(this string cmsPaymentMethodName)
        {
            if (string.IsNullOrEmpty(cmsPaymentMethodName) || cmsPaymentMethodName.IndexOf(MoneyMatrixPaymentMethodNamePrefix, StringComparison.InvariantCultureIgnoreCase) == -1)
            {
                return null;
            }

            return cmsPaymentMethodName.Replace(MoneyMatrixPaymentMethodNamePrefix, string.Empty).Replace("_", ".");
        }
    }
}