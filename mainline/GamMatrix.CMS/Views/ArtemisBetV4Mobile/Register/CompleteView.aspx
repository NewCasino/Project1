<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box UserBox CenterBox">
<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { CurrentStep = 3 }); %>

<div class="BoxContent TextBox FinalStep">
<%= this.GetMetadata(".Html") %>
<div class="AccountButtonContainer">
<a href="<%= Url.RouteUrl("Deposit", new{ @action = "Index" }) %>" class="Button AccountButton"> <strong class="ButtonText"><%= this.GetMetadata(".Deposit").SafeHtmlEncode()%></strong> </a>
<script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/regconfirm?" async defer></script>
<script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/loggedin?" async defer></script>
</div>
</div>
</div>

<script type="text/javascript">
$('#loginLink').remove();

$(CMS.mobile360.Generic.init);
</script>
</asp:Content>

