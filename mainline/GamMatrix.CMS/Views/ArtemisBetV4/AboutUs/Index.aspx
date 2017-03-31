<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" %>

<script runat="server"> 
    private void Page_Load(object sender, System.EventArgs e) {   
        if (string.Equals(this.ViewData["actionName"].ToString(), "contactus", StringComparison.InvariantCultureIgnoreCase)){
            Response.Status = "301 Moved Permanently"; 
            Response.AddHeader("Location","/contactus");     
        }
    } 
</script>
<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
   <div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/AboutUs/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/AboutUs/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
    <div class="AboutMain">
        <% Html.RenderPartial("/Components/ListContent", this.ViewData.Merge(new { @SideMenuTitle = this.GetMetadata(".SideMenuTitle"), @MetadataPath = "/Metadata/AboutUs", @Category = this.ViewData["actionName"], @SubCategory = this.ViewData["parameter"] })); %>
    </div>
    <ui:MinifiedJavascriptControl runat="server">
        <script type="text/javascript">
            jQuery('body').addClass('AboutUsPage').addClass('AuthenticatedProfile');
            jQuery('.inner').removeClass('PageBox').addClass('AboutUsContent');
        </script>
    </ui:MinifiedJavascriptControl>

</asp:content>

