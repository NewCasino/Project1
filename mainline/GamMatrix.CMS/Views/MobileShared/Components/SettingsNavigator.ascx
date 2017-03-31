<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.SettingsNavigatorViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<ul class="Tabs Cols-3 Container">
	<li class="Col Tab <%= Model.HasActive(SettingsNavigatorViewModel.Sections.OtherSettings, "ActiveTab")%>">
		<a class="TabLink" id="otherTab" href="<%= Url.RouteUrl("AccountSettings") %>"><%= this.GetMetadata(".OtherSettings").HtmlEncodeSpecialCharactors()%></a>
	</li>
	<li class="Col Tab <%= Model.HasActive(SettingsNavigatorViewModel.Sections.SelfExclusion, "ActiveTab")%>">
		<a class="TabLink" id="exclusionTab" href="<%= Url.RouteUrl("SelfExclusion") %>"><%= this.GetMetadata(".SelfExclusion").HtmlEncodeSpecialCharactors()%></a>
	</li>
	<li class="Col Tab <%= Model.HasActive(SettingsNavigatorViewModel.Sections.DepositLimit, "ActiveTab")%>">
		<a class="TabLink" id="limitTab" href="<%= Url.RouteUrl("DepositLimit") %>"><%= this.GetMetadata(".DepositLimit").HtmlEncodeSpecialCharactors()%></a>
	</li>
</ul>
<%if (!Model.HideSubHeading) { %>
<h2 class="SubHeading"><%= this.GetMetadata("." + Model.GetActiveTabId()).HtmlEncodeSpecialCharactors()%></h2>
<% } %>
<script type="text/javascript">
	$(function () {
		$('.ActiveTab .TabLink').removeAttr('href');
	});
</script>