﻿<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgDepositLimitInfoRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox CenterBox">
		<div class="BoxContent">
			<% 
				Html.RenderPartial("/Components/SettingsNavigator", new SettingsNavigatorViewModel { CurrentTab = SettingsNavigatorViewModel.Sections.DepositLimit });
				Html.RenderPartial("InputView", this.Model); 
			%>
		</div>
	</div>
	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
</asp:Content>
