<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="CM.State" %>

<script language="C#" type="text/C#" runat="server">
    private string GetMetadataPath()
    {
        return this.ViewData["MetadataPath"] as string;
    }

    private void PopulateMenus(NavigationMenu menu, string[] paths)
    {
        if( paths == null )
            return;
        foreach (string path in paths)
        {
            
            menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = path });

            string[] children = Metadata.GetChildrenPaths(path);
        }
    }

    private NavigationMenuItem GetNavigationMenuItem(string path)
    {
        NavigationMenuItem item = new NavigationMenuItem();

        item.Text = this.GetMetadata(string.Format("{0}.Text", path))
            .DefaultIfNullOrEmpty(Path.GetFileNameWithoutExtension(path));

        item.Target = this.GetMetadata(string.Format("{0}.Target", path))
            .DefaultIfNullOrEmpty("_self");

        item.CssClass = this.GetMetadata(string.Format("{0}.CssClass", path));

        item.ShowedOnCountries = this.GetMetadata(string.Format("{0}.ShowedOnCountries", path));

        string url = this.GetMetadata(string.Format("{0}.Url", path));
        if (string.IsNullOrWhiteSpace(url))
        {
            try
            {
                string routeName = this.GetMetadata(string.Format("{0}.RouteName", path));
                if (!string.IsNullOrWhiteSpace(routeName))
                    url = this.Url.RouteUrl(routeName);
            }
            catch
            {
            }
        }
        if (string.IsNullOrWhiteSpace(url))
            url = "#";
        item.NagivationUrl = url;
        
        string urlMatchExpression = this.GetMetadata(string.Format("{0}.UrlMatchExpression", path) );
        if (!string.IsNullOrWhiteSpace(urlMatchExpression))
        {
            try
            {
                Match m = Regex.Match(Request.Url.PathAndQuery, urlMatchExpression.Trim(), RegexOptions.Singleline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                item.IsSelected = m.Success;
            }
            catch
            {
            }
        }
        else if( url != "#" )
        {
            item.IsSelected = Request.Url.PathAndQuery.StartsWith(url, StringComparison.OrdinalIgnoreCase); 
        }


        string[] paths = Metadata.GetChildrenPaths(path);
        if (paths != null)
        {
            foreach (string childPath in paths)
            {
                var childItem = GetNavigationMenuItem(childPath);
                if (!string.IsNullOrWhiteSpace(item.ShowedOnCountries))
                {
                    string[] ShowedOnCountries = childItem.ShowedOnCountries.Split(new char[] { ',' });
                    if (!(ShowedOnCountries.Contains(CustomProfile.Current.IpCountryID.ToString()) || ShowedOnCountries.Contains(CustomProfile.Current.UserCountryID.ToString())))
                    {
                        continue;
                    }
                }
                item.Children.Add(childItem);
            }

            if(paths.Length>0 && url=="#")
            {
                item.NagivationUrl="javascript:void(0)";
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
            if (!string.IsNullOrWhiteSpace(item.ShowedOnCountries))
            {
                string[] ShowedOnCountries = item.ShowedOnCountries.Split(new char[] { ',' });
                if (!(ShowedOnCountries.Contains(CustomProfile.Current.IpCountryID.ToString()) || ShowedOnCountries.Contains(CustomProfile.Current.UserCountryID.ToString())))
                {
                    continue;
                }
            }
            menu.Items.Add(item);
        }
    }
} 
%>