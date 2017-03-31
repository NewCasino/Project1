<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="System.Globalization" %>
<script language="C#" type="text/C#" runat="server">
    private string GameDataJson { get; set; }
    private int MaxPopularGames
    {
        get
        {
            int maxPopularGames = 40;
            if (this.ViewData["MaxPopularGames"] != null)
            {
                if (!int.TryParse(this.ViewData["MaxPopularGames"].ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out maxPopularGames))
                    maxPopularGames = 40;
            }
            return maxPopularGames;
        }
    }

    private string _DefaultCategory = null;
    private string DefaultCategory
    {
        get
        {
            if (_DefaultCategory == null)
            {                                
                if (this.ViewData["DefaultCategory"] != null)
                {
                    _DefaultCategory = this.ViewData["DefaultCategory"].ToString();
                }
                if (string.IsNullOrWhiteSpace(_DefaultCategory))
                    _DefaultCategory = "Pop";
            }
            return _DefaultCategory;
        }
    }
    
    private SelectList GetVendors()
    {
        List<KeyValuePair<string, string>> list = new List<KeyValuePair<string, string>>();
        list.Add(new KeyValuePair<string, string>(string.Empty, this.GetMetadata(".Filter_Specific_Vendors")));
        List<VendorInfo> vendors = CasinoEngineClient.GetVendors();
        foreach (VendorInfo vendor in vendors)
        {
            if (vendor.VendorID == VendorID.XProGaming || vendor.VendorID == VendorID.EvolutionGaming)
                continue;
            
            if (Profile.IsAuthenticated && vendor.RestrictedTerritories.Exists(c => c == Profile.UserCountryID))
                continue;

            if (Profile.IpCountryID > 0 && vendor.RestrictedTerritories.Exists(c => c == Profile.IpCountryID))
                continue;
            string text = this.GetMetadata(string.Format(".Vendor_{0}", vendor.VendorID.ToString())).DefaultIfNullOrEmpty(vendor.VendorID.ToString());
            KeyValuePair<string, string> item = new KeyValuePair<string, string>( ((int)vendor.VendorID).ToString() , text );
            list.Add(item);
        }
        return new SelectList(list, "Key", "Value", this.ViewData["Vendor"]);
    }

    private SelectList GetSortTypes()
    {
        List<KeyValuePair<string, string>> list = Enum.GetNames(typeof(SortType))
            .Where( t => t != SortType.None.ToString())
            .Select(v => new KeyValuePair<string, string>(v
            , this.GetMetadata(string.Format(".Sort_By_{0}", v)).DefaultIfNullOrEmpty(v)
            )).ToList();
        list.Insert(0, new KeyValuePair<string, string>(string.Empty, this.GetMetadata(".Pick_Sort_Method")));
        return new SelectList(list, "Key", "Value", string.Empty);
    }

    private void AppendGameToJson(ref StringBuilder json, GameRef gameRef)
    {
        // V = Vendor; N = Name; P = Popularity; G = IsGroup; C = Children
        if (gameRef.IsGameGroup && gameRef.Children.Count > 1)
        {
            json.AppendFormat("{{ID:'{0}',N:'{1}',G:true,P:{2},C:["
                , gameRef.ID.SafeJavascriptStringEncode()
                , gameRef.ShortName.SafeJavascriptStringEncode()
                , gameRef.Popularity
                );

            foreach (GameRef childRef in gameRef.Children)
            {
                json.AppendFormat("{{ID:'{0}',V:'{1}',N:'{2}',P:{3}}},"
                    , childRef.ID.SafeJavascriptStringEncode()
                    , (int)childRef.Game.VendorID
                    , childRef.Game.ShortName.SafeJavascriptStringEncode()
                    , childRef.Game.Popularity
                    );
            }

            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);

            json.Append("]},");
            return;
        }     
        
        Game game = null;
        if (!gameRef.IsGameGroup)
            game = gameRef.Game;
        else if(gameRef.Children.Count == 1) // if only one game in the game group, then carry to the first level
            game = gameRef.Children[0].Game;

        if (game!= null)
        {
            json.AppendFormat("{{ID:'{0}',V:'{1}',N:'{2}',G:false,P:{3}}},"
                , game.ID.SafeJavascriptStringEncode()
                , (int)game.VendorID
                , game.ShortName.SafeJavascriptStringEncode()
                , game.Popularity
                );
        }
           
    }


    private List<string> GetFavoriteGameIDs()
    {
        try
        {
            long clientIdentity = 0L;
            if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
                long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out clientIdentity);

            CasinoFavoriteGameAccessor cfga = CasinoFavoriteGameAccessor.CreateInstance<CasinoFavoriteGameAccessor>();
            return cfga.GetByUser(SiteManager.Current.DomainID, ProfileCommon.Current.UserID, clientIdentity);
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
            return new List<string>();
        }
    }
</script>

<div class="Box AllGames">
	<div class="GamesHeader Container">
		<h2 class="BoxTitle GamesTitle">
			<span class="TitleIcon">&sect;</span>
			<strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode()%></strong>
		</h2>
		<form class="FilterForm" id="gameSearch" action="#" method="post" onsubmit="return false;">
			<fieldset>
				<label class="SearchLabel hidden" for="txtGameSearchKeywords"><%= this.GetMetadata(".Insert_Game_Name").SafeHtmlEncode()%></label>
				<input class="FilterInput" type="text" id="txtGameSearchKeywords" name="txtGameSearchKeywords" accesskey="g" maxlength="300" value="" placeholder="<%= this.GetMetadata(".Search_Game").SafeHtmlEncode()%>" />

			</fieldset>
		</form>
		<form class="FilterForm" id="gameFilter" action="#" method="post" onsubmit="return false;">
			<fieldset>
				<label class="hidden" for="ddlFilterVendor"><%= this.GetMetadata(".Choose_Vendor").SafeHtmlEncode()%></label>
                <%: Html.DropDownList("filterVendors", GetVendors(), new { @class = "FilterSelect", id = "ddlFilterVendor", size = "1" })%>

				<label class="hidden" for="ddlSortType"><%= this.GetMetadata(".Choose_Sorting_Method").SafeHtmlEncode()%></label>
                <%: Html.DropDownList("sortType", GetSortTypes(), new { @class = "FilterSelect FSSmaller", id = "ddlSortType", size = "1" })%>

			</fieldset>
		</form>
		<ol class="ListDisplay">
			<li class="LDItem">
				<a title="<%= this.GetMetadata(".Linear_View_Tip").SafeHtmlEncode()%>" href="#" class="LinearView">
					<span><%= this.GetMetadata(".Linear_View").SafeHtmlEncode()%></span>
				</a>
			</li>
			<li class="LDItem Active">
				<a title="<%= this.GetMetadata(".Grid_View_Tip").SafeHtmlEncode()%>" href="#" class="GridView">
					<span><%= this.GetMetadata(".Grid_View").SafeHtmlEncode()%></span>
				</a>
			</li>
		</ol>
	</div>
	<ol class="GamesCategories Tabs Tabs-1">
		<li class="TabItem First All Active">
			<a href="#" class="TabLink" title="<%= this.GetMetadata(".Category_All_Games_Tip").SafeHtmlEncode()%>">
				<span class="CatIcon">&para;</span>
				<span class="CatText"><%= this.GetMetadata(".Category_All_Games").SafeHtmlEncode()%></span>
			</a>
		</li>
		<li class="TabItem Fav">
			<a href="#" class="TabLink" title="<%= this.GetMetadata(".Category_Your_Favorites_Tip").SafeHtmlEncode()%>">
				<span class="CatIcon">&para;</span>
				<span class="CatText"><%= this.GetMetadata(".Category_Your_Favorites").SafeHtmlEncode()%></span>
			</a>
		</li>

		<li class="TabItem Pop">
			<a href="#" class="TabLink" title="<%= this.GetMetadata(".Category_Popular_Games_Tip").SafeHtmlEncode()%>">
				<span class="CatIcon">&para;</span>
				<span class="CatText"><%= this.GetMetadata(".Category_Popular_Games").SafeHtmlEncode()%></span>
			</a>
		</li>

		<li class="TabItem New">
			<a href="#" class="TabLink" title="<%= this.GetMetadata(".Category_Newest_Games_Tip").SafeHtmlEncode()%>">
				<span class="CatIcon">&para;</span>
				<span class="CatText"><%= this.GetMetadata(".Category_Newest_Games").SafeHtmlEncode()%></span>
			</a>
		</li>




<%-------------------------
 Customized Categories Start
-------------------------%>
<%
    {
        StringBuilder json = new StringBuilder();
        json.Append("var GDATA = {};");
        json.Append("function __resetGDATA(){");
        {
            List<GameRef> newGames = new List<GameRef>();
            Dictionary<string, GameRef> allGames = new Dictionary<string, GameRef>();
            
            List<GameCategory> categories = GameMgr.GetCategories();
            foreach (GameCategory category in categories)
            {
                string title = this.GetMetadataEx(".Category_Tip_Format", category.Name).SafeHtmlEncode();
                json.AppendFormat("GDATA['{0}']=[", category.ID.SafeJavascriptStringEncode());
                {
                    foreach (GameRef gameRef in category.Games)
                    {
                        // add the new games
                        if (!gameRef.IsGameGroup)
                        {
                            Game game = gameRef.Game;
                            if (game == null) continue;
                            allGames[game.ID] = gameRef;
                            if (game.IsNewGame)
                                newGames.Add(gameRef);
                        }
                        else
                        {
                            for ( int i = gameRef.Children.Count -1; i >= 0; i--)
                            {
                                GameRef childRef = gameRef.Children[i];
                                if (childRef.Game == null)
                                {
                                    gameRef.Children.RemoveAt(i);
                                    continue;
                                }
                                allGames[childRef.Game.ID] = gameRef;
                                if (childRef.Game.IsNewGame)
                                    newGames.Add(childRef);
                            }
                        }
                        
                        AppendGameToJson(ref json, gameRef);
                    }
                    if (json[json.Length - 1] == ',')
                        json.Remove(json.Length - 1, 1);
                }
                json.Append("];");
             %>

		<li class="TabItem <%= category.ID.SafeHtmlEncode() %>" data-categoryID="<%= category.ID.SafeHtmlEncode() %>">
			<a href="#" class="TabLink" title="<%= title %>">
				<span class="CatIcon">&para;</span>
				<span class="CatText"><%= category.Name.SafeHtmlEncode()%></span>
			</a>
		</li>

<%          }
            
            // new games
            json.Append("GDATA['NewGames']=[");
            foreach (GameRef gameRef in newGames)
            {
                AppendGameToJson(ref json, gameRef);
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("];");


            // Popular Games
            json.Append("GDATA['Popular']=[");
            List<GameRef> popGames = allGames.Values.OrderByDescending(g => g.Popularity).Take(MaxPopularGames).ToList();
            foreach (GameRef gameRef in popGames)
            {
                AppendGameToJson(ref json, gameRef);
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("];");


            json.Append("}; __resetGDATA();"); // __resetGDATA end
            

           
            // favorites
            json.Append("GDATA['Favorites']=[");
            List<string> favGameIDs = GetFavoriteGameIDs();
            foreach (string gameID in favGameIDs)
            {
                json.AppendFormat("'{0}',", gameID.SafeJavascriptStringEncode());
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("];");
            
            this.GameDataJson = json.ToString();

            

        }
    }%>
<%-------------------------
 Customized Categories End
-------------------------%>



	</ol>

    
	<div class="GamesContainer">
        <% this.Html.RenderAction("SearchGames"); %>
	</div>

    <div id="divAllGamesContainer" style="display:none">
    </div>


</div>

<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript" >
    <%= GameDataJson.ToString() %>
    var _CLONED_GAMES = {};
    $(function () {        
        
        

        $('div.AllGames ol.GamesCategories > li').click(function (e) {
            e.preventDefault();
            $(this).siblings('li.Active').removeClass('Active');
            $(this).addClass('Active');
        });

        // <%-- customized categories click event --%>
        $('div.AllGames ol.GamesCategories > li[data-categoryID]').click(function (e) {
            var categoryID = $(this).data("categoryID") || $(this).attr("data-categoryID");
            filterGames( categoryID, '');
            
        });

        // <%-- all games click event --%>
        $('div.AllGames ol.GamesCategories > li.All').click(function (e) {
            filterGames( '', '');
        });

        // <%-- Popular games click event --%>
        $('div.AllGames ol.GamesCategories > li.Pop').click(function (e) {
            filterGames( 'Popular', '');
        });

        // <%-- Newest games click event --%>
        $('div.AllGames ol.GamesCategories > li.New').click(function (e) {
            filterGames( 'NewGames', '');
        });

        // <%-- Favorites click event --%>
        $('div.AllGames ol.GamesCategories > li.Fav').click(function (e) {
            var $container = $('<ol></ol>');
            for( var i = 0; i < GDATA["Favorites"].length; i++){
                var $li = $('li.GLItem[data-gameID="' + GDATA["Favorites"][i].scriptEncode() + '"]');
                if( $li.length > 0 ){
                    $container.append( $li.eq(0).clone(true) );
                }
            }
            $('li.GLItem[data-gameID] a.BtnRemoveFavorite', $container).parent('li.GTPItem').show();
            $('li.GLItem[data-gameID] a.BtnAddFavorite', $container).parent('li.GTPItem').hide();
            __setGames($container);
        });


        

        // <%-- keywords textbox change event --%>
        var timerID = null;
        $('#txtGameSearchKeywords').keyup( function(e){
            if( timerID != null ) clearTimeout(timerID);
            timerID = setTimeout( function(){
                timerID = null;
                filterGames('', $('#txtGameSearchKeywords').val() );
                $('div.AllGames ol.GamesCategories > li.Active').removeClass('Active');
                $('div.AllGames ol.GamesCategories > li.All').addClass('Active');
            }, 300);
        });

        


        var lastCategoryID = '';
        function filterGames(categoryID, keywords){
            lastCategoryID = categoryID;

            __resetGDATA();
            var array = GDATA[categoryID];

            // <%-- if the array cannot be found, then show all the games --%>
            if( array === undefined || array == null ){
                array = new Array();
                var added = {}; // <%-- store the added games by key to prevent dunplicate games --%>
                $('div.AllGames ol.GamesCategories > li[data-categoryID]').each( function(i,el){
                    var cid = $(el).data("categoryID") || $(el).attr("data-categoryID");
                    var subArray = GDATA[cid];
                    if( subArray == null ) return;
                    for ( var i = 0; i < subArray.length; i++){
                        if( added[subArray[i].ID] ) continue; // <%-- the game is already added --%>

                        // <%-- filter by keywords --%>
                        if( keywords != null && keywords != '' ){
                            if( subArray[i].N.toLowerCase().indexOf(keywords.toLowerCase()) < 0 )
                                continue;
                        }
                        array.push(subArray[i]);
                        added[subArray[i].ID] = true;
                    }
                });
            }

            // <%-- filter by vendor --%>
            var vendor = $('#ddlFilterVendor').val();
            if( vendor.length > 0 ){
                for( var i = array.length - 1; i >= 0; i--){
                    if( !array[i].G ){
                        if( array[i].V != vendor ){
                            array.splice(i, 1);
                        }
                    }
                    else {
                        var subArray = [];
                        for( var j = 0; j < array[i].C.length; j++) {
                            if( array[i].C[j].V == vendor ){
                                subArray.push( array[i].C[j] );
                            }
                        }
                        if( subArray.length == 0 )
                            array.splice(i, 1);
                        else if( subArray.length == 1 ){
                            array.splice(i, 1, subArray[0]);
                        }else{
                            array[i].C = subArray;
                        }
                    }
                }
            }

            if( 'Alphabet' == $('#ddlSortType').val() ){
                array.sort( function(a, b){
                    return a.N.localeCompare(b.N);
                });
            }
            else if( 'Popularity' == $('#ddlSortType').val() ){
                array.sort( function(a, b){
                    if( a.P == b.P ) return 0;
                    return (a.P > b.P) ? -1 : 1;
                });
            }

            var $container = $('<ol></ol>');
            for( var i = 0; i < array.length; i++){
                var $li = _CLONED_GAMES[array[i].ID];
                $container.append($li);
                
                //<%--  check the children --%>
                if( array[i].G && $li.hasClass('GLMultiple') ){
                    
                    var $children = $('ol.GamesList > li.GLItem', $li);
                    for( var c = $children.length - 1; c >= 0; c--){
                        var $child = $children.eq(c);
                        var gid = $child.data("gameID") || $child.attr("data-gameID");
                        var found = false;
                        for( var j = array[i].C.length - 1; j >= 0; j--){
                            if( array[i].C[j].ID == gid ){
                                found = true;
                                break;
                            }
                        }
                        if(found) $child.show();
                        else $child.hide();
                    }

                    $('span.AlternatesNumber', $li).text( array[i].C.length.toString(10) );
                    $('sup.MoreVariants', $li).text( '(' + array[i].C.length.toString(10) + ')' );
                }

                
            }

            // <%-- Hide "Add to Favorites" --%>
            for( var i = 0; i < GDATA["Favorites"].length; i++){
                $('li.GLItem[data-gameID="' + GDATA["Favorites"][i].scriptEncode() + '"] a.BtnAddFavorite', $container).parent('li.GTPItem').hide();
            }

            $('li.GLItem[data-gameID] a.BtnRemoveFavorite', $container).parent('li.GTPItem').hide();


            __setGames($container);
        }

        // <%---------------------------------------%>
        $('#ddlSortType').change( function(){
            filterGames( lastCategoryID, $('#txtGameSearchKeywords').val() );
        });

        $('#ddlFilterVendor').change( function(){
            filterGames( lastCategoryID, $('#txtGameSearchKeywords').val() );
        });

        // <%-- clone all the games to backup --%>
        $('div.AllGames div.GamesContainer > div > ol').clone(true).appendTo('#divAllGamesContainer');

        // <%-- remove .hidden for "remove button" --%>
        $('#divAllGamesContainer li.hidden > a.BtnRemoveFavorite').parent('li').removeClass('hidden');

        $('#divAllGamesContainer li[data-gameID]').each( function(i, el){
            var gameID = $(el).data("gameID") || $(el).attr("data-gameID"); 
            _CLONED_GAMES[gameID] = $(el).clone(true);
        });

        var cid = '<%= Request.QueryString["cid"].SafeJavascriptStringEncode() %>';
        if( cid.length > 0 ){
            try{
                var $destC = $('li.TabItem[data-categoryid="' + cid + '"]');
                if($destC.length==0)
                    $destC = $('div.AllGames ol.GamesCategories > li.<%=DefaultCategory.SafeJavascriptStringEncode() %>');
                
                if($destC.length > 0)
                {
                    $destC.trigger('click');
                }
            } catch(ex){}
        }
        else{
            $('div.AllGames ol.GamesCategories > li.<%=DefaultCategory.SafeJavascriptStringEncode() %>').trigger('click');
        }
    });

    
</script>

</ui:MinifiedJavascriptControl>