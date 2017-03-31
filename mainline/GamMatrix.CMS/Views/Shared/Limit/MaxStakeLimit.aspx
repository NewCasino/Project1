<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgMaxStakeLimitRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

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

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        if (this.Model != null)
        {
            btnSubmitMaxStakeLimit.Style["display"] = "none";
        }
        btnChangeMaxStakeLimit.Visible = this.Model != null;
        btnRemoveMaxStakeLimit.Visible = this.Model != null;
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">


<form action="/Limit/SetMaxStakeLimit<%=Request.Url.Query.SafeHtmlEncode() %>" id="formMaxStakeLimit" target="_self" method="post">

<div id="maxstake-limit">
<p><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></p>

<%------------------------------------------
    Currency
 -------------------------------------------%>
<ui:InputField ID="fldMaxStakeLimitCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
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
<ui:InputField ID="fldMaxStakeLimitAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
            <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%>
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

    function validateAmount() {
        var value = this;
        value = value.replace(/\$|\,/g, '');
        if (isNaN(value) || parseFloat(value, 10) <= 0)
            return '<%= this.GetMetadata(".Amount_Empty").SafeJavascriptStringEncode() %>';
        return true;
    }
</script>
</ui:MinifiedJavascriptControl>

<center>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Back) %>" id="btnLimitBack" CssClass="BackButton button" onclick="self.location='/Limit'" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Submit) %>" id="btnSubmitMaxStakeLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Change) %>" id="btnChangeMaxStakeLimit" CssClass="ContinueButton button" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Remove) %>" id="btnRemoveMaxStakeLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
</center>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(function () {
        $('#btnSubmitMaxStakeLimit').click(function (e) {
            if (!validateAmount()) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
        });
        $('#btnChangeMaxStakeLimit').click(function (e) {
            e.preventDefault();
            $(this).hide();
            $('#btnSubmitMaxStakeLimit').show();
            $('#btnRemoveMaxStakeLimit').hide();
            $('#ddlCurrency').attr('disabled', false);
            $('#txtAmount').attr('disabled', false).attr('readonly', false);
        });
        <% if (this.Model != null) { %>
        $('#btnRemoveMaxStakeLimit').click(function (e) {
            if (window.confirm('<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>') != true) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
            $('#formMaxStakeLimit').attr('action', '<%= this.Url.RouteUrl("Limit", new { @action="RemoveMaxStakeLimit"}).SafeJavascriptStringEncode()%>');
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
        $('#formMaxStakeLimit').initializeForm();
    });
</script>
</ui:MinifiedJavascriptControl>

</asp:content>



