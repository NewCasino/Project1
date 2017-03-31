<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="changepwd-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata("/ChangePwd/_Index_aspx.HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnChangePwd">


<%
        Html.RenderPartial("InputView", this.ViewData);
%>

</ui:Panel>

</div>


</asp:Content>

