using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.State;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Deposit.Prepare
{
    public class PrepareInPayViewModel : PayCardTransaction
    {
        public PayCardInfoRec ExistingPayCard { get; protected set; }

        public SelectList InPayBankList { get; protected set; }

        public PrepareInPayViewModel(PaymentMethod paymentMethod, Dictionary<string, string> stateVars)
            : base(paymentMethod, stateVars)
        {
            ExistingPayCard = PayCards.FirstOrDefault();

            List<InPayCountry> inPayCountries = null;
            try
            {
                inPayCountries = InPayClient.GetInPayCountryAndBanks();
            }
            catch (GmException ge)
            {
                var message = ge.TryGetFriendlyErrorMsg();
                if (message.IndexOf("SYS_1170", StringComparison.InvariantCultureIgnoreCase) >= 0)
                    inPayCountries = new List<InPayCountry>();
            }
            catch
            {
                throw;
            }

            if (inPayCountries.Count == 0)
            {
                InPayBankList = null;
                return;
            }
            
            var selectedValue = inPayCountries.FirstOrDefault().CountryCode;
            var userCountry = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID);
            if (userCountry != null)
                selectedValue = userCountry.ISO_3166_Alpha2Code;
            //selectedValue = "BA";

            var selectedCountry = inPayCountries.FirstOrDefault(c => c.CountryCode == selectedValue);
            if (selectedCountry == null)
            {
                selectedCountry = inPayCountries.FirstOrDefault(c => c.CountryCode == "DE");//default to DE, Germany
                if (selectedCountry == null)
                    InPayBankList = null;
            }

            var list = selectedCountry.Banks.Select(b => new { Key = b.ID, Value = b.Name }).ToList();
            InPayBankList = new SelectList(list, "Key", "Value");
        }

        protected override IEnumerable<PayCardInfoRec> RetrievePayCards()
        {
            return GamMatrixClient.GetPayCards(VendorID.InPay)
                .Where(p => p.IsDummy && p.ActiveStatus == ActiveStatus.Active)
                .OrderByDescending(c => c.Ins);
        }
    }
}
