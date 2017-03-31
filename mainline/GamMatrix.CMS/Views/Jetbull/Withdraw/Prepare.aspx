<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="CM.State" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">

<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<% if (this.Model.UniqueName == "EnterCashBank" && CustomProfile.Current.UserCountryID == 79)
{ %>
    <%: Html.WarningMessage("From 26th Aug, Aktia/Sp/Pop will be split into Aktia, Sp, Pop three banks. During the changes, we will stop processing any payout to Aktia/Sp/Pop therefore we highly recommend that you request payout to Aktia/Sp/Pop before 26th Aug or after 27th Aug.", true)%>
<% } %>

<div class="withdraw_steps">
    <div id="prepare_step">
        <% Html.RenderPartial("InputView", this.Model); %>
        <% Html.RenderPartial(this.ViewData["PayCardView"] as string, this.Model); %>
    </div>
    <div id="confirm_step" style="display:none">
    </div>
    <div id="error_step" style="display:none">
        <center>
        <br /><br /><br />
        <%: Html.ErrorMessage("Internal Error.", false, new { id="withdraw_error" })%>
        <br /><br /><br />
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousWithdrawStep(); return false;" })%>
        </center>
    </div>
</div>

</ui:Panel>
</div>


<script language="javascript" type="text/javascript">
//<![CDATA[
    var g_previousWithdrawSteps = new Array();
    
    function returnPreviousWithdrawStep() {
        if (g_previousWithdrawSteps.length > 0) {
            $('div.withdraw_steps > div').hide();
            g_previousWithdrawSteps.pop().show();
        }
    }

    function showWithdrawError(errorText) {
        $('#error_step div.message_Text').text(errorText);
        g_previousWithdrawSteps.push($('div.withdraw_steps > div:visible'));
        $('div.withdraw_steps > div').hide();
        $('#error_step').show();
    }
 
    function showWithdrawConfirmation(sid) {
        g_previousWithdrawSteps.push($('div.withdraw_steps > div:visible'));
        $('div.withdraw_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("Withdraw", new { @action = "Confirmation", @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }
//]]>
</script>

<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

