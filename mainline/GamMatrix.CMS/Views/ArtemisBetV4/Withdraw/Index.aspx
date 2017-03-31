<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %> 
<script language="C#" type="text/C#" runat="server">
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
            && p.SupportedCountries.Exists(ProfileCommon.Current.UserCountryID));

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

        return paymentMethodNames.Select(n => allPaymentMethods.FirstOrDefault(p =>
        string.Equals(p.UniqueName, n, StringComparison.InvariantCultureIgnoreCase)))
        .Where(p => p != null && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID))
        .ToArray();
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/WithdrawPage/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/WithdrawPage/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="withdraw-wrapper" class="content-wrapper">

<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<%= this.GetMetadata(".Warning_Text") %>
<ui:Panel runat="server" ID="pnWithdraw">


<div id="withdraw-plus-container">
</div>

<div class="withdraw-table">
    <div class="row tableHead">
        <div class="col-1"><span><%= this.GetMetadata(".ListHeader_Type").SafeHtmlEncode()%></span></div>
        <div class="col-3"><span><%= this.GetMetadata(".ListHeader_Fee").SafeHtmlEncode()%></span></div>
        <div class="col-4"><span><%= this.GetMetadata(".ListHeader_Limits").SafeHtmlEncode()%></span></div>
    </div>

    <%
        bool isAlternate = false;
        foreach (PaymentMethod paymentMethod in GetWithdrawPaymentMethods())
        {
            
            isAlternate = !isAlternate;
            string url = this.Url.RouteUrl("Withdraw", new { @action = "Prepare", @paymentMethodName = paymentMethod.UniqueName });%>

        <a href="<%= url.SafeHtmlEncode() %>" title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" class="row payment-list-item-<%=paymentMethod.UniqueName %> <%= isAlternate ? "odd" : "" %>" data-uniquename="<%= paymentMethod.UniqueName.SafeHtmlEncode() %>" data-vendor="<%= paymentMethod.VendorID %>" data-resourcekey="<%= paymentMethod.ResourceKey.SafeHtmlEncode() %>">
            <div class="col-1">
                <span>
                    <img border="0" alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" />
                </span>
            </div>
            <div class="col-2">
                <div class="holderButton">
                    <span class="Button" title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" href="<%= url.SafeHtmlEncode() %>">
                        <%= this.GetMetadata(".WithdrawButtonText") %>
                    </span>
                </div>
                <div class="link">
                    <%= paymentMethod.GetWithdrawMessage().SafeHtmlEncode() %>
                </div>
            </div>
            <div class="col-3">
                <%= paymentMethod.WithdrawProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR") ).SafeHtmlEncode()%>
            </div>
            <div class="col-4">
                <%= GetLimitationHtml(paymentMethod) %>
            </div>
           </a>
        </div>

    <% } %>

</div>

</ui:Panel>
</div>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
  $(document).ready(function () {
        var url = '<%= this.Url.RouteUrl("Withdraw", new { @action = "WithdrawPlus" }).SafeJavascriptStringEncode()  %>';
        $('#withdraw-plus-container').load(url, function () {
            $('#withdraw-plus-container').fadeIn();
        });
    });
jQuery('body').addClass('WithdrawPage');
jQuery('.inner').addClass('ProfileContent WithdrawPage');
jQuery('.MainProfile').addClass('MainWithdraw');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');

setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
</script>
</ui:MinifiedJavascriptControl>

<%  Html.RenderPartial("IndexBodyPlus", this.ViewData ); %>
</asp:Content>

