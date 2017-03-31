<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
    private string GetContentMetaPath()
    {
		return string.Format("{0}/{1}", this.GetMetadata("/TermsConditions/_Index_aspx.HTML"), this.ViewData["Category"] as string);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<% Html.RenderPartial("/Components/InfoContent", new InfoContentViewModel(GetContentMetaPath())); %>
</asp:Content>

