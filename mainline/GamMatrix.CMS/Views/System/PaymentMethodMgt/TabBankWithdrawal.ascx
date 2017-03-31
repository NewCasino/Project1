<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script type="text/C#" runat="server">

    private Dictionary<long, BankWithdrawalCountryConfig> BankWithdrawalConfiguraton { get; set; }
    protected override void OnInit(EventArgs e)
    {
        this.BankWithdrawalConfiguraton 
            = PaymentMethodManager.GetBankWithdrawalConfiguration(this.ViewData["cmSite"] as cmSite);
        base.OnInit(e);
    }
    
    private bool IsTypeSelected(BankWithdrawalType type, long internalID)
    {
        BankWithdrawalCountryConfig config;
        if (this.BankWithdrawalConfiguraton.TryGetValue(internalID, out config))
            return config.Type == type;
        return type == BankWithdrawalType.None;
    }
</script>

<% cmSite domain = this.ViewData["cmSite"] as cmSite; %>

<div id="bank-withdrawal-links" class="payment-method-mgt-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li>
    <li>
        <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
            @action = "Dialog",
            @distinctName = domain.DistinctName.DefaultEncrypt(),
            @relativePath = "/.config/BankWithdrawalConfiguration".DefaultEncrypt(),
            @searchPattner = "",
            } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </li>
</ul>
</div>

<hr class="seperator" />

<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all"> 
	<p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-info"></span>
	The bank withdrawal form format is controlled here.
</div>
<br />
<% 
    using (Html.BeginRouteForm("PaymentMethodMgt", new
    {
        @action = "SaveBankWithdrawalConfiguration",
        @distinctName = domain.DistinctName.DefaultEncrypt()
    }, FormMethod.Post
    , new { @id = "formSaveBankWithdrawalConfiguration" }
    ))
    {
    
     %>

<table border="0" cellpadding="10" cellspacing="0" id="country-bank-withdraw-table">
    <thead>
        <tr>
            <th>Country</th>
            <th>
                <%: this.Html.RadioButton("all_countries_type", BankWithdrawalType.None, false, new { @class = "None", @id = "btnType_None" })%>
                <label for="btnType_None">None</label>
            </th>
            <th>
                <%: this.Html.RadioButton( "all_countries_type", BankWithdrawalType.Envoy, false, new { @class = "Envoy", @id = "btnType_Envoy" })%>
                <label for="btnType_Envoy">Envoy</label>
            </th>
            <th>
                <%: this.Html.RadioButton("all_countries_type", BankWithdrawalType.ClassicInternationalBank, false, new { @class = "ClassicInternationalBank", @id = "btnType_ClassicInternationalBank" })%>
                <label for="btnType_ClassicInternationalBank">Classic International Bank</label>
            </th>
            <th>
                <%: this.Html.RadioButton("all_countries_type", BankWithdrawalType.ClassicEECBank, false, new { @class = "ClassicEECBank", @id = "btnType_ClassicEECBank" })%>
                <label for="btnType_ClassicEECBank">Classic E.E.C Bank</label>
            </th>
            <th>
                <%: this.Html.RadioButton("all_countries_type", BankWithdrawalType.InPay, false, new { @class = "InPay", @id = "btnType_InPay" })%>
                <label for="btnType_InPay">InPay</label>
            </th>
            <th>
                <%: this.Html.RadioButton("all_countries_type", BankWithdrawalType.EnterCash, false, new { @class = "EnterCash", @id = "btnType_EnterCash" })%>
                <label for="btnType_EnterCash">EnterCash</label>
            </th>
        </tr>
    </thead>
    <tbody>
        <% 
            bool isAlternate = true;
            List<CountryInfo> countries = CountryManager.GetAllCountries().Where( c => c.InternalID > 0 ).ToList();
            foreach( CountryInfo country in countries)
            {
                isAlternate = !isAlternate;
                string name = string.Format( string.Format("bank_withdrawal_type_{0}", country.InternalID) );
                    %>
            
        <tr class="<%= isAlternate ? "odd" : "" %>">
            <td valign="middle">
            <%= country.EnglishName.SafeHtmlEncode() %>
            </td>
            <td valign="middle">
                <%: this.Html.RadioButton(name, BankWithdrawalType.None, IsTypeSelected(BankWithdrawalType.None, country.InternalID), new { @class = "None", @id = string.Format("btnType_None_{0}", country.InternalID) })%>
                <label for="<%= string.Format("btnType_None_{0}", country.InternalID) %>">None</label>
            </td>
            <td valign="middle">
                <%: this.Html.RadioButton(name, BankWithdrawalType.Envoy, IsTypeSelected(BankWithdrawalType.Envoy, country.InternalID), new { @class = "Envoy", @id = string.Format("btnType_Envoy_{0}", country.InternalID) })%>
                <label for="<%= string.Format("btnType_Envoy_{0}", country.InternalID) %>">Envoy</label>
            </td>
            <td>
                <%: this.Html.RadioButton(name, BankWithdrawalType.ClassicInternationalBank, IsTypeSelected(BankWithdrawalType.ClassicInternationalBank, country.InternalID), new { @class = "ClassicInternationalBank", @id = string.Format("btnType_ClassicInternationalBank_{0}", country.InternalID) })%>
                <label for="<%= string.Format("btnType_ClassicInternationalBank_{0}", country.InternalID) %>">Classic International Bank</label>
            </td>
            <td valign="middle">
                <%: this.Html.RadioButton(name, BankWithdrawalType.ClassicEECBank, IsTypeSelected(BankWithdrawalType.ClassicEECBank, country.InternalID), new { @class = "ClassicEECBank", @id = string.Format("btnType_ClassicEECBank_{0}", country.InternalID) })%>
                <label for="<%= string.Format("btnType_ClassicEECBank_{0}", country.InternalID) %>">Classic E.C.C Bank</label>
            </td>
            <td valign="middle">
                <%: this.Html.RadioButton(name, BankWithdrawalType.InPay, IsTypeSelected(BankWithdrawalType.InPay, country.InternalID), new { @class = "InPay", @id = string.Format("btnType_InPay_{0}", country.InternalID) })%>
                <label for="<%= string.Format("btnType_InPay_{0}", country.InternalID) %>">InPay</label>
            </td>
            <td valign="middle">
                <%: this.Html.RadioButton(name, BankWithdrawalType.EnterCash, IsTypeSelected(BankWithdrawalType.EnterCash, country.InternalID), new { @class = "EnterCash", @id = string.Format("btnType_EnterCash_{0}", country.InternalID) })%>
                <label for="<%= string.Format("btnType_EnterCash_{0}", country.InternalID) %>">EnterCash</label>
            </td>
        </tr>
        
        <%  } %>
    </tbody>
</table>

<% } //form %>


<script type="text/javascript">
    $(function () {
        $('#country-bank-withdraw-table thead :radio').click(function (e) {
            var cls = $(this).attr('class');

            $('#country-bank-withdraw-table tbody :radio.' + cls).attr('checked', true);
        });

        $('#bank-withdrawal-links a.save').click(function (e) {
            e.preventDefault();

            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) {
                    if (!json.success) { alert(json.error); }
                    if (self.stopLoad) self.stopLoad();
                }
            };
            if (self.startLoad) self.startLoad();
            $('#formSaveBankWithdrawalConfiguration').ajaxForm(options);
            $('#formSaveBankWithdrawalConfiguration').submit();
        });

        this.init = function () {
            $('#bank-withdrawal-links a.history').click(function (e) {
                var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                if (wnd) e.preventDefault();
            });
        };

        this.init();
    });
</script>
