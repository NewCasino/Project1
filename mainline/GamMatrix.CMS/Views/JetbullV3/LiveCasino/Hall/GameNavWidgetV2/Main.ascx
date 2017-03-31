<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script type="text/C#" runat="server">
    /* Options
     * InitalLoadGameCount          int     optional default = 20
     * MaxNumOfNewGames             int     optional default = 12
     * MaxNumOfPopularGames         int     optional default = 12
     * DefaultCategory              string  optional
     * DialogWidth                  int     optional default = 400
     * DialogHeight                 int     optional default = 300
     * 
     
     * 
     */

    #region Options


    private string GamesViewType
    {
        get
        {
            if (this.ViewData["GamesViewType"] != null)
            {
                return this.ViewData["GamesViewType"].ToString();
            }

            return "GridView";
        }
    }

    private int MaxNumOfNewGames
    {
        get
        {
            int maxNumOfNewGames = 0;
            try
            {
                maxNumOfNewGames = (int)this.ViewData["MaxNumOfNewGames"];
            }
            catch
            {
                maxNumOfNewGames = 12;
            }
            return maxNumOfNewGames;
        }
    }

    private int MaxNumOfPopularGames
    {
        get
        {
            int maxNumOfPopularGames = 0;
            try
            {
                maxNumOfPopularGames = (int)this.ViewData["MaxNumOfPopularGames"];
            }
            catch
            {
                maxNumOfPopularGames = 12;
            }
            return maxNumOfPopularGames;
        }
    }

    private string DefaultCategory
    {
        get
        {
            return (this.ViewData["DefaultCategory"] as string) ?? "popular";
        }
    }

    private int DialogWidth
    {
        get
        {
            try
            {
                return int.Parse(this.ViewData["DialogWidth"] as string, CultureInfo.InvariantCulture);
            }
            catch
            {
                return 400;
            }
        }
    }

    private int DialogHeight
    {
        get
        {
            try
            {
                return int.Parse(this.ViewData["DialogHeight"] as string, CultureInfo.InvariantCulture);
            }
            catch
            {
                return 300;
            }
        }
    }

    private bool IsIncompleteProfile()
    {
        bool isIncompleteProfile = false;
        if (Profile.IsAuthenticated)
        {
            if (Profile.IsInRole("Incomplete Profile"))
            {
                isIncompleteProfile = true;
            }
        }

        return isIncompleteProfile;
    }

    private bool IsEmailVerified()
    {
        if (!Profile.IsAuthenticated)
            return false;
        if (!Profile.IsEmailVerified)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(Profile.UserID);
            if (!user.IsEmailVerified)
                return false;
            else if (!Profile.IsEmailVerified)
                Profile.IsEmailVerified = true;
        }

        return true;
    }

    #endregion
    private int TotalTableCount;
    private string CategoryHtml;
    private string VendorFilterHtml;
    private string JsonData;
    private string[] Vendors;
    private int FavoritesTableCount;

    private string[] GetFavorites()
    {
        long clientIdentity = 0L;

        if (HttpContext.Current != null &&
            HttpContext.Current.Request != null &&
            HttpContext.Current.Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
        {
            long.TryParse(HttpContext.Current.Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value
                , NumberStyles.Any
                , CultureInfo.InvariantCulture
                , out clientIdentity
                );
        }

        LiveCasinoFavoriteTableAccessor cfga = LiveCasinoFavoriteTableAccessor.CreateInstance<LiveCasinoFavoriteTableAccessor>();

        return cfga.GetByUser(SiteManager.Current.DomainID, CM.State.CustomProfile.Current.UserID, clientIdentity).ToArray();
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        /////////////////////////////////////////////////////////////////////////
        // CategoryHtml
        /////////////////////////////////////////////////////////////////////////

        const string CATEGORY_FORMAT = @"
<li class=""TabItem cat-{0}"">
<a href=""#"" class=""Button TabLink CatTabLink"" data-category=""{0}"">
<span class=""CatIcon"">&para;</span>
        <span class=""CatNumber"">{1:D}</span>
<span class=""CatText"">{2}</span>
</a>
</li>";

        StringBuilder json1 = new StringBuilder();
        StringBuilder json2 = new StringBuilder();
        StringBuilder html = new StringBuilder();
        Dictionary<VendorID, string> vendors = new Dictionary<VendorID, string>();
        List<KeyValuePair<string, List<LiveCasinoTable>>> categories = new List<KeyValuePair<string, List<LiveCasinoTable>>>();

        string specifiedCategory = this.ViewData["category"] as string;
        if (!string.IsNullOrWhiteSpace(specifiedCategory) && !specifiedCategory.Equals("all", StringComparison.InvariantCultureIgnoreCase))
        {
            categories = GameMgr.GetLiveCasinoTables(SiteManager.Current).Where(n => n.Key.Equals(specifiedCategory, StringComparison.InvariantCultureIgnoreCase)).ToList();
        }
        else
        {
            categories = GameMgr.GetLiveCasinoTables(SiteManager.Current).Where(n => !n.Key.Equals("LOTTERY", StringComparison.InvariantCultureIgnoreCase)).ToList();
        }

        TotalTableCount = 0;

        var favorites = GetFavorites();

        FavoritesTableCount = favorites.Length;

        json1.Append("[");
        foreach (KeyValuePair<string, List<LiveCasinoTable>> category in categories)
        {
            string name = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "/Metadata/LiveCasino/GameCategory/{0}.Text", category.Key)).DefaultIfNullOrEmpty(category.Key);
            html.AppendFormat(CultureInfo.InvariantCulture, CATEGORY_FORMAT
                , category.Key
                , category.Value.Count
                , name.SafeHtmlEncode()
                );
            TotalTableCount = TotalTableCount + category.Value.Count;

            foreach (LiveCasinoTable table in category.Value)
            {
                vendors[table.VendorID] = table.VendorID.ToString();
                string limitVal = table.GetLimit(Profile.UserCurrency.DefaultIfNullOrEmpty("EUR")).SafeJavascriptStringEncode();

                var startLimit = 0.0;
                var endLimit = 0.0;

                if (!string.IsNullOrEmpty(limitVal))
                {
                    var arr = limitVal.Split(' ');

                    if (arr.Length > 3)
                    {
                        double.TryParse(arr[1].Replace(",", ""), out startLimit);
                        double.TryParse(arr[3].Replace(",", ""), out endLimit);
                    }


                    Regex regex = new Regex(@"^(\D)+ (\d|\.)+ - (\d)+$");
                    Match m = regex.Match(limitVal);
                    if (m.Success)
                    {
                        int limitValI = 0;
                        string limitValT = limitVal.Substring((limitVal.IndexOf("-")) + 1, (limitVal.Length - limitVal.IndexOf("-")) - 1);

                        if (int.TryParse(limitValT.Replace(" ", ""), out limitValI))
                        {
                            limitValT = limitValI.ToString("N");
                            limitVal = string.Format("{0} {1}",
                                limitVal.Substring(0, limitVal.IndexOf("-") + 1),
                                (limitValT.IndexOf(",00") > 0 && limitValT.Substring(limitValT.Length - 3, 3).Equals(",00"))
                                    ? limitValI.ToString("N").Split(',')[0].Replace('.', ',') : limitValI.ToString("N").Split('.')[0]


                                );
                        }
                    }
                }
                StringBuilder json = table.IsOpened ? json1 : json2;
                json.AppendFormat(CultureInfo.InvariantCulture
                    , "{{\"ID\":{0},\"P\":{1},\"V\":\"{2}\",\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"R\":{6},\"S\":\"{7}\",\"T\":{8},\"H\":{9},\"O\":{10},\"C\":\"{11}\",\"Opened\":{12},\"Limit\":\"{13}\",\"OpeningHours\":\"{14}\",\"VIP\":\"{15}\",\"NewTable\":\"{16}\",\"TurkishTable\":\"{17}\",\"BetBehind\":{18},\"ExcludedFromRandomLaunch\":{19},\"SeatsUnlimited\":{20},\"DealerGender\":\"{21}\",\"DealerOrigin\":\"{22}\",\"SeatsMax\":{23},\"SeatsTaken\":{24},\"SeatsAvailable\":{25},\"StartLimit\":{26},\"EndLimit\":{27},\"Fav\":{28}}},"
                    , table.ID
                    , Math.Min(table.Popularity, 9007199254740991)
                    , table.VendorID.ToString()
                    , table.Name.SafeJavascriptStringEncode()
                    , table.ThumbnailUrl.SafeJavascriptStringEncode()
                    , (Profile.IsAuthenticated ? table.IsFunModeEnabled : table.IsAnonymousFunModeEnabled) ? "1" : "0"
                    , (Profile.IsAuthenticated && table.IsRealMoneyModeEnabled) ? "1" : "0"
                    , table.Slug.DefaultIfNullOrEmpty(table.ID).SafeJavascriptStringEncode()
                    , "0"
                    , "0"
                    , table.FPP >= 1.00M ? "1" : "0"
                    , category.Key.SafeJavascriptStringEncode()
                    , table.IsOpened.ToString().ToLowerInvariant()
                    , limitVal
                    , table.OpeningHours.SafeJavascriptStringEncode()
                    , table.IsVIPTable ? "1" : "0"
                    , table.IsNewTable ? "1" : "0"
                    , table.IsTurkishTable ? "1" : "0"
                    , table.IsBetBehindAvailable ? "1" : "0"
                    , table.IsExcludedFromRandomLaunch ? "1" : "0"
                    , table.IsSeatsUnlimited ? "1" : "0"
                    , table.DealerGender
                    , table.DealerOrigin
                    , table.SeatsMax
                    , table.SeatsTaken
                    , table.SeatsMax - table.SeatsTaken
                    , startLimit
                    , endLimit
                    , favorites.Contains(table.ID) ? "1" : "0");
            }
        }
        if (json2.Length > 0)
        {
            json2.Remove(json2.Length - 1, 1);
            json1.Append(json2);
        }
        else if (json1[json1.Length - 1] == ',')
            json1.Remove(json1.Length - 1, 1);

        json1.Append("]");

        this.Vendors = vendors.Keys.Select(v => v.ToString()).ToArray();

        JsonData = json1.ToString();
        
        CategoryHtml = html.ToString();

        // vendors
        html.Clear();
        html.AppendFormat(@"<div class=""GLVendorFilter GFListWrapper GFL{0}"">
<ul class=""GFilterList GFMultipleItems Container"">"
            , vendors.Count
            );

        html.AppendFormat(@"<li class=""GFilterItem GFilterDropdown"">
                                <a class=""GFDLink"" href=""#"" title=""{2}"">
                                    <span class=""GFDText"">
                                        <span class=""Hidden"">{0}</span>
                                        <span class=""ActionSymbol"">&#9660;</span>
                                    </span>
<span class=""GFDInfo"">
                                        <span class=""GFDVar"" id=""gfdVar-contentProviders"">{1}</span>
                                        <span class=""GFDDelimiter"">/</span>
                                        <span class=""GFDTotel"">{1}</span>
                                        <span class=""GFDIText""> selected</span>
                                    </span>
</a>
</li>",
                            this.GetMetadata(".Filters_See_All").SafeHtmlEncode(),
                            vendors.Count,
                            this.GetMetadata(".VendorFilter_Title").SafeHtmlEncode());

        var index = 0;

        foreach (var vendor in vendors)
        {

            string name = this.GetMetadata(
                    string.Format(CultureInfo.InvariantCulture
                        , "/Metadata/GammingAccount/{0}.Display_Name"
                        , vendor.Value
                    )
                 ).DefaultIfNullOrEmpty(vendor.Value);

            html.AppendFormat(@"
<li class=""GFilterItem {0} GFActive GFilterItemExtra"">
    <label for=""gfVendor{0}"" class=""GFLabel"" title=""{1}"">
        <input type=""checkbox"" checked=""checked"" id=""gfVendor{0}"" name=""filterVendors"" value=""{0}"" class=""hidden"" />
        <span class=""GFText"">{2}</span>
        <span class=""GFVendorName"">{2}</span>
    </label>
</li>"
                , vendor.Key
                , this.GetMetadataEx(".VendorFilter_Toggle", name).SafeHtmlEncode()
                , name.SafeHtmlEncode()
                );

            index++;
        }

        html.Append("</ul></div>");
        VendorFilterHtml = html.ToString();
    }
</script>
<%
    
    if (this.ViewData["BannerPath"] != null && !string.IsNullOrEmpty(this.ViewData["BannerPath"].ToString()))
    {
        Response.Write(this.GetMetadata(this.ViewData["BannerPath"].ToString()));
    }
    else
    {
        Response.Write(this.GetMetadata(".StaticSlider_Html"));
    }
        
        %>
<div id="livecasino-inline-game-section" class="LiveCasinoInlineTableSection" style="width:100%;display:none;">
    <div class="ControlBar">
<ul class="ControllerButtons">
            <li class="CB CBClose">
<a class="Button" href="javascript:void(0)" title="<%= this.GetMetadata("/_Popup_ascx.Close").SafeHtmlEncode() %>">
<span class="CloseIcon Close"></span>
<span><%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Close").SafeHtmlEncode() %></span>
</a>
</li>
<li class="CB CBFav">
<a class="Button" href="javascript:void(0)" title="<%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_AddToFav").SafeHtmlEncode() %>">
<span class="InfoIcon AddToFav"></span>
<span><%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_AddToFav").SafeHtmlEncode() %></span>
</a>
</li>

        </ul>
    </div>
    <div id="livecasino-inline-game-container" class="LiveCasinoInlineTableContainer" style="width:100%;">
    </div> 
</div>
<div class="Box AllTables New" style="display:none;">
    <%=this.GetMetadata(".SliderControllerBar_Html")%>

    <div class="TablesHeader Container">
        <h2 class="BoxTitle TablesTitle">
            <span class="TitleIcon">&sect;</span>
            <strong class="TitleText"><%= this.GetMetadataEx(".Title_Tables", this.TotalTableCount).HtmlEncodeSpecialCharactors() %></strong>
        </h2>
        <div class="TableFilters clearfix">
            <form class="FilterForm SearchFilterForm" action="#" onsubmit="return false">
                <%----------------------------
                    Search Games
                ----------------------------%>
                <fieldset>
                    <label class="hidden" for="txtTableSearchKeywords"><%= this.GetMetadata(".GameName_Insert").SafeHtmlEncode() %></label>
                    <input class="FilterInput" type="search" id="txtTableSearchKeywords" name="txtTableSearchKeywords" accesskey="g" maxlength="50" value="" placeholder="<%= this.GetMetadata(".GameName_PlaceHolder").SafeHtmlEncode() %>" />
                    <button type="submit" class="Button SearchButton" name="gameSearchSubmit" id="btnSearchGame">
                        <span class="ButtonText"><%= this.GetMetadata(".Search").SafeHtmlEncode() %></span>
                    </button>
                </fieldset>
            </form>
            <% if (this.GetMetadata(".IsRandomTable_Visible").ToLowerInvariant() == "yes") { %>
            <div class="random-table-container">
                <button type="button" class="Button RandomTable" name="RandomTable" id="btnRandomTable" title="<%=this.GetMetadata(".Button_RandomTable")%>">
<span><%=this.GetMetadata(".Button_RandomTable")%></span>
</button>
            </div>
            <%} %>
            <form class="FilterForm GlobalFilterForm" action="#" onsubmit="return false">
                <fieldset>
                    <div class="GlobalFilterSummary">
                        <a class="GFDLink GFSLink" id="gfl-summary" href="#" title="List of Applied Filters">
                            <span class="GFDText"><span class="Hidden">t&#252;m bak</span><span class="ActionSymbol">&#9660;</span></span>
                            <span class="GFDInfo">Filter</span>
                        </a>
                    </div>
                    <div class="GlobalFilterCollection">
                        <%=this.GetMetadata(".GLFilterTitle")%>
                        
                        <%----------------------------
                            View Switcher
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_View").ToLowerInvariant() == "yes")
                           { %>
    <div class="GFListWrapper GFL2 GLViewSwitcher">
    <ul class="GFilterList Container" id="gfl-display">
    <li class="GFilterItem GFilterDropdown">
    <a class="GFDLink GFDSymbol" id="gfl-displayTrigger" href="#" title="<%= this.GetMetadata(".ViewSwitcher_Title").SafeHtmlEncode()%>">
    <span class="GFDText"><span class="Hidden"><%= this.GetMetadata(".Filters_See_All").SafeHtmlEncode()%></span><span class="ActionSymbol">&#9660;</span></span>
    <span class="GFDInfo <%= GamesViewType == "GridView" ? "Grid" : "List" %>">
                                                <span class="GFDVar" id="gfdVar-display">
                                                    <%= GamesViewType == "GridView" ? this.GetMetadata(".ViewSwitcher_Grid").SafeHtmlEncode() : this.GetMetadata(".ViewSwitcher_List").SafeHtmlEncode() %>
                                                </span>
    </span>
    </a>
    </li>
    <li class="GFilterItem GFGrid <%= GamesViewType == "GridView" ? "GFActive" : string.Empty %>">
    <label for="gfGrid" class="GFLabel" title="<%= this.GetMetadata(".ViewSwitcher_Grid_Title").SafeHtmlEncode()%>">
    <input type="radio" checked="checked" id="gfGrid" name="displayType" value="Grid" class="hidden" />
    <span class="GFText"><%= this.GetMetadata(".ViewSwitcher_Grid").SafeHtmlEncode()%></span>
    </label>
    </li>
    <li class="GFilterItem GFList <%= GamesViewType == "ListView" ? "GFActive" : string.Empty %>">
    <label for="gfList" class="GFLabel" title="<%= this.GetMetadata(".ViewSwitcher_List_Title").SafeHtmlEncode()%>">
    <input type="radio" id="gfList" name="displayType" value="List" class="hidden" />
    <span class="GFText"><%= this.GetMetadata(".ViewSwitcher_List").SafeHtmlEncode()%></span>
    </label>
    </li>
    </ul>
    </div>
                        <% } %>

                        <%----------------------------
                            More Filters
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_MoreFilters").ToLowerInvariant() == "yes")
                           { %>
                            <div class="GFListWrapper GFL1 GLOpenModePopup">
                                <a class="GFLabel" href="javascript:void(0);" title="<%: this.GetMetadata(".MoreFiltersText") %>">
                                    <span class="GFText"><%: this.GetMetadata(".MoreFiltersText") %></span>
</a>
                                <div class="GPopupMenu">
                                    <table>
                                        <tr style="display:none;">
                                            <td><%: this.GetMetadata(".HideFullTablesText") %></td>
                                            <td>
                                                <input type="checkbox" id="cbxHideFullTables" />
                                            </td>
                                        </tr>
                                        <tr>
                                            <td><%: this.GetMetadata(".HideClosedTablesText") %></td>
                                            <td>
                                                <input type="checkbox" id="cbxHideClosedTables" />
                                            </td>
                                        </tr>
                                        <tr>
                                            <td><%: this.GetMetadata(".HideRandomTableLaunchButtonText") %></td>
                                            <td>
                                                <input type="checkbox" id="cbxHideRandomTableLunchButton" />
                                            </td>
                                        </tr>
                                        <tr>
                                            <td><%: this.GetMetadata(".DealerGenderText") %></td>
                                            <td>
                                                <input type="checkbox" id="cbxMaleOnly" />
                                                <label for="cbxMaleOnly"><%: this.GetMetadata(".MaleOnlyText") %></label>
                                                <input type="checkbox" id="cbxFemaleOnly" />
                                                <label for="cbxFemaleOnly"><%: this.GetMetadata(".FemaleOnlyText") %></label>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td><%: this.GetMetadata(".BetlimitText") %></td>
                                            <td>
                                                <input type="text" id="txtBetLimitStart" /> --
                                                <input type="text" id="txtBetLimitEnd" />
                                            </td>
                                        </tr>
                                        <tr>
                                            <td><%: this.GetMetadata(".DealerOriginText") %></td>
                                            <td>
                                                <select id="sltDealerOrigin">
                                                </select>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        <% } %>

                        <%----------------------------
                            Sort Criteria
                        ----------------------------%>
                        
                        <% if (this.GetMetadata(".IsSortFilter_View").ToLowerInvariant() == "yes")
                           { %>
    <div class="GFListWrapper GFL3 GLSortSwitcher">
    <ul class="GFilterList Container" id="gfl-sort">
    <li class="GFilterItem GFilterDropdown">
    <a class="GFDLink GFDSymbol" id="gfl-sortTrigger" href="#" title="<%= this.GetMetadata(".SortSwitcher_Title").SafeHtmlEncode()%>">
    <span class="GFDText"><span class="Hidden"><%= this.GetMetadata(".Filters_See_All").SafeHtmlEncode()%></span><span class="ActionSymbol">&#9660;</span></span>
    <span class="GFDInfo GFDefault">
                                                <span class="GFDVar" id="gfdVar-sort">
                                                    <%= this.GetMetadata(".SortSwitcher_Default").SafeHtmlEncode() %>
                                                </span>
    </span>
    </a>
    </li>
    <li class="GFilterItem GFDefault GFActive">
    <label for="gfSortDefault" class="GFLabel" title="<%= this.GetMetadata(".SortSwitcher_Default_Title").SafeHtmlEncode()%>">
    <input type="radio" checked="checked" id="gfSortDefault" name="SortType" value="Default" class="hidden" data-sortfield="default" data-sortorder="asc"/>
    <span class="GFText"><%= this.GetMetadata(".SortSwitcher_Default").SafeHtmlEncode()%></span>
    </label>
    </li>
    <li class="GFilterItem GFPopularity">
    <label for="gSortPopularity" class="GFLabel" title="<%= this.GetMetadata(".SortSwitcher_Popularity_Title").SafeHtmlEncode()%>">
    <input type="radio" id="gSortPopularity" name="SortType" value="Popularity" class="hidden" data-sortfield="popularity" data-sortorder="desc"/>
    <span class="GFText"><%= this.GetMetadata(".SortSwitcher_Popularity").SafeHtmlEncode()%></span>
    </label>
    </li>
                                <li class="GFilterItem GFAlphabetical">
    <label for="gSortAlphabetical" class="GFLabel" title="<%= this.GetMetadata(".SortSwitcher_Alphabetical_Title").SafeHtmlEncode()%>">
    <input type="radio" id="gSortAlphabetical" name="SortType" value="Alphabetical" class="hidden" data-sortfield="alphabetical" data-sortorder="asc"/>
    <span class="GFText"><%= this.GetMetadata(".SortSwitcher_Alphabetical").SafeHtmlEncode()%></span>
    </label>
    </li>
    </ul>
    </div>
                        <% } %>

                        <%----------------------------
                            Open Mode
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_OpenMode").ToLowerInvariant() == "yes")
                           { %>
    <div class="GFListWrapper GFL4 GLOpenModeList">
    <ul class="GFilterList Container" id="gfl-opening">
    <li class="GFilterItem GFilterDropdown">
    <a class="GFDLink GFDSymbol" id="gfl-openingTrigger" href="#" title="<%= this.GetMetadata(".OpenMode_Title").SafeHtmlEncode()%>">
    <span class="GFDText"><span class="Hidden"><%= this.GetMetadata(".Filters_See_All").SafeHtmlEncode()%></span><span class="ActionSymbol">&#9660;</span></span>
    <span class="GFDInfo GFPopup"><span class="GFDVar" id="gfdVar-opening"><%= this.GetMetadata(".OpenMode_Popup").SafeHtmlEncode()%></span></span>
    </a>
    </li>
    <li class="GFilterItem GFPopup GFActive">
    <label for="gfPopup" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Popup_Title").SafeHtmlEncode()%>">
    <input type="radio" checked="checked" id="gfPopup" name="openType" value="popup" class="hidden" />
    <span class="GFText"><%= this.GetMetadata(".OpenMode_Popup").SafeHtmlEncode()%></span>
    </label>
    </li>
    <li class="GFilterItem GFInline">
    <label for="gfInline" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Inline_Title").SafeHtmlEncode()%>">
    <input type="radio" id="gfInline" name="openType" value="inline" class="hidden" />
    <span class="GFText"><%= this.GetMetadata(".OpenMode_Inline").SafeHtmlEncode()%></span>
    </label>
    </li>
    <li class="GFilterItem GFNewTab">
    <label for="gfNewTab" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_NewTab_Title").SafeHtmlEncode()%>">
    <input type="radio" id="gfNewTab" name="openType" value="newtab" class="hidden" />
    <span class="GFText"><%= this.GetMetadata(".OpenMode_NewTab").SafeHtmlEncode()%></span>
    </label>
    </li>
    <li class="GFilterItem GFFullScreen">
    <label for="gfFullScreen" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Fullscreen_Title").SafeHtmlEncode()%>">
    <input type="radio" id="gfFullScreen" name="openType" value="fullscreen" class="hidden" />
    <span class="GFText"><%= this.GetMetadata(".OpenMode_Fullscreen").SafeHtmlEncode()%></span>
    </label>
    </li>
    </ul>
    </div>

                        <% } %>

                        <%----------------------------
                        Vendor Filter
                        ----------------------------%>
                        <%= this.VendorFilterHtml %>
                        
                        <%----------------------------
                              Table Categories Switcher
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_TableCategoriesSwitcher").ToLowerInvariant() == "yes")
                           { %>

                        <div class="GFListWrapper GLCategoriesFilter GFL4">
                            <ul class="GFilterList GFMultipleItems Container">
                                <li class="GFilterItem GFilterDropdown">
    <a class="GFDLink GFDSymbol" id="A1" href="#" title="<%= this.GetMetadata(".Categories_Title").SafeHtmlEncode()%>">
    <span class="GFDText"><span class="Hidden"><%= this.GetMetadata(".Filters_See_All").SafeHtmlEncode()%></span><span class="ActionSymbol">&#9660;</span></span>
    <span class="GFDInfo GFCategories"><span class="GFDVar" id="Span1"><%= this.GetMetadata(".Categories_Title").SafeHtmlEncode()%></span></span>
    </a>
    </li>
                        <%----------------------------
                              Table Favorites Switcher
                        ----------------------------%>
                        
                                <li class="GFilterItem GFFavoriteTables">
                                    <label for="filterFavorites" class="GFLabel" title="Show Only Favorite Tables">
                                        <input type="checkbox" id="filterFavorites" name="filterFavorites" value="Favorites" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".FavoritesTable_Text") %></span>
                                        <span class="GFIcon">&nbsp;</span>
                                    </label>
                                </li>
                            
                        <%----------------------------
                              Table Popular Switcher
                        ----------------------------%>

                                <li class="GFilterItem GFPopularTables">
                                    <label for="filterPopular" class="GFLabel" title="Show Only Popular Tables">
                                        <input type="checkbox" id="filterPopular" name="filterPopular" value="Popular" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".PopularTable_Text") %></span>
                                        <span class="GFIcon">&nbsp;</span>
                                    </label>
                                </li>

                        <%----------------------------
                            New Table Switcher
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_NewTable").ToLowerInvariant() == "yes")
                           { %>
                                <li class="GFilterItem GFNewTables">
                                    <label for="filterNew" class="GFLabel" title="Show Only New Tables">
                                        <input type="checkbox" id="filterNew" name="filterNew" value="New" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".NewTable_Text") %></span>
                                        <span class="GFIcon">&nbsp;</span>
                                    </label>
                                </li>
                        <% } %>

                        <%----------------------------
                            Unlimited Seats Table Switcher
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_UnlimitedSeatsTable").ToLowerInvariant() == "yes")
                           { %>
                                <li class="GFilterItem GFUnlimitedSeatsTables">
                                    <label for="filterUnlimitedSeats" class="GFLabel" title="Show Only Tables With Unlimited Seats">
                                        <input type="checkbox" id="filterUnlimitedSeats" name="filterUnlimitedSeats" value="UnlimitedSeats" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".UnlimitedSeatsTable_Text") %></span>
                                        <span class="GFIcon">&nbsp;</span>
                                    </label>
                                </li>
                        <% } %>

                        <%----------------------------
                            VIPTable Switcher
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_VIPTable").ToLowerInvariant() == "yes")
                           { %>
                                <li class="GFilterItem GFVIPTables">
                                    <label for="filterVIPTables" class="GFLabel" title="Show VIP Tables">
                                        <input type="checkbox" id="filterVIPTables" name="filterVIPTables" value="VIPTables" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".VIPTable_Text") %></span>
                                        <span class="GFIcon">&nbsp;</span>
                                    </label>
                                </li>
                        <% } %>
                        
                        <%----------------------------
                            TurkishTable Switcher
                        ----------------------------%>
                        <% if (this.GetMetadata(".IsFilterVisible_TurkishTable").ToLowerInvariant() == "yes")
                           { %>
                                <li class="GFilterItem GFTurkishTables">
                                    <label for="filterTurkishTables" class="GFLabel" title="Show Turkish Tables">
                                        <input type="checkbox" id="filterTurkishTables" name="filterTurkishTables" value="TurkishTables" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".TurkishTable_Text")%></span>
                                        <span class="GFIcon">&nbsp;</span>
                                    </label>
                                </li>
                        <% } %>

                            </ul>
                        </div>
                        <%} %>
                    </div>
                    <button type="submit" class="Button hidden">
                        <span>Filter</span>
                    </button>
                </fieldset>
            </form>
        </div>
    </div>

    <div class="GamesCategoriesWrap">
        <ol class="GamesCategories Tabs Tabs-1">
            <li class="TabItem cat-favorites">
                <a href="#" class="Button TabLink CatTabLink" data-category="favorites">
                    <span class="CatIcon">&para;</span>
                    <span class="CatNumber"><%= FavoritesTableCount %></span>
                    <span class="CatText"><%= this.GetMetadata(".Category_Favorites").SafeHtmlEncode() %></span>
                </a>
            </li>
            <li class="TabItem cat-popular">
                <a href="#" class="Button TabLink CatTabLink" data-category="popular" data-sortfield="popularity" data-sortorder="desc">
                    <span class="CatIcon">&para;</span>
                    <span class="CatNumber"><%= TotalTableCount <= MaxNumOfPopularGames ? TotalTableCount : MaxNumOfPopularGames %></span>
                    <span class="CatText"><%= this.GetMetadata(".Category_Popular").SafeHtmlEncode() %></span>
                </a>
            </li>

            <%= CategoryHtml %>

            <li class="TabItem cat-All ActiveCat">
                <a href="#" class="Button TabLink CatTabLink" data-category="All">
                    <span class="CatIcon">&para;</span>
                    <span class="CatNumber"><%= TotalTableCount %></span>
                    <span class="CatText"><%= this.GetMetadata(".Category_All").SafeHtmlEncode() %></span>
                </a>
            </li>
        </ol>
        <div class="LiveCasinobanner TableExclusive">
            <div class="BannerContent">
                <%=this.GetMetadata(".LiveCasinoBanner") %>
            </div>
        </div>
    </div>

    <div class="TablesContainer" <%= GamesViewType %>>
        <div class="TablesList ListViewContainer">
            <% if (this.JsonData.Length > 2 && GamesViewType == "ListView")
               {%>
            <%= this.PopulateTemplateWithJson("ListViewGames", this.JsonData, new { isLoggedIn = Profile.IsAuthenticated })%>
            <%} %>
        </div>
        <div class="TablesList Container">
            <%=this.GetMetadata(".TimeTable_Html") %>
            <%if (this.JsonData.Length > 2 && GamesViewType == "GridView") // []
              { %>
            <%= this.PopulateTemplateWithJson("TableListItem", this.JsonData, new { isLoggedIn = Profile.IsAuthenticated })%>
            <% } %>
            <%if (this.JsonData == "[]")
              {
                  string msg = this.GetMetadataEx(".No_Table_Available"
                      , Request.GetRealUserAddress()
                      , Profile.IpCountryID
                      , Profile.UserCountryID
                      );
               %>
            <%: Html.WarningMessage(msg) %>
            <% } %>
        </div>
        <div class="ShowMoreTablesBox Hidden"> 
            <a id="show-MoreTables" class="SliderToggle ShowMoreTables" href="#show-MoreTables" data-url="show-MoreTables"> 
                <span class="ButtonText SliderCloseText"><%=this.GetMetadata(".MoreTables")%></span> 
                <span class="SliderBtnIcon"> </span> 
            </a> 
        </div>
    </div>
</div>
<%------------------------
    this is the container for all the popups in the page. they will need to be positioned with JavaScript
------------------------%>
<div class="PopupsContainer" id="livecasino-hall-popups">
    <div class="Popup GamePopup" id="livecasino-game-popup">
    </div>
</div>
<%= this.ClientTemplate("GamePopup", "livecasino-game-popup-template", new { vendors = this.Vendors, isLoggedIn = Profile.IsAuthenticated })%>
<%= this.ClientTemplate("ListViewGames", "livecasino-list-view-games-template")%>
<%= this.ClientTemplate("TableListItem", "livecasino-grid-view-games-template")%>

<% Html.RenderPartial("GameNavWidgetV2/Popup", this.ViewData.Merge(new { })); %>

<script src="/js/jquery/jquery.kwicks.js" type="text/javascript"></script>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="false" Enabled="false">
<script type="text/javascript">
    var _game_map = {};
    function GameNavWidgetV2(){
        $('.Box.AllTables.New').toggle();
        var self = this;

        

        var randomLaunchJson = <%= JsonData %>;
        var initialJson = <%= JsonData %>;
        var json = <%= JsonData %>;

        var _timer = null;
        var _timerBetLimitStart = null;
        var _timerBetLimitEnd = null;

        var maxNumberOfPopularGames = <%= TotalTableCount <= MaxNumOfPopularGames ? TotalTableCount : MaxNumOfPopularGames %>;

        var gamesViewType = '<%= GamesViewType %>';

        var gridViewGamesModel = null;
        var listViewGamesModel = null;

        self.VisibleGames = json;
        self.IsLoggedIn = <%= Profile.IsAuthenticated.ToString().ToLower() %>;
        self.GamesViewTypes = { ListView: 'ListView', GridView: 'GridView' };
        
        var addToFavText = "<%=this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_AddToFav").SafeJavascriptStringEncode()%>";
        var removeFromFavText = "<%=this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_RemoveFav").SafeJavascriptStringEncode()%>";


        self.GetGame = function(gameId){
            return _game_map[gameId];
        };
        
        function setFavButtonState(gameIsFav) {
            if (gameIsFav == true) {
                $('.ControllerButtons .CB.CBFav').addClass('Actived');
                $('.ControllerButtons .CB.CBFav span').text(removeFromFavText);
                $('.ControllerButtons .CB.CBFav .Button').attr('title', removeFromFavText);
                
                return;
            }
            
            $('.ControllerButtons .CB.CBFav').removeClass('Actived');
            $('.ControllerButtons .CB.CBFav span').text(addToFavText);
            $('.ControllerButtons .CB.CBFav .Button').attr('title', addToFavText);
        }
        
        $('.ControllerButtons .CB.CBFav .Button').click(function (e) {
            e.preventDefault();
            var url = '/LiveCasino/Home/AddToFavorites/';

            var isActived = $(this).parent().hasClass('Actived');

            if (isActived){
                url = '/LiveCasino/Home/RemoveFromFavorites/';
            }
            
            $.getJSON(url, { tableID: $(this).data('gameId') }, function (data) {
                if (data.success) {
                    setFavButtonState(!isActived);
                }
            });
        });

        $('.ControllerButtons .CB.CBClose').click(function(){
            $('#livecasino-inline-game-section').hide();
            $('.LiveCasinoInlineTableContainer').empty();
        });

        function openLiveTableGame(gameId, openType) {
            var game = self.GetGame(gameId);

            if( !game.Opened )
                return;

            if (!openType){
                openType = $.cookie('_lcot');
            }
            
            switch (openType) {
                case 'fullscreen':
                    var w = screen.availWidth * 9 / 10;
                    var h = screen.availHeight * 9 / 10;
                    var l = (screen.width - w)/2;
                    var t = (screen.height - h)/2;
                    //var scrollbars='no';

                    //if(game.V == 'BetGames')
                    //    scrollbars='yes';
                    var params = [
                        'height=' + h,
                        'width=' + w,
                        'fullscreen=no',
                        'scrollbars=auto',
                        'status=yes',
                        'resizable=yes',
                        'menubar=no',
                        'toolbar=no',
                        'left=' + l,
                        'top=' + t,
                        'location=no',
                        'centerscreen=yes'
                    ].join(',');

                    window.open( '/LiveCasino/Hall/Start?tableID=' + game.ID, 'live_casino_table', params);
                    break;

                case 'newtab':
                    window.open('/LiveCasino/Hall/Game?tableID=' + game.ID + '&f=' + game.Fav, 'live_casino_table');
                    break;

                case 'inline':
                    $('.ControllerButtons .CB.CBFav .Button').data('gameId', game.ID);
                    setFavButtonState(game.Fav);
                    $('#livecasino-inline-game-section').show();
                    var container = $('.LiveCasinoInlineTableContainer');

                    if (container != null) {
                        var $iframe = $('<iframe>', {
                            src: '/LiveCasino/Hall/Start?tableID=' + game.ID,
                            id:  'LiveCasinoTableFrame',
                            frameborder: 0,
                            scrolling: 'auto',
                        });

                        $(container).empty();
                        $iframe.appendTo(container);

                        //adjusting game window dimentions
                        var fw = parseInt($iframe.width(), 10);
                        var fh = parseInt($iframe.height(), 10) * 1.0;
                        var finalHeight = container.width() * fh / fw;

                        $iframe.width('100%');
                        $iframe.height(finalHeight);
                    }
                    break;
                
                default:
                    liveCasinoTableOpenerWidget.OpenTable(game);
                    $('.LiveCasinoTableOverlay').show().fadeIn(700);
                    break;
            }
        }

        self.OpenGame = function(gameId){
            if( !self.IsLoggedIn ){
                $.cookie('loginDialogGameId', gameId);
                $('iframe.LoginDialog').remove();
                $('<iframe style="border:0px;width:<%=DialogWidth %>px;height:<%=DialogHeight %>px;display:none" frameborder="0" scrolling="no" src="/Login/Dialog?_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="LoginDialog"></iframe>').appendTo(top.document.body);
                var $iframe = $('iframe.LoginDialog', top.document.body).eq(0);
                $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
            } else {
                //check if user profile is full or not
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

                openLiveTableGame(gameId);
            }
        };

        self.SortGames = function(element, sortByParam, sortOrderParam){
            var sortBy = '';
            var sortOrder = '';

            if (element){
                sortBy = $(element).attr('data-sortfield');
                sortOrder = $(element).attr('data-sortorder');
            }

            if (sortByParam){
                sortBy = sortByParam;
            }

            if (sortOrderParam){
                sortOrder = sortOrderParam;
            }

            var propertyName = '';

            switch (sortBy) {
                case 'name':
                case 'alphabetical':
                    propertyName = 'G';
                    break;
                case 'provider':
                    propertyName = 'V';
                    break;
                case 'category':
                    propertyName = 'C';
                    break;
                case 'betlimit':
                    propertyName = 'Limit';
                    break;
                case 'openinghours':
                    propertyName = 'OpeningHours';
                    break;
                case 'popularity':
                    propertyName = 'P';
                    break;
                default:
                    var newGames = [];

                    for (var i = 0; i < initialJson.length; i++) {
                        for (var j = 0; j < self.VisibleGames.length; j++) {
                            if (initialJson[i].ID == self.VisibleGames[j].ID){
                                newGames.push(self.VisibleGames[j]);
                                break;
                            }
                        }
                    }

                    self.VisibleGames = newGames;
                    break;
            }
                
            var sortOrderCase = { a: -1, b: 1 };

            $('.lv-asc, .lv-desc').removeClass('active');
            $(element).addClass('active');

            if (sortOrder == 'desc'){
                sortOrderCase = { a: 1, b: -1 };
                
                if (element){
                    $(element).attr('data-sortorder', 'asc');
                    $(element).addClass('lv-asc').removeClass('lv-desc');
                }
            }else{
                if (element){
                    $(element).attr('data-sortorder', 'desc');
                    $(element).addClass('lv-desc').removeClass('lv-asc');
                }
            }

            if (propertyName){
                self.VisibleGames.sort(function(a, b){
                    if (a[propertyName] < b[propertyName])
                        return sortOrderCase.a;
                    if (a[propertyName] > b[propertyName])
                        return sortOrderCase.b;
                    return 0;
                });
            }
        };

        self.InitCategories = function(){
            $('ol.GamesCategories a.TabLink').unbind('click');

            $('ol.GamesCategories a.TabLink').click(function (e) {
                e.preventDefault();
                // var _targetTop = jQuery(".TablesContainer").offset().top - 340;
                // jQuery("html,body").animate({scrollTop:_targetTop},1000);

                try{
                    var activeTab = $(this).parent();
                    var classList = $(activeTab).className;
                    var cls = $(activeTab).attr('class').split(' ');
                    for (var i = 0; i < cls.length; i++) { 
                        if (cls[i].indexOf("cat-") > -1) {   
                            cls = cls[i];
                        }
                    }
                    changeBodyClass(cls);

                    $('ol.GamesCategories li.ActiveCat').removeClass('ActiveCat');
                    $(this).parent('li').addClass('ActiveCat');

                    $('.GFilterItem.GFFavoriteTables').removeClass('GFActive');
                    $('#filterFavorites').removeAttr('checked');

                    $('.GFilterItem.GFPopularTables').removeClass('GFActive');
                    $('#filterPopular').removeAttr('checked');

                    if ($(this).attr('data-category') == "popular"){
                        $('.GFilterItem.GFPopularTables').addClass('GFActive');
                        $('#filterPopular').attr('checked', 'checked');
                    }

                    if ($(this).attr('data-category') == "favorites"){
                        $('.GFilterItem.GFFavoriteTables').addClass('GFActive');
                        $('#filterFavorite').attr('checked', 'checked');
                    }
                }catch(err){}

                filterGames();

                if ($('.ShowMoreTablesBox').is('.Hidden')){ 
                    $('.ShowMoreTablesBox').removeClass('Hidden');
                }
                /* 
            $(activeTab).siblings().removeClass('ActiveCat');
            $(activeTab).toggleClass('ActiveCat');
            */
            });
        };

        init();

        function init(){
            $(window).on('load', function(){
                $('li.ClosedTable img.GT').each( function() {
                    grayscaleImage(this);
                });
            });

            $(".GLItem").hide();
            $("body").addClass("Style-Default");

            var popup = $('#livecasino-hall-popups').clone();
            $('#livecasino-hall-popups').remove();
            $('body').append(popup);

            initGamesData();

            self.InitCategories();
            initVipTurkishTables();
            initVendors();
            initPopup();
            initSwitch();
            initShowMoreGames();
            initSearch();
            initDropDowns();
            initSorting();
            initOpenMode();
            initMoreFilters();

            gridViewGamesModel = new GridViewGamesModel();
            listViewGamesModel = new ListViewGamesModel();

            gridViewGamesModel.GameNavWidgetV2 = self;
            listViewGamesModel.GameNavWidgetV2 = self;

            switchGamesView(gamesViewType);

            var gameIdToOpen = $.cookie('loginDialogGameId');

            if (self.IsLoggedIn && gameIdToOpen != null){
                $.cookie("loginDialogGameId", null, { expires: -1 });

                self.OpenGame(gameIdToOpen);
            }
        }

        function initGamesData(){
            var dealerOrigins = [];

            for( var i = 0; i < json.length; i++){
                _game_map[json[i].ID] = json[i];

                if (dealerOrigins.indexOf(json[i].DealerOrigin) < 0){
                    dealerOrigins.push(json[i].DealerOrigin);
                    $('#sltDealerOrigin').append(new Option(json[i].DealerOrigin == 'NotFixed' ? 'All' : json[i].DealerOrigin, json[i].DealerOrigin));
                }
            }

            $(randomLaunchJson).each(function (index, el) {
                if (el.ExcludedFromRandomLaunch == 1)
                    randomLaunchJson.splice(index, 1); 
            });
        }

        function initDropDowns(){
            $('a.GFDLink').click(function () {
                if ($(this).hasClass('GFSLink')) {
                    $('.ActiveDrop').removeClass('ActiveDrop');
                    $('.Popup').hide();
                    $('form.GlobalFilterForm').toggleClass('ActiveSummaryDrop');
                } else {
                    var dropParent = $(this).parents('.GFListWrapper');
                    var closeThis = dropParent.hasClass('ActiveDrop');
                    closeAllPopups();
                    dropParent.toggleClass('ActiveDrop');
                    if (closeThis) dropParent.removeClass('ActiveDrop');
                }

                return false;
            });

            $('.GFListWrapper.GLOpenModePopup .GFLabel').click(function(){
                var container = $('.GFListWrapper.GLOpenModePopup');

                var isActive = container.hasClass('ActiveDrop');

                if (isActive){
                    container.removeClass('ActiveDrop');
                }else{
                    closeAllPopups();
                    container.addClass('ActiveDrop');
                }
            });
        }

        function initVipTurkishTables(){
            $('li.GFVIPTables,li.GFTurkishTables,li.GFUnlimitedSeatsTables,li.GFNewTables, li.GFFavoriteTables, li.GFPopularTables').click(function(e){
                e.preventDefault(); 

                var $checkbox = $(this).find(":checkbox");

                $checkbox.is(':checked') ? $(this).removeClass('GFActive') : $(this).addClass('GFActive');

                var s = !$checkbox.is(':checked');

                $checkbox.attr('checked', s);

                var favChecked = false;
                var popularChecked = false;

                if ($(this).hasClass('GFFavoriteTables')){
                    favChecked = true;
                }

                if ($(this).hasClass('GFPopularTables')){
                    popularChecked = true;
                }

                if (favChecked || popularChecked){
                    $('.GamesCategories.Tabs li.ActiveCat').removeClass('ActiveCat');

                    if ($('#filterPopular').is(':checked') || $('#filterFavorites').is(':checked')){
                        $('.AllTables .GamesCategories').kwicks('select', -1);
                    }else{
                        $('.TabItem.cat-All').addClass('ActiveCat');
                        $('.AllTables .GamesCategories').kwicks('select', $('.GamesCategories li.TabItem').length - 1);
                    }
                }

                filterGames();
            });
        }

        function initVendors(){
            $(':checkbox[name="filterVendors"]').each(function (i, el) {
                var $li = $(el).parents('li');

                if ($(el).is(':checked'))
                    $li.addClass('GFActive');
                else
                    $li.removeClass('GFActive');

                $(el).siblings('span.GFText,span.GFVendorName').click(function (e) {
                    e.preventDefault();

                    var $checkbox = $(this).siblings(':checkbox');
                    var s = !$checkbox.is(':checked');
                        
                    $checkbox.attr('checked', s);
                        
                    var $li = $checkbox.parent().parent();
                        
                    if (s)
                        $li.addClass('GFActive');
                    else
                        $li.removeClass('GFActive');

                    filterGames();

                    $('#gfdVar-contentProviders').text($('.GLVendorFilter li.GFActive').length);
                });
            });
        }

        function initSorting(){
            $(':radio[name="SortType"]').click(function(){
                var $li = $(this).parents('li');

                $('.GLSortSwitcher li.GFilterItem').removeClass('GFActive');

                if ($li.hasClass('GFActive'))
                {
                    return;
                }
                    
                $li.addClass('GFActive');

                $('.GLSortSwitcher .GFilterList .GFDInfo')
                    .removeClass('Default')
                    .removeClass('Popularity')
                    .removeClass('Alphabetical')
                    .addClass($(this).val());

                self.SortGames(this);
                refreshGames(self.VisibleGames);

                closeAllPopups();
            });
        }

        function initOpenMode() {
            $(':radio[name="openType"]').click( function(e){
                var $li = $(this).parents('li');

                $('.GLOpenModeList li.GFilterItem').removeClass('GFActive');
                if ($li.hasClass('GFActive'))
                {
                    return;
                }
                $li.addClass('GFActive');

                closeAllPopups();
                $.cookie('_lcot', $(this).val().toLowerCase(), { expires: 70, path: '/', secure: false });
                $("#gfdVar-opening").text($(".GLOpenModeList .GFilterItem.GFActive .GFText").text());
            });

            //checking setting in cookie and setting default if empty
            var openType = $.cookie('_lcot');
            if( openType != null && openType != '' ) {
                $(':radio[name="openType"]:checked').attr('checked', false);
                var $selected = $(':radio[name="openType"][value="' + openType + '"]');
                $selected.attr('checked', true);
                $selected.click();
            } else {
                $.cookie('_lcot', $(':radio[name="openType"]:checked').val(), { expires: 70, path: '/', secure: false });
            }
        }

        function initPopup(){
            $(document.body).append($('.LiveCasinoTableOverlay'));
        }

        function initSearch(){
            $('#txtTableSearchKeywords').keyup( function(e){
                clearTimeout(_timer);

                _timer = setTimeout(filterGames, 300);
            });
        }

        function initSwitch(){
            $('.GLViewSwitcher .GFilterItem.GFGrid').click(function(){
                if (gamesViewType != self.GamesViewTypes.GridView){
                    $('.GLViewSwitcher li.GFActive').removeClass('GFActive');
                    $(this).addClass('GFActive');

                    switchGamesView(self.GamesViewTypes.GridView);

                    closeAllPopups();
                }
            });

            $('.GLViewSwitcher .GFilterItem.GFList').click(function(){
                if (gamesViewType != self.GamesViewTypes.ListView){
                    $('.GLViewSwitcher li.GFActive').removeClass('GFActive');
                    $(this).addClass('GFActive');

                    switchGamesView(self.GamesViewTypes.ListView);

                    closeAllPopups();
                }
            });
        }

        function initShowMoreGames(){
            $('#show-MoreTables').on('click', function(evt){
                evt.preventDefault();
                console.log('show-MoreTables');
                //show-MoreTables
            });
        }

        function initMoreFilters(){
            $('#cbxHideFullTables').click(function(){
                filterGames();
            });

            $('#cbxHideClosedTables').click(function(){
                filterGames();
            });

            $('#cbxHideRandomTableLunchButton').click(function(){
                if ($(this).is(':checked')){
                    $('#btnRandomTable').hide();
                }else{
                    $('#btnRandomTable').show();
                }
            });

            $('#btnRandomTable').click(function() {
                if (randomLaunchJson.length > 0) {
                    var randomResult = getRandomInt(0, randomLaunchJson.length - 1);
                    var gameId = randomLaunchJson[randomResult].ID;

                    self.OpenGame(gameId);

                    randomLaunchJson.splice(randomResult, 1); // removing already randomly launched table
                    if (randomLaunchJson.length === 0) {
                        randomLaunchJson = self.VisibleGames.slice(); //if all tables was launched reload list

                        $(randomLaunchJson).each(function (index, el) {
                            if (el.ExcludedFromRandomLaunch == 1)
                                randomLaunchJson.splice(index, 1); 
                        });
                    }
                } else {
                    this.disabled = true;
                }
            });

            $('#cbxMaleOnly').click(function(){
                if ($(this).is(':checked')){
                    $('#cbxFemaleOnly').removeAttr('checked');
                }

                filterGames();
            });

            $('#cbxFemaleOnly').click(function(){
                if ($(this).is(':checked')){
                    $('#cbxMaleOnly').removeAttr('checked');
                }

                filterGames();
            });

            $('#sltDealerOrigin').change(function(){
                filterGames();
            });

            $('#txtBetLimitStart').keyup(function(){
                clearTimeout(_timerBetLimitStart);

                var value = $(this).val();
                var newValue = value.replace(',', '');

                if (newValue != value){
                    $(this).val(newValue);
                }

                _timerBetLimitStart = setTimeout(filterGames, 300);
            });

            $('#txtBetLimitEnd').keyup(function(){
                clearTimeout(_timerBetLimitEnd);

                var value = $(this).val();
                var newValue = value.replace(',', '');

                if (newValue != value){
                    $(this).val(newValue);
                }

                _timerBetLimitEnd = setTimeout(filterGames, 300);
            });
        }

        function filterGames(){
            var category = $('ol.GamesCategories .ActiveCat a.TabLink').attr('data-category');
            var name = $('#txtTableSearchKeywords').val();
            var vendors = [];
            var hideFullTables = $('#cbxHideFullTables').is(':checked');
            var hideClosedTables = $('#cbxHideClosedTables').is(':checked');
            var maleOnly = $('#cbxMaleOnly').is(':checked');
            var femaleOnly = $('#cbxFemaleOnly').is(':checked');
            var dealerOrigin = $('#sltDealerOrigin option:selected').val();
            var betLimitStart = $('#txtBetLimitStart').val();
            var betLimitEnd = $('#txtBetLimitEnd').val();
            var showOnlyVipTables = $('#filterVIPTables').is(':checked');
            var showOnlyTurkishTables = $('#filterTurkishTables').is(':checked');
            var showOnlyWithUnlimitedSeats = $('#filterUnlimitedSeats').is(':checked');
            var showOnlyNewTables = $('#filterNew').is(':checked');
            var showOnlyFavorites = $('#filterFavorites').is(':checked');
            var showOnlyPopular = $('#filterPopular').is(':checked');

            var maxNumberToDisplay = null;
            var gamesSorted = false;

            $(':checkbox[name="filterVendors"]:checked').each(function (index, el) {
                vendors.push($(el).val().toUpperCase());
            });

            var searchedGames = [];

            var filterByName = false;
            var filterByCategory = false;
            var filterByVendors = false;
            var filterByStartLimit = false;
            var filterByEndLimit = false;

            var games = json.slice();

            var tableLength = games.length;

            if (name){
                name = name.toUpperCase();

                filterByName = true;
            }

            if (showOnlyPopular){
                category = "POPULAR";
            }

            if (category){
                category = category.toUpperCase();

                if (category == 'FAVORITES'){
                    showOnlyFavorites = true;
                }else if(category == "POPULAR"){
                    self.VisibleGames = games;

                    self.SortGames(null, 'popularity', 'desc');

                    gamesSorted = true;

                    games = self.VisibleGames.slice();
                    
                    maxNumberToDisplay = maxNumberOfPopularGames;

                    if (maxNumberToDisplay <= games.length){
                        tableLength = maxNumberToDisplay;
                    }
                }else{
                    filterByCategory = category != 'ALL';
                }
            }

            if (vendors){
                filterByVendors = true;
            }

            if (betLimitStart){
                betLimitStart = parseFloat(betLimitStart);

                filterByStartLimit = true;
            }

            if (betLimitEnd){
                betLimitEnd = parseFloat(betLimitEnd);

                filterByEndLimit = true;
            }

            for (var i = 0; i < tableLength; i++) {
                if (
                    (!showOnlyFavorites || games[i].Fav == 1) && // Only Favorites
                    (!showOnlyNewTables || games[i].NewTable == 1) && // Only New
                    (!showOnlyWithUnlimitedSeats || games[i].SeatsUnlimited == 1) && // Only Unlimited Seats
                    (!showOnlyTurkishTables || games[i].TurkishTable == 1) && // Only Turkish
                    (!showOnlyVipTables || games[i].VIP == 1) && // Only VIP
                    (!filterByName || games[i].G.toUpperCase().indexOf(name) >= 0) && // Name
                    (!filterByCategory || games[i].C.toUpperCase() == category) &&    // Category
                    (!filterByVendors || vendors.indexOf(games[i].V.toUpperCase()) >= 0) && // Vendors
                    (!hideFullTables || (games[i].SeatsUnlimited == 1 || games[i].SeatsAvailable > 0 || games[i].SeatsMax == 0)) && // Hide Full
                    (!hideClosedTables || games[i].Opened) &&                                            // Hide Closed
                    (!maleOnly || games[i].DealerGender.toUpperCase() == 'MALE') &&                      // Only Male
                    (!femaleOnly || games[i].DealerGender.toUpperCase() == 'FEMALE') &&                  // Only Female
                    (dealerOrigin == 'NotFixed' || games[i].DealerOrigin == dealerOrigin) &&             // Origin
                    (!filterByStartLimit || !games[i].Limit || (games[i].StartLimit <= betLimitStart && (!filterByEndLimit || games[i].EndLimit >= betLimitStart))) && // Start Limit
                    (!filterByEndLimit || !games[i].Limit || (games[i].EndLimit >= betLimitEnd && (!filterByStartLimit || games[i].StartLimit <= betLimitEnd)))        // End Limit
                ){
                    searchedGames.push(games[i]);
                }
            }
            
            if (!gamesSorted){
                var selectedSortItem = $('.GLSortSwitcher li.GFActive input[type="radio"]');

                self.SortGames(null, selectedSortItem.attr('data-sortfield'), selectedSortItem.attr('data-sortorder') == 'desc' ? 'asc' : 'desc');
            }

            refreshGames(searchedGames);

            $(".BannerGLItem").show();
            $('#livecasino-game-popup').hide();
        }

        function refreshGames(games){
            self.VisibleGames = games;
            randomLaunchJson = games.slice();

            switch (gamesViewType) {
                case self.GamesViewTypes.ListView:
                    listViewGamesModel.RefreshGames(games);
                    break;
                case self.GamesViewTypes.GridView:
                    gridViewGamesModel.RefreshGames(games);
                    break;
            }
        }

        function switchGamesView(viewType){
            switch (viewType) {
                case self.GamesViewTypes.ListView:
                    gridViewGamesModel.Disable();
                    listViewGamesModel.Enable(self.VisibleGames);
                    gamesViewType = self.GamesViewTypes.ListView;
                    break;
                case self.GamesViewTypes.GridView:
                    listViewGamesModel.Disable();
                    gridViewGamesModel.Enable(self.VisibleGames);
                    gamesViewType = self.GamesViewTypes.GridView;
                    break;
            }
        }

        function changeBodyClass(cls){
            var bodyclass = $('body').attr('class').split(' ');
            for (var i = 0; i < bodyclass.length; i++) {
                // Iterate over the class and log it if it matches
                if (bodyclass[i].indexOf("Style-") > -1) {
                    bodyclass = bodyclass[i];
                }
            }
            cls = cls.replace('cat-',''); 
            $('body').removeClass(bodyclass);
            bodyclass = 'Style-'+cls; 
            $('body').addClass(bodyclass);
            changeLiveCasinoSlide(cls);
        }

        function changeLiveCasinoSlide(cls) {
            var pre = "LCSlide-";
            $('.LiveCasinoSlide').removeClass('Active');
            var currentSlide = '#'+ pre + cls; 
            $(currentSlide).addClass('Active');
        }

        function closeAllPopups() {
            $('.ActiveDrop').removeClass('ActiveDrop');
            $('.ActiveSummaryDrop').removeClass('ActiveSummaryDrop');
            $('.Popup').hide();
        }
    }

    function ListViewGamesModel(){
        var self = this;

        var initialized = false;
        var gamesTableSelector = '.live-casino.list-view-table';
        var gamesTemplate = $('#livecasino-list-view-games-template');

        self.GameNavWidgetV2 = null;

        self.Enable = function(games){
            $('.Box.AllTables').addClass(self.GameNavWidgetV2.GamesViewTypes.ListView);
            $('.TablesList.ListViewContainer').show();
            $('.GLViewSwitcher .GFilterList .GFDInfo').addClass('List');

            $('li.TabItem.cat-favorites').show();
            $('li.TabItem.cat-popular').show();

            if (games){
                self.RefreshGames(games);
            }
        };

        self.Disable = function(){
            $('.Box.AllTables').removeClass(self.GameNavWidgetV2.GamesViewTypes.ListView);
            $('.TablesList.ListViewContainer').hide();
            $('.GLViewSwitcher .GFilterList .GFDInfo').removeClass('List');
        };

        self.RefreshGames = function(games){
            if (!gamesTemplate){
                return;
            }

            var html = gamesTemplate.parseTemplate({
                Games: games,
                TableExists: initialized
            });

            if (!initialized){
                $('.TablesList.ListViewContainer').html(html);

                init();
            }else{
                $(gamesTableSelector + ' tbody').empty().html(html);
            }

            bindListViewRowEvents();
        };

        init();

        function init(){
            var exists = $(gamesTableSelector).length > 0;

            if (exists){
                bindListViewEvents();

                initialized = true;
            }
        }

        function bindListViewEvents(){
            $('.list-view-table thead th').click(function(){
                self.GameNavWidgetV2.SortGames(this);

                self.RefreshGames(self.GameNavWidgetV2.VisibleGames);
            });
        }

        function bindListViewRowEvents(){
            $(gamesTableSelector + ' tbody .btn-play').click(function(){
                var gameId = $(this).data('gameid');

                self.GameNavWidgetV2.OpenGame(gameId);
            });
        }
    }

    function GridViewGamesModel(){
        var self = this;

        var container = $('.AllTables .GamesCategories');
        var tabs = $('.AllTables .TabItem');
        var gamesCategories = $('.GamesCategories');

        var gamesTableSelector = '.TablesList.Container';
        var gamesTemplate = $('#livecasino-grid-view-games-template');

        var categoryFavorites =  null;
        var categoryPopular =  null;

        var showPopupTimeout = null;

        var showGamePopupOnMouseOver = <%= (this.GetMetadata(".ShowGamePopupOnMouseOver").ToLowerInvariant() == "yes").ToString().ToLower() %>;

        self.GameNavWidgetV2 = null;

        self.Enable = function(games){
            $('.Box.AllTables').addClass(self.GameNavWidgetV2.GamesViewTypes.GridView);
            $('.TablesList.Container').show();
            $('.GFListWrapper.GLFavoritesFilter').show();
            $('.GFListWrapper.GLPopularFilter').show();

            //categoryFavorites =  $('.TabItem.cat-favorites').removeClass('ActiveCat').clone();
            //$('.TabItem.cat-favorites').remove();

            //categoryPopular =  $('.TabItem.cat-popular').removeClass('ActiveCat').clone();
            //$('.TabItem.cat-popular').remove();

            //$('li.TabItem.cat-favorites').hide();
            //$('li.TabItem.cat-popular').hide();

            container.kwicks({
                maxSize: 610,
                spacing: 0,
                duration: 300,
                behavior: 'menu'
            });

            var selectedCategoryIndex = -1;
                
            $('ol.GamesCategories .TabItem:visible').each(function(index, item){
                if ($(item).hasClass('ActiveCat')) {
                    selectedCategoryIndex = index;
                    return;
                }
            });

            container.kwicks('select', selectedCategoryIndex);

            tabs.on('hover', tabsHover);

            gamesCategories.on('mouseleave', gamesCategoriesMouseleave);

            $('.GLViewSwitcher .GFilterList .GFDInfo').addClass('Grid');

            if (games){
                self.RefreshGames(games);
            }
        };

        self.Disable = function(){
            $('.Box.AllTables').removeClass(self.GameNavWidgetV2.GamesViewTypes.GridView);
            $('.TablesList.Container').hide();
            //$('.GFListWrapper.GLFavoritesFilter').hide();
            //$('.GFListWrapper.GLPopularFilter').hide();

            $('li.TabItem.cat-favorites').show();
            $('li.TabItem.cat-popular').show();

            $('.GLViewSwitcher .GFilterList .GFDInfo').removeClass('Grid');

            $(container).kwicks('destroy');

            if (categoryPopular){
                if (!$('.GFilterItem.GFFavoriteTables').hasClass('GFActive') && $('.GFilterItem.GFPopularTables').hasClass('GFActive')){
                    categoryPopular.addClass('ActiveCat');
                }

                $('.GamesCategories.Tabs').prepend(categoryPopular);
            }

            if (categoryFavorites){
                if ($('.GFilterItem.GFFavoriteTables').hasClass('GFActive')){
                    categoryFavorites.addClass('ActiveCat');
                }

                $('.GamesCategories.Tabs').prepend(categoryFavorites);
            }

            self.GameNavWidgetV2.InitCategories();

            tabs.unbind('hover', tabsHover);
            gamesCategories.unbind('hover', gamesCategoriesMouseleave);
        };

        self.RefreshGames = function(games){
            if (!gamesTemplate){
                return;
            }

            var html = gamesTemplate.parseTemplate(games);

            $(gamesTableSelector + ' li:not(:first-child)').remove();
            $(gamesTableSelector).append(html);
                
            $('.GLItem').show();

            $('a.GameThumb, a.Game', $('div.TablesList li.GLItem')).click(function (e) {
                e.preventDefault();

                var $anchor = $(this).parents('.GLItem');
                var game = self.GameNavWidgetV2.GetGame($anchor.data('tableid'));
                var $popup = $('#livecasino-game-popup');
                var html = $('#livecasino-game-popup-template').parseTemplate(game);

                $popup.empty().html(html);
                $popup.show();

                var $images = $('div.ClosedTable img.GT', $popup);

                if( $images.length > 0 ){
                    $images.attr('src', $('img.GT', $anchor).attr('src'));
                    grayscaleImage( $images[0] );
                }
            
                positionPopup($popup, $anchor);

                $('#livecasino-game-popup a.Close').click(function (e) {
                    e.preventDefault();
                    $popup.hide();
                });

                $('a.PlayNowButton', $popup).click( function(e){
                    e.preventDefault();
                    self.GameNavWidgetV2.OpenGame(game.ID);
                });

                initAddToFav(game);
            });

            if (showGamePopupOnMouseOver){
                $('a.GameThumb').mouseenter(function () {
                    clearTimeout(showPopupTimeout);
                    $(this).click();
                });

                $('#livecasino-game-popup').mouseenter(function () {
                    clearTimeout(showPopupTimeout);
                });

                $('#livecasino-game-popup').mouseleave(function () {
                    clearTimeout(showPopupTimeout);
                    showPopupTimeout = setTimeout(function(){
                        $('#livecasino-game-popup').hide();
                    }, 300);
                });
            }
        };

        init();

        function init(){

        }

        function tabsHover(evt){
            var el = $(this);
            $('.AllTables .TabItem').removeClass('ActiveCat');
            el.addClass('ActiveCat');
        }

        function gamesCategoriesMouseleave(evt){
            tabs.removeClass('ActiveCat');

            var classNames = $.grep($('body').attr('class').split(" "), 
                function (v, i) { 
                    return v.indexOf('Style') === 0; 
                }).join();

            classNames = classNames.replace('Style-', '');

            var cat = 'cat-' + classNames;

            $("li." + cat).addClass('ActiveCat');
        }

        function positionPopup($popup, $anchor) {
            // debugger;
            var pos = $anchor.find('.GameThumb').offset();
            var left = Math.floor(pos.left);

            if (left + $popup.width() > $(document.body).width()) {
                var dx = ($popup.width() + left) - $(document.body).width();
                left = left - dx;
            }

            var top = Math.floor(pos.top);

            $popup.css({ 'left': left + 'px', 'top': top + 'px' });

            pos = $popup.offset();
            pos.right = pos.left + $popup.width();
            pos.maxRight = $(window).scrollLeft() + $(window).width();
            pos.bottom = pos.top + $popup.height();
            pos.maxBottom = $(window).scrollTop() + $(window).height();

            if (pos.maxRight < pos.right) {
                $(window).scrollLeft(pos.right - $(window).width());
            }

            if (pos.maxBottom < pos.bottom) {
                $(window).scrollTop(pos.bottom - $(window).height());
            }
        }

        function grayscaleImage(img){
            var url = img.src;
            if( url.indexOf('data:image') == 0 )
                return;
            $.getImageData({
                url: url,
                success: function(image){
                    var src = $(image).attr('src');
                    if( src != $(img).attr('src') ) {
                        $(img).attr( 'src', src ); 
                        grayscale(img);
                    }  
                },
                error: function(xhr, text_status){
                }
            });
        }

        function initAddToFav(table){
            $('.GameOptions .AddFav a').click( function(e){
                e.preventDefault();
                var url = '/LiveCasino/Home/AddToFavorites/';

                $.getJSON( url, { tableID : table.ID }, function(data){
                    if (data.success){
                        $('.GameOptions .AddFav').addClass('Hidden');
                        $('.GameOptions .RemoveFav').removeClass('Hidden');
                        $('.GLItem[data\-tableid="' + table.ID + '"] span.GTfav').removeClass('Hidden');
                        $('.PopupContent span.GTfav').removeClass('Hidden');

                        var categoryNumberElement = $('.CatTabLink[data\-category="favorites"] span.CatNumber');
                        var count = parseInt(categoryNumberElement.text());

                        categoryNumberElement.text(count + 1);

                        table.Fav = 1;
                    }
                });
            });

            $('.GameOptions .RemoveFav a').click( function(e){
                e.preventDefault();
                var url = '/LiveCasino/Home/RemoveFromFavorites/';
                $.getJSON( url, { tableID : table.ID }, function(data){
                    if (data.success){
                        $('.GameOptions .AddFav').removeClass('Hidden');
                        $('.GameOptions .RemoveFav').addClass('Hidden');
                        $('.GLItem[data\-tableid="' + table.ID + '"] span.GTfav').addClass('Hidden');
                        $('.PopupContent span.GTfav').addClass('Hidden');
                        var categoryNumberElement = $('.CatTabLink[data\-category="favorites"] span.CatNumber');
                        var count = parseInt(categoryNumberElement.text());

                        categoryNumberElement.text(count - 1);

                        table.Fav = 0;
                    }
                });
            });
        }
    }

    function getRandomInt(min, max) {
        return Math.floor(Math.random() * (max - min + 1) + min);
    }

    var gameNavWidgetV2 = null;

    $(function () {
        gameNavWidgetV2 = new GameNavWidgetV2();
    });


    // /livecasino/Hall/GetSeatsData?isProd=True
    function checkSeatStatus(){
        try{
            var url = '/livecasino/Hall/GetSeatsData';
            jQuery.getJSON( url, function(json){ 
                if (json.success) {
                    var seats =  json.data ;
                    for(var item in seats){
                        var $item =   $(".GLItem[data-tableid='"+ item + "']");  
                        if(seats[item].totalSeats > 0 ){
                            _game_map[item].SeatsMax = seats[item].totalSeats;
                            _game_map[item].SeatsTaken = seats[item].takenSeats; 
                            $item.find(".SeatInfos").removeClass("Hidden");
                            $item.find(".TakenSeats").html(seats[item].takenSeats);
                            $item.find(".TotalSeats").html(seats[item].totalSeats);
                            $item.find(".SeatsAvailable").html( seats[item].totalSeats - seats[item].takenSeats);
                        }   else{
                            $item.find(".SeatInfos").removeClass("Hidden").addClass("Hidden");
                        }
                    }
                    setTimeout(function(){
                        checkSeatStatus();
                    },20000);
                }
            });
        }catch(err){
            console.log(err);
        }
    }
    checkSeatStatus();

</script>
</ui:MinifiedJavascriptControl>
