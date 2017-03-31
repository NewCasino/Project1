<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="CM.Content" %>

<script language="C#" type="text/C#" runat="server">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
    private string Category { get { return this.ViewData["Category"] as string; } }
    private string SideMenuTitle { get { return this.ViewData["SideMenuTitle"] as string; } }
    private string SubCategory { get { return this.ViewData["SubCategory"] as string; } }
    private string CurrentPath { get; set; }
    private string CurrentTitle
    {
        get
        {
            if (string.IsNullOrWhiteSpace(CurrentPath)) return string.Empty;
            return Metadata.Get(string.Format("{0}.Title", CurrentPath));
        }
    }
</script>
<div class="left-pane">
    <div class="sidemenu-container">
    <%: Html.H1( SideMenuTitle ) %>

    <ui:Panel runat="server" ID="pnSideMenu" CssClass="sidemenupanel">
    
    <% 
        string baseUrl = string.Empty;
        Match m = Regex.Match(this.Request.Path, @"^\/(?<baseUrl>\w+)(\/.*)?", RegexOptions.ECMAScript);
        if (m.Success)
        {
            baseUrl = string.Format( "/{0}", m.Groups["baseUrl"].Value );
        }
        
        using( NavigationMenu menu = this.Html.BeginNavigationMenu( MenuType.SideMenu ) )
        {
            string[] paths = Metadata.GetChildrenPaths(this.MetadataPath);

            if (paths != null)
            {
                foreach (string path in paths)
                {
                    NavigationMenuItem item = new NavigationMenuItem()
                    {
                        Text = Metadata.Get( string.Format("{0}.Title", path) ).DefaultIfNullOrEmpty( Path.GetFileNameWithoutExtension(path) ),
                        Target = "_self",
                        NagivationUrl = baseUrl + path.Substring(MetadataPath.Length),
                        IsSelected = string.Equals( CurrentPath, path, StringComparison.OrdinalIgnoreCase),
                    };
                    menu.Items.Add(item);
                    
                    // sub-categories
                    string[] subpaths = Metadata.GetChildrenPaths(path);
                    if (subpaths != null && subpaths.Length > 0)
                    {
                        foreach (string subpath in subpaths)
                        {
                            item.Children.Add( new NavigationMenuItem()
                            {
                                Text = Metadata.Get(string.Format("{0}.Title", subpath)).DefaultIfNullOrEmpty(Path.GetFileNameWithoutExtension(subpath)),
                                Target = "_self",
                                NagivationUrl = baseUrl + subpath.Substring(MetadataPath.Length),
                                IsSelected = string.Equals( CurrentPath, subpath, StringComparison.OrdinalIgnoreCase),
                            });
                        }
                    }
                }
            }
        } 
    %>

    </ui:Panel>
    </div>
</div>

