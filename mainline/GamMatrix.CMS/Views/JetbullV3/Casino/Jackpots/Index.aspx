<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<h1 class="PageTitle"><%=this.GetMetadata(".PageTitle").SafeHtmlEncode() %></h1>
	<div id="framework" class="Container">
		<div class="Zone Container Games">
			<% this.Html.RenderPartial("JackpotList", this.ViewData.Merge(new{IsHall=true})); %>
		</div>
	</div>
</asp:Content>

