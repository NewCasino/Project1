<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="CM.Content" %>
<script language="C#" type="text/C#" runat="server">
    private string SideMenuPath
    {
        get { return "/Metadata/AboutUs"; }
    }
    private string CurrentPath { get { return "/Metadata/AboutUs/ContactUs"; } }
    private string BaseUrl { get { return "/AboutUs"; } }
</script>
<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="left-pane">
    <div class="sidemenu-container">
        <ui:Panel runat="server" ID="pnSideMenu" CssClass="sidemenupanel">
    
            <% 
                using (NavigationMenu menu = this.Html.BeginNavigationMenu(MenuType.SideMenu))
                {
                    string[] paths = Metadata.GetChildrenPaths(this.SideMenuPath);

                    if (paths != null)
                    {
                        foreach (string path in paths)
                        {
                            NavigationMenuItem item = new NavigationMenuItem()
                            {
                                Text = Metadata.Get(string.Format("{0}.Title", path)).DefaultIfNullOrEmpty(Path.GetFileNameWithoutExtension(path)),
                                Target = "_self",
                                NagivationUrl = BaseUrl + path.Substring(SideMenuPath.Length),
                                IsSelected = string.Equals(CurrentPath, path, StringComparison.OrdinalIgnoreCase),
                            };
                            menu.Items.Add(item);

                            // sub-categories
                            string[] subpaths = Metadata.GetChildrenPaths(path);
                            if (subpaths != null && subpaths.Length > 0)
                            {
                                foreach (string subpath in subpaths)
                                {
                                    item.Children.Add(new NavigationMenuItem()
                                    {
                                        Text = Metadata.Get(string.Format("{0}.Title", subpath)).DefaultIfNullOrEmpty(Path.GetFileNameWithoutExtension(subpath)),
                                        Target = "_self",
                                        NagivationUrl = BaseUrl + subpath.Substring(SideMenuPath.Length),
                                        IsSelected = string.Equals(CurrentPath, subpath, StringComparison.OrdinalIgnoreCase),
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
<div class="main-pane">
    <div id="contactus-wrapper" class="content-wrapper">
        <%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
        <ui:Panel runat="server" ID="pnContactUs">
        <div class="BoxInformation"><%=this.GetMetadata(".Information_HTML").HtmlEncodeSpecialCharactors()%></div>
        <% Html.RenderPartial("InputView", this.ViewData); %>

        </ui:Panel>

    </div>
</div>

</asp:content>
