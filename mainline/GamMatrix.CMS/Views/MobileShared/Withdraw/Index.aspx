<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    protected bool IsV2DepositProcessEnabled()
    {
        return Settings.MobileV2.IsV2DepositProcessEnabled;
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
            if( max > 0.00M )
                MoneyHelper.SmoothCeilingAndFloor(ref min, ref max);

            if (limitation.MinAmount > 0.00M)
                html.AppendFormat( "<p>{0}</p>", string.Format(this.GetMetadata(".Min_Limit"), currency, min) );

            if (limitation.MaxAmount > 0.00M)
            {
                html.AppendFormat("<p>{0}</p>", string.Format(this.GetMetadata(".Max_Limit"), currency, max) );
            }
        }
        catch
        {
        }
        return html.ToString();
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


    private PaymentMethod[] GetWithdrawPaymentMethods()
    {
        List<PaymentMethod> allPaymentMethods = PaymentMethodManager.GetPaymentMethods().Where(p => p.SupportWithdraw
            && GmCore.DomainConfigAgent.IsWithdrawEnabled(p)
            && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID)
            ).ToList();
        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards();

        List<string> paymentMethodNames = new List<string>();

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

        if (payCards.Exists(p => p.VendorID == VendorID.Moneybookers
            && p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Moneybookers");
        }
        else if (Profile.IsInRole("Affiliate"))
        {
            paymentMethodNames.Add("Moneybookers");
        }

        // EcoCard
        if (payCards.Exists(p => p.VendorID == VendorID.EcoCard && p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("EcoCard");
        }
        // UKash
        if (IsUkashAllowed(payCards))
        {
            paymentMethodNames.Add("Ukash");
        }

        if (payCards.Exists(p => p.VendorID == VendorID.Neteller &&
            p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("Neteller");
        }
        else if (Profile.IsInRole("Affiliate"))
        {
            paymentMethodNames.Add("Neteller");
        }

        bool isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "BankTransfer", StringComparison.InvariantCultureIgnoreCase)
            // && p.IsAvailable
            && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
            );
        if( isAvailable )
            paymentMethodNames.Add("BankTransfer");

        // TLNakit
        if (payCards.Exists(p => p.VendorID == VendorID.TLNakit && p.IsDummy && p.SuccessDepositNumber > 0))
        {
            paymentMethodNames.Add("TLNakit");
        }

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


        //Trustly
        isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "Trustly", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID)
               );
        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.Trustly && p.IsDummy);
        if (isAvailable)
            paymentMethodNames.Add("Trustly");

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
        if (isAvailable)
        {

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(ProfileCommon.Current.UserID);
            isAvailable = !String.IsNullOrEmpty(user.PersonalID);
            if (isAvailable)
            {
                paymentMethodNames.Add("Nets");
                paymentMethodNames.Remove("BankTransfer");
            }
        }

        //MoneyMatrix
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );
        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.SuccessDepositNumber > 0 && !p.IsDummy);
        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix");

        //MoneyMatrix Visa
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Visa", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );
        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.CardName.Equals("visa", StringComparison.InvariantCultureIgnoreCase) && p.SuccessDepositNumber > 0 && !p.IsDummy);
        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Visa");

        //MoneyMatrix MasterCard
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_MasterCard", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );
        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.CardName.Equals("mastercard", StringComparison.InvariantCultureIgnoreCase) && p.SuccessDepositNumber > 0 && !p.IsDummy);
        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_MasterCard");

        //MoneyMatrix Dankort
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Dankort", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            );
        if (isAvailable)
            isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && (p.DisplayName.StartsWith("4571") || p.DisplayName.StartsWith("5019")) && p.SuccessDepositNumber > 0 && !p.IsDummy);
        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Dankort");

        //MoneyMatrix_PayKasa
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_PayKasa");

        //MoneyMatrix_IBanq
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_IBanq", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_IBanq");

        //MoneyMatrix_Offline_Nordea
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Offline_Nordea");

        //MoneyMatrix_Offline_Nordea
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Offline_LocalBank", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Offline_LocalBank");

        //MoneyMatrix_Adyen_SEPA
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Adyen_SEPA", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_Adyen_SEPA");

        //MoneyMatrix_InPay
        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_InPay", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable);

        if (isAvailable)
            paymentMethodNames.Add("MoneyMatrix_InPay");

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

        var hasMmPProQiwiSuccessDeposits = mMPayCards.Exists(p => p.CardName.Equals("PPro.Qiwi") && !p.IsDummy && p.SuccessDepositNumber > 0);

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PPro_Qiwi", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        if (isAvailable && hasMmPProQiwiSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_PPro_Qiwi");
        }

        #endregion

        #region PPro.Sepa

        var hasMmPProSuccessDeposits = mMPayCards.Exists(p => p.CardName.Contains("PPro") && !p.CardName.Equals("PPro.Qiwi") && !p.IsDummy && p.SuccessDepositNumber > 0);

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_PPro_Sepa", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        if (isAvailable && hasMmPProSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_PPro_Sepa");
        }

        #endregion

        #region UPayCard

        var hasMmUPayCardSuccessDeposits = mMPayCards.Exists(p => p.CardName.Equals("UPayCard") && !p.IsDummy && p.SuccessDepositNumber > 0);

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        if (isAvailable && hasMmUPayCardSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_UPayCard");
        }

        #endregion

        #region Paysera.Wallet

        var hasMmPayseraWalletSuccessDeposits = mMPayCards.Exists(p => p.CardName.Equals("Paysera.Wallet") && !p.IsDummy && p.SuccessDepositNumber > 0);

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Paysera_Wallet", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        if (isAvailable && hasMmPayseraWalletSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_Paysera_Wallet");
        }

        #endregion

        #region Paysera.BankTransfer

        var hasMmPayseraBankTransferSuccessDeposits = this.HasMmPayseraBankTransferSuccessDeposits(mMPayCards);

        isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "MoneyMatrix_Paysera_BankTransfer", StringComparison.InvariantCultureIgnoreCase) &&
            p.IsAvailable);

        if (isAvailable && hasMmPayseraBankTransferSuccessDeposits)
        {
            paymentMethodNames.Add("MoneyMatrix_Paysera_BankTransfer");
        }

        #endregion

        return paymentMethodNames.Select(n => allPaymentMethods.FirstOrDefault(p =>
        string.Equals(p.UniqueName, n, StringComparison.OrdinalIgnoreCase)))
        .Where(p => p != null && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID))
        .ToArray();
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

    public PaymentMethod[] LoadedWithdrawPaymentMethods;

    protected override void OnInit(EventArgs e)
    {
        LoadedWithdrawPaymentMethods = GetWithdrawPaymentMethods();
        base.OnInit(e);
    }
</script>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Box UserBox CenterBox WithdrawBox <%= (!IsV2DepositProcessEnabled() ? "" : "WithdrawBox_V2")%>" id="WithdrawBox">
	<div class="BoxContent WithdrawContent <%= (!IsV2DepositProcessEnabled() ? "" : "WithdrawContent_V2")%>" id="WithdrawContent">
        <% if (!IsV2DepositProcessEnabled()) { %>
    		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel() { FlowSteps = 4 }); %>
        <% } %>
		<div class="Box CenterBox OpenCategory CreditCards WithdrawCards <%= (!IsV2DepositProcessEnabled() ? "" : "WithdrawCards_V2")%>">
			<h2 class="GameCatTitle WithdrawCardsTitle <%= (!IsV2DepositProcessEnabled() ? "" : "WithdrawCardsTitle_V2")%>">
				<a class="GameCatLink" href="#">
					<span class="ToggleIcon"><span class="ToggleText">Toggle</span></span>
					<span class="CatIcon"><span class="CatIconText">Category:</span></span>
					<span class="GameCatText"><%= this.GetMetadata(".WithdrawOptions").SafeHtmlEncode() %></span>
				</a>
			</h2>
			<ol class="Container CardList<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> IconList<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> WithdrawCardsList WithdrawCardsList<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> Items-Count-<%= LoadedWithdrawPaymentMethods.Count() %>" id="WithdrawCreditCards">
                 <% if (IsV2DepositProcessEnabled()) { %>
                 <li class="WithdrawBack BackItem <%= (!IsV2DepositProcessEnabled() ? "" : "WithdrawBack_V2")%>">
                    <a class="SideMenuLink BackButton BackWithdraw" href="#">
                        <span class="ActionArrow icon-arrow-left"> </span>
                        <span class="ButtonIcon icon Hidden">&nbsp;</span>
                        <span class="ButtonText">Back</span>
                    </a>
                    <h3 class="DepositCategoryTitle"><%= this.GetMetadata(".WithdrawOptions").SafeHtmlEncode() %></h3>
                </li>
                 <% } %>
			<%
			bool isAlternate = false;
            int index = 0;
            if (LoadedWithdrawPaymentMethods.Length > 0) 
            {
			    foreach (PaymentMethod paymentMethod in LoadedWithdrawPaymentMethods)
			    {
                    index++; 
				    isAlternate = !isAlternate;
				    string url = this.Url.RouteUrl("Withdraw", new { @action = "Account", @paymentMethodName = paymentMethod.UniqueName });
				    %>
				    <li class="WithdrawCard<%= (!IsV2DepositProcessEnabled() ? " A" : "_V2")%> DepositItem<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> DepositCard<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> CardItem Col Item<%=(index).ToString() %>" data-uniquename="<%= paymentMethod.UniqueName.SafeHtmlEncode() %>">
					    <a class="Container DepositTitle<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> CardHeader W WithdrawHeader <%= (!IsV2DepositProcessEnabled() ? "" : "WithdrawHeader_V2")%>" href="<%= url.SafeHtmlEncode() %>" data-vendor="<%=paymentMethod.VendorID %>">
						    <%-- <span class="ActionArrow WithdrawActionIcon icon-arrow-right"></span> --%>
                            <span class="Icon DepositIcon<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%> WithdrawIcon<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%>">
                                <span class="IconWrapper DepositWrapper WithdrawIconWrapper<%= (!IsV2DepositProcessEnabled() ? "" : "_V2")%>">
                                    <img class="Card I" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" width="66" height="66" alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" />
                                </span>
                            </span>
						    <span class="CardText N"><%= paymentMethod.GetWithdrawMessage().SafeHtmlEncode() %></span>
						    <span class="CardDetails S">
							    <span class="DTF"><%= paymentMethod.WithdrawProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR") ).SafeHtmlEncode()%></span>
							    <span class="DTM"><%= GetLimitationHtml(paymentMethod) %></span>
						    </span>
					    </a>
				    </li>
			    <% } 
             %>
                <li>
                    <%: Html.ErrorMessage(this.GetMetadata(".NoPayment_Message"), true)%>
                </li>
            <% }%>
			</ol>
		</div>
	</div>
</div>

<script type="text/javascript">
	$(function () {
		$('.GameCatLink').click(function () {
			$(this)
				.closest('.CreditCards')
					.toggleClass('OpenCategory');
			return false;
		});
	});
	$(CMS.mobile360.Generic.init);
</script>

</asp:Content>

