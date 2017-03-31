<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div class="UserBox CenterBox ProfileBox EditProfileBox <% if (Settings.MobileV2.IsV2ProfileEnabled) { %> ProfileBox_V2 <% } %>" id="EditProfileBox">
		<div class="BoxContent ProfileContent EditProfileContent" id="EditProfileContent">
			<% Html.RenderPartial("InputView", this.Model); %>
		</div>
	</div>
	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
</asp:Content>
