<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        base.OnPreRender(e);
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
</script>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<ui:Header ID="Header1" runat="server" HeadLevel="h1">
    <%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode() %>
    -
    <%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>
</ui:Header>
<ui:Panel runat="server" ID="pnDeposit">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<div class="deposit_steps">
    <div id="prepare_step">
        <% Html.RenderPartial("InputView", this.Model); %>
        <% Html.RenderPartial(this.ViewData["PayCardView"] as string, this.Model); %>
    </div>
    <div id="terms_conditions_step" style="display:none">
    </div>
    <div id="confirm_step" style="display:none">
    </div>
    <div id="error_step" style="display:none">
        <center>
        <br /><br /><br />
        <%: Html.ErrorMessage("Internal Error.", false, new { id="deposit_error" })%>
        <br /><br /><br />
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnErrorBack", @onclick = "returnPreviousDepositStep(); return false;", @class="BackButton button" })%>
        </center>
    </div>
</div>

</ui:Panel>


</div>
<%  Html.RenderPartial("LocalConnection", this.ViewData); %>
<input type="hidden" id="hdOpener" />
<script type="text/javascript">
//<![CDATA[
    var g_previousDepositSteps = new Array();


    function returnPreviousDepositStep() {
        if (g_previousDepositSteps.length > 0) {
            $('div.deposit_steps > div').hide();
            g_previousDepositSteps.pop().show();
        }
    }

    function showDepositError(errorText) {
        try {
            if (self.parent !== null && self.parent != self) {
                var targetOrigin = '<%=this.GetMetadata("/Deposit/_Prepare_aspx.TargetOriginForPostMessage").SafeJavascriptStringEncode().DefaultIfNullOrWhiteSpace("") %>';
                if (targetOrigin.trim() == '') {
                    targetOrigin = top.window.location.href;
                }
                window.top.postMessage('{"user_id":<%=CM.State.CustomProfile.Current.UserID %>, "message_type": "deposit_result", "success": false, "message": "' + errorText + '"}', targetOrigin);
            }
        } catch (e) { console.log(e); }
        
        $('#error_step div.message_Text').text(errorText);
        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
        $('div.deposit_steps > div').hide();
        $('#error_step').show();
    }


    function showDepositTermsAndConditions(sid) {
        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
        $('div.deposit_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "BonusTC"}).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('#terms_conditions_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }

    function showDepositConfirmation(sid) {
        $(document.documentElement).css('overflow', 'hidden');
        $(document.body).css('overflow', 'hidden');

        var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Confirm", @paymentMethodName = this.Model.UniqueName}).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('<form style="display:none" target="_self" method="post" enctype="application/x-www-form-urlencoded"></form>').appendTo(document.body).attr('action', url).submit();

        self.redirectToReceiptPage = function () {
            var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
            window.location = url;
            return true;
        };
    }
//]]>
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

