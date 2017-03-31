<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Game>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">   
    private string GetDataName()
    {
        switch (this.ViewData["DataField"] as string)
        {
            case "RTP":
                return this.GetMetadata(".RTP");
            case "FPP":
                return this.GetMetadata(".Rates");

            case "BonusContribution":
                return this.GetMetadata(".Bonus_Contribution");

            default:
                return string.Empty;
        }
    }
    private string GetDataValueClass(Game game)
    {
        decimal fpp = 0;
        switch (this.ViewData["DataField"] as string)
        {
            case "RTP":
                fpp = game.TheoreticalPayOut;
                return fpp <= 0 ? " hidden" : "";
            default:
                return string.Empty;
        }
    }
    private string GetDataValue(Game game)
    {
        decimal fpp = 0;
        switch (this.ViewData["DataField"] as string)
        {
            case "RTP":
                fpp = game.TheoreticalPayOut;
                return string.Format("{0:f3} %", fpp * 100.00M);              
            case "FPP":
                fpp = game.FPP * 100.0M;
                if (Math.Floor(fpp) == fpp)
                {
                    return string.Format("{0:F0} %", fpp);
                }
                else
                {
                    return string.Format("{0:F1} %", fpp);
                }
                
            case "BonusContribution":
                fpp = game.BonusContribution * 100.0M;
                if (Math.Floor(fpp) == fpp)
                {
                    return string.Format("{0:F0} %", fpp);
                }
                else
                {
                    return string.Format("{0:F1} %", fpp);
                }
                
            default:
                return string.Empty;
        }
    }

    public static bool IsLiveCasinoGame(Game game)
    {
        if (GlobalConstant.AllLiveCasinoVendors.Contains(game.VendorID))
        {
            if (!GlobalConstant.AllUniversalVendors.Contains(game.VendorID))
                return true;

            if (game.Categories.Contains("LIVEDEALER"))
                return true;

            switch (game.VendorID)
            {
                case VendorID.Microgaming:
                    {
                        if (game.Slug != null &&
                            (game.Slug.StartsWith("mgs-live-", StringComparison.InvariantCultureIgnoreCase) ||
                            game.Slug.StartsWith("ce-live-", StringComparison.InvariantCultureIgnoreCase)))
                        {
                            return true;
                        }
                        else
                        {
                            return false;
                        }
                    }
            }

        }
        return false;
    }

    private string GetGameUrl(Game game)
    {
        if (!Profile.IsAuthenticated && !game.IsFunModeEnabled)
            return "javascript:void(0);return false;";

        if ( Profile.IsAuthenticated && !game.IsRealMoneyModeEnabled)
            return "javascript:void(0);return false;";

        if (IsLiveCasinoGame(game))
            return "javascript:void(0);return false;";
        
        return string.Format("/Casino/Game/Index/{0}?realMoney={1}"
            , game.Slug.DefaultIfNullOrEmpty(game.ID).SafeHtmlEncode()
            , Profile.IsAuthenticated
            );
    }

    private string GetContentProviderLogo(string contentProviderID)
    {
        string html = contentProviderID;
        if (ContentProviders.Keys.Contains(contentProviderID) &&
            !string.IsNullOrWhiteSpace(ContentProviders[contentProviderID]))
        {            
            html = string.Format(@"<img src=""{0}"" alt="""" />", ContentProviders[contentProviderID]);
        }
        return html;
    }

    
    private bool EnableContentProvider
    {
        get {
            return Settings.Casino_EnableContentProvider;
        }
    }

    Dictionary<string, string> ContentProviders = new Dictionary<string,string>();
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (EnableContentProvider)
            ContentProviders = CasinoEngineClient.GetContentProviders().ToDictionary(p => p.ID, p => p.Logo);
    }
    
</script>


<div class="ResponsibleGamingContainer InfoGames">
        <div class="row tableHead">
          <div class="GameVendor col-20"></div>
            <div class="GameName col-50"><%= this.GetMetadata(".Game_Name").SafeHtmlEncode() %></div>
            <div class="Percentage col-20"><%= GetDataName().SafeHtmlEncode() %></div>
        </div>

    <%
        foreach (Game game in this.Model)
        { %>
        <div class="row">
            <%if (EnableContentProvider) { %>
            <div class="GameContentProvider col-10" data="<%: game.ContentProvider %>"><%=GetContentProviderLogo(game.ContentProvider) %></div>            
            <%} else { %>
            <div class="GameVendor col-20" data="<%: game.VendorID.ToString() %>">
                 <span class="<%: game.VendorID.ToString() %>">
                    <span class="GFText Icon GTicon"></span>  
                 </span>
            </div>
            <%} %>
            <div class="GameName sitemap_items col-50" data="<%= game.Name.SafeHtmlEncode() %>">
                <a target="_blank" href="<%= GetGameUrl(game).SafeHtmlEncode() %>">
                    <%= game.Name.SafeHtmlEncode() %>
                </a>
            </div>
            <div class="Percentage col-20" data="<%= GetDataValue(game).Replace(" %","") %>">
                <span><%= GetDataValue(game) %></span>
            </div>
        </div>
    <% } %>
</div>
   