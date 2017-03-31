
<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Yahoo.Yui.Compressor" %>
<script language="C#" type="text/C#" runat="server">
    private List<PaymentMethod> _AllPaymentMethods = null;
    private List<PaymentMethod> AllPaymentMethods
    {
        get
        {
            if (_AllPaymentMethods == null)
            {
                _AllPaymentMethods = PaymentMethodManager.GetPaymentMethods().Where(p => p.SupportWithdraw
                    && GmCore.DomainConfigAgent.IsWithdrawEnabled(p)
                    && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID)
                    ).ToList();

                if (_AllPaymentMethods == null)
                    _AllPaymentMethods = new List<PaymentMethod>();
            }

            return _AllPaymentMethods;
        }
    }
    private string GetLimitationHtml(PaymentMethod paymentMethod)
    {
        string currency = this.ViewData.GetValue<string>("Currency", "EUR");
        if (string.IsNullOrWhiteSpace(currency))
            currency = "EUR";
        Range limitation = paymentMethod.GetWithdrawLimitation(currency);
        if (limitation == null || (limitation.MinAmount <= 0.00M && limitation.MaxAmount <= 0.00M))
        {
            return this.GetMetadata(".Variable").SafeHtmlEncode();
        }
        StringBuilder html = new StringBuilder();
        try
        {

            decimal min = limitation.MinAmount;
            decimal max = limitation.MaxAmount;
            if (max > 0.00M)
                MoneyHelper.SmoothCeilingAndFloor(ref min, ref max);

            if (limitation.MinAmount > 0.00M)
                html.AppendFormat(this.GetMetadata(".Min_Limit"), currency, min);

            if (limitation.MaxAmount > 0.00M)
            {
                if (html.Length > 0)
                    html.Append("<br />");
                html.AppendFormat(this.GetMetadata(".Max_Limit"), currency, max);
            }
        }
        catch
        {
        }

        return MoneyHelper.FormatCurrencySymbol(html.ToString());
    }

    private bool IsCreditCardWithdrawable(PayCardInfoRec payCard)
    {
        if (payCard.SuccessDepositNumber <= 0)
            return false;

        if (string.IsNullOrWhiteSpace(payCard.IssuerCountryCode))
            return true;

        var countries = CountryManager.GetAllCountries();
        var country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, payCard.IssuerCountryCode, StringComparison.InvariantCultureIgnoreCase));
        if (country == null)
            return true;

        return !country.RestrictCreditCardWithdrawal;
    }

    private bool IsUkashAllowed(List<PayCardInfoRec> payCards)
    {
        if (string.Equals(SiteManager.Current.DistinctName, "ArtemisBet", StringComparison.InvariantCultureIgnoreCase))
            return false;

        if (payCards.Exists(p => p.VendorID == VendorID.Ukash && p.SuccessDepositNumber > 0))
            return true;

        if (Profile.IsInRole("Verified Identity", "Withdraw only"))
            return true;

        string[] countries = Settings.Ukash_AllowWithdrawalCCIssueCountries;
        if (countries != null && countries.Length > 0)
        {
            if (payCards.Exists(p => p.VendorID == VendorID.PaymentTrust && p.SuccessDepositNumber > 0 && countries.Contains(p.IssuerCountryCode, StringComparer.InvariantCultureIgnoreCase)))
                return true;
        }

        return false;
    }

    public bool HasMmPayseraBankTransferSuccessDeposits(List<PayCardInfoRec> mMPayCards)
    {
        return mMPayCards.Exists(p => p.CardName.Equals("Paysera.LithuanianCreditUnion") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.MedicinosBankas") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SiauliuBankas") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.Dnb") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SwedbankLithuania") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SebLithuania") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.NordeaLithuania") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.CitadeleLithuania") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.DanskeLithuania") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SwedbankLatvia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SebLatvia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.NordeaLatvia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.CitadeleLatvia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SwedbankEstonia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.SebEstonia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.DanskeEstonia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.NordeaEstonia") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.Krediidipank") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.LhvBank") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.BzwbkBank") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.PekaoBank") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.PkoBank") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.mBank") && !p.IsDummy && p.SuccessDepositNumber > 0) ||
               mMPayCards.Exists(p => p.CardName.Equals("Paysera.AliorBank") && !p.IsDummy && p.SuccessDepositNumber > 0);
    }

    private PaymentMethod[] GetWithdrawPaymentMethods()
    {
        List<PaymentMethod> allPaymentMethods = PaymentMethodManager.GetPaymentMethods().Where(p => p.SupportWithdraw
            && GmCore.DomainConfigAgent.IsWithdrawEnabled(p)
            && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID)
            ).ToList();
        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards();

        List<string> paymentMethodNames = new List<string>();


        bool isAvailable = false;

        // PT
        if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_VISA") && IsCreditCardWithdrawable(p)))
            paymentMethodNames.Add("PT_VISA");
        if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_VISA_Debit") && IsCreditCardWithdrawable(p)))
            paymentMethodNames.Add("PT_VISA_Debit");
        if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_VISA_Electron") && IsCreditCardWithdrawable(p)))
            paymentMethodNames.Add("PT_VISA_Electron");
        if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_EntroPay") && IsCreditCardWithdrawable(p)))
            paymentMethodNames.Add("PT_EntroPay");
        if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_MasterCard") && IsCreditCardWithdrawable(p)))
            paymentMethodNames.Add("PT_MasterCard");

        // MB
        if (payCards.Exists(p => p.VendorID == VendorID.Moneybookers &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Moneybookers");
        }
        else if (Profile.IsInRole("Affiliate"))
        {
            paymentMethodNames.Add("Moneybookers");
        }
        else if (SiteManager.Current.DistinctName.Equals("IntraGame", StringComparison.InvariantCultureIgnoreCase)
            && Profile.UserCountryID == 166) // Norway
        {
            paymentMethodNames.Add("Moneybookers");
        }


        // Intercash
        if (payCards.Exists(p => p.VendorID == VendorID.Intercash))
        {
            if (payCards.Exists(p => p.VendorID == VendorID.Intercash && !p.IsDummy))
            {
                paymentMethodNames.Add("Intercash");
            }
            else if (Profile.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("Intercash");
            }
        }

        // EcoCard
        if (payCards.Exists(p => p.VendorID == VendorID.EcoCard && !p.IsDummy))
        {
            paymentMethodNames.Add("EcoCard");
        }

        // NETELLER
        bool isNetEllerAvailable = true;
        if (Profile.UserCountryID == 28
            && (SiteManager.Current.DistinctName.Equals("jetbull", StringComparison.InvariantCultureIgnoreCase)
                || SiteManager.Current.DistinctName.Equals("jetbullmobile", StringComparison.InvariantCultureIgnoreCase)
                || SiteManager.Current.DistinctName.Equals("jetbullRD", StringComparison.InvariantCultureIgnoreCase))
            ) //Belgium
        {
            isNetEllerAvailable = false;
        }

        if (isNetEllerAvailable)
        {
            if (payCards.Exists(p => p.VendorID == VendorID.Neteller &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Neteller");
            }
            else if (Profile.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("Neteller");
            }
        }

        // TLNakit
        if (payCards.Exists(p => p.VendorID == VendorID.TLNakit && p.IsDummy && p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("TLNakit");
        }


        //if (allPaymentMethods.Exists(p => p.IsAvailable && p.UniqueName.Equals("EnterCashBank", StringComparison.InvariantCultureIgnoreCase)))
        //{
        //    var enterCashBank = allPaymentMethods.FirstOrDefault(p => p.IsAvailable && p.UniqueName.Equals("EnterCashBank", StringComparison.InvariantCultureIgnoreCase));
        //    if (enterCashBank.SupportedCountries.Exists(Profile.UserCountryID))
        //    {
        //        paymentMethodNames.Add("EnterCashBank");
        //    }
        //}

        // Local Bank
        if (payCards.Exists(p => p.VendorID == VendorID.LocalBank && p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("LocalBank");
        }

        // Envoy One-Click Services
        if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
            string.Equals(p.BankName, "WEBMONEY", StringComparison.InvariantCultureIgnoreCase) &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Envoy_WebMoney");
        }
        else if (Profile.IsInRole("Affiliate"))
        {
            paymentMethodNames.Add("Envoy_WebMoney");
        }

        if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
            string.Equals(p.BankName, "MONETA", StringComparison.InvariantCultureIgnoreCase) &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Envoy_Moneta");
        }
        if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
            string.Equals(p.BankName, "INSTADEBIT", StringComparison.InvariantCultureIgnoreCase) &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Envoy_InstaDebit");
        }
        if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
            string.Equals(p.BankName, "SPEEDCARD", StringComparison.InvariantCultureIgnoreCase) &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Envoy_SpeedCard");
        }

        // UKash
        if (IsUkashAllowed(payCards))
        {
            paymentMethodNames.Add("Ukash");
        }

        // GEOGIAN CARD
        if (payCards.Exists(p => p.VendorID == VendorID.GeorgianCard &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("GeorgianCard");
        }
        else if (string.Equals(SiteManager.Current.DistinctName, "PlayAdjara", StringComparison.InvariantCultureIgnoreCase))
        {
            paymentMethodNames.Add("GeorgianCard");
        }

        // MENOTA
        if (payCards.Exists(p => p.VendorID == VendorID.PayAnyWay &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("PayAnyWay_Moneta");
            paymentMethodNames.Add("PayAnyWay_Yandex");
            paymentMethodNames.Add("PayAnyWay_WebMoney");
        }

        if (payCards.Exists(p => p.VendorID == VendorID.IPSToken &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("IPSToken");
        }


        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "GeorgianCard_ATM", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );
        if (isAvailable)
            paymentMethodNames.Add("GeorgianCard_ATM");

        isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "APX_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
                );

        if (isAvailable)
        {
            paymentMethodNames.Add("APX_BankTransfer");
        }

        // Bank
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "ArtemisBank", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );
        if (isAvailable)
            paymentMethodNames.Add("ArtemisBank");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "TurkeyBank", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
            );
        if (isAvailable)
            paymentMethodNames.Add("TurkeyBank");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "Trustly", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
            );
        if (isAvailable)
            paymentMethodNames.Add("Trustly");

        isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
                );
        if (isAvailable)
            paymentMethodNames.Add("BankTransfer");

        // UIPAS
        if (payCards.Exists(p => p.VendorID == VendorID.UiPas &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("UIPAS");
        }
        else if (Profile.IsInRole("Affiliate"))
        {
            paymentMethodNames.Add("UIPAS");
        }

        //IPG
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "IPG", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
            );
        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.IPG && p.SuccessDepositNumber > 0);
        if (isAvailable)
            paymentMethodNames.Add("IPG");

        //NETS
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "Nets", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
            );
        if (isAvailable){

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(ProfileCommon.Current.UserID);
            isAvailable = !String.IsNullOrEmpty(user.PersonalID);
            if (isAvailable)
            {
                paymentMethodNames.Add("Nets");
                paymentMethodNames.Remove("BankTransfer");
            }
        }

        // MoneyMatrix payment methods
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.SuccessDepositNumber > 0 && !p.IsDummy);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix");

        // MoneyMatrix_PayKasa
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_PayKasa");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_IBanq", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_IBanq");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_GPaySafe_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_GPaySafe_BankTransfer");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Offline_Nordea");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Offline_LocalBank", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Offline_LocalBank");

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Adyen_SEPA", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Adyen_SEPA");

        var mMPayCards = GamMatrixClient.GetMoneyMatrixPayCards();

        #region EnterPays.BankTransfer

        var hasMmEnterPaysSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("EnterPays") && !p.IsDummy && p.SuccessDepositNumber > 0);

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_EnterPays_BankTransfer", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        if (isAvailable && hasMmEnterPaysSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_EnterPays_BankTransfer");
        }

        #endregion

        #region EcoPayz

        isAvailable = allPaymentMethods.Exists(pm =>
            string.Equals(pm.UniqueName, "MoneyMatrix_EcoPayz", StringComparison.InvariantCultureIgnoreCase) &&
            pm.IsAvailable);

        if (isAvailable)
        {
            var hasMmEcoPayzSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("EcoPayz") && !p.IsDummy && p.SuccessDepositNumber > 0);

            var hasGmEcoCardSuccessDeposits = payCards.Exists(p => p.VendorID == VendorID.EcoCard && !p.IsDummy && p.SuccessDepositNumber > 0);

            if (hasMmEcoPayzSuccessDeposits || hasGmEcoCardSuccessDeposits)
            {
                paymentMethodNames.Add("MoneyMatrix_EcoPayz");
            }
        }

        #endregion

        #region PaySafeCard

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PaySafeCard", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
        {
            var hasMmPaySafeCardSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("PaySafeCard") && !p.IsDummy && p.SuccessDepositNumber > 0);

            var hasGmPaySafeCardSuccessDeposits = payCards.Exists(p => p.VendorID == VendorID.Paysafecard && p.IsDummy && p.SuccessDepositNumber > 0);
            
            if (hasMmPaySafeCardSuccessDeposits || hasGmPaySafeCardSuccessDeposits)
            {
                paymentMethodNames.Add("MoneyMatrix_PaySafeCard");
            }
        }

        #endregion

        #region Trustly

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
        {
            var hasMmTrustlySuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("Trustly") && !p.IsDummy && p.SuccessDepositNumber > 0);

            var hasGmTrustlySuccessDeposits = payCards.Exists(p => p.VendorID == VendorID.Trustly && p.SuccessDepositNumber > 0);

            if (hasMmTrustlySuccessDeposits || hasGmTrustlySuccessDeposits)
            {
                paymentMethodNames.Add("MoneyMatrix_Trustly");
            }
        }

        #endregion

        #region TlNakit

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_TlNakit", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
        {
            var hasMmTlNakitSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("TlNakit") && !p.IsDummy && p.SuccessDepositNumber > 0);

            var hasGmTlNakitSuccessDeposits = payCards.Exists(p => p.VendorID == VendorID.TLNakit && p.IsDummy && p.SuccessDepositNumber > 0);

            if (hasMmTlNakitSuccessDeposits || hasGmTlNakitSuccessDeposits)
            {
                paymentMethodNames.Add("MoneyMatrix_TlNakit");
            }
        }

        #endregion

        #region Skrill

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Skrill", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
        {
            var hasMmSkrillSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("Skrill") && !p.IsDummy && p.SuccessDepositNumber > 0);

            var hasGmSkrillSuccessDeposits = payCards.Exists(p => p.VendorID == VendorID.Moneybookers && !p.IsDummy && p.SuccessDepositNumber > 0);

            if (hasMmSkrillSuccessDeposits || hasGmSkrillSuccessDeposits)
            {
                paymentMethodNames.Add("MoneyMatrix_Skrill");
            }
        }

        #endregion

       #region InPay

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_InPay", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
        {
             paymentMethodNames.Add("MoneyMatrix_InPay");
        }

        #endregion

        #region Neteller

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Neteller", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
        {
            var hasMmNetellerSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("Neteller") && !p.IsDummy && p.SuccessDepositNumber > 0);

            var hasGmNetellerSuccessDeposits = payCards.Exists(p => p.VendorID == VendorID.Neteller && !p.IsDummy && p.SuccessDepositNumber > 0);

            if (hasMmNetellerSuccessDeposits || hasGmNetellerSuccessDeposits)
            {
                paymentMethodNames.Add("MoneyMatrix_Neteller");
            }
        }

        #endregion

        #region PPro.Qiwi

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PPro_Qiwi", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        var hasMmPProQiwiSuccessDeposits = mMPayCards.Exists(p => p.CardName.Equals("PPro.Qiwi") && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmPProQiwiSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_PPro_Qiwi");
        }

        #endregion

        #region PPro.Sepa

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PPro_Sepa", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        var hasMmPProSepaPayoutSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("PPro") && !p.CardName.Equals("PPro.Qiwi") && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmPProSepaPayoutSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_PPro_Sepa");
        }

        #endregion

        #region UPayCard

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        var hasMmUPayCardSuccessDeposits = mMPayCards.Exists(p => p.CardName.Equals("UPayCard") && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmUPayCardSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_UPayCard");
        }

        #endregion

         #region MoneyMatrix.Visa

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Visa", StringComparison.InvariantCultureIgnoreCase) && p.IsAvailable);

        var hasMmVisaSuccessDeposits = mMPayCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.CardName.Equals("visa", StringComparison.InvariantCultureIgnoreCase) && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmVisaSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_Visa");
        }

        #endregion

         #region MoneyMatrix.MasterCard

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_MasterCard", StringComparison.InvariantCultureIgnoreCase) && p.IsAvailable);

        var hasMmMasterCardSuccessDeposits = mMPayCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.CardName.Equals("mastercard", StringComparison.InvariantCultureIgnoreCase) && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmMasterCardSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_MasterCard");
        }

        #endregion

        #region MoneyMatrix.Dankort

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Dankort", StringComparison.InvariantCultureIgnoreCase) && p.IsAvailable);

        var hasMmDankortSuccessDeposits = mMPayCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && (p.DisplayName.StartsWith("5019") || p.DisplayName.StartsWith("4571")) && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmDankortSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_Dankort");
        }

        #endregion

        #region Paysera.Wallet

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Paysera_Wallet", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        var hasMmPayseraWalletPayoutSuccessDeposits = mMPayCards.Exists(p => p.CardName.Equals("Paysera.Wallet") && !p.IsDummy && p.SuccessDepositNumber > 0);

        if (isAvailable && hasMmPayseraWalletPayoutSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_Paysera_Wallet");
        }

        #endregion

        #region Paysera.BankTransfer

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Paysera_BankTransfer", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        var hasMmPayseraBankTransferPayoutSuccessDeposits = this.HasMmPayseraBankTransferSuccessDeposits(mMPayCards);

        if (isAvailable && hasMmPayseraBankTransferPayoutSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_Paysera_BankTransfer");
        }

        #endregion

        return paymentMethodNames.Select(n => allPaymentMethods.FirstOrDefault(p =>
        string.Equals(p.UniqueName, n, StringComparison.InvariantCultureIgnoreCase)))
        .Where(p => p != null && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID))
        .ToArray();
    }
</script>



<% PaymentMethod[] paymentMethods = GetWithdrawPaymentMethods();
if (paymentMethods.Length > 0) 
{ %>
<table cellpadding="0" cellspacing="0" border="0" class="withdraw-table">
    <thead>
        <tr>
            <th class="col-1" colspan="2"><span><%= this.GetMetadata(".ListHeader_Type").SafeHtmlEncode()%></span></th>
            <th class="col-3" align="center"><span><%= this.GetMetadata(".ListHeader_Fee").SafeHtmlEncode()%></span></th>
            <th class="col-4" align="center"><span><%= this.GetMetadata(".ListHeader_Limits").SafeHtmlEncode()%></span></th>
        </tr>
    </thead>
    <tbody>

        <%
            bool isAlternate = false;
            foreach (PaymentMethod paymentMethod in GetWithdrawPaymentMethods())
            {

                isAlternate = !isAlternate;
                string url = this.Url.RouteUrl("Withdraw", new { @action = "Prepare", @paymentMethodName = paymentMethod.UniqueName });%>

        <tr class="payment-list-item-<%=paymentMethod.UniqueName %> <%= isAlternate ? "odd" : "" %>" data-uniquename="<%= paymentMethod.UniqueName.SafeHtmlEncode() %>" data-vendor="<%= paymentMethod.VendorID %>" data-resourcekey="<%= paymentMethod.ResourceKey.SafeHtmlEncode() %>">
            <td class="col-1" valign="middle" align="center">
                <a href="<%= url.SafeHtmlEncode() %>" title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>">
                    <img border="0" alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" />
                </a>
            </td>
            <td class="col-2" valign="middle">
                <div class="wrap">
                    <div class="link">
                        <a title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" href="<%= url.SafeHtmlEncode() %>">
                            <%= paymentMethod.GetWithdrawMessage().SafeHtmlEncode() %>
                        </a>
                    </div>
                </div>
            </td>
            <td class="col-3" valign="middle" align="center">
                <%= MoneyHelper.FormatCurrencySymbol(paymentMethod.WithdrawProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR") )).SafeHtmlEncode()%>
            </td>
            <td class="col-4" valign="middle" align="center">
                <%= GetLimitationHtml(paymentMethod) %>
            </td>
        </tr>
        <tr class="payment-space">
                    <td class="col-full" colspan="4"></td>
                </tr>
        <% } %>
    </tbody>
    <tfoot>
        <tr>
            <td colspan="5"></td>
        </tr>
    </tfoot>
</table>
<% } 
else 
{ %>
<%: Html.ErrorMessage(this.GetMetadata(".NoPayment_Message"), true)%>
<% } %>