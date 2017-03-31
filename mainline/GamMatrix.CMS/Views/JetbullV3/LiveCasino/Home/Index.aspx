<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%: Html.WarningMessage("We are upgrading our live casino service, will be back online soon.") %>
</asp:Content>
