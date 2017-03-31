<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box ContactUsBox CenterBox" id="ContactUsBox">
		<div class="BoxContent ContactContent">
          <div class="BoxInformation"><%=this.GetMetadata(".Information_HTML").HtmlEncodeSpecialCharactors()%></div>
			<% Html.RenderPartial("InputView"); %>
		</div>
	</div>

	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
</asp:Content>

