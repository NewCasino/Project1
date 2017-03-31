<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div class="UserBox CenterBox">
		<div class="BoxContent">
		<% Html.RenderPartial("ClaimReward", this.ViewData.Merge(new { })); %>
		</div>
	</div>
	<script type="text/javascript">
	    $(CMS.mobile360.Generic.init);
	</script>
</asp:Content>

