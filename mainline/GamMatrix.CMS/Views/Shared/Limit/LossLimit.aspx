<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgLossLimitInfoRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
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
            if(this.Model.ExpiryDate.Date == DateTime.MaxValue.Date)
                return this.GetMetadata(".No_Expiration");

            return this.Model.ExpiryDate.ToString("dd/MM/yyyy");
        }
        return string.Empty;
    }
    
    private string GetPeriodRadioAttribute(RgLossLimitPeriod rgLossLimitPeriod
        , bool updatedLimit = false)
    {
        if (this.Model == null)
            return (rgLossLimitPeriod == RgLossLimitPeriod.Daily) ? "checked=\"checked\"" : string.Empty;

        if( !updatedLimit )
            return (this.Model.Period == rgLossLimitPeriod) ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
        return (this.Model.UpdatePeriod == rgLossLimitPeriod) ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
    }

    private bool IsRemoved()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod == RgLossLimitPeriod.None;
    }

    private bool IsScheduled()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod != RgLossLimitPeriod.None;
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        fldExpirationDate.Visible = this.Model != null;
        if (this.Model != null)
        {
            btnSubmitLossLimit.Style["display"] = "none";
        }
        btnChangeLossLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
        btnRemoveLossLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">

<form action="/Limit/SetLossLimit<%=Request.Url.Query.SafeHtmlEncode() %>" id="formLossLimit" target="_self" method="post">

<div id="loss-limit">
<p><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></p>


<%------------------------------------------
    Currency
 -------------------------------------------%>
<ui:InputField ID="fldLossLimitCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
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
<ui:InputField ID="fldLossLimitAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        
            <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%>
<%--        <%: Html.TextBox("amount"
            , ((this.Model == null) ? string.Empty : this.Model.Amount.ToString())
            , (new Dictionary<string, object>()  
		    { 
			    { "id", "txtLossLimitAmount" },
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
    //function formatAmount(num) {
    //    num = num.toString().replace(/\$|\,/g, '');
    //    if (isNaN(num)) num = '0';
    //    sign = (num == (num = Math.abs(num)));
    //    num = Math.floor(num * 100 + 0.50000000001);
    //    cents = num % 100;
    //    num = Math.floor(num / 100).toString();
    //    if (cents < 10) cents = '0' + cents;
    //    for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3); i++)
    //        num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
    //    return num + '.' + cents;
    //}
    //function onAmountChange() {
    //    $('#txtLossLimitAmount').val(formatAmount($('#txtLossLimitAmount').val()));
    //};
    //function onAmountFocus() {
    //    $('#txtLossLimitAmount').val($('#txtLossLimitAmount').val().replace(/\$|\,/g, '')).select();
    //}
    var pAmount = <%=(this.Model == null) ? "0" : this.Model.Amount.ToString(System.Globalization.CultureInfo.InvariantCulture) %>;
    if(pAmount != 0){
        $('#txtAmount').val(formatAmount(pAmount, true));
        $('#txtAmount').data('fillvalue',pAmount);
        $("input[name='amount']").val(pAmount );
        $('#txtAmount').attr('disabled',true).attr('readonly',true);
    }
    $('#txtAmount').css("text-align","right") ;
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
<ui:InputField ID="fldLossLimitPeriod" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <ul style="list-style-type:none; margin:0px; padding:0px;">
            <li><input type="radio" name="lossLimitPeriod" id="lossLimitPeriod_daily" value="Daily" 
            <%= GetPeriodRadioAttribute( RgLossLimitPeriod.Daily, false) %> />
                <label for="lossLimitPeriod_daily"><%= this.GetMetadata(".Period_Daily").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="lossLimitPeriod" id="lossLimitPeriod_weekly" value="Weekly" 
            <%= GetPeriodRadioAttribute( RgLossLimitPeriod.Weekly, false) %>/>
                <label for="lossLimitPeriod_weekly"><%= this.GetMetadata(".Period_Weekly").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="lossLimitPeriod" id="lossLimitPeriod_monthly" value="Monthly" 
            <%= GetPeriodRadioAttribute( RgLossLimitPeriod.Monthly, false) %>/>
                <label for="lossLimitPeriod_monthly"><%= this.GetMetadata(".Period_Monthly").SafeHtmlEncode()%></label></li>
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
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Submit) %>" id="btnSubmitLossLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Change) %>" id="btnChangeLossLimit" CssClass="ContinueButton button" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Remove) %>" id="btnRemoveLossLimit" CssClass="ContinueButton button" type="submit"></ui:Button>

</center>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(function () {
        $('#btnSubmitLossLimit').click(function (e) {
            if (!validateAmount()) {
                e.preventDefault();
                return;
            } 
            $(this).toggleLoadingSpin(true); 
        });
        $('#btnChangeLossLimit').click(function (e) {
            e.preventDefault();
            $(this).hide();
            $('#btnSubmitLossLimit').show();
            $('#btnRemoveLossLimit').hide();
            $('#ddlCurrency').attr('disabled', false);
            $('#txtAmount').attr('disabled', false).attr('readonly', false);
            $('#fldLossLimitPeriod input').attr('disabled', false);
        });

        $('#btnRemoveLossLimit').click(function (e) {
            if (window.confirm('<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>') != true) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
            $('#formLossLimit').attr('action', '/Limit/RemoveLossLimit');
        });
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
        $('#formLossLimit').initializeForm();
    });
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

