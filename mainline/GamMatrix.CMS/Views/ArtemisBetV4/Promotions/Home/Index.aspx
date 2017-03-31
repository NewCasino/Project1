<%@ Page Language="C#" PageTemplate="/Promotions/PromotionsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<script runat="server" type="text/C#">
    private string BannerPath { get { return "/Promotions/HomeBanner"; } }
    protected override void OnInit(EventArgs e) {
        this.ViewData["MetadataPath"] = "/Metadata/Promotions";
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
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Promotions/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Promotions/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Promotions/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>

    <div class="PromotionWrap">
        <ul class="PromoFilters">
            <li class="PromoFilterItem ActivePromoFilterItem">
                <a class="PromoFilterButton" href="#PromoItem"><%=this.GetMetadata(".FilterAll")%></a>
            </li>
            <li class="PromoFilterItem">
                <a class="PromoFilterButton" href="#PromoSports"><%=this.GetMetadata(".FilterSports")%></a>
            </li>
            <li class="PromoFilterItem">
                <a class="PromoFilterButton" href="#PromoCasino"><%=this.GetMetadata(".FilterCasino")%></a>
            </li>
            <li class="PromoFilterItem">
                <a class="PromoFilterButton" href="#PromoLiveCasino"><%=this.GetMetadata(".FilterLiveCasino")%></a>
            </li>
        </ul>
        <h1 class="PageTitle"><%=this.GetMetadata(".PageTitle")%></h1>
        <ol class="PromoList">
        <% if (!string.IsNullOrEmpty(BannerPath)) {
            foreach (string path in Metadata.GetChildrenPaths(BannerPath)) {
                string img = ContentHelper.ParseFirstImageSrc(this.GetMetadata(path + ".Image"));
                string css = this.GetMetadata(path + ".CssClassName");    
                if (string.IsNullOrWhiteSpace(img))
                    continue;
                string html = this.GetMetadata(path + ".Html");
                string title = this.GetMetadata(path + ".Title");
                string more = this.GetMetadata(".PromoDetails");    
                //string _temp = path.Substring(0, path.LastIndexOf("/"));
                // string subPath = (_temp.Substring(_temp.LastIndexOf("/")) + path.Substring(path.LastIndexOf("/"))).ToLowerInvariant();
                string url = this.GetMetadata(path + ".Url");// this.Url.RouteUrl("Promotions_TermsConditions") + subPath;
        %>
        <%= string.Format(@"
            <li class=""PromoItem {5}"">
                <a class=""PromoItemLink"" href=""{2}"">
                    <div class=""PromoContainer"" style=""background-image:url({0})""></div>
                    <div class=""PromoDescription"">
                        <h2 class=""PromoTitle"">{3}</h2>
                        <div class=""PromoContent"">{1}</div>
                        <span class=""PromoMoreLink"" href=""{2}"">{3}</span>
                    </div>
                </a>
            </li>"
            , img.SafeHtmlEncode()
            , html.HtmlEncodeSpecialCharactors()
            , url
            , title
            , more
            , css
        ) %>
            <% }
        } %>
        </ol>
    </div>


    <ui:MinifiedJavascriptControl runat="server">
        <script type="text/javascript">
            jQuery('body').addClass('PromotionsPage');
            jQuery('.inner').removeClass('PageBox').addClass('PromotionsContent');
            $('.homeVideo').insertBefore('.inner');
            $('.PromoFilterButton').each( function() {
                var targetClass = $(this).attr("href").substring(1);
                var noOfPromos = $('.PromoItem.'+targetClass).length;
                $(this).append(' <em class="PromoFilterNumber">('+noOfPromos+')</em>');
            });
            $('.PromoFilterButton').click( function (e) {
                e.preventDefault();
                var targetClass = $(this).attr("href").substring(1);
                $('.PromoFilterItem').removeClass('ActivePromoFilterItem');
                $(this).parents('.PromoFilterItem').addClass('ActivePromoFilterItem');
                $('.PromoItem').hide().each( function () {
                    var item = $(this);
                    if (item.hasClass(targetClass)) item.show(500);
                });
            });
        </script>
    </ui:MinifiedJavascriptControl>

</asp:content>