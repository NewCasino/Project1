<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server" type="text/C#">
    private string BannerPath { get { return "/Promotions/HomeBanner"; } }
    protected override void OnInit(EventArgs e) {
        this.ViewData["MetadataPath"] = "/Metadata/Promotions";
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div class="DialogHeader">
        <span class="DialogIcon">ArtemisBet</span>
        <h3 class="DialogTitle"><%= this.GetMetadata(".LoginDialogTitle") %></h3>
        <p class="DialogInfo"><%= this.GetMetadata(".LoginDialogInfo") %></p>
    </div>
    <div class="PromotionWrap">
        <ol class="PromoList">
        <% if (!string.IsNullOrEmpty(BannerPath)) {
            int proCount = 0;
            foreach (string path in Metadata.GetChildrenPaths(BannerPath)) {
                proCount++;
                if(proCount>6){
                    break;
                }
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
                <a class=""PromoItemLink"" href=""{2}"" target=""_top"">
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
    <div>
        <div><a class="Button Deposit" href="/Deposit" title="Deposit now!" target="_top">
            <span class="ButtonText"><%= this.GetMetadata(".Deposit_Now") %></span>
        </a></div>
        <div><a class="Skip" href="/" title="Skip" target="_top">
            <span class="ButtonText"><%= this.GetMetadata(".Skip") %></span>
        </a></div>
    </div>
</asp:Content>

