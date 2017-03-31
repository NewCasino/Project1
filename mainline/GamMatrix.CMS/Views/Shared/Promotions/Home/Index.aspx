<%@ Page Language="C#" PageTemplate="/Promotions/PromotionsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<script runat="server" type="text/C#">
    protected override void OnInit(EventArgs e)
    {
        this.ViewData["MetadataPath"] = "/Metadata/Promotions";
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<ui:Panel runat="server" ID="pnPromotion">
    <%Html.RenderPartial("Menu", this.ViewData.Merge()); %>
    <%Html.RenderPartial("BlockList", this.ViewData.Merge(new { @Category = this.ViewData["actionName"], @SubCategory = this.ViewData["parameter"] })); %>
</ui:Panel>
</asp:Content>

