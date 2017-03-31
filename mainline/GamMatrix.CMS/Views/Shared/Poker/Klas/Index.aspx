<%@ Page Language="C#" PageTemplate="/Poker/PokerMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        CasinoKlasAPIRequest request = new CasinoKlasAPIRequest()
        {
            OpeningGameMethod = true,
            UserId = Profile.UserID,
        };
        GamMatrixClient client = new GamMatrixClient();
        request = client.SingleRequest<CasinoKlasAPIRequest>(request);

        string url = request.OpeningGameMethodURLResult;
        Response.Redirect(url);
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

</asp:Content>

