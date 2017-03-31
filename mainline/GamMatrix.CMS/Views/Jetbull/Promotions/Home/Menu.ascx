<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="CM.Content" %>

<script runat="server" type="text/C#">
    private string MenuPath { get { return this.ViewData["MenuPath"] as string; } }
</script>

<ui:Panel runat="server" ID="pnPromotionMenu" CssClass="promotion-menu">
<ul>
<% 
    string[] paths = Metadata.GetChildrenPaths(this.MenuPath);

    if (paths != null)
    {        
        for (int i = 0; i < paths.Length;i++ )
        {
            string title = Metadata.Get(string.Format("{0}.Text", paths[i])).DefaultIfNullOrEmpty("Untitled");
            string name = paths[i].Substring(paths[i].LastIndexOf("/") + 1).ToLowerInvariant();
            string url = Metadata.Get(string.Format("{0}.Url", paths[i])).DefaultIfNullOrEmpty("#");
            var active = string.Equals(Request.Url.PathAndQuery, url, StringComparison.OrdinalIgnoreCase);
            %>
                <li class="<%=active? "active" : "" %>"><span><a href="<%=url  %>"><%= title.HtmlEncodeSpecialCharactors() %></a></span></li>
            <%
        }
    }
%>
</ul>
</ui:Panel>