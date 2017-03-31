<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<script runat="server"> 
    private void Page_Load(object sender, System.EventArgs e) { 
        Response.Status = "301 Moved Permanently"; 
        Response.AddHeader("Location","/Casino/Lobby"); 
    } 
</script>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"> </asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server"> </asp:Content>
