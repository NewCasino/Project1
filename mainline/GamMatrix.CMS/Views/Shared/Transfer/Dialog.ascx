<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<div id="transfer-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnTransfer">


<br />
<div class="transfer_steps">
    <div id="prepare_step">
        <%if (Profile.IsInRole("Withdraw only"))
              Html.RenderPartial("GamblingRegulationsRestrictionMessage"); 
          else
              Html.RenderPartial("Prepare");
        %>
    </div>
    <div id="confirm_step" style="display:none">
    </div>
    <div id="receipt_step" style="display:none">
    </div>
    <div id="error_step" style="display:none">
        <center>
        <br /><br /><br />
        <%: Html.ErrorMessage("Internal Error.", false, new { id="transfer_error" })%>
        <br /><br /><br />
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousTransferStep(); return false;" })%>
        </center>
    </div>
</div>

</ui:Panel>
</div>

<script language="javascript" type="text/javascript">
//<![CDATA[
    $(function () {
        $('#transfer-wrapper').parents('div.simplemodal-container').css('border', '0px').css('background-color', 'transparent');
    });
    var g_previousTransferSteps = new Array();

    function returnPreviousTransferStep() {
        if (g_previousTransferSteps.length > 0) {
            $('div.transfer_steps > div').hide();
            g_previousTransferSteps.pop().show();
        }
    }

    function showTransferError(errorText) {
        $('#error_step div.message_Text').text(errorText);
        g_previousTransferSteps.push($('div.transfer_steps > div:visible'));
        $('div.transfer_steps > div').hide();
        $('#error_step').show();
    }

    

<%
    if (Settings.Transfer_RemoveConfirmationForPopup)
    { %>
        function showTransferConfirmation(sid) {
            showTransferReceipt(sid);
        }
 <% }
    else
    { %>
        function showTransferConfirmation(sid) {
            g_previousTransferSteps.push($('div.transfer_steps > div:visible'));
            $('div.transfer_steps > div').hide();
            var url = '<%= this.Url.RouteUrl("Transfer", new { @action = "Confirmation" }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
            $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
        }
        <%
    }
 %>

    function showTransferReceipt(sid) {
        g_previousTransferSteps.push($('div.transfer_steps > div:visible'));
        $('div.transfer_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("Transfer", new { @action = "Confirm" }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('#receipt_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url, null, function () { setTimeout(function () { $(document).trigger('BALANCE_UPDATED'); }, 0); });
    }
//]]>
</script>



