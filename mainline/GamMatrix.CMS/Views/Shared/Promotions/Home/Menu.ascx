<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="CM.Content" %>

<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
</script>

<ui:Panel runat="server" ID="pnPromotionMenu" CssClass="promotion-menu">
<ul>
<% 
    string[] paths = Metadata.GetChildrenPaths(this.MetadataPath);

    if (paths != null)
    {        
        for (int i = 0; i < paths.Length;i++ )
        {
            string title = Metadata.Get(string.Format("{0}.Title", paths[i])).DefaultIfNullOrEmpty("Untitled");
            string name = paths[i].Substring(paths[i].LastIndexOf("/") + 1).ToLowerInvariant();
            
            %>
                <li><span><a href="<%= name.Equals("all", StringComparison.OrdinalIgnoreCase)?this.Url.RouteUrl("Promotions"):this.Url.RouteUrl("Promotions", new { @action= name}) %>"><%= title.HtmlEncodeSpecialCharactors() %></a></span></li>
            <%
        }
    }
%>
</ul>
</ui:Panel>