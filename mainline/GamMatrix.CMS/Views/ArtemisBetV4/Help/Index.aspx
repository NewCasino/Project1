<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
 <div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Help/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Help/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<% Html.RenderPartial("/Components/ListContent", this.ViewData.Merge(new { @SideMenuTitle = this.GetMetadata(".SideMenuTitle"), @MetadataPath = "/Metadata/Help", @Category = this.ViewData["actionName"], @SubCategory = this.ViewData["parameter"] })); %>



<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        jQuery('body').addClass('HelpPages').addClass("AuthenticatedProfile");;
        jQuery('.inner').addClass('HelpContent');
    </script>
</ui:MinifiedJavascriptControl>

</asp:Content>

