<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="System.Globalization" %>
<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);        
    }

    private NavigationMenuItem GetNavigationMenuItem(string category)
    {
        NavigationMenuItem item = new NavigationMenuItem();
        item.Text = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Title", category));
        item.NagivationUrl = "javascript:void(0)";
        item.Target = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Target", category)).DefaultIfNullOrEmpty("_top");

        foreach (string path in Metadata.GetChildrenPaths(category))
        {
            NavigationMenuItem childItem = new NavigationMenuItem();
            childItem.Text = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Title", path));
            childItem.NagivationUrl = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Url", path));
            childItem.Target = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Target", path)).DefaultIfNullOrEmpty("_blank");

            if (string.IsNullOrWhiteSpace(childItem.Text) )
            {
                continue;
            }

            if (string.IsNullOrEmpty(childItem.NagivationUrl))
            {
                string subPath = path.Substring(0, path.LastIndexOf("/"));
                subPath = (subPath.Substring(subPath.LastIndexOf("/")) + path.Substring(path.LastIndexOf("/"))).ToLowerInvariant();

                childItem.NagivationUrl = this.Url.RouteUrl("Promotions_TermsConditions") + subPath;
            }
            
            item.Children.Add(childItem);
        }


        return item;
    }
</script>


<ui:Panel runat="server" CssClass="promoton-list" ID="pnPromotionList">
<% 
    using (NavigationMenu menu = this.Html.BeginNavigationMenu(MenuType.SideMenu))
    {
        foreach (string category in Metadata.GetChildrenPaths(MetadataPath))
        {
            NavigationMenuItem item = GetNavigationMenuItem(category);
            if( item.Children.Count > 0 )
                menu.Items.Add(item);
        }
    } 
%>
</ui:Panel>

