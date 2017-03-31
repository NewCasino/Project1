<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" ValidateRequest="false" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server" type="text/C#">
    protected string MetadataPath { get { return "/Metadata/ResponsibleGaming"; } }
</script>

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
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>

    <% Html.RenderPartial("/Components/GeneralContent2", this.ViewData.Merge(new{ @MetadataPath= MetadataPath})); %>

    <ui:MinifiedJavascriptControl runat="server">
        <script type="text/javascript">
            jQuery('body').addClass('RespGamingPage');
            jQuery('.inner').removeClass('PageBox').addClass('RespGamingContent');
        </script>
    </ui:MinifiedJavascriptControl>

</asp:Content>