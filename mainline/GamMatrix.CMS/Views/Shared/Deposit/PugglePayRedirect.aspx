<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    private bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }

    private PaymentMethod paymentMethod = null;
    private PaymentMethod GetPaymentMethod()
    {
        if (paymentMethod != null)
            return paymentMethod;

        var paymentMethodName = this.ViewData["PaymentMethodName"].ToString();
        paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
        return paymentMethod;
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<!-- 1. Element where the form is inserted. -->
<div id="pugglepay-authorize"></div>

<!-- 2. PugglePay JavaScript. -->
<script src="<%=this.Model.RequestFields["pugglepay_api_url"] %>"></script>

<!-- 3. Define callback and call authorize. -->
<script type="text/javascript">
    function redirectToReceipt() {
        var success = false;
        var url = '<%= this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = this.ViewData["PaymentMethodName"], @sid = this.Model.Record.Sid }).SafeJavascriptStringEncode() %>';
        try { if (self.opener !== null && self.opener.redirectToReceiptPage(url)) { success = true; } } catch (e) { }
        if (!success)
            try { if (self.parent !== null && self.parent != self && self.parent.redirectToReceiptPage(url)) { success = true; } } catch (e) { }

        var paymentPopupEnable  = <%= SafeParseBoolString(Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnablePopup"), true)  ? ((Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnabledPopup_Vendors").Contains(GetPaymentMethod().UniqueName) || Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnabledPopup_Vendors").Contains(GetPaymentMethod().VendorID.ToString())) ? "true" : "false") : "false" %>;
        if (!paymentPopupEnable)
            closeSelf();
    }

    function closeSelf() {
        top.window.opener = top;
        top.window.open('', '_parent', '');
        top.window.close();
    }

    var onSuccess = function () {
        var options = {
            dataType: "json",
            type: 'POST',
            success: function (json) {
                redirectToReceipt();
            },
            error: function (xhr, textStatus, errorThrown) {
                //showDepositError(errorThrown);
                redirectToReceipt();
            }
        };
        $('#formSuccess').ajaxForm(options);
        $('#formSuccess').submit();
    };
    PugglePay.authorize("<%=this.Model.RequestFields["authorization_id"]%>", onSuccess);
</script>

<!-- 4. Form used for posting on authorization success. -->
<form id="formSuccess" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "PugglePayPostback", @paymentMethodName = this.ViewData["PaymentMethodName"], @sid = this.Model.Record.Sid, @authorizationID = this.Model.RequestFields["authorization_id"] }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
</form>
</asp:content>

