<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<script type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {        
        base.OnPreRender(e);
        
        HttpCookie cookie = new HttpCookie("_cvm", "1");
        cookie.Secure = false;
        //cookie.Expires
        cookie.HttpOnly = true;
        HttpContext.Current.Response.Cookies.Add(cookie);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnDeposit">
<%if (Profile.IsAnonymous) { %>
<% Html.RenderPartial("PaymentMethodList", this.ViewData.Merge(new { CountryID = -1, Currency = "EUR" })); %>
<%} else { %>
<% Html.RenderPartial("PaymentMethodList", new { @country = Profile.UserCountryID, @currency = Profile.UserCurrency }); %>
<%} %>
</ui:Panel>
</div>
</asp:Content>