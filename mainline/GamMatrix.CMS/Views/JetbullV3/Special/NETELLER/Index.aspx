<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

<link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/JetbullV2/special_neteller.css" /></asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%=this.GetMetadata(".Html")%> 
</asp:Content>

