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
                html.AppendFormat("<span class=\"min\">{0}</span>", this.GetMetadataEx(".Min_Limit", currency, min).SafeHtmlEncode());

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

        var list = query.ToArray();

        var query2 = list.Where(p => p.RepulsivePaymentMethods == null ||
            p.RepulsivePaymentMethods.Count == 0 ||
            !p.RepulsivePaymentMethods.Exists(p2 => list.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
            );

        return query2.ToArray();
    }
</script>
<ul class="Container CategoriesBox DepositCategories_V2" id="DepositCategories">
    <%
        PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();
        paymentMethods = FilterPaymentMethods(paymentMethods);
        foreach (PaymentMethodCategory category in PaymentMethodManager.GetCategories())
        {
            var filteredMethods = paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal).ToArray();
            if (filteredMethods.Length == 0)
                continue;
    %>

    <li class="Container DepositItem_V2 Item-<%= category.GetHashCode().ToString().SafeHtmlEncode() %>" >
        <h2 class="DepositTitle_V2">
            <a class="DepositLink" href="#" data-category="<%= category.GetHashCode().ToString().SafeHtmlEncode() %>">
                <%-- <span class="ToggleIcon"><span class="ToggleText">Toggle</span></span> 
                <span class="CatIcon"><span class="CatIconText">Category:</span></span> --%>
                <span class="DepositCatText"><%= category.GetDisplayName().SafeHtmlEncode() %></span>
            </a>
        </h2>
    </li>
    <%  } %>
</ul>
<% 
    foreach (PaymentMethodCategory category in PaymentMethodManager.GetCategories())
    {
        var filteredMethods = paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal).ToArray();
        if (filteredMethods.Length == 0)
            continue;
%>

<ol class="Container CardList_V2 IconList_V2 DepositList_V2" data-category="<%= category.GetHashCode().ToString().SafeHtmlEncode() %>">
    <li class="DepositBack BackItem">
        <a class="SideMenuLink BackButton BackDeposit" href="#">
            <span class="ActionArrow icon-arrow-left"> </span>
    <span class="ButtonIcon icon Hidden">&nbsp;</span>
    <span class="ButtonText"><%=this.GetMetadata(".Back_Text")%></span>
        </a>
        <h3 class="DepositCategoryTitle"><%= category.GetDisplayName().SafeHtmlEncode() %></h3>
    </li>
    <% 
        int index = 1;
        foreach (PaymentMethod paymentMethod in filteredMethods)
        {
            index++; 
            bool isBank = (paymentMethod.VendorID == GamMatrixAPI.VendorID.Bank) ;
            string url = isBank ? Url.RouteUrl("Deposit", new { action = "Account", paymentMethodName = HttpUtility.UrlEncode(paymentMethod.UniqueName) }) : Url.RouteUrl("Deposit", new { action = "Prepare", paymentMethodName = HttpUtility.UrlEncode(paymentMethod.UniqueName) });
    %>
    <li class="DepositItem_V2 DepositCard_V2 Item<%=(index).ToString() %>" data-uniquename="<%= paymentMethod.UniqueName.SafeHtmlEncode() %>">
            <a class="Container DepositTitle_V2 CardHeader D" href="<%=isBank ? url.SafeHtmlEncode() : "javascript:void(0);" %>" data-index="<%=index.ToString() %>" data-bank="<%=isBank.ToString() %>">
                <%if (!isBank){ %><form id="formDepositAmount<%=index.ToString() %>" method="post" action="<%= url.SafeHtmlEncode() %>" novalidate="novalidate"></form><%} %>
                <%-- <span class="ActionArrow Y">&#9658;</span> --%>
                <span class="Icon DepositIcon_V2">
                    <span class="IconWrapper DepositWrapper">
                        <img class="Card I" src="<%= paymentMethod.GetImageUrl().SafeHtmlEncode() %>" width="66" height="66" alt="<%= paymentMethod.GetTitleHtml().SafeHtmlEncode() %>" />
                    </span>
                </span>
                <span class="CardText N"><%= this.GetMetadata(".DepositCard").SafeHtmlEncode()%> <%= paymentMethod.GetTitleHtml() %></span>
                <span class="CardDetails S">
                    <span class="FirstDetails">
                        <span class="DTF">Fee: <%= paymentMethod.DepositProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR")).SafeHtmlEncode()%></span>
                        <span class="DTM">Processing: <%= paymentMethod.ProcessTime.GetDisplayName().SafeHtmlEncode() %></span>
                    </span>
                    <span class="DTL">Limit: <%= GetLimitationHtml(paymentMethod) %></span>
                </span>
            </a>
        
    </li>
    <% } %>
</ol>
<% } %>
<script type="text/javascript">
    $(function () {
        // $(".DepositProgress,.Footer,#accountPanel").remove();
        $('.DepositLink').click(function (evt) {
            evt.preventDefault();
            $("#DepositCategories").addClass('SwipeUp');
            $('.DepositList_V2').hide().removeClass('ActiveCategory');
            $(".DepositList_V2[data-category='" + $(this).data("category") + "']").show().toggleClass('ActiveCategory');
            $('#DepositOptionsList').attr('data-step', '2');

            //move the page Up
            el = $('#DepositCategories');
            eltop = $('#DepositOptionsList');
            var moveup = el.height() + 20 ;
            console.log(moveup);
            var neweltop = eltop.height() - moveup + 'px';
            console.log(neweltop);

            moveup = 'translateY(-' + moveup + 'px)';
            $('#DepositContent').css({
                '-moz-transform': moveup,
                '-webkit-transform': moveup,
                '-o-transform': moveup,
                '-ms-transform': moveup,
                'transform': moveup
            });
           
            eltop.css('overflow', 'hidden').css('height', neweltop);

        });

        $('.DepositList_V2').find('a.CardHeader').click(function () {
            if ($(this).data("Bank") != "True")
                $(this).find("form").submit();
            //$("#formDepositAmount" + $(this).data("index")).submit();
        });

        $('.BackDeposit').click(function (evt) {
            evt.preventDefault();
            $("#DepositCategories").removeClass('SwipeUp');
            $('.DepositList_V2').hide().removeClass('ActiveCategory');
            $('#DepositOptionsList').attr('data-step', '1');
            eltop = $('#DepositOptionsList');
            el = $('#DepositContent');
            el.removeAttr('style');
            eltop.removeAttr('style');
        });

    });
   
</script>
