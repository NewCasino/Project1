<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>


<script type="text/C#" runat="server">
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
    protected string DeclindedErrorCodes()
    {
        string items = "";
        foreach (var item in Settings.DeclindedDeposit_SensitiveErrorCodes)
        {
            if (!string.IsNullOrWhiteSpace(item))
            {
                items += "," + item.Trim().SafeJavascriptStringEncode();
            }
        }
        return items == "" ? "" : items.Substring(1, items.Length - 1);
    }
    protected override void OnPreRender(EventArgs e)
    {
        if(Profile.IsAuthenticated && Profile.UserCountryID == 230 && !IsAcceptUKTerms())
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
 
<script language="javascript" type="text/javascript">
    //<![CDATA[
    var g_previousDepositSteps = new Array();
    var DeclindedErrorCodes = "<%=DeclindedErrorCodes()%>" == "" ? null : "<%=DeclindedErrorCodes()%>".split(',');
    var DeclindedURL = "<%=Settings.DeclindedDeposit_SuggestionUrl.SafeJavascriptStringEncode().DefaultIfNullOrEmpty("about:blank")%>";

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
        if (DeclindedErrorCodes != null && DeclindedURL != "about:blank") {
            for (var i = 0; i < DeclindedErrorCodes.length; i++) {
                if (errorText.indexOf(DeclindedErrorCodes[i]) > -1) {
                    var id = '_DeclindedIframe_' + (new Date).getTime().toString();
                    var $iframe = $('<iframe src="' + DeclindedURL  + '" name="DeclindedIframe"  marginwidth="0"  marginheight="0" align="middle" scrolling="auto" frameborder="0" hspace="0" vspace="0" class="DeclindedIframe" id="DeclindedIframe" title="DeclindedIframe Iframe" allowtransparency="true" border="0" style=" min-width:540px;min-height:500px; width:100%;height:100%;"></iframe>');
                    $iframe.modalex($(window).width() * 0.8, $(window).height() * 0.8 , true, self.document.body);
                    break;
                }
            }
            //return;
        }
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
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData); %>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('DepositPage').addClass('DepositStep2');
</script>
</ui:MinifiedJavascriptControl>

</asp:content>