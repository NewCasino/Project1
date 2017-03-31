<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<script runat="server">
    private string linkBackURL = string.Empty;
    private string GeneraterLinkBackUrl()
    {
        if (SiteManager.Current.HttpsPort > 0)
        {
            return string.Format("https://{0}:{1}{2}"
                , Request.Url.Host
                , SiteManager.Current.HttpsPort
                , this.Url.RouteUrl("Deposit", new { @action = "Index" })
                );
        }

        return string.Format("http://{0}:{1}{2}"
                , Request.Url.Host
                , SiteManager.Current.HttpPort
                , this.Url.RouteUrl("Deposit", new { @action = "Index" })
                , DateTime.Now.Ticks
                );
    }
    protected override void OnLoad(EventArgs e)
    {
        linkBackURL = ViewData["returnUrl"] == null ? GeneraterLinkBackUrl() : ViewData["returnUrl"].ToString();
        base.OnLoad(e);
    }
</script>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <form action="<%=this.GetMetadata("/Metadata/PaymentMethod/Neteller.QuickSignup_URL") %>" method="post" id="QuickRegisterForm">
    <%: Html.Hidden("linkbackurl", linkBackURL)%>
    <%: Html.Hidden("merchantid", ViewData["merchantid"])%>
    <%: Html.Hidden("merchant", ViewData["merchant"])%>
    <%: Html.Hidden("currency", ViewData["currency"])%>
    <%: Html.Hidden("firstname", ViewData["firstname"])%>
    <%: Html.Hidden("lastname", ViewData["lastname"])%>
    <%: Html.Hidden("email", ViewData["email"])%>
    <%: Html.Hidden("address", ViewData["address"])%>
    <%: Html.Hidden("address2", ViewData["address2"])%>
    <%: Html.Hidden("city", ViewData["city"])%>
    <%: Html.Hidden("country", ViewData["country"])%>
    <%: Html.Hidden("postcode", ViewData["postcode"])%>
    <%: Html.Hidden("phone1", ViewData["phone1"])%>
    <%: Html.Hidden("phone1type", ViewData["phone1type"])%>
    <%: Html.Hidden("phone2", ViewData["phone2"])%>
    <%: Html.Hidden("phone2type", ViewData["phone2type"])%>
    <%: Html.Hidden("gender", ViewData["gender"])%>
    <%: Html.Hidden("dob", ViewData["dob"])%>
    <%: Html.Hidden("lang", ViewData["lang"])%>
    </form>
    <ui:MinifiedJavascriptControl runat="server" ID="MinifiedJavascriptControl1" AppendToPageEnd="true" Enabled="false">
        <script type="text/javascript">
            $(function () {
                $("#QuickRegisterForm").submit();
            });
        </script>
    </ui:MinifiedJavascriptControl>
</asp:Content>
