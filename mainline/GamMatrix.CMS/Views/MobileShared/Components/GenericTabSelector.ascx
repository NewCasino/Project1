<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.GenericTabSelectorViewModel>" %>

<ul class="Tabs Cols-<%= Model.Items.Count %> Container" id="<%= Model.ComponentId.SafeHtmlEncode()%>">
	<% 
	for (int i = 0; i < Model.Items.Count; i++)
	{
	%>
	<li class="Col Tab" <%= Model.GetItemAttributeHtml(i) %>>
		<a class="TabLink" href="#"><%= Model.GetItemName(i).SafeHtmlEncode()%></a>
	</li>
	<% } %>
</ul>

<% 
	if (!Model.DisableJsCode)
	{
%>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
	function GenericTabSelector(domSelector) {
		var list = new CMS.views.DataList(domSelector, 'ActiveTab');

		return {
			evt: list.evt,
			select: list.select,
			deselect: list.deselect,
			data: list.data
		}
	}
</script>
</ui:MinifiedJavascriptControl>
<%
	}
%>