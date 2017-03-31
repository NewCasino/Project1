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

    private string CurrentContent
    {
        get
        {
            if (string.IsNullOrWhiteSpace(CurrentPath)) return string.Empty;
            return Metadata.Get(string.Format("{0}.Html", CurrentPath));
        }
    }

    private string CurrentPartialView
    {
        get
        {
            if (string.IsNullOrWhiteSpace(CurrentPath)) return string.Empty;
            return Metadata.Get(string.Format("{0}.PartialView", CurrentPath));
        }
    }

    protected bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }

    protected override void OnInit(EventArgs e)
    {
        string[] paths = Metadata.GetChildrenPaths(this.MetadataPath);
        if (paths.Length > 0)
        {
            if (!string.IsNullOrWhiteSpace(this.Category))
            {
                string path = string.Format("{0}/{1}", MetadataPath, Category);
                CurrentPath = paths.FirstOrDefault(p => string.Equals(p, path, StringComparison.OrdinalIgnoreCase));
                if (!string.IsNullOrWhiteSpace(SubCategory))
                {
                    CurrentPath = string.Format("{0}/{1}", path, SubCategory);
                }
            }
            if (string.IsNullOrWhiteSpace(CurrentPath))
                CurrentPath = paths[0];
        }
        this.Page.Title = this.CurrentTitle + this.GetMetadata(string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0}.TitlePostfix", MetadataPath));
        base.OnInit(e);
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
                    baseUrl = string.Format("/{0}", m.Groups["baseUrl"].Value);
                }

                using (NavigationMenu menu = this.Html.BeginNavigationMenu(MenuType.SideMenu))
                {
                    string[] paths = Metadata.GetChildrenPaths(this.MetadataPath);

                    if (paths != null)
                    {
                        foreach (string path in paths)
                        {
                            string isUK = Metadata.Get(string.Format("{0}.IsUK", path)).DefaultIfNullOrEmpty("No");
                            if (!(Profile.IpCountryID == 230 || Profile.UserCountryID == 230) && SafeParseBoolString(isUK, false)) continue;

                            NavigationMenuItem item = new NavigationMenuItem()
                            {
                                Text = Metadata.Get(string.Format("{0}.Title", path)).DefaultIfNullOrEmpty(Path.GetFileNameWithoutExtension(path)),
                                Target = "_self",
                                NagivationUrl = baseUrl + path.Substring(MetadataPath.Length),
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
                                        NagivationUrl = baseUrl + subpath.Substring(MetadataPath.Length),
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


    <div class="content-wrapper">
        <% if (!string.IsNullOrEmpty(CurrentPartialView))
           { %>
        <% Html.RenderPartial(CurrentPartialView); %>
        <% } %>
        <% else %>
        <% { %>
        <%: Html.H1(CurrentTitle)%>
        <ui:Panel runat="server" ID="pnLiteral">
            <%= CurrentContent.HtmlEncodeSpecialCharactors() %>
        </ui:Panel>
        <% } %>
    </div>

</div>
<div style="clear: both"></div>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        document.title = '<%= this.CurrentTitle.SafeJavascriptStringEncode() + this.GetMetadata(string.Format(System.Globalization.CultureInfo.InvariantCulture,"{0}.TitlePostfix", this.MetadataPath)).SafeJavascriptStringEncode() %>';
    });
</script>
