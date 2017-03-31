<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        string title = this.GetMetadata(".Title");
        if (title != null)
            this.Title = title.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());

        string desc = this.GetMetadata(".Description");
        if (desc != null)
            this.MetaDescription = desc.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());


        string keywords = this.GetMetadata(".Keywords");
        if (keywords != null)
            this.MetaDescription = keywords.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());
        base.OnPreRender(e);
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/DepositPage/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/DepositPage/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="javascript:;" itemprop="url" title="<%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>">
                    <span itemprop="title"><%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="deposit-wrapper" class="content-wrapper">
<ui:Header ID="Header1" runat="server" HeadLevel="h1">
    <%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode() %>
    -
    <%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>
</ui:Header>
<ui:Panel runat="server" ID="pnDeposit">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<div class="deposit_steps deposit_steps_<%=this.Model.UniqueName %>">
    <div id="prepare_step">
        <% using (Html.BeginRouteForm("Deposit", new { @action = "ProcessInPayTransaction", @paymentMethodName = this.Model.UniqueName }, FormMethod.Post, new { @id = "formProcessInPayTransaction", @onsubmit = "return false;" }))
           { %>
        <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
        <% Html.RenderPartial("InputViewInPay", this.Model); %>
        <% Html.RenderPartial(this.ViewData["PayCardView"] as string, this.Model); %>
        <% } // Form ended %>
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
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnErrorBack", @onclick = "returnPreviousDepositStep(); return false;" })%>
        </center>
    </div>
</div>

</ui:Panel>


</div>
<%  Html.RenderPartial("LocalConnection", this.ViewData); %>

<script language="javascript" type="text/javascript">
    //<![CDATA[
    jQuery('body').addClass('DepositPage').addClass('DepositStep2');
    var g_previousDepositSteps = new Array();


    function returnPreviousDepositStep() {
        if (g_previousDepositSteps.length > 0) {
            $('div.deposit_steps > div').hide();
            g_previousDepositSteps.pop().show();
        }
    }

    function showDepositError(errorText) {
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
        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
        $('div.deposit_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Confirmation", @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
    $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
}
//]]>
</script>

<script type="text/javascript">
    //<![CDATA[
    $(function () {
        $('#formProcessInPayTransaction').initializeForm();
    });

    var g_ProcessInPayFormCallback = null;
    function tryToSubmitProcessInPayForm(payCardID, callback) {
        $('#fldCurrencyAmount input[name="payCardID"]').val(payCardID);
        if (!$('#formProcessInPayTransaction').valid()) {
            if (callback !== null) callback();
            return false;
        }

        g_ProcessInPayFormCallback = callback;
        var options = {
            dataType: "json",
            type: 'POST',
            success: function (json) {
                if (g_ProcessInPayFormCallback !== null)
                    g_ProcessInPayFormCallback();

                if (!json.success) {
                    if (json.error === "OUTRANGE") {
                        json.error = "<%=this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>";
                    }
                    showDepositError(json.error);
                    return;
                }

                // <%-- trigger the DEPOSIT_TRANSACTION_PREPARED event --%>
                $(document).trigger('DEPOSIT_TRANSACTION_PREPARED', json.sid);
                if (json.showTC)
                    showDepositTermsAndConditions(json.sid);
                else
                    showDepositConfirmation(json.sid);
            },
            error: function (xhr, textStatus, errorThrown) {
                if (g_ProcessInPayFormCallback !== null)
                    g_ProcessInPayFormCallback();
                showDepositError(errorThrown);
            }
        };
        $('#formProcessInPayTransaction').ajaxForm(options);
        $('#formProcessInPayTransaction').submit();
        return true;
    }

    function isDepositInputFormValid() {
        try {
            if (validateBonusCodeVendor() != true) {
                return false;
            }
        } catch (ex) { }

        return $('#formProcessInPayTransaction').valid();
    }
    //]]>
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData); %>
<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">

</script>
</ui:MinifiedJavascriptControl>
</asp:content>

