<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<script language="C#" type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        if (Request.QueryString["depositAmount"] != null)
        {
            var amount = Request.QueryString["depositAmount"].ToString();
            if (!string.IsNullOrEmpty(amount))
            {
                decimal requestAmount;
                if (decimal.TryParse(Regex.Replace(amount, @"[^\d\.]", string.Empty), out requestAmount))
                {
                    HttpCookie cookie = new HttpCookie("depositAmount", requestAmount.ToString("n2", CultureInfo.InvariantCulture));
                    if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
                        cookie.Domain = SiteManager.Current.SessionCookieDomain.Trim();
                    cookie.HttpOnly = true;
                    cookie.Secure = false;
                    Response.Cookies.Remove("depositAmount");
                    Response.Cookies.Add(cookie);
                }
            }
        }
        base.OnPreRender(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.AnonymousCachedPartial("PendingWithdrawWidget", this.ViewData)%>

<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnDeposit">
<%: Html.AnonymousCachedPartial("PaymentMethodFilterView", this.ViewData)%>
</ui:Panel>
</div>

<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<% Html.RenderPartial("SetLimitPopup", this.ViewData.Merge(new { })); %>
</asp:Content>

