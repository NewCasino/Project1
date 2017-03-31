<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
    /* Options
     * InitalLoadGameCount          int     optional default = 20
     * MaxNumOfNewGames             int     optional default = 40
     * MaxNumOfPopularGames         int     optional default = 40
     * InitialRows                  int     optional default = 4
     * IncreasedRows                int     optional default = 8
     * InitialSliderCategoryCount   int     optional default = 3
     * InitialListCategoryCount     int     optional default = 1
     *
     * DefaultCategoty      string  optional
     *
     */

    #region Options
    private int InitalLoadGameCount {
        get {
            int initalLoadGameCount = 0;
            try {
                initalLoadGameCount = (int)this.ViewData["InitalLoadGameCount"];
            } catch {
                initalLoadGameCount = 20;
            }
            return initalLoadGameCount;
        }
    }

    private int MaxNumOfNewGames {
        get {
            int maxNumOfNewGames = 0;
            try {
                maxNumOfNewGames = (int)this.ViewData["MaxNumOfNewGames"];
            } catch {
                maxNumOfNewGames = 40;
            }
            return maxNumOfNewGames;
        }
    }

    private int MaxNumOfPopularGames {
        get {
            int maxNumOfPopularGames = 0;
            try {
                maxNumOfPopularGames = (int)this.ViewData["MaxNumOfPopularGames"];
            } catch {
                maxNumOfPopularGames = 40;
            }
            return maxNumOfPopularGames;
        }
    }

    private int InitialRows {
        get {
            int initialRows = 0;
            try {
                initialRows = (int)this.ViewData["InitialRows"];
            } catch {
                initialRows = 4;
            }
            return initialRows;
        }
    }

    private int IncreasedRows {
        get {
            int increasedRows = 0;
            try {
                increasedRows = (int)this.ViewData["IncreasedRows"];
            } catch {
                increasedRows = 8;
            }
            return increasedRows;
        }
    }


    private int InitialSliderCategoryCount {
        get {
            int initialSliderCategoryCount = 0;
            try {
                initialSliderCategoryCount = 3;
            } catch {
                initialSliderCategoryCount = 3;
            }
            return initialSliderCategoryCount;
        }
    }

    private int InitialListCategoryCount {
        get {
            int initialListCategoryCount = 0;
            try {
                initialListCategoryCount = (int)this.ViewData["InitialListCategoryCount"];
            } catch {
                initialListCategoryCount = 3;
            }
            return initialListCategoryCount;
        }
    }

    private string DefaultCategory {
        get {
            return (this.ViewData["DefaultCategory"] as string) ?? "popular";
        }
    }
    #endregion

    private string JsonUrl {
        get {
            return string.Format(CultureInfo.InvariantCulture
                , "/Casino/Hall/GameData?maxNumOfNewGame={0}&maxNumOfPopularGame={1}&_={2}"
                , this.MaxNumOfNewGames
                , this.MaxNumOfPopularGames
                , DateTime.Now.Ticks
                );
        }
    }



    private int TotalGameCount;
    private string CategoryHtml;
    private string CategoryJson;
    private string VendorFilterHtml;
    private string JsonData;
    private Dictionary<string, string> VendorDic; // the vendors for template
    List<GameCategory> categories;
    private bool IsEmailVerified() {
        bool isEmailVerified = false;
        if (Profile.IsAuthenticated) {
            isEmailVerified = Profile.IsEmailVerified;
            if (!Profile.IsEmailVerified) {
                CM.db.Accessor.UserAccessor ua = CM.db.Accessor.UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                CM.db.cmUser user = ua.GetByID(Profile.UserID);
                if (user.IsEmailVerified) {
                    isEmailVerified = true;
                    Profile.IsEmailVerified = true;
                }
            }
        }
        return isEmailVerified;
    }

    private bool IsIncompleteProfile() {
        bool isIncompleteProfile = false;
        if (Profile.IsAuthenticated) {
            if (Profile.IsInRole("Incomplete Profile")) {
                isIncompleteProfile = true;
            }
        }

        return isIncompleteProfile;
    }

    private string GetDomain()
    {
        string host = HttpContext.Current.Request.Url.Host;
        if (host.EndsWith(".gammatrix-dev.net", StringComparison.InvariantCultureIgnoreCase))
        {
            //If the accessing domain name is under gammatrix-dev.net (i.e, www.jetbull.gammatrix-dev.net), 
            //the domain is set to jetbull.gammatrix-dev.net
            var fields = host.Split('.');
            string domain = string.Empty;
            for (var i = fields.Length - 3; i < fields.Length; i++)
                domain += fields[i] + ".";
            return domain.TrimStart('.').TrimEnd('.');
        }
        else
        {
            //Otherwise, the root domain name is set as the domain. 
            //For example, www.casino.jetbull.com and www.jetbull.com and jetbull.com all get the same cookie domain jetbull.com;
            //www.casino.jetbull.com.mx and www.jetbull.com.mx and jetbull.com.mx all get the same cookie domain jetbull.com.mx
            //Note: the same logic will be applied to domain XXX.net, XXX.org, XXX.co and XXX.net.XX, XXX.org.XX, XXX.co.XX
            var tlds = new[]
                {
                ".com",
                ".net",
                ".org",
                ".co",
            };//top-level domains

            foreach (var tld in tlds)
            {
                if (host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase) > 0)
                {
                    var temp = host.Substring(0, host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                    if (temp.LastIndexOf(".") >= 0)
                        temp = temp.Substring(temp.LastIndexOf(".") + 1);
                    var domain2 = temp + host.Substring(host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                    return domain2.TrimStart('.').TrimEnd('.');
                }
            }

            var fields = host.Split('.');
            if (fields.Length < 2)
                return host;
            string domain = string.Empty;
            for (var i = fields.Length - 2; i < fields.Length; i++)
                domain += fields[i] + ".";
            return domain.TrimStart('.').TrimEnd('.');
        }
    }

    private bool isGlobalbetGames
    {
        get 
        { 
            if (this.ViewData["isGlobalbetGames"] != null) 
                return (bool)this.ViewData["isGlobalbetGames"];
            else return false; 
        }
    }

    private string GetBetRadarGames(string category)
    {
        StringBuilder json = new StringBuilder();
        json.Append("[");
        if (isGlobalbetGames && category == "other_games")
        {
            string[] gamelistpath = Metadata.GetChildrenPaths("/Metadata/Casino/BetRadarGames");
            if (gamelistpath != null && gamelistpath.Length > 0)
            {
                foreach (string gamepath in gamelistpath)
                {
                    string play_url = string.Format(CultureInfo.InvariantCulture, this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.Play_Url", gamepath)), HttpUtility.UrlEncode(Profile.SessionID));
                    if (play_url.Contains("$DOMAIN$"))
                        play_url = play_url.Replace("$DOMAIN$", GetDomain());

                    json.Append("{");
                    json.AppendFormat(CultureInfo.InvariantCulture
                        , "\"ID\":{0},\"P\":{1},\"V\":{2},\"Name\":\"{3}\",\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"RealMoney\":{6},\"R\":{6},\"S\":\"{7}\",\"N\":{8},\"T\":{9},\"H\":{10},\"O\":{11},\"D\":{12},\"L\":\"{13}\",\"CP\":\"{14}\",\"Url\":\"{15}\",\"ElementID\":\"{16}\", \"Width\": 1024, \"Height\": 768  "
                        , this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.GameID", gamepath))
                        , Settings.SafeParseBoolString((this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.IsHot", gamepath))), false) ? 1 : 0
                        , 999
                        , this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.Title", gamepath))
                        , this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.ThumbnailUrl", gamepath))
                        , "0"
                        , "1"
                        , this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.GameID", gamepath))
                        , Settings.SafeParseBoolString((this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.IsNew", gamepath))), false) ? "1" : "0"
                        , "0"
                        , "0"
                        , "0"
                        , "0"
                        , this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "{0}.LogoUrl", gamepath))
                        , "BetRadar"
                        , play_url
                        , string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6))
                        );
                    json.Append("},");
                }
                if (json[json.Length - 1] == ',')
                {
                    json.Remove(json.Length - 1, 1);
                }
            }
        }
        json.Append("]");
        return json.ToString();
    }

    private int GetBetRadarGamesCount(string category)
    {
        if (isGlobalbetGames && category == "other_games")
        {
            string[] gamelistpath = Metadata.GetChildrenPaths("/Metadata/Casino/BetRadarGames");
            if (gamelistpath != null && gamelistpath.Length > 0)
                return gamelistpath.Length;
        }

        return 0;
    }

    protected override void OnPreRender(EventArgs e) {
        base.OnPreRender(e);

        string currentCategory = this.ViewData["CurrentCategory"] as string;
        if (string.IsNullOrEmpty(currentCategory)) {
            HttpCookie cookie = Request.Cookies["_ccc"];
            if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                currentCategory = cookie.Value;
            else
                currentCategory = this.DefaultCategory;
        }

        /////////////////////////////////////////////////////////////////////////
        // CategoryHtml
        StringBuilder json = new StringBuilder();
        StringBuilder html = new StringBuilder();
        const string CATEGORY_FORMAT = @"
<li class=""TabItem {4}"">
    <a href=""/Casino/Hall/Index/{0}"" class=""Button TabLink CatTabLink"" title=""{1}"" data-categoryid=""{0}"">
        <span class=""CatIcon"">&para;</span>
        <span class=""CatNumber"">{2}</span>
        <span class=""CatText"">{3}</span>
    </a>
</li>";
        json.Append("[");
        {

            // popular games
            if (!isGlobalbetGames)
            {
                int num = this.MaxNumOfPopularGames;
                string jsonData = GameMgr.GetPopularGameJson(ref num);
                string cssClasses;
                if (string.Equals(currentCategory, "Popular", StringComparison.InvariantCultureIgnoreCase))
                {
                    this.JsonData = jsonData;
                    cssClasses = "ActiveCat Pop";
                }
                else
                {
                    cssClasses = "Pop";
                }

                html.AppendFormat(CATEGORY_FORMAT
                       , "popular"
                       , this.GetMetadata(".Category_Popular_Title").SafeHtmlEncode()
                       , this.GetMetadataEx(".Category_Superscript", num)
                       , this.GetMetadata(".Category_Popular").SafeHtmlEncode()
                       , cssClasses
                       );
            }


            // new games
            if (!isGlobalbetGames)
            {
                int num = this.MaxNumOfNewGames;
                string jsonData = GameMgr.GetNewGameJson(ref num);

                string cssClasses;
                if (string.Equals(currentCategory, "Newest", StringComparison.InvariantCultureIgnoreCase))
                {
                    this.JsonData = jsonData;
                    cssClasses = "ActiveCat New";
                }
                else
                {
                    cssClasses = "New";
                }

                html.AppendFormat(CATEGORY_FORMAT
                       , "newest"
                       , this.GetMetadata(".Category_Newest_Title").SafeHtmlEncode()
                       , this.GetMetadataEx(".Category_Superscript", num)
                       , this.GetMetadata(".Category_Newest").SafeHtmlEncode()
                       , cssClasses
                       );
            }

            int count = 0;
            categories = GameMgr.GetCategories();
            List<GameRef> globalbetGames = GameMgr.GetAllGames().Where(f => f.VendorID == VendorID.Globalbet || f.VendorID == VendorID.Kiron).ToList();

            if (categories != null && categories.Count > 0)
            {
                foreach (GameCategory category in categories)
                {
                    List<GameRef> availableGames = category.Games;
                    if (isGlobalbetGames) 
                    {
                        availableGames = availableGames.Where(f => globalbetGames.Contains(f)).ToList();
                    }
                    else
                    {
                        availableGames = availableGames.Where(f => !globalbetGames.Contains(f)).ToList();
                    } 

                    if (availableGames.Count == 0)
                        continue;

                    json.AppendFormat(CultureInfo.InvariantCulture, "{{ID:'{0}',Name:'{1}'}},"
                        , category.FriendlyID.SafeJavascriptStringEncode()
                        , category.Name.SafeJavascriptStringEncode()
                        );

                    if (category.FriendlyID == currentCategory)
                        JsonData = GameMgr.GetCategoryJson(category, InitalLoadGameCount);

                    if (isGlobalbetGames && category.FriendlyID == "other_games")
                    {
                        string betRadarGamesJson = GetBetRadarGames(category.FriendlyID);
                        if (!string.IsNullOrEmpty(JsonData))
                        {
                            if (betRadarGamesJson.Length > 2)
                            {
                                JsonData = JsonData.Substring(0, JsonData.Length - 1) + "," + betRadarGamesJson.Substring(1);
                            }
                        }
                        else
                        {
                            if (betRadarGamesJson.Length > 2)
                            {
                                JsonData = betRadarGamesJson;
                            }
                        }
                    }
                    
                    string cssClasses = string.Format(CultureInfo.InvariantCulture, "{0} Cat-{1}"
                        , (category.FriendlyID == currentCategory) ? "ActiveCat" : string.Empty
                        , category.FriendlyID
                        );

                    count += availableGames.Count + GetBetRadarGamesCount(category.FriendlyID);
                    html.AppendFormat(CultureInfo.InvariantCulture, CATEGORY_FORMAT
                        , category.FriendlyID.SafeHtmlEncode()
                        , this.GetMetadataEx(".Category_Title", category.Name.ToLowerInvariant()).SafeHtmlEncode()
                        , this.GetMetadataEx(".Category_Superscript", availableGames.Count + GetBetRadarGamesCount(category.FriendlyID))
                        , category.Name.SafeHtmlEncode()
                        , cssClasses.SafeHtmlEncode()
                        );
                }
            }
            
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("]");
            this.CategoryJson = json.ToString();
            this.TotalGameCount = count;

        }
        this.CategoryHtml = html.ToString();



        /////////////////////////////////////////////////////////////////////////
        // VendorFilterHtml

        Func<VendorInfo, bool> isAvailableVendor = (VendorInfo vendor) =>
        {
            if (vendor.VendorID == VendorID.XProGaming || vendor.VendorID == VendorID.EvolutionGaming || vendor.VendorID == VendorID.Ezugi || vendor.VendorID == VendorID.BetGames || vendor.VendorID == VendorID.Vivo || vendor.VendorID == VendorID.BetSoft || vendor.VendorID == VendorID.PokerPlus)
                return false;

            if (Profile.IsAuthenticated && vendor.RestrictedTerritories.Exists(c => c == Profile.UserCountryID))
                return false;

            if (Profile.IpCountryID > 0 && vendor.RestrictedTerritories.Exists(c => c == Profile.IpCountryID))
                return false;

            if (isGlobalbetGames && vendor.VendorID != VendorID.Globalbet && vendor.VendorID != VendorID.Kiron) return false;

            if (!isGlobalbetGames && (vendor.VendorID == VendorID.Globalbet || vendor.VendorID == VendorID.Kiron)) return false;

            return true;
        };

        VendorInfo[] vendors = CasinoEngineClient.GetVendors().Where(v => isAvailableVendor(v)).ToArray();
        VendorDic = vendors.ToDictionary(v => ((int)v.VendorID).ToString(), v => v.VendorID.ToString());
        if (isGlobalbetGames)
        {
            VendorDic.Add("999", "BetRadar");
        }
        html.Clear();
        html.AppendFormat(@"<div class=""GLVendorFilter GFListWrapper GFL{0} "">
<h4 class=""GFDHeader"" href=""#"" title=""{1}""><span class=""GFDVar"" id=""gfdVar-vendors"">{0}</span><span class=""GFDDelimiter"">/</span><span class=""GFDTotel"">{0}</span><span class=""GFDIText""> {2}</span></h4>
<ul class=""GFilterList {4} Container"" id=""gfl-colors"">"
            , vendors.Length + ((isGlobalbetGames && GetBetRadarGamesCount("other_games") > 0) ? 1 : 0)
            , this.GetMetadata(".ViewSwitcher_Title").SafeHtmlEncode()
            , this.GetMetadata(".ViewSwitcher_Selected").SafeHtmlEncode()
            , this.GetMetadata(".Filters_See_All").SafeHtmlEncode()
            , ((vendors.Length + ((isGlobalbetGames && GetBetRadarGamesCount("other_games") > 0) ? 1 : 0)) >= 6) ? "GFMultipleItems" : string.Empty
            );

        for (int i = 0; i < vendors.Length; i++) {
            VendorInfo vendor = vendors[i];
            string name = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, ".Vendor_{0}", vendor.VendorID.ToString()))
                .DefaultIfNullOrEmpty(vendor.VendorID.ToString());

            html.AppendFormat(@"
    <li class=""GFilterItem {0} GFActive {4}"">
        <label for=""gfVendor{0}"" class=""GFLabel"" title=""{2}"">
            <input type=""checkbox"" checked=""checked"" id=""gfVendor{0}"" name=""filterVendors"" value=""{1}"" class=""hidden"" />
            <span class=""GFText"">{3}</span>
        </label>
    </li>"
                , vendor.VendorID.ToString()
                , (int)vendor.VendorID
                , this.GetMetadataEx(".VendorFilter_Toggle", name).SafeHtmlEncode()
                , name
                , (i >= 6) ? "GFilterItemExtra" : string.Empty
                );
        }

        if (isGlobalbetGames && GetBetRadarGamesCount("other_games") > 0)
        {
            string name = this.GetMetadata(".Vendor_BetRadar").DefaultIfNullOrEmpty(string.Empty);
            html.AppendFormat(@"
    <li class=""GFilterItem {0} GFActive {4}"">
        <label for=""gfVendor{0}"" class=""GFLabel"" title=""{2}"">
            <input type=""checkbox"" checked=""checked"" id=""gfVendor{0}"" name=""filterVendors"" value=""{1}"" class=""hidden"" />
            <span class=""GFText"">{3}</span>
        </label>
    </li>"
                , "BetRadar"
                , 999
                , this.GetMetadataEx(".VendorFilter_Toggle", name).SafeHtmlEncode()
                , name
                , (vendors.Length >= 6) ? "GFilterItemExtra" : string.Empty
                );
        }
        html.Append("</ul></div>");
        this.VendorFilterHtml = html.ToString();
    }
</script>

<div class="Box AllGames">
    <div class="GamesHeader Container">
        <h2 class="BoxTitle GamesTitle">
            <strong class="TitleText"><%= this.GetMetadataEx(".Title_Games", this.TotalGameCount).HtmlEncodeSpecialCharactors() %></strong>
        </h2>
        <div class="GameFilters">
            <%----------------------------
                    Search Filter
            ----------------------------%>
            <form class="FilterForm SearchFilterForm" id="gameSearch" action="#" onsubmit="return false">
                <fieldset>
                    <label class="hidden" for="txtGameSearchKeywords"><%= this.GetMetadata(".GameName_Insert").SafeHtmlEncode() %></label>
                    <input class="FilterInput SearchInput" type="search" id="txtGameSearchKeywords" name="txtGameSearchKeywords" accesskey="g" maxlength="50" value="" placeholder="<%= this.GetMetadata(".GameName_PlaceHolder").SafeHtmlEncode() %>" />
                    <button type="submit" class="Button SearchButton" name="gameSearchSubmit" id="btnSearchGame">
                        <span class="ButtonText"><%= this.GetMetadata(".Search").SafeHtmlEncode() %></span>
                    </button>
                </fieldset>
            </form>
            <form class="FilterForm GlobalFilterForm" id="gameFilter" action="#" onsubmit="return false">
                <fieldset>
                    <div class="GlobalFilterSummary">
                        <a class="GFDLink GFSLink" id="gfl-summary" href="#" title="<%= this.GetMetadata(".Filters_Title").SafeHtmlEncode() %>">
                            <span class="GFDText"><span class="Hidden"><%= this.GetMetadata(".Filters_See_All").SafeHtmlEncode()%></span><span class="ActionSymbol">&#9660;</span></span>
                            <span class="GFDInfo"><%= this.GetMetadata(".Filters").SafeHtmlEncode()%></span>
                        </a>
                    </div>
                    <div class="GlobalFilterCollection">
                        <%----------------------------
                                Vendor Filter
                        ----------------------------%>
                        <%= this.VendorFilterHtml %>
                        <%----------------------------
                                  Open Mode
                        ----------------------------%>
                        <div class="GFListWrapper GFL4 GLOpenModeList">
                            <h4 class="GFDHeader" id="gfl-openingTrigger" href="#" title="<%= this.GetMetadata(".OpenMode_Title").SafeHtmlEncode()%>"><span class="GFDVar" id="gfdVar-opening"><%= this.GetMetadata(".OpenMode_Popup").SafeHtmlEncode()%></span></h4>
                            <ul class="GFilterList Container" id="gfl-opening">
                                <li class="GFilterItem GFFullScreen">
                                    <label for="gfFullScreen" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Fullscreen_Title").SafeHtmlEncode()%>">
                                        <input type="radio" id="gfFullScreen" name="openType" value="fullscreen" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".OpenMode_Fullscreen").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFNewTab">
                                    <label for="gfNewTab" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_NewTab_Title").SafeHtmlEncode()%>">
                                        <input type="radio" id="gfNewTab" name="openType" value="newtab" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".OpenMode_NewTab").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFInline<%= isGlobalbetGames ? " GFActive" : "" %>">
                                    <label for="gfInline" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Inline_Title").SafeHtmlEncode()%>">
                                        <input type="radio"<%= isGlobalbetGames ? " checked=\"checked\"" : "" %> id="gfInline" name="openType" value="inline" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".OpenMode_Inline").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFPopup<%= isGlobalbetGames ? "" : " GFActive" %>">
                                    <label for="gfPopup" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Popup_Title").SafeHtmlEncode()%>">
                                        <input type="radio"<%= isGlobalbetGames ? "" : " checked=\"checked\"" %> id="gfPopup" name="openType" value="popup" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".OpenMode_Popup").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                            </ul>
                        </div>
                        <%----------------------------
                                Sort Switcher
                        ----------------------------%>
                        <div class="GFListWrapper GFL3 GLSortList">
                            <h4 class="GFDHeader" id="gfl-sortingTrigger" href="#" title="<%= this.GetMetadata(".SortSwitcher_Title").SafeHtmlEncode()%>"><span class="GFDVar" id="gfdVar-sorting"><%= this.GetMetadata(".SortSwitcher_Default").SafeHtmlEncode()%></span></h4>
                            <ul class="GFilterList Container" id="gfl-sorting">
                                <li class="GFilterItem GFDefault GFActive">
                                    <label for="gfDefault" class="GFLabel" title="<%= this.GetMetadata(".SortSwitcher_Default_Title").SafeHtmlEncode()%>">
                                        <input type="radio" checked="checked" id="gfDefault" name="sortType" value="" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".SortSwitcher_Default").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFAlphabetical">
                                    <label for="gfAlphabetical" class="GFLabel" title="<%= this.GetMetadata(".SortSwitcher_Alphabetical_Title").SafeHtmlEncode()%>">
                                        <input type="radio" id="gfAlphabetical" name="sortType" value="alphabetical" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".SortSwitcher_Alphabetical").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFPopularity">
                                    <label for="gfPopularity" class="GFLabel" title="<%= this.GetMetadata(".SortSwitcher_Popularity_Title").SafeHtmlEncode()%>">
                                        <input type="radio" id="gfPopularity" name="sortType" value="popularity" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".SortSwitcher_Popularity").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                            </ul>
                        </div>
                    </div>
                </fieldset>
            </form>
        </div>
    </div>
    <%------------------------
         Game Categories
    ------------------------%>
    <nav class="GamesCategoriesWrap">
        <ol class="GamesCategories Tabs Tabs-1">
            <% if (!isGlobalbetGames)
            { %>
            <li class="TabItem First All">
                <a href="/Casino/Hall" class="Button TabLink AllViewLink" title="<%= this.GetMetadata(".Category_All_Title").SafeHtmlEncode() %>">
                    <span class="CatIcon">&para;</span>
                    <span class="CatNumber"><%= this.GetMetadataEx(".Category_Superscript", this.TotalGameCount) %></span>

                    <span class="CatText"><%= this.GetMetadata(".Category_All").SafeHtmlEncode() %></span>
                </a>
            </li>
            <li class="TabItem  Fav">
                <a href="/Casino/Hall#favorites" class="Button TabLink CatTabLink" title="<%= this.GetMetadata(".Category_Favorites_Title").SafeHtmlEncode() %>" data-categoryid="favorites">
                    <span class="CatIcon">&para;</span>
                    <span class="CatText"><%= this.GetMetadata(".Category_Favorites").SafeHtmlEncode() %></span>
                </a>
            </li>
            <% } %>
            <%= CategoryHtml %>
        </ol>
    </nav>
    <%------------------------
        Except "All Games", show as grid or list
      ------------------------%>
    <div class="GamesContainer">

        <h2 class="GamesContainerTitle"><%= this.GetMetadata(".PopularGames")%></h2>

        <ol class="GamesList Container">
            <% if (!string.IsNullOrEmpty(this.JsonData)) { %>
                <%= this.PopulateTemplateWithJson("GameListItem", this.JsonData, new { vendors = this.VendorDic, isLoggedIn = Profile.IsAuthenticated })%>
            <% } %>
        </ol>

        <div class="AllGamesList Container"></div>
        <div class="AllGamesTextList Container"></div>

        <div id="divIncentiveMessage" class="Hidden"></div>

        <div class="GamesControls">
            <a id="lnkLoadMoreGames" class="Button LoadMoreButton Hidden" href="#" title="<%= this.GetMetadata(".Button_LoadMore_Title").SafeHtmlEncode()%>">
                <span class="ButtonText"><%= this.GetMetadata(".Button_LoadMore")%>&nbsp;<span class="ActionSymbol">&#9660;</span></span>
            </a>
            <a id="lnkLoadAllCategories" class="Button LoadMoreButton Hidden" href="#" title="<%= this.GetMetadata(".Button_LoadAll_Title").SafeHtmlEncode()%>">
                <span class="ButtonText"><%= this.GetMetadata(".Button_LoadAll").SafeHtmlEncode()%>&nbsp;<span class="ActionSymbol">&#9660;</span></span>
            </a>
        </div>
    </div>

</div>

<%-- UNUSED COMPONENTS --%>
                        <%----------------------------
                                  Tutorial
                        ----------------------------%>
                        <%--<a class="Button GLTutorialButton" id="lnkGameNavTutorial" href="javascript:void(0)" title="<%= this.GetMetadata(".Button_Tutorial_Title").SafeHtmlEncode()%>">
                            <span class="GLTutorialText"><%= this.GetMetadata(".Button_Tutorial") %></span>
                            <span class="GLTutorialIcon"><%= this.GetMetadata(".Button_Tutorial_Icon") %></span>
                        </a>--%>
                        <%----------------------------
                                View Switcher
                        ----------------------------%>
                        <%--<div class="GFListWrapper GFL2 GLViewSwitcher">
                            <ul class="GFilterList Container" id="gfl-display">
                                <li class="GFilterItem GFilterDropdown">
                                    <a class="GFDLink GFDSymbol" id="gfl-displayTrigger" href="#" title="<%= this.GetMetadata(".ViewSwitcher_Title").SafeHtmlEncode()%>">
                                        <span class="GFDText"><span class="Hidden"><%= this.GetMetadata(".Filters_See_All").SafeHtmlEncode()%></span><span class="ActionSymbol">&#9660;</span></span>
                                        <span class="GFDInfo"><span class="GFDVar" id="gfdVar-display"><%= this.GetMetadata(".ViewSwitcher_Grid").SafeHtmlEncode()%></span></span>
                                    </a>
                                </li>
                                <li class="GFilterItem GFGrid GFActive">
                                    <label for="gfGrid" class="GFLabel" title="<%= this.GetMetadata(".ViewSwitcher_Grid_Title").SafeHtmlEncode()%>">
                                        <input type="radio" checked="checked" id="gfGrid" name="displayType" value="Grid" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".ViewSwitcher_Grid").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFList">
                                    <label for="gfList" class="GFLabel" title="<%= this.GetMetadata(".ViewSwitcher_List_Title").SafeHtmlEncode()%>">
                                        <input type="radio" id="gfList" name="displayType" value="List" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".ViewSwitcher_List").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                            </ul>
                        </div>--%>
        <%----------------------------
                Icon Meanings
        ----------------------------%>
        <%--div class="IconHelp">
            <h3 class="AdditionalTitle"><%= this.GetMetadata(".IconMeaning").SafeHtmlEncode() %></h3>
            <ul class="HelpList">
                <li class="HelpItem">
                    <span class="GTnew">New</span>
                    <span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_New").SafeHtmlEncode() %></span>
                </li>
                <li class="HelpItem HelpItemTournament">
                    <span class="GTtournament">T<span class="Hidden">ournament</span></span>
                    <span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_Tournament").SafeHtmlEncode()%></span>
                </li>
                <li class="HelpItem">
                    <span class="GToffer AltButton">&euro;</span>
                    <span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_SpecialOffer").SafeHtmlEncode()%></span>
                </li>
                <li class="HelpItem">
                    <span class="GThot">Hot</span>
                    <span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_Popular").SafeHtmlEncode()%></span>
                </li>
                <li class="HelpItem">
                    <span class="GTfav">Favorite</span>
                    <span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_Favorite").SafeHtmlEncode()%></span>
                </li>
            </ul>
        </div--%>


<%------------------------
    this is the container for all the popups in the page. they will need to be positioned with JavaScript
------------------------%>
<div class="PopupsContainer" id="casino-hall-popups">
    <div class="Popup TooltipPopup" id="tooltipPopup">
        <div class="PopupIcon">Info about this item:</div>
        <span class="PopupText">This is some info about this item</span>
    </div>
</div>
<input type="hidden" id="isGameCategorySorted" value="0" />
<%= this.ClientTemplate("GameListItem", "casino-game-item", new { vendors = this.VendorDic, isLoggedIn = Profile.IsAuthenticated })%>

<%= this.ClientTemplate("CategorySlider", "casino-category-slider") %>

<%= this.ClientTemplate("CategoryList", "casino-category-list") %>
<div id="categories2"></div>
<%--
  = this.ClientTemplate("GamePopup", "casino-game-popup-template", new { vendors = this.VendorDic, isLoggedIn = Profile.IsAuthenticated })
    --%>
<% if (isGlobalbetGames) 
{ %>
<%= this.ClientTemplate( "/Casino/Hall/GameOpenerWidget/GameFrame", "betradargame-template", new {})  %>
<% } %>

<%--<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">--%>
    <script type="text/javascript">
        $(function () {
            var _gamecategoriesOld = <%= this.CategoryJson %>;
            function randomsort(a, b) {  
                return Math.random()>.5 ? -1 : 1;
            } 
            var _gamecategories = _gamecategoriesOld.sort(randomsort);
            var isAvailableLogin = <%= (Profile.IsAuthenticated && Profile.IsEmailVerified).ToString().ToLowerInvariant() %>;
            // <%-- casino game list virtual threads --%>
            CGL_Threads = {
                _threads : [],
                _filterAndSortGames: function (games, keywords, callback) {
                    var vendors = {};
                    var $checked = $(':checkbox[name="filterVendors"]:checked');
                    for (var k = 0; k < $checked.length; k++) {
                        vendors[parseInt($checked.eq(k).val(),10)] = true;
                    }

                    var filterName = keywords != null && keywords.toString().length > 0;
                    if( filterName ) {
                        keywords = keywords.toUpperCase();
                    }

                    var searchedGames = {};
                    var result = [];
                    for (var i = 0; i < games.length; i++) {
                        if (vendors[games[i].V] != true)
                            continue;

                        if( filterName && games[i].G.toUpperCase().indexOf(keywords) < 0 ){
                            continue;
                        }

                        if( filterName ){
                            if( searchedGames[games[i].ID] == true )
                                continue;
                            searchedGames[games[i].ID] = true;
                        }
                        result.push(games[i]);
                    }

                <%-- Sorting --%>
                    var merge = null;
                    var sort = function (array) {
                        var len = array.length;
                        if (len < 2) {
                            return array;
                        }
                        var pivot = Math.ceil(len / 2);
                        return merge(sort(array.slice(0, pivot)), sort(array.slice(pivot)));
                    };

                    var sortType = $(':radio[name="sortType"]:checked').val();
                    if( 'alphabetical' == sortType ) {
                        merge = function(left, right) {
                            var r = [];
                            while((left.length > 0) && (right.length > 0)) {
                                if( left[0].G.localeCompare(right[0].G) < 0 ) {
                                    r.push(left.shift());
                                }
                                else {
                                    r.push(right.shift());
                                }
                            }

                            r = r.concat(left, right);
                            return r;
                        };
                    } else if( 'popularity' == sortType ) {
                        merge = function(left, right) {
                            var r = [];
                            while((left.length > 0) && (right.length > 0)) {
                                if(left[0].P > right[0].P) {
                                    r.push(left.shift());
                                }
                                else {
                                    r.push(right.shift());
                                }
                            }

                            r = r.concat(left, right);
                            return r;
                        };
                    }
                    if( merge != null )
                        result = sort(result);
                    callback(result);
                },
                filterAndSortGames: function (games, keywords, callback) {
                    var th = Concurrent.Thread.create(CGL_Threads._filterAndSortGames, games, keywords, callback);
                    CGL_Threads._threads.push(th);
                },
                killThreads: function(){
                    while(CGL_Threads._threads.length > 0 ){
                        try{
                            CGL_Threads._threads[0].kill(0);
                        }
                        catch(e) {}
                        CGL_Threads._threads.splice(0, 1);
                    }
                }
            }; // <%-- virtual threads end --%>


            var _view = null; // <%-- Current Casino Game List instance --%>
            var _game_map = {}; // <%-- All games --%>
            var _data = null;

            function closeAllPopups() {
                $('.ActiveDrop').removeClass('ActiveDrop');
                $('.ActiveSummaryDrop').removeClass('ActiveSummaryDrop');
                // $('.Popup').hide();
            }
            $(document).bind('GAME_TO_BE_OPENED', closeAllPopups);

            function positionPopup( $popup, $anchor ) {
                var pos = $anchor.offset();
                var left = Math.floor(pos.left);

                if ( left + $popup.width() > $(document.body).width() ) {
                    var dx = ( $popup.width() + left ) - $(document.body).width();
                    left = left - dx;
                }

                var top = Math.floor(pos.top);

                $popup.css({ 'left' : left + 'px', 'top' : top+'px' });

                pos = $popup.offset();
                pos.right = pos.left + $popup.width();
                pos.maxRight = $(window).scrollLeft() + $(window).width();
                pos.bottom = pos.top + $popup.height();
                pos.maxBottom = $(window).scrollTop() + $(window).height();

                if( pos.maxRight < pos.right ){
                    $(window).scrollLeft( pos.right - $(window).width() );
                }

                if( pos.maxBottom < pos.bottom ){
                    $(window).scrollTop( pos.bottom - $(window).height() );
                }
            }


            $(document.body).append($('#casino-hall-popups'));
            $('ol.GamesCategories a.TabLink').click(function (e) {
                e.preventDefault();
                $('ol.GamesCategories li.ActiveCat').removeClass('ActiveCat');
                $(this).parent('li').addClass('ActiveCat');
            });

            // <%-- favorites --%>
            function removeFavGame(g){
                var favorites = _data['favorites'];
                for( var i = favorites.length - 1; i >= 0; i--){
                    if( favorites[i].ID == g.ID )
                        favorites.splice(i, 1);
                }
            }

            $(document).on( 'GAME_ADDED_TO_FAV', function(e, gid){
                var game = _game_map[gid];
                $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav').removeClass('Hidden');
                game.Fav = 1;
                removeFavGame(game);
                _data['favorites'].push(game);
            });

            $(document).on( 'GAME_REMOVE_FROM_FAV', function(e, gid){
                var game = _game_map[gid];
                $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav').addClass('Hidden');
                removeFavGame(game);
            });

            function bindPopupEvent($containers){
                $('a.GameThumb', $containers).click(function(e){
                    e.preventDefault();
                });
                $('a.Game', $containers).click(function(e){
                    e.preventDefault();
                    var $anchor = $(this).parents('.GLItem');
                    var game = _game_map[$anchor.data('gameid')];
                    if(game.S == undefined ){
                        $(this).attr("href",$anchor.find(".GVLink").eq(0).attr("href")) ;
                    }
                    url = $(this).attr("href");
                    try{
                        window.open(url, 'casino_game_page_' + game.S.replace('-','_'));
                    }catch(err){
                        window.open(url, 'casino_game_page_' + game.ID);
                    }
                });
                $('a.GameThumb,a.Game,.Popup.GamePopup', $containers).mouseenter( function(e){
                    e.preventDefault();
                    var $anchor = $(this).parents('.GLItem');
                    if($anchor.attr("load")=="1")return;
                    $anchor.attr("load","1");

                    var game = _game_map[$anchor.data('gameid')];

                    $anchor.find('.AddFav a').click( function(e){
                        e.preventDefault();
                        var url = '/Casino/Lobby/AddToFavorites';
                        $.getJSON( url, { gameID : game.ID }, function(){
                            $anchor.find('.AddFav').addClass('Hidden');
                            $anchor.find('.RemoveFav').removeClass('Hidden');
                            $anchor.find('span.GTfav').removeClass('Hidden');
                            $(document).trigger( 'GAME_ADDED_TO_FAV', game.ID);
                        });
                    });


                    $anchor.find('.RemoveFav a').click( function(e){
                        e.preventDefault();
                        //console.log("$anchor.find('.RemoveFav a').click()");
                        //var $anchor = $(this).parents('.GLItem');
                        //var game = _game_map[$anchor.data('gameid')];
                        var url = '/Casino/Lobby/RemoveFromFavorites';
                        $.getJSON( url, { gameID : game.ID }, function(r){
                            $anchor.find('.AddFav').removeClass('Hidden');
                            $anchor.find('.RemoveFav').addClass('Hidden');
                            $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav').addClass('Hidden');
                            $anchor.find('span.GTfav').addClass('Hidden');
                            game.Fav = 0;
                            removeFavGame(game);
                        });
                    });

                    $anchor.find('li.Info.GOItem a').click( function(e){
                        e.preventDefault();
                        // console.log("$anchor.find('  li.Info.GOItem a').click()");
                        //var $anchor = $(this).parents('.GLItem');
                        //var game = _game_map[$anchor.data('gameid')];
                        var url = '/Casino/Game/Rule/' + game.S;
                        window.open(url
                            , 'game_rule'
                            , 'width=300,height=200,menubar=0,toolbar=0,location=0,status=1,resizable=1,centerscreen=1'
                            );
                    });

                    $anchor.find('.Fun a').click( function(e){
                        e.preventDefault();
                        showAdditional(false);
                    });

                    $anchor.find('a.CTAButton').click( function(e){
                        e.preventDefault();
                        showAdditional(true);
                    });
                    // <%-- play buttons --%>
                    function showAdditional(real){
                        // console.log("showAdditional("+real+")");
                        if( (!isAvailableLogin && real) ||
                            (game.C == null && real && game.R != 1) ||
                            (game.C == null && !real && game.F != 1) ){
                            //{'a':'c'}
                            var subUrl = game.S == undefined ? "/casino/" : "/casino/game/info/"+game.S ;
                            $(document).trigger( 'OPEN_OPERATION_DIALOG',{'returnUrl': subUrl} );
                            return;
                        }

                        if (real == true) {
                            var isEmailVerified = '<%=IsEmailVerified() %>';
                            if (!isEmailVerified.toLowerCase() == 'true') {
                                window.location = "/EmailNotVerified";
                                return;
                            } else {
                                var isIncompleteProfile = '<%=IsIncompleteProfile() %>';
                            if (isIncompleteProfile.toLowerCase() == 'true') {
                                window.location = "/IncompleteProfile";
                                return;
                            }
                        }
                    }

                    var $extra = $('#casino-game-popup-'+game.ID+' .PopupAdditional');
                    if( $extra.length == 0 ){
                        if (game.V == "999")
                        {
                            var betRadarGame = "";
                            if ($('#betradargame-template').length > 0) {
                                betRadarGame = $('#betradargame-template').parseTemplate(game);
                            }
                            $(document).trigger('GAME_TO_BE_OPENED');
                            var el = document.getElementById('casino-inline-game-container');
                            if (el != null)
                            {
                                $(el).empty().html("<div class=\"CasinoInlineGame\"></div>");
                                $('.CasinoInlineGame').html(betRadarGame);
                            }

                            jQuery('body').addClass('InlineGamePage');
                            jQuery('.SliderCol').hide("500");
                            jQuery('#show-Casinoslider').removeClass('hidden');
                            jQuery('#close-Casinoslider').addClass('hidden');

                            var $c = $('.CasinoInlineGame');

                            var $iframe = $('iframe', $c);
                            var w = parseInt($iframe.data('width'), 10);
                            var h = parseInt($iframe.data('height'), 10) * 1.0;
                            $iframe.height($iframe.width() * h / w);

                            $c.hide().fadeIn();
                            $(document).trigger('INLINE_GAME_OPENED', [{ bgImg : "" }]);

                            $('a.BackButton', $c).click(function (e) {
                                e.preventDefault();
                                $c.slideUp(function () {
                                    $(document).trigger('INLINE_GAME_CLOSED');
                                    $(this).remove();
                                });
                            });
                        } 
                        else 
                        {
                            _openCasinoGame( game.S, real == true);
                        }
                        
                    }
                    else{
                        $(".PopupAdditional").hide();
                        $extra.show();
                        $('ol.GameVariants a.GVLink').off( 'click' );
                        $('ol.GameVariants a.GVLink').on( 'click', function(e){
                            e.preventDefault();
                            _openCasinoGame( $(this).data('gameid'), real == true);
                        });
                    }
                }
                });

        }



            // <%-- Game Text List --%>
            function GameTextList(el, games){
                this._container = $(el);
                this._orginalGames = games;
                this._filteredGames = [];
                this._isVisible = false;

                this.show = function(){
                    this._isVisible = true;
                    this._container.parents('div.CatSlider').fadeIn();
                };

                this.populateView = function(){
                    var callback = (function (o) {
                        return function () {
                            o.populateViewCompleted(arguments[0]);
                        };
                    })(this);

                    CGL_Threads.filterAndSortGames(this._orginalGames, '', callback);
                };

                this.populateViewCompleted = function (result) {
                    this._filteredGames = result;

                    this._container.html( $('#casino-game-item').parseTemplate( this._filteredGames ) );
                    $(this._container).width(result.length*234);
                    bindPopupEvent(this._container);
                    $('> li.GLItem', this._container).addClass('SlideItem');

                    if(!this._isVisible)
                        this._container.parents('div.CatSlider').hide();
                };

            };

            // <%-- Game Slider --%>
            function GameSlider(el, games){
                this._slider = $(el);
                this._container = $('ul.SlideList', el);
                this._prevButton = $('a.PrevLink', el);
                this._nextButton = $('a.NextLink', el);
                this._orginalGames = games;
                this._filteredGames = [];
                this._currentLeftIndex = 0;
                this._currentRightIndex = 0;
                this._width = 0;
                this._direction = 0;
                this._isAnimating = false;
                this._isVisible = false;

                this.show = function(){
                    this._isVisible = true;
                    this._slider.parents('div.CatSlider').fadeIn();
                };

                this.populateView = function(){
                    var callback = (function (o) {
                        return function () {
                            o.populateViewCompleted(arguments[0]);
                        };
                    })(this);

                    CGL_Threads.filterAndSortGames(this._orginalGames, '', callback);
                };

                this.populateViewCompleted = function (result) {
                    this._filteredGames = result;
                    this._container.empty();
                    this._currentLeftIndex = 0;
                    var r = this._slider.offset().left + this._slider.width();

                    for( var i = 0; i < this._filteredGames.length; i++){
                        var $item = this.createItem(i).appendTo(this._container);
                        this._currentRightIndex = i;
                        if( $item.offset().left > r )
                            break;
                    }
                    var $items = $('> li', this._container);
                    if( $items.length > 1 )
                        this._width = $items.eq(1).offset().left - $items.eq(0).offset().left;

                    if(!this._isVisible)
                        this._slider.parents('div.CatSlider').hide();
                };

                this.createItem = function(index, append){
                    index = index % this._filteredGames.length;
                    if( index < 0 )
                        index = this._filteredGames.length + index;
                    var g = this._filteredGames[index];
                    if(this._filteredGames.length == 0 ){
                        return null;
                    }
                    var $item = $( $('#casino-game-item').parseTemplate( [ g ] ) );
                    if( append )
                        $item.appendTo(this._container);
                    else
                        $item.prependTo(this._container);
                    bindPopupEvent($item);
                    $item.addClass('SlideItem');
                    return $item;
                };

                this.startAnimation = function(){
                    if( this._direction == 0 )
                        return;

                    if( this._isAnimating )
                        return;
                    closeAllPopups();
                    this._isAnimating = true;

                    if( this._direction < 0 ){
                        var $first = $('> li:first', this._container);

                        var fun = (function (o) {
                            return function () {
                                o._currentLeftIndex += 1;
                                o._isAnimating = false;
                                $('> li:first', o._container).remove();
                                o.startAnimation();
                            };
                        })(this);

                        this._currentRightIndex += 1;
                        this.createItem(this._currentRightIndex, true);
                        $first.animate({ 'marginLeft': -1 * this._width }
                        , {
                            duration: 300,
                            easing: 'linear',
                            complete: function () { fun(); }
                        });
                    }
                    else {
                        this._currentLeftIndex -= 1;
                        var $first = this.createItem(this._currentLeftIndex, false);
                        $first.css( 'marginLeft', -1 * this._width );

                        var fun = (function (o) {
                            return function () {
                                o._currentRightIndex -= 1;
                                o._isAnimating = false;
                                $('> li:last', o._container).remove();
                                o.startAnimation();
                            };
                        })(this);

                        $first.animate({ 'marginLeft': 0 }
                        , {
                            duration: 300,
                            easing: 'linear',
                            complete: function () { fun(); }
                        });
                    }
                };

                var fun1 = (function (o) {
                    return function () {
                        o._direction = -1;
                        o.startAnimation();
                    };
                })(this);
                var fun2 = (function (o) {
                    return function () {
                        o._direction = 1;
                        o.startAnimation();
                    };
                })(this);
                var fun3 = (function (o) {
                    return function () {
                        o._direction = 0;
                        o.startAnimation();
                    };
                })(this);

                this._prevButton.mousedown(fun2).mouseup(fun3).mouseout(fun3).attr('href', 'javascript:void(0)');
                this._nextButton.mousedown(fun1).mouseup(fun3).mouseout(fun3).attr('href', 'javascript:void(0)');
            }

            // <%-- All List View --%>
            function CasinoAL(allData){
                this._controls = [];

                this.isSliderView = function(){
                    return $(':radio[name="displayType"][value="Grid"]').is(':checked');
                }

                this.initLoadAllButton = function(controls, count){
                    var invisibleControls = [];
                    for( var i = 0; i < controls.length; i++){
                        if( i < count )
                            controls[i]._isVisible = true;
                        else {
                            controls[i]._isVisible = false;
                            invisibleControls.push(controls[i]);
                        }
                    }

                    if( invisibleControls.length > 0 ) {
                        $('#lnkLoadAllCategories').removeClass('Hidden').off('click').on('click', function(e){
                            e.preventDefault();
                            $(invisibleControls).each( function( i, control){
                                control.show();
                            });
                            $(this).addClass('Hidden');
                        });
                    }
                    else {
                        $('#lnkLoadAllCategories').addClass('Hidden');
                    }
                };

                this.populateView = function(){
                    CGL_Threads.killThreads();
                    if( this.isSliderView() ){

                        $('div.AllGamesTextList').empty().hide();
                        $('div.AllGamesList').show();
                        if( $('div.AllGamesList > div.CatSlider').length == 0 ){
                            var html = $('#casino-category-slider').parseTemplate(_gamecategories);
                            $('div.AllGamesList').html(html);
                            this._controls = [];
                        }

                        if( this._controls.length == 0 ){
                            var controls = [];
                            $('div.AllGamesList div.Slider').each( function( i, el){
                                var cid = $(el).data('categoryid');
                                controls.push( new GameSlider(el, allData[cid]) );
                            });
                            this._controls = controls;
                            this.initLoadAllButton(this._controls, <%= InitialListCategoryCount %>);
                        }
                        for( var i = 0; i < this._controls.length; i++){
                            this._controls[i].populateView();
                        }
                    }
                    else {
                        $('div.AllGamesList').empty().hide();
                        $('div.AllGamesTextList').show();

                        if( $('div.AllGamesTextList > div.CatSlider').length == 0 ) {
                            var html = $('#casino-category-list').parseTemplate(_gamecategories);
                            $('div.AllGamesTextList').html(html);
                            this._controls = [];
                        }

                        if( this._controls.length == 0 ){
                            var controls = [];
                            $('div.AllGamesTextList ol.GamesList').each( function( i, el){
                                var cid = $(el).data('categoryid');
                                controls.push( new GameTextList(el, allData[cid]) );
                                $(this).width(allData[cid].length*234);
                            });
                            this._controls = controls;
                            this.initLoadAllButton(this._controls, <%= InitialListCategoryCount %>);
                    }
                    for( var i = 0; i < this._controls.length; i++){
                        this._controls[i].populateView();
                    }
                }
                };

            this.updateView = function(){
                this.populateView();
            };
        }

            // <%-- Game List View --%>
            function CasinoGL(games, keywords) {
                this._orginalGames = games;
                this._filteredGames = [];
                this._initialRows = <%= this.InitialRows %>;
                this._increasedRows = <%= this.IncreasedRows %>;
                this._currentRows = this._initialRows;
                this._keywords = keywords;

                this.populateView = function () {
                    var callback = (function (o) {
                        return function () {
                            o.populateViewCompleted(arguments[0]);
                        };
                    })(this);

                    CGL_Threads.killThreads();
                    CGL_Threads.filterAndSortGames(this._orginalGames, this._keywords, callback);

                    var handler = (function (o) {
                        return function () {
                            o.loadMoreGames(arguments[0]);
                        };
                    })(this);

                    var $lnk = $('#lnkLoadMoreGames').off('click').on('click', handler);
                };

                this.populateViewCompleted = function (result) {
                    this._filteredGames = result;
                    this.updateView(true);
                };

                this.updateView = function (reload) {
                    var $container = $('ol.GamesList');
                    if( reload )
                        $container.empty();

                    var $existing = $container.children('li.GLItem');

                    var columnsPerRow = 0;
                    var left = 0;
                    for( var i = 0; i < this._filteredGames.length; i++){
                        var $li = null;
                        if( i < $existing.length ){
                            $li = $existing.eq(i);
                        }
                        else{
                            var html = $('#casino-game-item').parseTemplate([this._filteredGames[i]]);
                            $li = $(html).appendTo($container);
                            bindPopupEvent($li);
                            $li.data('game', this._filteredGames[i]);
                        }

                        if( $li.offset().left > left ){
                            left = $li.offset().left;
                            columnsPerRow++;
                        } else {
                            break;
                        }
                    }

                    var num = Math.min( columnsPerRow * this._currentRows, this._filteredGames.length);
                    $existing = $container.children('li.GLItem');

                    var diff = $existing.length - num;
                    if( diff < 0 ){ // <%-- Not enough --%>
                        for( var i = $existing.length; i < num; i++){
                            var html = $('#casino-game-item').parseTemplate([this._filteredGames[i]]);
                            var $li = $(html).appendTo($container).data('game', this._filteredGames[i]);
                            bindPopupEvent($li);
                        }
                    }
                    else if( diff > 0 ){ // <%-- Too Many --%>
                        $existing.slice(-1 * diff).remove();
                    }

                    if (num < this._filteredGames.length)
                        $('#lnkLoadMoreGames').removeClass('Hidden');
                    else
                        $('#lnkLoadMoreGames').addClass('Hidden');
                }

                this.loadMoreGames = function (evt) {
                    evt.preventDefault();
                    this._currentRows += this._increasedRows;
                    this.updateView(false);
                };
            }


            // <%-- IncentiveMessage --%>
            $(document).bind( 'CATEGORY_CHANGED', function(e, category){
                $('#divIncentiveMessage').empty().addClass('Hidden');
                if( category == 'favorites' ){
                    $('#divIncentiveMessage').removeClass('Hidden').load('/Casino/Hall/IncentiveMessage/', function(){
                        $('#divIncentiveMessage > *').fadeIn();
                    });
                }
            });


            function onGameLoad(data) {
                function randomsort(a, b) {  
                    return Math.random()>.5 ? -1 : 1;
                }  
                //data.sort(randomsort);
                <% if (isGlobalbetGames) 
                { %>
                    var betRadarGames = eval('<%=GetBetRadarGames("other_games") %>');
                    if (betRadarGames.length > 0)
                    {
                        if (data["other_games"] == null) data["other_games"] = new Array();
                        for(var i=0; i< betRadarGames.length; i++)
                        {
                            data["other_games"].push(betRadarGames[i]);
                        }
                    }
                <% } %>
                _data = data;

                function initializeView(games, keywords) {
                    closeAllPopups();
                    $('div.AllGamesList').empty();
                    $('div.AllGamesTextList').empty();
                    $('ol.GamesList').removeClass('Hidden');
                    $('#lnkLoadAllCategories').addClass('Hidden');
                    _view = new CasinoGL(games, keywords);
                    _view.populateView();
                }

                function initializeAllView(games) {
                    closeAllPopups();
                    $('ol.GamesList').addClass('Hidden').empty();
                    $('#lnkLoadMoreGames').addClass('Hidden');
                    _view = new CasinoAL(games);
                    _view.populateView();
                }

                $('ol.GamesCategories a.CatTabLink,a.AdditionalLink').click(function (e) {
                    var categoryid = $(this).data('categoryid');
                    initializeView(_data[categoryid]);
                    $.cookie('_ccc', categoryid);
                    $(document).trigger('CATEGORY_CHANGED', categoryid);
                });

                $('ol.GamesCategories a.AllViewLink').click(function (e) {
                    if($(".AllGamesTextList.Container .CatSlider").length >0){return;}
                    initializeAllView(_data);
                    $(document).trigger('CATEGORY_CHANGED', '');
                });


                //<%-- filter tooltip popups --%>
                $('div.GlobalFilterCollection').delegate('.GFLabel, .GFDLink', 'mouseenter', function () {
                    var label = $(this);
                    var title = label.attr('title');
                    var popup = $('div.TooltipPopup');
                    popup.find('.PopupText').text(title);
                    label.attr('title', '');

                    pos = label.offset();
                    left = Math.floor(pos.left - popup.width() + label.width() / 2 - 2);
                    Xtop = Math.floor(pos.top) + label.height();

                    popup.css({ 'left': left + 'px', 'top': Xtop + 'px' });

                    popup.show();
                });
                $('div.GlobalFilterCollection').delegate('.GFLabel, .GFDLink', 'mouseleave', function () {
                    var label = $(this);
                    var popup = $('div.TooltipPopup');
                    label.attr('title', popup.find('.PopupText').text());
                    popup.hide();
                });

                //<%-- filter dropdown functionality --%>
                $('a.GFDLink').click(function () {
                    /*if ($(this).hasClass('GFSLink')) {
                        $('.ActiveDrop').removeClass('ActiveDrop');
                        $('.Popup').hide();
                        $('form.GlobalFilterForm').toggleClass('ActiveSummaryDrop');
                    } else {*/
                    var dropParent = $(this).parents('.GFListWrapper');
                    var closeThis = dropParent.hasClass('ActiveDrop');
                    closeAllPopups();
                    dropParent.toggleClass('ActiveDrop');
                    if (closeThis) dropParent.removeClass('ActiveDrop');
                    //}
                    return false;
                });

                //<%-- radio-button filters --%>

                $(':radio[name="sortType"],:radio[name="openType"],:radio[name="displayType"]').each( function(i, el){
                    var $li = $(el).parents('li');
                    if( $(el).is(':checked') )
                        $li.addClass('GFActive');
                    else
                        $li.removeClass('GFActive');

                    $(el).siblings('span.GFText').click( function(e){
                        e.preventDefault();
                        var $radio = $(this).siblings(':radio');
                        var name = $radio.prop('name');
                        $(':radio[name="' + name + '"]:checked').attr('checked', false);
                        $radio.attr('checked', true);
                        var $li = $radio.parent().parent();
                        $li.siblings('.GFActive').removeClass('GFActive');
                        $li.addClass('GFActive');
                        $radio.click();

                        var cssClasses = $li.attr('class').toString();
                        cssClasses = cssClasses.replace('GFilterItem', '').replace('GFActive', '');
                        $('li:first span.GFDInfo', $li.parent()).attr('class', '').addClass(cssClasses).addClass('GFDInfo');
                    });
                } );

                <% if (isGlobalbetGames) {%> 
                $.cookie('_cot', 'inline', { expires: 70, path: '/', secure: false }); 
                <%}%>
                var openType = $.cookie('_cot');
                if( openType != null && openType != '' ){
                    $(':radio[name="openType"]:checked').attr('checked', false);
                    var $selected = $(':radio[name="openType"][value="' + openType + '"]');
                    $selected.attr('checked', true);
                    $selected.siblings('span.GFText').click();
                    $("#gfdVar-opening").text($(".GLOpenModeList .GFilterItem.GFActive .GFText").text());
                } else {
                    $.cookie('_cot', $(':radio[name="openType"]:checked').val(), { expires: 70, path: '/', secure: false });
                }

                $(':radio[name="sortType"]').click( function(e){
                    closeAllPopups();
                    if( _view != null )
                        _view.populateView();
                });

                $(':radio[name="displayType"]').click( function(e){
                    if( $(this).val() == 'Grid' )
                        $('div.GamesContainer').removeClass('ViewList');
                    else
                        $('div.GamesContainer').addClass('ViewList');

                    closeAllPopups();
                    if( _view != null )
                        _view.updateView(false);
                });
                $(':radio[name="displayType"]:checked').click();

                $(':radio[name="openType"]').click( function(e){
                    closeAllPopups();
                    $.cookie('_cot', $(this).val().toLowerCase(), { expires: 70, path: '/', secure: false });
                    $("#gfdVar-opening").text($(".GLOpenModeList .GFilterItem.GFActive .GFText").text());
                });

                //<%-- window resize --%>
                $(window).bind('resize', function(e){
                    closeAllPopups();
                    if( _view != null )
                        _view.updateView(false);
                });

                //<%-- checkbox filters --%>
                $(':checkbox[name="filterVendors"]').each( function(i, el){
                    var $li = $(el).parents('li');
                    if( $(el).is(':checked') )
                        $li.addClass('GFActive');
                    else
                        $li.removeClass('GFActive');

                    $li.click( function(e){
                        e.preventDefault();
                        var $checkbox = $(this).find('span.GFText').siblings(':checkbox');

                        if ($('.GLVendorFilter').find('.GFilterItem').not('.GFilterDropdown').length == $('.GLVendorFilter').find('.GFilterItem.GFActive').length) {
                            $checkbox.parents('.GLVendorFilter').find('.GFilterItem').each(function(){
                                $(this).find(':checkbox').attr('checked', false);
                                $(this).removeClass('GFActive');
                            });
                        }

                        var s = !$checkbox.is(':checked');
                        $checkbox.attr('checked', s);
                        var $li = $checkbox.parent().parent();
                        if( s )
                            $li.addClass('GFActive');
                        else
                            $li.removeClass('GFActive');

                        if ($('.GLVendorFilter').find('.GFilterItem.GFActive').length == 0) {
                            $('.GLVendorFilter').find('.GFilterItem').each(function(){
                                $(this).find(':checkbox').attr('checked', true);
                                $(this).addClass('GFActive');
                            });
                        }

                        $('#gfdVar-vendors').text($('.GLVendorFilter').find('.GFilterItem.GFActive').length);

                        closeAllPopups();
                        if( _view != null )
                            _view.populateView();
                    });
                });

                //<%-- search games --%>
                var _timer = null;
                function searchGames(){
                    _timer = null;

                    var keywords = $('#txtGameSearchKeywords').val();
                    if( keywords.length == 0 ){
                        $('ol.GamesCategories li.ActiveCat a').trigger('click');
                    }
                    else{
                        var games = [];
                        for( var cat in _data) {
                            if( _data[cat] && !isNaN(_data[cat].length) && _data[cat].length > 0 ){
                                games = games.concat(_data[cat]);
                            }
                        }
                        initializeView( games, keywords);
                    }
                }
                $('#txtGameSearchKeywords').keyup( function(e){
                    if( _timer != null )
                        clearTimeout(_timer);
                    _timer = setTimeout( searchGames, 300);
                });



                //<%-- initialize the data --%>
                var favorites = _data['favorites'];
                for( var cat in _data)
                {
                    if( _data[cat] && !isNaN(_data[cat].length) && _data[cat].length > 0 ){
                        if( cat != 'favorites' ){
                            for( var i = 0; i < _data[cat].length; i++ ){
                                var g1 = _data[cat][i];
                                g1.Fav = favorites.indexOf(g1.ID.toString()) >= 0 ? 1 : 0;
                                _game_map[g1.ID] = g1;
                            }
                        }
                    }
                }
                favorites = [];
                for( var i = 0; i < _data['favorites'].length; i++){
                    var g3 = _game_map[_data['favorites'][i]];
                    if( g3 != null ){
                        favorites.push(g3);
                    }
                }
                _data['favorites'] = favorites;

                for( var i = 0; i < _data['popular'].length; i++){
                    _data['popular'][i].H = 1;
                    var g3 = _game_map[_data['popular'][i].ID];
                    if( g3 != null ){
                        g3.H = 1;
                    }
                }

                //<%-- Default selection --%>
                var $cur = $('ol.GamesCategories li.ActiveCat a');
                if( $cur.length > 0 )
                    $cur.trigger('click');
                else
                    $('ol.GamesCategories li:last a').trigger('click');

            } //<%-- onGameLoad end--%>

            //<%-- initialization after game data load --%>
            $.getJSON('<%= JsonUrl.SafeJavascriptStringEncode() %>', onGameLoad); //<%-- getJSON end--%>


            // <%-- Tutorials --%>
            <%-- $('#lnkGameNavTutorial').click(function(){

                var step = 1;
                function addStep( selector, information){
                    var $o = $(selector);
                    if( $o.is(':visible') ) {
                        $o.attr('data-step', step).attr('data-intro', information);
                        step ++;
                    }
                }
                $('*[data-step]').removeAttr('data-step').removeAttr('data-intro');
                addStep( 'div.AllGames ol.GamesCategories', '<%= this.GetMetadata(".Spotlight_Categories").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames ol.GamesCategories > li.Fav', '<%= this.GetMetadata(".Spotlight_MyFavorites").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames form.SearchFilterForm', '<%= this.GetMetadata(".Spotlight_SearchGame").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames div.GLVendorFilter', '<%= this.GetMetadata(".Spotlight_VendorFilter").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames #gfl-opening', '<%= this.GetMetadata(".Spotlight_OpenMode").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames #gfl-sorting', '<%= this.GetMetadata(".Spotlight_SortMethod").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames #gfl-display', '<%= this.GetMetadata(".Spotlight_ViewMode").SafeJavascriptStringEncode() %>');
                addStep( 'div.AllGames #lnkGameNavTutorial', '<%= this.GetMetadata(".Spotlight_Help").SafeJavascriptStringEncode() %>');

                introJs().start();
            });
            if ($.browser.msie  && parseInt($.browser.version, 10) === 7) {
                $('#lnkGameNavTutorial').remove();
            } --%>
        });

        $(document.body).mouseup(function () {
            $('.GFListWrapper').removeClass('ActiveDrop');

        });
        (function(){
            var GLAnimateStatus = true;
            var targetObj = $(".GLVendorFilter.GFListWrapper"),
                content_w=$(".GFilterList.Container",targetObj).width(),
                vs = $("li.GFilterItem:visible",targetObj),
                preBtn=$(".navgationbarp-wraper .pre_icon",targetObj),
                nextBtn=$(".navgationbarp-wraper .next_icon",targetObj),
                i_w=0,nb=0,lth=vs.length,
                d=200;

            function init(){
                if(lth==0)return;
                i_w=vs.width();
                nb=Math.floor(content_w/i_w);

                if(nb<vs.length){
                    preBtn.addClass("active");
                    nextBtn.addClass("active");
                }
                bindEvent();
            }
            function bindEvent(){
                preBtn.bind("click",function(){
                    if(GLAnimateStatus){
                        startAnima(true);
                        GLAnimateStatus = false;
                        setTimeout(function(){
                            GLAnimateStatus = true;
                        },500);
                    }
                });
                nextBtn.bind("click",function(){
                    if(GLAnimateStatus){
                        startAnima(false);
                        GLAnimateStatus = false;
                        setTimeout(function(){
                            GLAnimateStatus = true;
                        },500);
                    }
                });
            }
            function startAnima(dir){
                if(dir){
                    $(vs[lth-1]).css("marginLeft",-i_w).insertBefore($(vs[0])).animate({marginLeft:0},d);
                    vs = $("li.GFilterItem:visible",targetObj);
                }else{
                    $(vs[0]).animate({marginLeft:-i_w},d,function(){
                        $(vs[0]).css("marginLeft",0).insertAfter($(vs[lth-1]));
                        vs = $("li.GFilterItem:visible",targetObj);
                    });
                }
            }
            init();
        })();
</script>

<%--</ui:MinifiedJavascriptControl>--%>
