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

        return MoneyHelper.FormatCurrencySymbol(html.ToString()); 
    }

    private PaymentMethod[] FilterPaymentMethods(PaymentMethod[] paymentMethods)
    {
        var query = paymentMethods.Where(p => p.IsAvailable &&
            p.SupportDeposit &&
            DomainConfigAgent.IsVendorEnabled(p));

        int countryID = this.ViewData.GetValue<int>("CountryID", -1);
        string currency = this.ViewData.GetValue<string>("Currency", "EUR");

        if (countryID > 0)
            query = query.Where(p => p.SupportedCountries.Exists(countryID));

        //if (!string.IsNullOrWhiteSpace(currency))
        //    query = query.Where(p => p.SupportedCurrencies.Exists(currency));

        if (Profile.IsAuthenticated) {
            if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.AstroPayCard_Ignore_DenyDepositCardRole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            {
                query = query.Where(p => !Profile.IsInRole(p.DenyAccessRoleNames)
                    || (p.UniqueName == "AstroPayCard" && !Profile.IsInRole(p.DenyAccessRoleNames.Where(r => !r.Equals("Deny Card Deposit", StringComparison.InvariantCultureIgnoreCase)).ToArray())));
            }
            else
            {
                query = query.Where(p => !Profile.IsInRole(p.DenyAccessRoleNames));
            }
        }

        var list = query.ToArray();
        
        var query2 = list.Where(p => p.RepulsivePaymentMethods == null ||
            p.RepulsivePaymentMethods.Count == 0 ||
            !p.RepulsivePaymentMethods.Exists(p2 => list.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
            );

        return query2.ToArray();
    }
</script>

<%
    PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();
    paymentMethods = FilterPaymentMethods(paymentMethods);
    foreach (PaymentMethodCategory category in PaymentMethodManager.GetCategories())
    {
        var filteredMethods = paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal).ToArray();
        if (filteredMethods.Length == 0)
            continue;
       %>

       <table cellpadding="0" cellspacing="0" border="0" class="deposit-table" data-category="<%=category.ToString() %>">
            <thead>
                <tr>
                    <th class="col-1" colspan="2"><span><%= category.GetDisplayName().SafeHtmlEncode() %></span></th>
                    <th class="col-3" align="center"><span><%= this.GetMetadata(".Fee").SafeHtmlEncode() %></span></th>
                    <th class="col-4" align="center"><span><%= this.GetMetadata(".Processing").SafeHtmlEncode()%></span></th>
                    <th class="col-5" align="center"><span><%= this.GetMetadata(".Transaction_Limit").SafeHtmlEncode()%></span></th>
                </tr>
            </thead>
            <tbody>
                
                <% 
                    bool isAlternate = true;
                    foreach (PaymentMethod paymentMethod in filteredMethods)
                    {
                        string url = this.Url.RouteUrl("Deposit"
                            , new { @action = "Prepare", @paymentMethodName = paymentMethod.UniqueName }
                            );
                        isAlternate = !isAlternate;
                        %>
                    
                <tr class="payment-list-item-<%=paymentMethod.UniqueName %> <%= isAlternate ? "odd" : "" %>" data-resourcekey="<%= paymentMethod.ResourceKey.SafeHtmlEncode() %>">
                    <td class="col-1" valign="middle" align="center">
                        <a href="<%= url.SafeHtmlEncode() %>" title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>">
                            <img border="0" alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" /></a>
                    </td>                        
                    <td class="col-2" valign="middle">
                        <div class="wrap">
                            <div class="link">
                                <a title="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" href="<%= url.SafeHtmlEncode() %>">
                                <%= paymentMethod.GetTitleHtml().HtmlEncodeSpecialCharactors() %>
                                </a>
                                <%if (paymentMethod.UniqueName == "MoneyMatrix_Ochapay")
                                    { %>
                                     <br />
                                <%= paymentMethod.GetWithdrawMessage().HtmlEncodeSpecialCharactors()%>
                                    <%} %>
                                <% else if (!paymentMethod.SupportWithdraw && paymentMethod.VendorID != GamMatrixAPI.VendorID.TxtNation)
                                   { %>
                                <br />
                                <%= this.GetMetadata(".Bank_Withdraw_Only").HtmlEncodeSpecialCharactors()%>
                                <% } else if (paymentMethod.VendorID == GamMatrixAPI.VendorID.TxtNation){%>
                                <br />
                                <%= this.GetMetadata(".PayByMobile").HtmlEncodeSpecialCharactors()%>
                                <% } %>
                            </div>
                            <div class="button">
                                <%: Html.LinkButton(this.GetMetadata(".Deposit"), new { @class="depositbutton"}) %>
                            </div>
                        </div>
                    </td>
                    <td class="col-3" valign="middle" align="center">
                        <%= MoneyHelper.FormatCurrencySymbol(paymentMethod.DepositProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR"))).SafeHtmlEncode()%>
                    </td>
                    <td class="col-4" valign="middle" align="center">
                        <%= paymentMethod.ProcessTime.GetDisplayName().SafeHtmlEncode() %>
                    </td>
                    <td class="col-5" valign="middle" align="center">
                        <p class="currencyContainer">
                            <%= GetLimitationHtml(paymentMethod) %>
                        </p>
                    </td>
                </tr>

                <% if (paymentMethod.HasPromotion())
                    { %>
                <tr <%= isAlternate ? "class=\"odd\"" : "" %>>
                    <td colspan="5" valign="middle" align="center">
                        <%= paymentMethod.GetPromotionHtml().HtmlEncodeSpecialCharactors() %>
                    </td>
                </tr>
                <% }// if %>



                <% }// for each %>

            </tbody>
            <tfoot>
                <tr>
                    <td colspan="5"></td>
                </tr>
            </tfoot>
       </table>

 <%  } %>

