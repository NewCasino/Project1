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
    private int InitalLoadGameCount
    {
        get
        {
            int initalLoadGameCount = 0;
            try
            {
                initalLoadGameCount = (int)this.ViewData["InitalLoadGameCount"];
            }
            catch
            {
                initalLoadGameCount = 20;
            }
            return initalLoadGameCount;
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
                maxNumOfNewGames = 40;
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
                maxNumOfPopularGames = 40;
            }
            return maxNumOfPopularGames;
        }
    }

    private int InitialRows
    {
        get
        {
            int initialRows = 0;
            try
            {
                initialRows = (int)this.ViewData["InitialRows"];
            }
            catch
            {
                initialRows = 4;
            }
            return initialRows;
        }
    }

    private int IncreasedRows
    {
        get
        {
            int increasedRows = 0;
            try
            {
                increasedRows = (int)this.ViewData["IncreasedRows"];
            }
            catch
            {
                increasedRows = 8;
            }
            return increasedRows;
        }
    }


    private int InitialSliderCategoryCount
    {
        get
        {
            int initialSliderCategoryCount = 0;
            try
            {
                initialSliderCategoryCount = (int)this.ViewData["InitialSliderCategoryCount"];
            }
            catch
            {
                initialSliderCategoryCount = 3;
            }
            return initialSliderCategoryCount;
        }
    }

    private int InitialListCategoryCount
    {
        get
        {
            int initialListCategoryCount = 0;
            try
            {
                initialListCategoryCount = (int)this.ViewData["InitialListCategoryCount"];
            }
            catch
            {
                initialListCategoryCount = 1;
            }
            return initialListCategoryCount;
        }
    }

    private string DefaultCategory
    {
        get
        {
            return (this.ViewData["DefaultCategory"] as string) ?? "popular";
        }
    }
    #endregion

    private string ID { get; set; }

    private string JsonUrl
    {
        get
        {
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

    private bool IsEmailVerified()
    {
        bool isEmailVerified = false;
        if (Profile.IsAuthenticated)
        {
            isEmailVerified = Profile.IsEmailVerified;
            if (!Profile.IsEmailVerified)
            {
                CM.db.Accessor.UserAccessor ua = CM.db.Accessor.UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                CM.db.cmUser user = ua.GetByID(Profile.UserID);
                if (user.IsEmailVerified)
                {
                    isEmailVerified = true;
                    Profile.IsEmailVerified = true;
                }
            }
        }

        return isEmailVerified;
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

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));

        string currentCategory = this.ViewData["CurrentCategory"] as string;
        if (string.IsNullOrEmpty(currentCategory))
        {
            HttpCookie cookie = Request.Cookies["_ccc"];
            if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                currentCategory = cookie.Value;
            else
                currentCategory = this.DefaultCategory;
        }

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
            int count = 0;
            List<GameCategory> categories = GameMgr.GetCategories();
            foreach (GameCategory category in categories)
            {
                if (category.Games.Count == 0)
                    continue;

                json.AppendFormat(CultureInfo.InvariantCulture, "{{ID:'{0}',Name:'{1}'}},"
                    , category.FriendlyID.SafeJavascriptStringEncode()
                    , category.Name.SafeJavascriptStringEncode()
                    );

                if (category.FriendlyID == currentCategory)
                    JsonData = GameMgr.GetCategoryJson(category, InitalLoadGameCount);

                string cssClasses = string.Format(CultureInfo.InvariantCulture, "{0} Cat-{1}"
                    , (category.FriendlyID == currentCategory) ? "ActiveCat" : string.Empty
                    , category.FriendlyID
                    );

                count += category.Games.Count;
                html.AppendFormat(CultureInfo.InvariantCulture, CATEGORY_FORMAT
                    , category.FriendlyID.SafeHtmlEncode()
                    , this.GetMetadataEx(".Category_Title", category.Name.ToLowerInvariant()).SafeHtmlEncode()
                    , this.GetMetadataEx(".Category_Superscript", category.Games.Count)
                    , category.Name.SafeHtmlEncode()
                    , cssClasses.SafeHtmlEncode()
                    );
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("]");
            this.CategoryJson = json.ToString();
            this.TotalGameCount = count;

            // popular games
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
        }

        this.CategoryHtml = html.ToString();

        Func<VendorInfo, bool> isAvailableVendor = (VendorInfo vendor) =>
        {
            if (GlobalConstant.AllLiveCasinoVendors.Except(GlobalConstant.AllUniversalVendors).Contains(vendor.VendorID))
                return false;

            if (Profile.IsAuthenticated && vendor.RestrictedTerritories.Exists(c => c == Profile.UserCountryID))
                return false;

            if (Profile.IpCountryID > 0 && vendor.RestrictedTerritories.Exists(c => c == Profile.IpCountryID))
                return false;

            return true;
        };

        VendorInfo[] vendors = CasinoEngineClient.GetVendors().Where(v => isAvailableVendor(v)).ToArray();

        VendorDic = vendors.ToDictionary(v => ((int)v.VendorID).ToString(), v => v.VendorID.ToString());

        html.Clear();

        html.AppendFormat(@"<div class=""GLVendorFilter GFListWrapper GFL{0} "">
<ul class=""GFilterList {4} Container"" id=""gfl-colors"">
    <li class=""GFilterItem GFilterDropdown"">
        <a class=""GFDLink"" href=""#"" title=""{1}"">
            <span class=""GFDText""><span class=""Hidden"">{3}</span><span class=""ActionSymbol"">&#9660;</span></span>
            <span class=""GFDInfo""><span class=""GFDVar"" id=""gfdVar-vendors"">{0}</span><span class=""GFDDelimiter"">/</span><span class=""GFDTotel"">{0}</span><span class=""GFDIText""> {2}</span></span>
        </a>
    </li>"
            , vendors.Length
            , this.GetMetadata(".ViewSwitcher_Title").SafeHtmlEncode()
            , this.GetMetadata(".ViewSwitcher_Selected").SafeHtmlEncode()
            , this.GetMetadata(".Filters_See_All").SafeHtmlEncode()
            , (vendors.Length >= 6) ? "GFMultipleItems" : string.Empty
            );

        for (int i = 0; i < vendors.Length; i++)
        {
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

        html.Append("</ul></div>");
        this.VendorFilterHtml = html.ToString();
    }
</script>

<div class="Box AllGames" id="gameMultiOpenerNavWidget<%= ID %>">
<div class="GamesPrelude">
    <div class="GamesHeader Container">
        <h2 class="BoxTitle GamesTitle">
            <strong class="TitleText"><%= this.GetMetadataEx(".Title_Games", this.TotalGameCount).HtmlEncodeSpecialCharactors() %></strong>
        </h2>
        <div class="GameFilters">
            <%----------------------------
                    Search Filter
            ----------------------------%>
            <form class="FilterForm SearchFilterForm" id="gameSearch<%= ID %>" action="#" onsubmit="return false">
                <fieldset>
                    <label class="hidden" for="txtGameSearchKeywords<%= ID %>"><%= this.GetMetadata(".GameName_Insert").SafeHtmlEncode() %></label>
                    <input class="FilterInput SearchInput" type="search" id="txtGameSearchKeywords<%= ID %>" name="txtGameSearchKeywords" accesskey="g" maxlength="50" value="" placeholder="<%= this.GetMetadata(".GameName_PlaceHolder").SafeHtmlEncode() %>" />
                    <button type="submit" class="Button SearchButton" name="gameSearchSubmit" id="btnSearchGame<%= ID %>">
                        <span class="ButtonText"><%= this.GetMetadata(".Search").SafeHtmlEncode() %></span>
                    </button>
                </fieldset>
            </form>
            <form class="FilterForm GlobalFilterForm" id="gameFilter<%= ID %>" action="#" onsubmit="return false">
                <fieldset>
                    <div class="GlobalFilterSummary">
                        <a class="GFDLink GFSLink" id="gfl-summary<%= ID %>" href="#" title="<%= this.GetMetadata(".Filters_Title").SafeHtmlEncode() %>">
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
                                <li class="GFilterItem GFInline">
                                    <label for="gfInline" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Inline_Title").SafeHtmlEncode()%>">
                                        <input type="radio" id="gfInline" name="openType" value="inline" class="hidden" />
                                        <span class="GFText"><%= this.GetMetadata(".OpenMode_Inline").SafeHtmlEncode()%></span>
                                    </label>
                                </li>
                                <li class="GFilterItem GFPopup GFActive">
                                    <label for="gfPopup" class="GFLabel" title="<%= this.GetMetadata(".OpenMode_Popup_Title").SafeHtmlEncode()%>">
                                        <input type="radio" checked="checked" id="gfPopup" name="openType" value="popup" class="hidden" />
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
            <%= CategoryHtml %>
        </ol>
    </nav>
</div>
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

<%------------------------
    this is the container for all the popups in the page. they will need to be positioned with JavaScript
------------------------%>
<div class="PopupsContainer" id="casino-hall-popups<%= ID %>">
    <div class="Popup GamePopup" id="casino-game-popup<%= ID %>"></div>
    <div class="Popup TooltipPopup" id="tooltipPopup<%= ID %>">
        <div class="PopupIcon">Info about this item:</div>
        <span class="PopupText">This is some info about this item</span>
    </div>
</div>

<%= this.ClientTemplate("GameListItem", "casino-game-item" + ID, new { vendors = this.VendorDic, isLoggedIn = Profile.IsAuthenticated })%>

<%= this.ClientTemplate("CategorySlider", "casino-category-slider" + ID) %>

<%= this.ClientTemplate("CategoryList", "casino-category-list" + ID) %>

<%= this.ClientTemplate("GamePopup", "casino-game-popup-template" + ID)%>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="false" Enabled="false">
    <script type="text/javascript">
        var GameDataManager=(function(){
            var _LogFlag='<%=Profile.IsAuthenticated?"1":"0" %>',
                JsonUrl = '<%= JsonUrl.SafeJavascriptStringEncode() %>',
            _IsLargeData = false,_DataSource = null;
        
            function updateLocalStorge(data){                 
                if(data !=null){
                    _IsLargeData = false;
                    _DataSource = {source:data,flag:_LogFlag};
                    try{
                        localStorage.setItem("__allGameList",JSON.stringify(_DataSource));
                    }catch(e){
                        _IsLargeData = true;
                    }
                }
            }
            function getDataFromLocalStorge(){
                var cacheData=null;
                if(_IsLargeData)
                    cacheData = _DataSource;
                else
                    cacheData = JSON.parse(localStorage.getItem("__allGameList"));
                if( cacheData != null && cacheData != 'null' && cacheData.length != 0){
                    if(cacheData.flag==_LogFlag){
                        return cacheData.source;
                    }
                }
                return null;
            }
            function onGameLoadByJson(callback){
                if(_DataSource && _DataSource.flag==_LogFlag){
                    callback(_DataSource.source);
                    return;
                }
                $.getJSON(JsonUrl, function(data){
                    callback(data);
                    _DataSource = {source:data,flag:_LogFlag};
                });
            }
            function onGameLoadByLocalStorage(callback){
                if($(".localstorage").length>0 && $(".ie7").length == 0 &&  $(".ie8").length == 0 )   {
                    try{
                        var lsData = getDataFromLocalStorge();
                        if( lsData != null && lsData != 'null' && lsData.length != 0 ){ 
                            callback(lsData);
                        }else{                        
                            $.getJSON(JsonUrl,function(data){ 
                                updateLocalStorge(data);
                                callback(data); 
                            } ); 
                        } 
                    }catch(err){
                        onGameLoadByJson(callback); 
                    }
                }else{
                    onGameLoadByJson(callback);
                }  
            }
            function setFlagStatus(status){
                _LogFlag = status;
            }
            function getDataSource(){
                return _DataSource;
            }
        
            return{
                GameLoadByLocalStorage:onGameLoadByLocalStorage,
                SetFlag:setFlagStatus,
                GetDataSource:getDataSource
            }
        })();
        function GameNavWidgetMulti(){
            var self = this;
            var gameSelectedCallbacks = [];

            self.Container = $('#gameMultiOpenerNavWidget<%= ID %>');

            self.GameSelected = function(game){
                for (var i = 0; i < gameSelectedCallbacks.length; i++) {
                    gameSelectedCallbacks[i](game);
                }
            };

            self.SubscribeGameSelected = function(callback){
                gameSelectedCallbacks.push(callback);
            };
            
            self.UnSubscribeGameSelected = function(callback){
                var index = gameSelectedCallbacks.indexOf(callback);

                gameSelectedCallbacks.splice(index, 1)
            };
        }

        var gameNavWidgetMulti = null;

        $(function () {
            gameNavWidgetMulti = new GameNavWidgetMulti();

            var isAvailableLogin = <%= (Profile.IsAuthenticated && Profile.IsEmailVerified).ToString().ToLowerInvariant() %>;
            // <%-- casino game list virtual threads --%>
            CGL_Threads<%= ID %> = {
                _threads : [],
                _filterAndSortGames: function (games, keywords, callback) {
                    var vendors = {};
                    var $checked = $(':checkbox[name="filterVendors"]:checked', gameNavWidgetMulti.Container);
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
                
                var sortType = $(':radio[name="sortType"]:checked', gameNavWidgetMulti.Container).val();
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
                var th = Concurrent.Thread.create(CGL_Threads<%= ID %>._filterAndSortGames, games, keywords, callback);
                CGL_Threads<%= ID %>._threads.push(th);
            },
            killThreads: function(){
                while(CGL_Threads<%= ID %>._threads.length > 0 ){
                    try{
                        CGL_Threads<%= ID %>._threads[0].kill(0);
                    }
                    catch(e) {}
                    CGL_Threads<%= ID %>._threads.splice(0, 1);
                }
            }
        }; // <%-- virtual threads end --%>

        
            var _view = null; // <%-- Current Casino Game List instance --%>
            var _game_map = {}; // <%-- All games --%>
            var _data = null;

            function closeAllPopups() {
                $('.ActiveDrop', gameNavWidgetMulti.Container).removeClass('ActiveDrop');
                $('.ActiveSummaryDrop', gameNavWidgetMulti.Container).removeClass('ActiveSummaryDrop');
                $('.Popup', gameNavWidgetMulti.Container).hide();
            }
            $(document).bind('GAME_TO_BE_OPENED_Multi', closeAllPopups);

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

        
            $(document.body).append($('#casino-hall-popups<%= ID %>'));

        $('ol.GamesCategories a.TabLink', gameNavWidgetMulti.Container).click(function (e) {
            e.preventDefault();
            $('ol.GamesCategories li.ActiveCat', gameNavWidgetMulti.Container).removeClass('ActiveCat');
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

            $(document).on('GAME_ADDED_TO_FAV', function(e, gid){
                var game = _game_map[gid];
                $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav', gameNavWidgetMulti.Container).removeClass('Hidden');
                game.Fav = 1;
                removeFavGame(game);
                _data['favorites'].push(game);
            });

            $(document).on('GAME_REMOVE_FROM_FAV', function(e, gid){ 
                var game = _game_map[gid];
                $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav', gameNavWidgetMulti.Container).addClass('Hidden'); 
                removeFavGame(game); 
            });
        
            // <%-- the game info popup --%>
            function bindPopupEvent($containers){
                $('a.GameThumb, a.Game', $containers).click( function(e){
                    e.preventDefault();

                    var $anchor = $(this).parents('.GLItem');
                    var game = _game_map[$anchor.data('gameid')];
                    //for game which have sub games
                    if(game.C!=null && game.C.length>0){
                        var $popup = $('#casino-game-popup<%= ID %>').empty().html($('#casino-game-popup-template<%= ID %>').parseTemplate(game)).css("z-index",999999).show();
                        positionPopup( $popup, $anchor);
                        var $extra = $('#casino-game-popup<%= ID %> .PopupAdditional').show();

                        $('#casino-game-popup<%= ID %> a.Close').click( function(e){
                            e.preventDefault();
                            $('#casino-game-popup<%= ID %>').hide();
                        });
                        $('ol.GameVariants a.GVLink', $extra).off( 'click' );
                        $('ol.GameVariants a.GVLink', $extra).on( 'click', function(e){
                            e.preventDefault();
                            gameNavWidgetMulti.GameSelected(game.C[$(this).data("gindex")]);
                            $('#casino-game-popup<%= ID %> .Close').trigger("click");
                        });
                    }else{
                        $('#casino-game-popup<%= ID %> .Close').trigger("click");
                        gameNavWidgetMulti.GameSelected(game);
                    }
                    return;
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

                    CGL_Threads<%= ID %>.filterAndSortGames(this._orginalGames, '', callback);
            };

            this.populateViewCompleted = function (result) {
                this._filteredGames = result;

                this._container.html( $('#casino-game-item<%= ID %>').parseTemplate( this._filteredGames ) );
                
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

                    CGL_Threads<%= ID %>.filterAndSortGames(this._orginalGames, '', callback);
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
                var $item = $( $('#casino-game-item<%= ID %>').parseTemplate( [ g ] ) );
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
                this._categories = <%= this.CategoryJson %>;
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
                    $('#lnkLoadAllCategories<%= ID %>').removeClass('Hidden').off('click').on('click', function(e){
                        e.preventDefault();
                        $(invisibleControls).each( function( i, control){
                            control.show();
                        });
                        $(this).addClass('Hidden');
                    });
                }
                else {
                    $('#lnkLoadAllCategories<%= ID %>').addClass('Hidden');
                }
            };

            this.populateView = function(){
                CGL_Threads<%= ID %>.killThreads();
                if( this.isSliderView() ){
                    
                    $('div.AllGamesTextList', gameNavWidgetMulti.Container).empty().hide();
                    $('div.AllGamesList', gameNavWidgetMulti.Container).show();
                    if($('div.AllGamesList > div.CatSlider', gameNavWidgetMulti.Container).length == 0 ){
                        var html = $('#casino-category-slider<%= ID %>').parseTemplate(this._categories);
                        $('div.AllGamesList', gameNavWidgetMulti.Container).html(html);
                        this._controls = [];
                    }

                    if( this._controls.length == 0 ){
                        var controls = [];
                        $('div.AllGamesList div.Slider', gameNavWidgetMulti.Container).each( function( i, el){
                            var cid = $(el).data('categoryid');
                            controls.push( new GameSlider(el, allData[cid]) );
                        });
                        this._controls = controls;
                        this.initLoadAllButton(this._controls, <%= InitialSliderCategoryCount %>);
                    }
                    for( var i = 0; i < this._controls.length; i++){
                        this._controls[i].populateView();
                    }
                } 
                else {
                    $('div.AllGamesList', gameNavWidgetMulti.Container).empty().hide();
                    $('div.AllGamesTextList', gameNavWidgetMulti.Container).show();

                    if( $('div.AllGamesTextList > div.CatSlider', gameNavWidgetMulti.Container).length == 0 ) {
                        var html = $('#casino-category-list<%= ID %>').parseTemplate(this._categories);
                        $('div.AllGamesTextList', gameNavWidgetMulti.Container).html(html);
                        this._controls = [];
                    }
                    
                    if( this._controls.length == 0 ){
                        var controls = [];
                        $('div.AllGamesTextList ol.GamesList', gameNavWidgetMulti.Container).each( function( i, el){
                            var cid = $(el).data('categoryid');
                            controls.push( new GameTextList(el, allData[cid]) );
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

                CGL_Threads<%= ID %>.killThreads();
                CGL_Threads<%= ID %>.filterAndSortGames(this._orginalGames, this._keywords, callback);

                var handler = (function (o) {
                    return function () {
                        o.loadMoreGames(arguments[0]);
                    };
                })(this);

                var $lnk = $('#lnkLoadMoreGames<%= ID %>').off('click').on('click', handler);
            };

            this.populateViewCompleted = function (result) {
                this._filteredGames = result;
                this.updateView(true);
            };

            this.updateView = function (reload) {
                var $container = $('ol.GamesList', gameNavWidgetMulti.Container);
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
                        var html = $('#casino-game-item<%= ID %>').parseTemplate([this._filteredGames[i]]);
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
                        var html = $('#casino-game-item<%= ID %>').parseTemplate([this._filteredGames[i]]);
                        var $li = $(html).appendTo($container).data('game', this._filteredGames[i]);
                        bindPopupEvent($li);
                    }
                } 
                else if( diff > 0 ){ // <%-- Too Many --%>
                    $existing.slice(-1 * diff).remove();
                }

                if (num < this._filteredGames.length)
                    $('#lnkLoadMoreGames<%= ID %>').removeClass('Hidden');
                else
                    $('#lnkLoadMoreGames<%= ID %>').addClass('Hidden');
            }

            this.loadMoreGames = function (evt) {
                evt.preventDefault();
                this._currentRows += this._increasedRows;
                this.updateView(false);
            };
        }
        

            // <%-- IncentiveMessage --%>
            $(document).bind('CATEGORY_CHANGED_Multi', function(e, category){
                $('#divIncentiveMessage<%= ID %>').empty().addClass('Hidden');
            if( category == 'favorites' ){
                $('#divIncentiveMessage<%= ID %>').removeClass('Hidden').load('/Casino/Hall/IncentiveMessage/', function(){
                    $('#divIncentiveMessage<%= ID %> > *').fadeIn();
                });
            }
        });
        
            function onGameLoad(data) {
                _data = data;

                function initializeView(games, keywords) {
                    closeAllPopups();
                    $('div.AllGamesList', gameNavWidgetMulti.Container).empty();
                    $('div.AllGamesTextList', gameNavWidgetMulti.Container).empty();
                    $('ol.GamesList', gameNavWidgetMulti.Container).removeClass('Hidden');
                    $('#lnkLoadAllCategories<%= ID %>').addClass('Hidden'); 
                _view = new CasinoGL(games, keywords);
                _view.populateView();
            }

            function initializeAllView(games) {
                closeAllPopups();
                $('ol.GamesList', gameNavWidgetMulti.Container).addClass('Hidden').empty();
                $('#lnkLoadMoreGames<%= ID %>').addClass('Hidden');          
                _view = new CasinoAL(games);
                _view.populateView();
            }

            $('ol.GamesCategories a.CatTabLink', gameNavWidgetMulti.Container).click(function (e) {
                var categoryid = $(this).data('categoryid');
                initializeView(_data[categoryid]);
                $.cookie('_ccc', categoryid);
                $(document).trigger('CATEGORY_CHANGED_Multi', categoryid);
            });

            $('ol.GamesCategories a.AllViewLink', gameNavWidgetMulti.Container).click(function (e) {
                initializeAllView(_data);
                $(document).trigger('CATEGORY_CHANGED_Multi', '');
            });

            //<%-- filter tooltip popups --%>
            $('div.GlobalFilterCollection', gameNavWidgetMulti.Container).delegate('.GFLabel, .GFDLink', 'mouseenter', function () {
                var label = $(this);
                var title = label.attr('title');
                var popup = $('div.TooltipPopup',$("#casino-hall-popups<%= ID %>"));
                popup.find('.PopupText').text(title);
                label.attr('title', '');

                pos = label.offset();
                left = Math.floor(pos.left - popup.width() + label.width() / 2 - 2);
                Xtop = Math.floor(pos.top) + label.height();

                popup.css({ 'left': left + 'px', 'top': Xtop + 'px' });

                popup.show();
            });
            $('div.GlobalFilterCollection', gameNavWidgetMulti.Container).delegate('.GFLabel, .GFDLink', 'mouseleave', function () {
                var label = $(this);
                var popup = $('div.TooltipPopup',$("#casino-hall-popups<%= ID %>"));
                label.attr('title', popup.find('.PopupText').text());
                popup.hide();
            });

            //<%-- filter dropdown functionality --%>
            $('a.GFDLink', gameNavWidgetMulti.Container).click(function () {
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

            //<%-- radio-button filters --%>
            
            $(':radio[name="sortType"],:radio[name="openType"],:radio[name="displayType"]', gameNavWidgetMulti.Container).each( function(i, el){
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
            var openType = $.cookie('_cot');
            if( openType != null && openType != '' ){
                $(':radio[name="openType"]:checked', gameNavWidgetMulti.Container).attr('checked', false);
                var $selected = $(':radio[name="openType"][value="' + openType + '"]', gameNavWidgetMulti.Container);
                $selected.attr('checked', true);
                $selected.siblings('span.GFText').click();
                $("#gfdVar-opening<%= ID %>").text($(".GLOpenModeList .GFilterItem.GFActive .GFText", gameNavWidgetMulti.Container).text());
            } else {
                $.cookie('_cot', $(':radio[name="openType"]:checked', gameNavWidgetMulti.Container).val(), { expires: 70, path: '/', secure: false });
            }

            $(':radio[name="sortType"]', gameNavWidgetMulti.Container).click( function(e){
                closeAllPopups();
                if( _view != null )
                    _view.populateView();
            });

            $(':radio[name="displayType"]', gameNavWidgetMulti.Container).click( function(e){
                if( $(this).val() == 'Grid' )
                    $('div.GamesContainer', gameNavWidgetMulti.Container).removeClass('ViewList');
                else
                    $('div.GamesContainer', gameNavWidgetMulti.Container).addClass('ViewList');

                closeAllPopups();
                if( _view != null )
                    _view.updateView(false);
            });
            $(':radio[name="displayType"]:checked', gameNavWidgetMulti.Container).click();

            $(':radio[name="openType"]', gameNavWidgetMulti.Container).click( function(e){
                closeAllPopups();
                $.cookie('_cot', $(this).val().toLowerCase(), { expires: 70, path: '/', secure: false });
                $("#gfdVar-opening<%= ID %>").text($(".GLOpenModeList .GFilterItem.GFActive .GFText", gameNavWidgetMulti.Container).text());
            });

            //<%-- window resize --%>
            $(window).bind('resize', function(e){
                closeAllPopups();
                if( _view != null )
                    _view.updateView(false);
            });

            //<%-- checkbox filters --%>
            $(':checkbox[name="filterVendors"]', gameNavWidgetMulti.Container).each( function(i, el){
                var $li = $(el).parents('li');
                if( $(el).is(':checked') )
                    $li.addClass('GFActive');
                else
                    $li.removeClass('GFActive');

                $(el).siblings('span.GFText').click( function(e){
                    e.preventDefault();
                    var $checkbox = $(this).siblings(':checkbox');
                    var s = !$checkbox.is(':checked');
                    $checkbox.attr('checked', s);
                    var $li = $checkbox.parent().parent();
                    if( s )
                        $li.addClass('GFActive');
                    else
                        $li.removeClass('GFActive');
                    
                    $('#gfdVar-vendors<%= ID %>').text( $(':checkbox[name="filterVendors"]:checked').length );

                    closeAllPopups();
                    if( _view != null )
                        _view.populateView();
                });
            });

            //<%-- search games --%>
            var _timer = null;
            function searchGames(){
                _timer = null;

                var keywords = $('#txtGameSearchKeywords<%= ID %>').val();
                if( keywords.length == 0 ){
                    $('ol.GamesCategories li.ActiveCat a', gameNavWidgetMulti.Container).trigger('click');
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
            $('#txtGameSearchKeywords<%= ID %>').keyup( function(e){
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
            var $cur = $('ol.GamesCategories li.ActiveCat a', gameNavWidgetMulti.Container);
            if( $cur.length > 0 )
                $cur.trigger('click');
            else
                $('ol.GamesCategories li:last a', gameNavWidgetMulti.Container).trigger('click');

            } 
            //<%-- onGameLoad end--%>

            GameDataManager.GameLoadByLocalStorage(onGameLoad);

            // <%-- Tutorials --%>
            $('#lnkGameNavTutorial<%= ID %>').click(function(){
                var step = 1;
                function addStep( selector, information){
                    var $o = $(selector);
                    if( $o.is(':visible') ) {
                        $o.attr('data-step', step).attr('data-intro', information);
                        step ++;
                    }
                }
                $('*[data-step]').removeAttr('data-step').removeAttr('data-intro');
                addStep('#gameMultiOpenerNavWidget<%= ID %> div.AllGames ol.GamesCategories', '<%= this.GetMetadata(".Spotlight_Categories").SafeJavascriptStringEncode() %>');
            addStep('#gameMultiOpenerNavWidget<%= ID %> div.AllGames ol.GamesCategories > li.Fav', '<%= this.GetMetadata(".Spotlight_MyFavorites").SafeJavascriptStringEncode() %>');
            addStep('#gameMultiOpenerNavWidget<%= ID %> div.AllGames form.SearchFilterForm', '<%= this.GetMetadata(".Spotlight_SearchGame").SafeJavascriptStringEncode() %>');
            addStep('#gameMultiOpenerNavWidget<%= ID %> div.AllGames div.GLVendorFilter', '<%= this.GetMetadata(".Spotlight_VendorFilter").SafeJavascriptStringEncode() %>');
            addStep('div.AllGames #gfl-opening<%= ID %>', '<%= this.GetMetadata(".Spotlight_OpenMode").SafeJavascriptStringEncode() %>');
            addStep('div.AllGames #gfl-sorting<%= ID %>', '<%= this.GetMetadata(".Spotlight_SortMethod").SafeJavascriptStringEncode() %>');
            addStep('div.AllGames #gfl-display<%= ID %>', '<%= this.GetMetadata(".Spotlight_ViewMode").SafeJavascriptStringEncode() %>');
            addStep('div.AllGames #lnkGameNavTutorial<%= ID %>', '<%= this.GetMetadata(".Spotlight_Help").SafeJavascriptStringEncode() %>');
            
            introJs().start();
        });
            if ($.browser.msie  && parseInt($.browser.version, 10) === 7) {
                $('#lnkGameNavTutorial<%= ID %>').remove();
        }
        });

    </script>

</ui:MinifiedJavascriptControl>
