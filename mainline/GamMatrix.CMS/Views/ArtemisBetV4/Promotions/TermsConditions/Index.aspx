<%@ Page Language="C#" PageTemplate="/Promotions/PromotionsMaster.master" ValidateRequest="false" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server" type="text/C#">
    protected string MetadataPath { get { return string.Format("/Metadata/Promotions/{0}/{1}", this.ViewData["actionName"], this.ViewData["parameter"]); } }
    protected string getImageSrc()
    {
        string imagePath = this.GetMetadata(MetadataPath + ".Image");
        int start = imagePath.IndexOf("src=");
        string imagePath2 = imagePath.Substring(start + 5);
        int start2 = imagePath2.IndexOf("\"");
        return imagePath2.Substring(0,start2);
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
<meta property="og:image" content="<%= getImageSrc() %>" />
</asp:content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Breadcrumbs" role="navigation">
    <ul class="BreadMenu Container" role="menu">
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Promotions/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Promotions/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Promotions/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata(MetadataPath + ".Url") %>" itemprop="url" title="<%= this.GetMetadata(".PromotionItemTitle") %>: <%= this.GetMetadata(MetadataPath + ".Title") %>">
                <span itemprop="title"><%= this.GetMetadata(MetadataPath + ".Title") %></span>
            </a>
        </li>
    </ul>
</div>

<div class="PromotionWrap">

    <% Html.RenderPartial("/Components/GeneralContent", this.ViewData.Merge(new{ @MetadataPath= MetadataPath})); %>

    <ui:MinifiedJavascriptControl runat="server">
        <script type="text/javascript">
            $(document).ready(function () {
                $('body').addClass('PromotionItemPage');
                <% if (!Profile.IsAuthenticated) {%>
                    $(".promotions-content-buttons .promotion-button.deposit").remove();
                <% } else { %>
                    $(".promotions-content-buttons .promotion-button.register").remove();
                <% } %>
            });
        </script>
    </ui:MinifiedJavascriptControl>

</div>
</asp:Content>