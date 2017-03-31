using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.State;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit
{
    public class EnterCashBankSelectorViewModel
    {
        public PaymentMethod PaymentDetails { get; set; }

        private List<EnterCashRequestBankInfo> EnterCashBankInfos { get; set; }

        private List<EnterCashRequestBankInfo> GetEnterCashBankInfos()
        {
            if (EnterCashBankInfos != null)
                return EnterCashBankInfos;

            bool isBank = false;

            string depositTypeCode = this.PaymentDetails.SubCode;
            switch (depositTypeCode)
            {
                case "ONLINEBANK": // Finland - 79 FI & Sweden - 211 SE 
                    isBank = true;
                    if (CustomProfile.Current.UserCountryID == 79)
                    {
                        depositTypeCode = "BANK_BUTTON";

                    }
                    else if (CustomProfile.Current.UserCountryID == 211)
                        depositTypeCode = "BANK_REFCODE";
                    break;
                case "WYWALLET":
                case "SIRU":
                    break;
                default:
                    depositTypeCode = string.Empty;
                    break;
            }
            if (string.IsNullOrWhiteSpace(depositTypeCode))
                return new List<EnterCashRequestBankInfo>();

            List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();
            if (depositTypeCode.Equals("BANK_BUTTON", StringComparison.InvariantCultureIgnoreCase))
                list.RemoveAll(b => !b.ButtonDepositSupport);

            if (depositTypeCode.Equals("BANK_REFCODE", StringComparison.InvariantCultureIgnoreCase))
                list.RemoveAll(b => !b.ClearingHouse.Equals("SE", StringComparison.InvariantCultureIgnoreCase));

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);
            List<CurrencyData> currencies = GamMatrixClient.GetSupportedCurrencies();
            CountryInfo mobilePrefixCountry = CountryManager.GetAllCountries().FirstOrDefault(c => c.PhoneCode.Equals(user.MobilePrefix, StringComparison.InvariantCultureIgnoreCase));

            if (currencies == null || mobilePrefixCountry == null)
                return new List<EnterCashRequestBankInfo>();

            EnterCashBankInfos = new List<EnterCashRequestBankInfo>();

            foreach (EnterCashRequestBankInfo bankInfo in list)
            {
                if (currencies.Exists(c => c.Code.Equals(bankInfo.Currency, StringComparison.InvariantCultureIgnoreCase))
                    && bankInfo.DepositTypes.Exists(t => t.Equals(depositTypeCode, StringComparison.InvariantCultureIgnoreCase))
                    && bankInfo.DepositSupport)
                {
                    if (this.PaymentDetails.UniqueName.Equals("EnterCash_Siru", StringComparison.InvariantCultureIgnoreCase))
                    {
                        if (bankInfo.ClearingHouse.Equals("INTERNATIONAL", StringComparison.InvariantCultureIgnoreCase)
                            || mobilePrefixCountry.ISO_3166_Alpha2Code.Equals(bankInfo.ClearingHouse, StringComparison.InvariantCultureIgnoreCase))
                        {
                            EnterCashBankInfos.Add(bankInfo);
                        }
                    }
                    else
                    {
                        EnterCashBankInfos.Add(bankInfo);
                    }
                }
            }

            return EnterCashBankInfos;
        }

        public string GetEnterCashBankInfoJson()
        {
            StringBuilder json = new StringBuilder();
            json.AppendLine("var enterCashBankInfos = {");

            var countries = CountryManager.GetAllCountries();

            foreach (EnterCashRequestBankInfo bank in this.GetEnterCashBankInfos())
            {
                var country = countries.FirstOrDefault(p => p.ISO_3166_Alpha2Code.Equals(bank.ClearingHouse, StringComparison.InvariantCultureIgnoreCase));

                json.AppendFormat(CultureInfo.InvariantCulture, "'{0}':{{Currency:'{1}', CountryCode:'{2}', PhoneCode:'{3}', DepositAmounts:[{4}]}},"
                    , bank.Id
                    , bank.Currency.SafeJavascriptStringEncode()
                    , bank.ClearingHouse.SafeJavascriptStringEncode()
                    , country.PhoneCode
                    , bank.DepositAmounts == null ? "" : bank.DepositAmounts.ConvertToCommaSplitedString()
                    );
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.AppendLine("};");
            return json.ToString();
        }

        public SelectList GetEnterCashBankList()
        {
            var list = this.GetEnterCashBankInfos().Select(b => new { Key = b.Id, Value = string.Format("{0} - {1}", b.Name, b.ClearingHouse) }).ToList();
            return new SelectList(list
                    , "Key"
                    , "Value"
                    );
        }


    }
}
