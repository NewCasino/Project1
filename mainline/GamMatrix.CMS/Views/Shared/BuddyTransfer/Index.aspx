<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="buddytransfer-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnBuddyTransfer">
<br />
<div class="buddytransfer_steps">
    <div id="select_friend">
        <% Html.RenderPartial("SelectFriend"); %>
    </div>
    <div id="prepare_step" style="display:none">
    </div>
    <div id="confirm_step" style="display:none">
    </div>
    <div id="error_step" style="display:none">
        <center>
        <br /><br /><br />
        <%: Html.ErrorMessage("Internal Error.", false, new { id="buddytransfer_error" })%>
        <br /><br /><br />
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousBuddyTransferStep(); return false;" })%>
        </center>
    </div>
</div>

</ui:Panel>
</div>

<script language="javascript" type="text/javascript">
//<![CDATA[
    var g_previousBuddyTransferSteps = new Array();

    function returnPreviousBuddyTransferStep() {
        if (g_previousBuddyTransferSteps.length > 0) {
            $('div.buddytransfer_steps > div').hide();
            var $last = g_previousBuddyTransferSteps.pop();
            $last.show();
        }
    }

    function showBuddyTransferError(errorText) {
        $('#error_step div.message_Text').text(errorText);
        g_previousBuddyTransferSteps.push($('div.buddytransfer_steps > div:visible'));
        $('div.buddytransfer_steps > div').hide();
        $('#error_step').show();
    }

    function showBuddyTransferPrepare(encryptedUserID) {
        g_previousBuddyTransferSteps.push($('div.buddytransfer_steps > div:visible'));
        $('div.buddytransfer_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("BuddyTransfer", new { @action = "Prepare" }).SafeJavascriptStringEncode() %>?encryptedUserID=' + encodeURIComponent(encryptedUserID);
        $('#prepare_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }

    function showBuddyTransferConfirmation(sid) {
        g_previousBuddyTransferSteps.push($('div.buddytransfer_steps > div:visible'));
        $('div.buddytransfer_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("BuddyTransfer", new { @action = "Confirmation" }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }

    
//]]>
</script>

</asp:Content>

