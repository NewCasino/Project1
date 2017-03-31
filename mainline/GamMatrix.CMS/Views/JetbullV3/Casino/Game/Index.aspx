<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<CasinoEngine.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        Response.Clear();
        Response.ClearHeaders();
        Response.AddHeader("Location", "/Casino/Game/Info/" + this.Model.Slug.DefaultIfNullOrEmpty(this.Model.ID));
        Response.StatusCode = 301;
        Response.Flush();
        Response.End();
        return;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

</asp:Content>

