<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script type="text/C#" runat="server">
    private string GetCompleteUrl()
    {
        return this.Url.RouteUrl("Register", new { @action = "Complete" });
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<%if (!Settings.Session.SecondFactorAuthenticationEnabled) { %>
<meta http-equiv="refresh" content="0; url=<%= GetCompleteUrl().SafeHtmlEncode() %>" />
<%}%>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<%if (Settings.Session.SecondFactorAuthenticationEnabled) {

        TwoFactorAuth.SecondFactorAuthSetupCode setupCode = ViewData["TwoFactorAuthSetupCode"] as TwoFactorAuth.SecondFactorAuthSetupCode;
        %>
<div class="two-factor-qrcode">
    <img src="<%=setupCode.QrCodeImageUrl %>"/>
    <label><%=setupCode.SetupCode %></label>
</div>
<%} else {%>
    <script type="text/javascript">
    self.location = '<%= GetCompleteUrl().SafeJavascriptStringEncode() %>';
    </script>
<%}%>


</asp:Content>

