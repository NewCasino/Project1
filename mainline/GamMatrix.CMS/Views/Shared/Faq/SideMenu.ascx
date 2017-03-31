<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>

<script language="C#" type="text/C#" runat="server">
    private string GetMetadataPath()
    {
        return this.ViewData["MetadataPath"] as string;
    }
    private string _parametersPath;
    private string GetParametersPath()
    {
        if (_parametersPath != null)
            return _parametersPath;
        if (Parameters.Count ==  0)
        {
            _parametersPath = string.Empty;

        }
        else
        {
            _parametersPath = string.Join("/", Parameters);
        }

        return _parametersPath;
    }
    private bool CheckSelected(string metadataPath)
    {
        if (string.IsNullOrEmpty(metadataPath) || Parameters.Count == 0)
            return false;

        var subPath = GetSubPath(metadataPath);
        if (GetParametersPath().Equals(subPath, StringComparison.InvariantCultureIgnoreCase))
            return true;

        if (GetParametersPath().ToLower().StartsWith(subPath.ToLower()))
            return true;

        return false;

    }

    private List<string> _parameters;
    private List<string> Parameters
    {
        get
        {
            if (_parameters != null)
                return _parameters;

            if (ViewData["Parameters"] != null)
                _parameters = ViewData["Parameters"] as List<string>;
            else
                _parameters = new List<string>();
            return _parameters;
        }
    }

    private string GetSubPath(string metadataPath)
    {
        return metadataPath.Substring(GetMetadataPath().Length).TrimStart('/').TrimEnd('/');
    }
    private string GetItemUrl(string metadataPath)
    {
        return "/Faq/" + GetSubPath(metadataPath);
    }


    private NavigationMenuItem GetNavigationMenuItem(string path)
    {
        NavigationMenuItem item = new NavigationMenuItem();

        item.Text = this.GetMetadata(string.Format("{0}.Title", path))
            .DefaultIfNullOrEmpty(Path.GetFileNameWithoutExtension(path));

        item.Target = this.GetMetadata(string.Format("{0}.Target", path))
            .DefaultIfNullOrEmpty("_self");

        item.CssClass = Path.GetFileNameWithoutExtension(path.TrimEnd('/'));// this.GetMetadata(string.Format("{0}.CssClass", path));

        string url = GetItemUrl(path);

        item.NagivationUrl = url;


        item.IsSelected = CheckSelected(path);


        string[] paths = Metadata.GetChildrenPaths(path);
        if (paths != null)
        {
            foreach (string childPath in paths)
            {
                var thridPaths = Metadata.GetChildrenPaths(childPath);
                if (thridPaths != null && thridPaths.Length > 0)
                {
                    item.Children.Add(GetNavigationMenuItem(childPath));
                }
            }
        }

        return item;
    }
</script>

<% 
using( NavigationMenu menu = this.Html.BeginNavigationMenu( MenuType.SideMenu ) )
{
    string [] paths = Metadata.GetChildrenPaths(this.GetMetadataPath());

    if (paths != null)
    {
        foreach (string path in paths)
        {
            NavigationMenuItem item = GetNavigationMenuItem(path);
            menu.Items.Add(item);
        }
    }
} 
%>