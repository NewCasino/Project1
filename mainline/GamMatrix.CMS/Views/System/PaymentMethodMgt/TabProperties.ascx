<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script language="C#" runat="server" type="text/C#">
    private string FormatList(List<string> list)
    {
        if (list == null || list.Count == 0)
            return "None";
        
        StringBuilder html = new StringBuilder();
        foreach (string item in list)
        {
            html.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", item);
        }
        if (html.Length > 0)
            html.Remove(html.Length - 1, 1);
        return html.ToString();
    }
    
    private string FormatLimitation(Range range)
    {
        StringBuilder html = new StringBuilder();
        if (range.MinAmount > 0.00M)
        {
            html.AppendFormat(CultureInfo.InvariantCulture, " Min {0:N2} EUR,", range.MinAmount);
        }
        if (range.MaxAmount > 0.00M)
        {
            html.AppendFormat(CultureInfo.InvariantCulture, " Max {0:N2} EUR,", range.MaxAmount);
        }
        if (html.Length > 0)
            html.Remove(html.Length - 1, 1);
        else
            html.Append("Variable");
        return html.ToString();
    }

    private string FormatCountryList(CountryList countryList)
    {
        cmSite domain = this.ViewData["cmSite"] as cmSite;
        List<CountryInfo> countries = CountryManager.GetAllCountries(domain.DistinctName);
        
        StringBuilder text = new StringBuilder();
        if (countryList.Type == CountryList.FilterType.Exclude)
        {
            if (countryList.List == null ||
                countryList.List.Count == 0)
            {
                text.Append("All");
            }
            else
            {
                text.Append("Exclude ");
            }
        }
        else
        {
            if (countryList.List == null ||
                countryList.List.Count == 0)
            {
                text.Append("None");
            }
        }

        if (countryList.List != null) 
        {
            foreach (int countryID in countryList.List)
            {
                CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
                if (country != null)
                    text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", country.EnglishName);
            }
            if (text.Length > 0)
                text.Remove(text.Length - 1, 1);
        }
        return text.ToString();
    }


    private string FormatCurrencyList(CurrencyList currencyList)
    {

        StringBuilder text = new StringBuilder();
        if (currencyList.Type == CurrencyList.FilterType.Exclude)
        {
            if (currencyList.List == null ||
                currencyList.List.Count == 0)
            {
                text.Append("All");
            }
            else
            {
                text.Append("Exclude ");
            }
        }
        else
        {
            if (currencyList.List == null ||
                currencyList.List.Count == 0)
            {
                text.Append("None");
            }
        }

        if (currencyList.List != null) 
        {
            foreach (string currency in currencyList.List)
            {
                text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", currency);
            }
            if (text.Length > 0)
                text.Remove(text.Length - 1, 1);
        }
        return text.ToString();
    }

    public bool IsSimultaneousDepositLimitAvailable(PaymentMethod paymentMethod)
    {
        if (paymentMethod.VendorID == GamMatrixAPI.VendorID.ArtemisSMS ||
            paymentMethod.VendorID == GamMatrixAPI.VendorID.TurkeySMS ||
            paymentMethod.VendorID == GamMatrixAPI.VendorID.TurkeyBankWire)
        {
            return true;
        }
               
        return false;
    }
</script>
    
<div id="properties-links" class="payment-method-mgt-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
</ul>
</div>

<hr class="seperator" />

<div class="ui-widget">
	<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-error ui-corner-all"> 
		<p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-alert"></span>
		<strong>PLEASE NOTE</strong>
        <ul style=" font-size:16px; font-family:Consolas; color:red">
            <li>The options outlined in the categories below are only applicable for the GamMatrix CMS frontend system</li>
            <li>Supported Countries are only possible to filter in the deposit list</li>
            <li>Deposit/Withdrawal Limitations’ are only possible to make in cases where the deposit input field is controlled by GamMatrix. For instance, bank transfers are not accepted as these are not regulated by GamMatrix.</li>
            <li>Deposit/Withdrawal Limitations’ must not deviate from whatever limits have been set up by banks and/or in the GamMatrix backend system</li>
            <li>Deposit Process Fee is only for presentation purposes</li>
            <li>Deposit Process Time is only for presentation purposes</li>
            <li>Supported Currencies are only available for certain payment methods such as Ukash</li>
        </ul>
	</div>
</div>
<br />

<div id="payment-method-wrap">

<% 
    cmSite domain = this.ViewData["cmSite"] as cmSite;
    PaymentMethodCategory[] categories = PaymentMethodManager.GetCategories(domain, "en");
    PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods(domain, false).ToArray();
    PaymentMethodCoverage[] paymentMethodsCoverageList = PaymentMethodManager.LoadPaymentMethodsOperatorCoverage().ToArray();
    
   foreach (PaymentMethodCategory category in categories)
   {  %>

   <%: Html.H2(category.GetDisplayName(domain, "en").SafeHtmlEncode())%>
   <hr />

   <%
        foreach (PaymentMethod paymentMethod in paymentMethods.Where( p => p.Category == category) )
        {
            var siteIsTemplate = SiteManager.IsSiteRootTemplate(domain.DistinctName);
            if (!siteIsTemplate)
            {
                if (!GmCore.DomainConfigAgent.IsVendorEnabled(paymentMethod, domain))
                    continue;
            }
    %>
   
    <div class="payment-method">
        <a name="<%= paymentMethod.UniqueName.SafeHtmlEncode() %>"></a>
        <div class="head">
            <div class="text">
                <span>
                    <%= paymentMethod.UniqueName.SafeHtmlEncode() %> (Powered by:<%= paymentMethod.VendorID.ToString().SafeHtmlEncode() %>)
                </span>
            </div>
            <div class="link">
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
            @action = "Dialog",
            @distinctName = domain.DistinctName.DefaultEncrypt(),
            @relativePath = string.Format("/.config/{0}", paymentMethod.UniqueName).DefaultEncrypt(),
            @searchPattner = ".%",
            } ).SafeHtmlEncode()  %>" target="_blank">Change history...</a>&#160;&#160;&#160;

            <a href="<%= this.Url.RouteUrl( "MetadataEditor", new {  
            @action = "Index",
            @distinctName = domain.DistinctName.DefaultEncrypt(),
            @path = string.Format("/Metadata/PaymentMethod/{0}", paymentMethod.ResourceKey).DefaultEncrypt(),
            } ).SafeHtmlEncode()  %>" target="_blank">Edit Metadata...</a>&#160;&#160;&#160;
            </div>
        </div>
        <div class="body">
            <table cellpadding="2" cellspacing="0" border="0">
                <tbody>
                    <tr class="row1">
                        <td align="center" valign="middle" class="col1">&nbsp;</td>
                        <td align="center" valign="middle" class="col2"><img border="0" src="<%= paymentMethod.GetImageUrl(domain, "en") %>" /></td>
                        <td align="center" valign="middle" class="col3"><%= paymentMethod.GetTitleHtml(domain, "en")%>&#160;</td>
                        <td align="left" valign="middle" class="col4"><%= paymentMethod.GetDescriptionHtml(domain, "en")%>&#160;</td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Supported Countries :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "SupportedCountryView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= FormatCountryList(paymentMethod.SupportedCountries).SafeHtmlEncode() %>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Supported Currencies :</td>
                        <td class="entry-value">
                        <a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "SupportedCurrencyView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= FormatCurrencyList(paymentMethod.SupportedCurrencies).SafeHtmlEncode() %>
                        </a>
                        </td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Deposit Process Time :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "ProcessTimeView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= paymentMethod.ProcessTime.ToString().SafeHtmlEncode() %>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Deposit Limitation :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "DepositLimitationView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= FormatLimitation(paymentMethod.GetDepositLimitation("EUR")).SafeHtmlEncode()%>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Withdraw Limitation :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "WithdrawLimitationView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= FormatLimitation(paymentMethod.GetWithdrawLimitation("EUR")).SafeHtmlEncode()%>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Deposit Process Fee :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "DepositProcessFeeView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= paymentMethod.DepositProcessFee.GetText("EUR").SafeHtmlEncode() %>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Withdraw Process Fee :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "WithdrawProcessFeeView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= paymentMethod.WithdrawProcessFee.GetText("EUR").SafeHtmlEncode()%>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Support Withdraw :</td>
                        <td class="entry-value">
                        <% if (Profile.IsAuthenticated && Profile.IsInRole("CMS System Admin"))
                           { %>
                           <a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "WithdrawSupportView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                           <%= paymentMethod.SupportWithdraw ? "Yes" : "No" %>
                           </a>
                           <%}
                           else { %>
                           <%= paymentMethod.SupportWithdraw ? "Yes" : "No" %>
                           <%} %>
                        </td>
                    </tr> 
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Withdrawal Supported Countries :</td>
                        <td class="entry-value"><a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "WithdrawSupportedCountryView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= FormatCountryList(paymentMethod.WithdrawSupportedCountries).SafeHtmlEncode() %>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Currency Changeable(deposit flow) :</td>
                        <td class="entry-value">
                        <%= paymentMethod.IsCurrencyChangable ? "Yes" : "No" %>
                        </td>
                    </tr> 
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Auto-hide if these methods available:</td>
                        <td class="entry-value">
                        <a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "RepulsivePaymentMethodsView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= FormatList(paymentMethod.RepulsivePaymentMethods) %>
                        </a></td>
                    </tr>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Deny Access Role Name(s):</td>
                        <td class="entry-value">
                        <% foreach( string roleName in paymentMethod.DenyAccessRoleNames )
                        { %>
                            <strong><%= roleName.SafeHtmlEncode()%></strong>,
                        <% } %>
                        </td>
                    </tr>
                    <% if (siteIsTemplate)
                    {
                        var operators = paymentMethodsCoverageList.Where(p => p.MethodUniqueName == paymentMethod.UniqueName).ToArray(); %>
                        <tr>
                            <td align="right" valign="top" colspan="3" class="entry-name">Enabled for:</td>
                            <td class="entry-value" style="overflow:hidden;">
                            <% if (operators.Any()) { %>    
                                <a href="javascript:void(0)" class="enabledOperatorToggle" target="self"><%: string.Join(", ", operators.Select(p => p.SiteDisplayName).Take(7)) %>...</a>

                                <div class="enabledOperatorsList" style="display:none;">
                                    <% foreach (var site in operators) { %>
                                        <a href="javascript:void(0)" style="display:inline;" class="enabledOperator" target="self" onclick="onTreeClick('/PaymentMethodMgt/Index/<%: site.SiteDistinctName.DefaultEncrypt() %>#<%: paymentMethod.UniqueName.SafeHtmlEncode() %>', event)"><%: site.SiteDisplayName %></a><br/>
                                    <% } %>
                                </div>
                            <% } else { %>
                                <strong>None</strong>
                            <% } %>
                            </td>
                        </tr>
                    <% } %>

                    <%if (IsSimultaneousDepositLimitAvailable(paymentMethod)) { %>
                    <tr>
                        <td align="right" valign="middle" colspan="3" class="entry-name">Simultaneous Deposit Limit:</td>
                        <td class="entry-value">
                        <a href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "SimultaneousDepositLimitView", @distinctName = domain.DistinctName.DefaultEncrypt(), @paymentMethodName = paymentMethod.UniqueName }).SafeJavascriptStringEncode() %>')">
                        <%= paymentMethod.SimultaneousDepositLimit > 0 ? paymentMethod.SimultaneousDepositLimit.ToString() : "unlimited" %>
                        </a>
                        </td>
                    </tr>
                    <%} %>
                </tfoot>
            </table>
           
        </div>
    </div>

    <% }
   } %>
</div>

<div id="popup-dialog" title="Edit properties..." style="display:none">

</div>

<ui:ExternalJavascriptControl runat="server" Enabled="false">
<script language="javascript" type="text/javascript">
function TabProperties(viewEditor) {
    self.tabProperties = this;

    this.init = function () {
        $('div.payment-method > div.head > div.link > a').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });

        $('#properties a.refresh').bind('click', this, function (e) {
            e.preventDefault();
            e.data.refresh();
        });

        $(".enabledOperatorToggle").click(function (e) {
            e.preventDefault();
            $(this).parent().find('.enabledOperatorsList').toggle();
            $(this).toggle();
        });
    };

    this.refresh = function () {
        if (self.startLoad) self.startLoad();
        self._scrollTop = $(self).scrollTop();
        var url = '<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "TabProperties", @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
        $('#properties-links').parent().load(url, function () {
            if (self.stopLoad) self.stopLoad();
            $(self).scrollTop(self._scrollTop);
            self.tabProperties.init();
        });
    };

    this.init();
}

function __showModalDialog (url) {
    $('<div class="popup-dialog"><img src="/images/icon/loading.gif" /></div>').appendTo(document.body).load(url).dialog({
        autoOpen: true,
        height: 'auto',
        minHeight:50,
        position: [100,50],
        width: 700,
        modal: true,
        resizable: false,
        close: function(ev, ui) { $("div.popup-dialog").dialog('destroy'); $("div.popup-dialog").remove(); }
    });
};

function onTreeClick(action, e) {
    if (parent && parent.onNavTreeClicked)
        parent.onNavTreeClicked(action);
};

</script>
</ui:ExternalJavascriptControl>