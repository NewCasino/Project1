<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<script language="C#" type="text/C#" runat="server">
    private string GetLimitationHtml(PaymentMethod paymentMethod)
    {
        string currency = this.ViewData.GetValue<string>("Currency", "EUR"); 
        Range range = paymentMethod.GetDepositLimitation(currency);
        
        if (range.MinAmount <= 0.00M && range.MaxAmount <= 0.00M)
        {
            return this.GetMetadata(".Variable").SafeHtmlEncode();
        }
        StringBuilder html = new StringBuilder();
        try
        {

            decimal min = MoneyHelper.TransformCurrency(range.Currency, currency, range.MinAmount);
            decimal max = MoneyHelper.TransformCurrency(range.Currency, currency, range.MaxAmount);
            MoneyHelper.SmoothCeilingAndFloor(ref min, ref max);

            if (range.MinAmount > 0.00M)
                html.AppendFormat(this.GetMetadata(".Min_Limit"), currency, min);

            if (range.MaxAmount > 0.00M)
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

    private PaymentMethod[] FilterPaymentMethods(PaymentMethod[] paymentMethods
        , PaymentMethodCategory paymentMethodCategory
        )
    {
        PaymentMethod[] query;
        if (paymentMethodCategory.ToString() == "InstantBanking")
        {
            query = paymentMethods.Where(p => p.Category == paymentMethodCategory && p.IsAvailable && p.SupportDeposit && DomainConfigAgent.IsVendorEnabled(p) && p.UniqueName != "APX").OrderBy(p => p.Ordinal).ToArray();
        }
        else if (paymentMethodCategory.ToString() == "BankTransfer")
        {
            query = paymentMethods.Where(p => p.Category == paymentMethodCategory && p.IsAvailable && p.SupportDeposit && DomainConfigAgent.IsVendorEnabled(p) || p.UniqueName == "APX").OrderByDescending(p => p.ProcessTime).ToArray();
        }
        else
        {
            query = paymentMethods.Where(p => p.Category == paymentMethodCategory && p.IsAvailable && p.SupportDeposit && DomainConfigAgent.IsVendorEnabled(p)).ToArray();
        }
        
        int countryID = this.ViewData.GetValue<int>("CountryID", -1);
        string currency = this.ViewData.GetValue<string>("Currency", "EUR");

        if (countryID > 0)
            query = query.Where(p => p.SupportedCountries.Exists(countryID)).ToArray();

        //if (!string.IsNullOrWhiteSpace(currency))
        //    query = query.Where(p => p.SupportedCurrencies.Exists(currency));

        if (Profile.IsAuthenticated) {
            if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.AstroPayCard_Ignore_DenyDepositCardRole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            {
                query = query.Where(p => !Profile.IsInRole(p.DenyAccessRoleNames)
                    || (p.UniqueName == "AstroPayCard" && !Profile.IsInRole(p.DenyAccessRoleNames.Where(r => !r.Equals("Deny Card Deposit", StringComparison.InvariantCultureIgnoreCase)).ToArray()))).ToArray();
            }
            else
            {
                query = query.Where(p => !Profile.IsInRole(p.DenyAccessRoleNames)).ToArray();
            }
        }
        
        var list = query.ToArray();
        query = query.Where(p => p.RepulsivePaymentMethods == null ||
            p.RepulsivePaymentMethods.Count == 0 ||
            !p.RepulsivePaymentMethods.Exists(p2 => paymentMethods.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
            ).ToArray();

        if (paymentMethodCategory.ToString() == "BankTransfer"){
            return query.OrderByDescending(p => p.UniqueName).ToArray();
        }
        else
            return query.OrderBy(p => p.Ordinal).ToArray();
    }
</script>

<%
    PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();
    foreach (PaymentMethodCategory category in PaymentMethodManager.GetCategories())
    {
        var filteredMethods = FilterPaymentMethods( paymentMethods, category);
        if (filteredMethods.Length == 0)
            continue;
       %>

       <div class="tablePaymentMethodsList" data-category="<%=category.ToString() %>">
            <div class="row tableHead">
                    <div class="col-1"><span><%= category.GetDisplayName().SafeHtmlEncode() %></span></div>
                    <div class="col-3"><span><%= this.GetMetadata(".Fee").SafeHtmlEncode() %></span></div>
                    <div class="col-4"><span><%= this.GetMetadata(".Processing").SafeHtmlEncode()%></span></div>
                    <div class="col-5"><span><%= this.GetMetadata(".Transaction_Limit").SafeHtmlEncode()%></span></div>
            </div>
                
                <% 
                    bool isAlternate = true;
                    foreach (PaymentMethod paymentMethod in filteredMethods)
                    {
                        string url = this.Url.RouteUrl("Deposit"
                            , new { @action = "Prepare", @paymentMethodName = paymentMethod.UniqueName }
                            );
                        isAlternate = !isAlternate;
                        %>

                <a href="<%= url.SafeHtmlEncode() %>" title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" class="row PaymentItem <%= isAlternate ? "odd" : "" %>" data-resourcekey="<%= paymentMethod.ResourceKey.SafeHtmlEncode() %>">
                    <div class="col-1">
                        <span>
                            <img alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" />
                        </span>
                    </div>                        
                    <div class="col-2">
                        <div class="holderButton">
                            <%-- Html.LinkButton(this.GetMetadata(".Deposit"), new { @class="Button depositbutton"}) --%>
                            <span class="Button depositbutton" onclick="this.blur()"><span class="ButtonText"><%= this.GetMetadata(".Deposit") %></span></span>
                        </div>
                        <div class="link">
                            <%= paymentMethod.GetTitleHtml().HtmlEncodeSpecialCharactors() %>
                            <% if (!paymentMethod.SupportWithdraw)
                               { %>

                            <% if (paymentMethod.UniqueName == "TurkeyBankWire")
                               { %>
                                <%= this.GetMetadata(".DIRECTBANKTRANSFER_Withdraw").HtmlEncodeSpecialCharactors()%>
                            <% } %>
                            <% else if(paymentMethod.UniqueName =="APX") {%>
                                <%= this.GetMetadata(".AUTOMATEDBANKTRANSFER_Withdraw").HtmlEncodeSpecialCharactors()%>
                            <% }%>
                            <% else{ %>
                            <%= this.GetMetadata(".Bank_Withdraw_Only").HtmlEncodeSpecialCharactors()%>
                            <% } %>
                            <% } %>
                        </div>
                    </div>
                    <div class="col-3">
                        <%= paymentMethod.DepositProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR")).SafeHtmlEncode()%>
                    </div>
                    <div class="col-4">
                        <%= paymentMethod.ProcessTime.GetDisplayName().SafeHtmlEncode() %>
                    </div>
                    <div class="col-5">
                        <%= GetLimitationHtml(paymentMethod) %>
                    </div>
                </a>

                <% if (paymentMethod.HasPromotion())
                    { %>
                <div <%= isAlternate ? "class=\"odd\"" : "" %>>
                    <div class="col-all">
                        <%= paymentMethod.GetPromotionHtml().HtmlEncodeSpecialCharactors() %>
                    </div>
                </div>
                <% }// if %>



                <% }// for each %>

       </div>

 <%  } %>

