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
                return string.Format("{0:f2} %", fpp * 100.00M);              
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
        switch (game.VendorID)
        {
            case VendorID.XProGaming:
            case VendorID.EvolutionGaming:
                return true;

            case VendorID.Microgaming:
                {
                    if (game.Slug != null &&
                        game.Slug.StartsWith("mgs-live-", StringComparison.InvariantCultureIgnoreCase))
                    {
                        return true;
                    }
                    break;
                }

            default:
                break;
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


<table class="GameTable <%= this.ViewData["CssClass"] %>">
    <thead>
        <tr>
            <th class="GameVendor"></th>
            <th class="GameName">
                <%= this.GetMetadata(".Game_Name").SafeHtmlEncode() %>
            </th>
            <th class="Percentage">
                <%= GetDataName().SafeHtmlEncode() %>
            </th>
        </tr>
    </thead>
    <tbody>
        
    <%
        foreach (Game game in this.Model)
        { %>
        <tr class="<%=GetDataValueClass(game) %>">
            <%if (EnableContentProvider) { %>
            <td class="GameContentProvider" data="<%: game.ContentProvider %>"><%=GetContentProviderLogo(game.ContentProvider) %></td>            
            <%} else { %>
            <td class="GameVendor" data="<%: game.VendorID.ToString() %>"><span class="<%: game.VendorID.ToString() %>Icon"></span></td>
            <%} %>
            <td class="GameName" data="<%= game.Name.SafeHtmlEncode() %>">
                <a target="_blank" href="<%= GetGameUrl(game).SafeHtmlEncode() %>">
                    <%= game.Name.SafeHtmlEncode() %>
                </a>
            </td>
            <td class="Percentage" data="<%= GetDataValue(game).Replace(" %","") %>">
                <span><%= GetDataValue(game) %></span>
            </td>
        </tr>
    <% } %>

    </tbody>
</table>    