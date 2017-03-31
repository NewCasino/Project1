<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<CM.db.cmUser>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox CenterBox ProfileBox <% if (Settings.MobileV2.IsV2ProfileEnabled) { %> ProfileBox_V2 <% } %>" id="ProfileBox">
		<div class="BoxContent ProfileContent" id="ProfileContent">
		<% Html.RenderPartial("DisplayView", this.ViewData.Merge(new { })); %>
		</div>
	</div>
	<script type="text/javascript">
		$(CMS.mobile360.Generic.init);
	</script>
</asp:Content>

