<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgDepositLimitInfoRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<%--
1. (Record == null) : No limit; Show "Submit" button
2. (Record != null && !Record.UpdateFlag) : Has a limit;  Show "Remove" / "Change" button
3. (Record != null && Record.UpdateFlag && Record.UpdatePeriod == None ) : The limit is schedualed to be removed
4. (Record != null && Record.UpdateFlag && Record.UpdatePeriod != None ) : The limit is schedualed to be changed
--%>

<script language="C#" type="text/C#" runat="server">
    private SelectList GetCurrencyList(string currency = null)
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .FilterForCurrentDomain()
                        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                        .ToList();
        string selectedValue = null;
        if (!string.IsNullOrWhiteSpace(currency))
            selectedValue = currency;
        else if (this.Model != null)
            selectedValue = this.Model.Currency;
        else if (Profile.IsAuthenticated)
            selectedValue = ProfileCommon.Current.UserCurrency;

        return new SelectList(list
            , "Key"
            , "Value"
            , selectedValue
            );
    }

    private string GetExpirationDate()
    {
        if (this.Model != null)
        {
            if (this.Model.ExpiryDate.Date == DateTime.MaxValue.Date)
                return this.GetMetadata(".No_Expiration");

            return this.Model.ExpiryDate.ToString("dd/MM/yyyy");
        }
        return string.Empty;
    }

    private string GetPeriodRadioAttribute(RgDepositLimitPeriod rgDepositLimitPeriod
        , bool updatedLimit = false)
    {
        if(this.Model == null)
            return (SpecificedPeriod == rgDepositLimitPeriod) ? "checked=\"checked\"" : string.Empty;
        if (!updatedLimit)
            return ((RgDepositLimitPeriod)this.ViewData["Period"]) == rgDepositLimitPeriod ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
        return ((RgDepositLimitPeriod)this.ViewData["Period"]) == rgDepositLimitPeriod ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
    }

    private bool IsRemoved()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod == RgDepositLimitPeriod.None;
    }

    private bool IsScheduled()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod != RgDepositLimitPeriod.None;
    }

    private RgDepositLimitPeriod SpecificedPeriod {
        get {
            if (this.ViewData["Period"] != null)
                return (RgDepositLimitPeriod)this.ViewData["Period"];
            return RgDepositLimitPeriod.None;
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        fldExpirationDate.Visible = this.Model != null;
        if (this.Model != null)
        {
            btnSubmitDepositLimit.Style["display"] = "none";
        }
        btnChangeDepositLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
        btnRemoveDepositLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">


<form action="/Limit/SetDepositLimit<%=Request.Url.Query.SafeHtmlEncode() %>" id="formDepositLimit" target="_self" method="post">

<div id="deposit-limit">
<p><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></p>
    <%
        if (Settings.Site_IsUnWhitelabel)
        {
         %>
<%: Html.InformationMessage(this.GetMetadata(".Notification"))%>
    <%} %>

<%------------------------------------------
    Currency
 -------------------------------------------%>
<ui:InputField ID="fldDepositLimitCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.DropDownList("currency"
        , GetCurrencyList()
        , (new Dictionary<string, object>()
        { 
            { "id", "ddlCurrency" },
            { "validator", ClientValidators.Create().Required(this.GetMetadata(".Currency_Empty")) },
        }).SetDisabled(this.Model != null))%>
	</ControlPart>
</ui:InputField>
<%: Html.Hidden("currency", "EUR", new { 
        @id = "txtCurrentVal"
})%>
<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
$("input[name='currency']").val($('#ddlCurrency').val());
function onCurrencyChange() {
    $("input[name='currency']").val($('#ddlCurrency').val());
}
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Amount
 -------------------------------------------%>
<ui:InputField ID="fldDepositLimitAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        
            <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%>
<%--        <%: Html.TextBox("amount"
            , ((this.Model == null) ? string.Empty : this.Model.Amount.ToString())
            , (new Dictionary<string, object>()  
		    { 
			    { "id", "txtDepositLimitAmount" },
			    { "onchange", "onAmountChange" },
			    { "onblur", "onAmountChange" },
			    { "onfocus", "onAmountFocus" },
			    { "dir", "ltr" },
                { "style", "text-align:right" },
			    { "validator", ClientValidators.Create().Required(this.GetMetadata(".Amount_Empty")).Custom("validateAmount") }
		    }).SetReadOnly(this.Model!= null)
            )%>--%>
	</ControlPart>
</ui:InputField>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    // <%-- Format the input amount to comma seperated amount --%>

    var pAmount = <%=(this.Model == null) ? "0" : this.Model.Amount.ToString(System.Globalization.CultureInfo.InvariantCulture) %>;
    if(pAmount != 0){
        $('#txtAmount').val(formatAmount(pAmount, true));
        $('#txtAmount').data('fillvalue',pAmount);
        $("input[name='amount']").val(pAmount );
        $('#txtAmount').attr('disabled',true).attr('readonly',true);
    }
    $('#txtAmount').css("text-align","right") ;

    //function formatAmount(num) {
    //    num = num.toString().replace(/\$|\,/g, '');
    //    if (isNaN(num)) num = '0';
    //    sign = (num == (num = Math.abs(num)));
    //    num = Math.floor(num * 100 + 0.50000000001);
    //    cents = num % 100;
    //    num = Math.floor(num / 100).toString();
    //    if (cents < 10) cents = '0' + cents;
    //    for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3) ; i++)
    //        num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
    //    return num + '.' + cents;
    //}
    //function onAmountChange() {
    //    $('#txtDepositLimitAmount').val(formatAmount($('#txtDepositLimitAmount').val()));
    //};
    //function onAmountFocus() {
    //    $('#txtDepositLimitAmount').val($('#txtDepositLimitAmount').val().replace(/\$|\,/g, '')).select();
    //}
    function validateAmount() {
        var value = this;
        value = value.replace(/\$|\,/g, '');
        if (isNaN(value) || parseFloat(value, 10) <= 0)
            return '<%= this.GetMetadata(".Amount_Empty").SafeJavascriptStringEncode() %>';
        return true;
    }
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Period
 -------------------------------------------%>
<ui:InputField ID="fldDepositLimitPeriod" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <ul style="list-style-type:none; margin:0px; padding:0px;">
            <%if (SpecificedPeriod == RgDepositLimitPeriod.None || SpecificedPeriod == RgDepositLimitPeriod.Daily)
              { %>
              <li><input type="radio" name="depositLimitPeriod" id="depositLimitPeriod_daily" value="Daily" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Daily, false) %> />
                <label for="depositLimitPeriod_daily"><%= this.GetMetadata(".Period_Daily").SafeHtmlEncode()%></label></li>
            <%} %>

            <%if (SpecificedPeriod == RgDepositLimitPeriod.None || SpecificedPeriod == RgDepositLimitPeriod.Weekly)
              { %>
              <li><input type="radio" name="depositLimitPeriod" id="depositLimitPeriod_weekly" value="Weekly" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Weekly, false) %> />
                <label for="depositLimitPeriod_weekly"><%= this.GetMetadata(".Period_Weekly").SafeHtmlEncode()%></label></li>
            <%} %>

            <%if (SpecificedPeriod == RgDepositLimitPeriod.None || SpecificedPeriod == RgDepositLimitPeriod.Monthly)
              { %>
              <li><input type="radio" name="depositLimitPeriod" id="depositLimitPeriod_monthly" value="Monthly" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Monthly, false) %> />
                <label for="depositLimitPeriod_monthly"><%= this.GetMetadata(".Period_Monthly").SafeHtmlEncode()%></label></li>
            <%} %>
        </ul>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    Expiration date
 -------------------------------------------%>
<ui:InputField ID="fldExpirationDate" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".ExpirationDate_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("expirationDate" , GetExpirationDate() , new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>


<center>

<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Back) %>" id="btnLimitBack" CssClass="BackButton button" onclick="self.location='/Limit'" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Submit) %>" id="btnSubmitDepositLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Change) %>" id="btnChangeDepositLimit" CssClass="ContinueButton button" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Remove) %>" id="btnRemoveDepositLimit" CssClass="ContinueButton button" type="submit"></ui:Button>

</center>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(function () {
        $('#btnSubmitDepositLimit').click(function (e) {
            if (!validateAmount()) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
        });
        $('#btnChangeDepositLimit').click(function (e) {
            e.preventDefault();
            $(this).hide();
            $('#btnSubmitDepositLimit').show();
            $('#btnRemoveDepositLimit').hide();
            $('#ddlCurrency').attr('disabled', false);
            $('#txtAmount').attr('disabled', false).attr('readonly', false);
            $('#fldDepositLimitPeriod input').attr('disabled', false);

        });
        <% if (this.Model != null && !this.Model.UpdateFlag) { %>
        $('#btnRemoveDepositLimit').click(function (e) {
            if (window.confirm('<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>') != true) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
            $('#formDepositLimit').attr('action', '<%= this.Url.RouteUrl("Limit", new { @action="RemoveDepositLimit", @period=this.Model.Period.ToString()}).SafeJavascriptStringEncode()%>');
        });
        <%}%>
    });
</script>
</ui:MinifiedJavascriptControl>



</div>

</form>
</ui:Panel>

</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(function () {
        $('#formDepositLimit').initializeForm();
    });
</script>
</ui:MinifiedJavascriptControl>

</asp:content>



