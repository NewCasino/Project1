<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox NoHeadBox">
    <div class="BoxContent">
		<% Html.RenderPartial("InputView", this.ViewData); %>
    </div>
</div>
<script type="text/javascript">
	$(CMS.mobile360.Generic.input);
</script>
</asp:Content>