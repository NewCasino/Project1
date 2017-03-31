<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="Finance" %>
<script type="text/C#" runat="server">
    private string GetLimitationHtml(PaymentMethod paymentMethod)
    {
        string currency = this.ViewData.GetValue<string>("Currency", "EUR");
        Range range = paymentMethod.GetDepositLimitation(currency);

        if (range.MinAmount <= 0.00M && range.MaxAmount <= 0.00M)
        {
            return string.Format("<span class=\"variable\">{0}</span>"
                , this.GetMetadata(".Variable").SafeHtmlEncode()
                );
        }
        StringBuilder html = new StringBuilder();
        try
        {

            decimal min = MoneyHelper.TransformCurrency(range.Currency, currency, range.MinAmount);
            decimal max = MoneyHelper.TransformCurrency(range.Currency, currency, range.MaxAmount);
            if (min < max)
                MoneyHelper.SmoothCeilingAndFloor(ref min, ref max);

            if (range.MinAmount > 0.00M)
                html.AppendFormat( "<span class=\"min\">{0}</span>", this.GetMetadataEx(".Min_Limit", currency, min).SafeHtmlEncode());

            if (range.MaxAmount > 0.00M)
            {
                html.AppendFormat("<span class=\"max\">{0}</span>", this.GetMetadataEx(".Max_Limit", currency, max).SafeHtmlEncode());
            }
        }
        catch
        {
        }
        return html.ToString();
    }

    private PaymentMethod[] FilterPaymentMethods(PaymentMethod[] paymentMethods)
    {
        var query = paymentMethods.Where(p => p.IsAvailable && p.SupportDeposit);

        //Hide EnterCash_Siru, it is not supported in mobile
        query = query.Where(p => p.UniqueName != "EnterCash_Siru");

        int countryID = this.ViewData.GetValue<int>("CountryID", -1);
        string currency = this.ViewData.GetValue<string>("Currency", "EUR");

        if (countryID > 0)
            query = query.Where(p => p.SupportedCountries.Exists(countryID));

        if (Profile.IsAuthenticated)
        {
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
</script><%
    PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();
    paymentMethods = FilterPaymentMethods(paymentMethods);
    foreach (PaymentMethodCategory category in PaymentMethodManager.GetCategories())
    {
        var filteredMethods = paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal).ToArray();
        if (filteredMethods.Length == 0)
            continue;
       %>	<div class="Box DepositCategory OpenCategory category_<%=category %>">		<h2 class="GameCatTitle">
			<a class="GameCatLink" href="#">
				<span class="ToggleIcon"><span class="ToggleText">Toggle</span></span>
				<span class="CatIcon"><span class="CatIconText">Category:</span></span>
				<span class="GameCatText"><%= category.GetDisplayName().SafeHtmlEncode() %></span>
			</a>
		</h2>
		<ol class="CardList IconList L Container">            <% 
                foreach (PaymentMethod paymentMethod in filteredMethods)
                {
					string url = Url.RouteUrl("Deposit", new { action = "Account", paymentMethodName = HttpUtility.UrlEncode(paymentMethod.UniqueName) });
            %>			<li class="DepositCard CardItem Col X" data-uniquename="<%= paymentMethod.UniqueName.SafeHtmlEncode() %>">				<a class="CardHeader A Container" href="<%= url.SafeHtmlEncode() %>">					<span class="ActionArrow Y">&#9658;</span>					<span class="Icon">
						<span class="IconWrapper">
							<img class="Game I" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" width="66" height="66" alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" />
						</span>
					</span>					<span class="CardText N"><%= this.GetMetadata(".DepositCard").SafeHtmlEncode()%> <%= paymentMethod.GetTitleHtml() %></span>					<span class="CardDetails S">
                        <span class="FirstDetails">
						    <span class="DTF">Fee: <%= paymentMethod.DepositProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR")).SafeHtmlEncode()%></span>
						    <span class="DTM">Processing: <%= paymentMethod.ProcessTime.GetDisplayName().SafeHtmlEncode() %></span>
                        </span>
						<span class="DTL">Limit: <%= GetLimitationHtml(paymentMethod) %></span>
                        <%if (paymentMethod.UniqueName == "MoneyMatrix_Ochapay")
                            { %>
                        <span class="FirstDetails">
                             <%= paymentMethod.GetWithdrawMessage().HtmlEncodeSpecialCharactors()%>
                        </span>
                            <%} %>
					</span>				</a>			</li>			<% } %>		</ol>	</div><%  } %><script type="text/javascript">
	$(function () {
		$('.GameCatLink').click(function () {
			$(this)
				.closest('.DepositCategory')
					.toggleClass('OpenCategory');
			return false;
		});
	});</script>