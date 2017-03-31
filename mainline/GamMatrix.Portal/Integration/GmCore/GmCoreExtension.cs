using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using CM.Content;
using CM.Sites;
using Finance;
using GamMatrixAPI;

namespace GmCore
{
    /// <summary>
    /// Summary description for GmCoreExtension
    /// </summary>
    public static class GmCoreExtension
    {
        public static string GetDisplayName(this CurrencyData currencyData)
        {
            return Metadata.Get(string.Format("Metadata/Currency/{0}.Display_Name", currencyData.Code)).DefaultIfNullOrEmpty(currencyData.Name);
        }

        public static string GetSymbol(this CurrencyData currencyData)
        {
            return Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currencyData.Code))
                .DefaultIfNullOrEmpty(currencyData.Code);
        }

        public static List<CurrencyData> FilterForCurrentDomain(this List<CurrencyData> currencies)
        {
            List<string> paths = Metadata.GetChildrenPaths("/Metadata/Currency/")
                .Select(p => Path.GetFileNameWithoutExtension(p))
                .ToList();
            return currencies.Where(c => paths.Exists(p => string.Equals(p, c.Code, StringComparison.OrdinalIgnoreCase))).ToList();
        }


        public static string GetDisplayName(this VendorID vendorID)
        {
            return Metadata.Get(string.Format("Metadata/GammingAccount/{0}.Display_Name", vendorID.ToString())).DefaultIfNullOrEmpty(vendorID.ToString());
        }
        
        public static string GetLastErrorCode(this TransInfoRec transInfoRec)
        {
            if (string.IsNullOrEmpty(transInfoRec.LastErrorMessage))
            {
                return null;
            }

            var match = Regex.Match(transInfoRec.LastErrorMessage, @"\[(.*_.*)\]");

            if (match.Success && match.Groups.Count > 1)
            {
                return match.Groups[1].Value;
            }

            return null;
        }
        
        public static T Get<T>(this ReplyResponse replyResponse) where T : HandlerRequest
        {
            if (!replyResponse.Success)
            {
                // renew the session id if SYS_1010 occurs
                if (replyResponse.ErrorCode == "SYS_1010")
                {
                    Logger.Error("GmCore Login", "SYS_1010 error");
                    GamMatrixClient.RenewSessionID(SiteManager.Current
                        , SiteManager.Current.SecurityToken
                        , SiteManager.Current.ApiUsername
                        );
                }

                throw new GmException(replyResponse);
            }
            return replyResponse.Reply as T;
        }
    }

    public static class GmCoreMoneyMatrixExtensions
    {
        private const string MoneyMatrixPaymentMethodNamePrefix = "MoneyMatrix_";

        public static bool IsMoneyMatrixFakePayCard(this PayCardInfoRec payCard)
        {
            if (!IsMoneyMatrixApmPayCard(payCard))
            {
                return false;
            }

            return payCard.DisplaySpecificFields.FirstOrDefault(y => y.Key == "IsDummy") != null;
        }

        public static bool IsMoneyMatrixApmPayCard(this PayCardInfoRec payCard, string alternatePaymentMethodName)
        {
            if (!IsMoneyMatrixApmPayCard(payCard) || string.IsNullOrEmpty(alternatePaymentMethodName))
            {
                return false;
            }

            return payCard.CardName == alternatePaymentMethodName;
        }

        public static bool IsMoneyMatrixApmPayCard(this PayCardInfoRec payCard)
        {
            if (payCard == null || payCard.VendorID != VendorID.MoneyMatrix || payCard.IsDummy)
            {
                return false;
            }

            return payCard.BrandType == "Not CC" && !string.IsNullOrEmpty(payCard.CardName);
        }

        public static bool IsMoneyMatrixCreditCard(this PayCardInfoRec payCard)
        {
            if (payCard == null || payCard.VendorID != VendorID.MoneyMatrix || payCard.IsDummy)
            {
                return false;
            }

            return payCard.BrandType != "Not CC";
        }

        public static string GetMoneyMatrixMethodUniqueName(this PayCardInfoRec payCard)
        {
            if (payCard.IsMoneyMatrixCreditCard())
            {
                return "MoneyMatrix";
            }
            else if (payCard.IsMoneyMatrixApmPayCard())
            {
                return string.Format("{0}{1}", MoneyMatrixPaymentMethodNamePrefix, payCard.CardName.Replace(".", "_"));
            }
            else
            {
                return null;
            }
        }

        public static string GetMoneyMatrixMethodUniqueNameQuickDeposit(this PayCardInfoRec payCard)
        {
            if (payCard.IsMoneyMatrixCreditCard())
            {
                switch (payCard.CardName)
                {
                    case "VISA":
                        return MoneyMatrixPaymentMethodNamePrefix + "Visa";
                    case "MASTERCARD":
                        return MoneyMatrixPaymentMethodNamePrefix + "MasterCard";
                    case "DANKORT":
                        return MoneyMatrixPaymentMethodNamePrefix + "Dankort";
                    default:
                        return MoneyMatrixPaymentMethodNamePrefix.Replace("_", string.Empty);
                }
            }
            else if (payCard.IsMoneyMatrixApmPayCard())
            {
                return string.Format("{0}{1}", MoneyMatrixPaymentMethodNamePrefix, payCard.CardName.Replace(".", "_"));
            }
            else
            {
                return null;
            }
        }

        public static bool IsMoneyMatrixPaymentMethod(this PaymentMethod paymentMethod)
        {
            if (paymentMethod == null)
            {
                return false;
            }

            return paymentMethod
                .UniqueName
                .IndexOf(MoneyMatrixPaymentMethodNamePrefix, StringComparison.InvariantCultureIgnoreCase) > -1;
        }
    }
}