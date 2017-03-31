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
                maxNumOfPopularGames = 3;
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
    #endregion

  
    

    private int TotalTableCount;
    private string CategoryHtml;
    private string VendorFilterHtml;
    private string JsonData;
    private string [] Vendors;

   

    

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        
        /////////////////////////////////////////////////////////////////////////
        // CategoryHtml
        /*
<li class="TabItem" data-category="5A0E42F6-C8BA-57FF-11E1-04B5ECA0F9F7">
    <a href="#" class="Button TabLink" title="Display only video slots games">
        <span class="CatIcon">&para;</span>
        <span class="CatText">Video Slots <sup>(222)</sup></span>
    </a>
</li>
         */

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
       // List<KeyValuePair<string, List<LiveCasinoTable>>> categories = GameMgr.GetLiveCasinoTables(SiteManager.Current);
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

        json1.Append("[");
        foreach (KeyValuePair<string, List<LiveCasinoTable>> category in categories)
        {
            string name = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "/Metadata/LiveCasino/GameCategory/{0}.Text", category.Key)).DefaultIfNullOrEmpty(category.Key);
            html.AppendFormat(CultureInfo.InvariantCulture, CATEGORY_FORMAT
                , category.Key.ToString()
                , category.Value.Count
                , name.SafeHtmlEncode()
                );
            TotalTableCount = TotalTableCount + category.Value.Count;

            foreach (LiveCasinoTable table in category.Value)
            {
                vendors[table.VendorID] = table.VendorID.ToString();

                StringBuilder json = table.IsOpened ? json1 : json2;
                json.AppendFormat(CultureInfo.InvariantCulture
                    , "{{\"ID\":{0},\"P\":{1},\"V\":\"{2}\",\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"R\":{6},\"S\":\"{7}\",\"N\":{8},\"T\":{9},\"H\":{10},\"O\":{11},\"C\":\"{12}\",\"Opened\":{13},\"Limit\":\"{14}\",\"OpeningHours\":\"{15}\"}},"
                    , table.ID
                    , Math.Min(table.Popularity, 9007199254740991)
                    , table.VendorID.ToString()
                    , table.Name.SafeJavascriptStringEncode()
                    , table.ThumbnailUrl.SafeJavascriptStringEncode()
                    , (Profile.IsAuthenticated ? table.IsFunModeEnabled : table.IsAnonymousFunModeEnabled) ? "1" : "0"
                    , (Profile.IsAuthenticated && table.IsRealMoneyModeEnabled) ? "1" : "0"
                    , table.Slug.DefaultIfNullOrEmpty(table.ID.ToString()).SafeJavascriptStringEncode()
                    , table.IsNewGame ? "1" : "0"
                    , "0"
                    , "0"
                    , table.FPP >= 1.00M ? "1" : "0"
                    , category.Key.SafeJavascriptStringEncode()
                    , table.IsOpened.ToString().ToLowerInvariant()
                    , table.GetLimit(Profile.UserCurrency.DefaultIfNullOrEmpty("EUR")).SafeJavascriptStringEncode()
                    , table.OpeningHours.SafeJavascriptStringEncode()
                    );
            }
        }
        if (json2.Length > 0)
        {
            json2.Remove(json2.Length - 1, 1);
            json1.Append(json2.ToString());
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
            , this.GetMetadata(".ViewSwitcher_Title").SafeHtmlEncode()
            , this.GetMetadata(".ViewSwitcher_Selected").SafeHtmlEncode()
            , this.GetMetadata(".Filters_See_All").SafeHtmlEncode()
            );

        foreach (var vendor in vendors)
        {

            string name = this.GetMetadata(
                    string.Format( CultureInfo.InvariantCulture
                        , "/Metadata/GammingAccount/{0}.Display_Name"
                        , vendor.Value
                    )
                 ).DefaultIfNullOrEmpty(vendor.Value);

            html.AppendFormat(@"
<li class=""GFilterItem {0} GFActive"">
    <label for=""gfVendor{0}"" class=""GFLabel"" title=""{2}"">
        <input type=""checkbox"" checked=""checked"" id=""gfVendor{0}"" name=""filterVendors"" value=""{1}"" class=""hidden"" />
        <span class=""GFText"">{3}</span>
        <span class=""GFVendorName"">{3}</span>
    </label>
</li>"
                , vendor.Key.ToString()
                , vendor.Key.ToString()
                , this.GetMetadataEx(".VendorFilter_Toggle", name).SafeHtmlEncode()
                , name.SafeHtmlEncode()
                );
        }

        html.Append("</ul></div>");
        VendorFilterHtml = html.ToString();
    }
</script>

<div class="Box AllTables">
<div class="TablesHeader Container">
<h2 class="BoxTitle TablesTitle">
<span class="TitleIcon">&sect;</span>
<strong class="TitleText">
                <%= this.GetMetadataEx(".Title_Tables", this.TotalTableCount).HtmlEncodeSpecialCharactors() %>
            </strong>
</h2>
<div class="TableFilters">
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
<form class="FilterForm GlobalFilterForm" action="#" onsubmit="return false">
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


                        
                    </div>

<button type="submit" class="Button hidden">
<span>Filter</span>
</button>
</fieldset>
</form>
</div>
</div>


  <%------------------------
    Game Categories
    ------------------------%>
    <div class="GamesCategoriesWrap">
    <ol class="GamesCategories Tabs Tabs-1">

            <%-- 
    <li class="TabItem First Fav">
    <a href="/Casino/Hall#favorites" class="Button TabLink CatTabLink" title="<%= this.GetMetadata(".Category_Favorites_Title").SafeHtmlEncode() %>" data-category="favorites">
    <span class="CatIcon">&para;</span>
    <span class="CatText"><%= this.GetMetadata(".Category_Favorites").SafeHtmlEncode() %></span>
    </a>
    </li>
            --%>
    
    <%= CategoryHtml %>

            <li class="TabItem Last All">
    <a href="/Casino/Hall" class="Button TabLink AllViewLink" title="<%= this.GetMetadata(".Category_All_Title").SafeHtmlEncode() %>">
    <span class="CatIcon">&para;</span>
                    <span class="CatNumber"><%= this.TotalTableCount %></span>
                    
    <span class="CatText"><%= this.GetMetadata(".Category_All").SafeHtmlEncode() %></span>
    </a>
    </li>
    </ol>

            <%----------------------------
                Icon Meanings
            ----------------------------%>
        <%-- 
        <div class="IconHelp">
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
<span class="GThot">Hot</span>
<span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_Popular").SafeHtmlEncode()%></span>
</li>
                
                <li class="HelpItem">
<span class="GTfav">Favorite</span>
<span class="HelpText">&ndash; <%= this.GetMetadata(".IconMeaning_Favorite").SafeHtmlEncode()%></span>
</li>
                
</ul>
</div>
        --%>
    </div>

    <%------------------------
        Except "All Games", show as grid or list
      ------------------------%>
<div class="TablesContainer">
        <div style="display:none;">
            <%= this.JsonData %>
        </div>
        
        <%--<%if (this.JsonData.Length > 2){ %>
            <%= this.PopulateTemplateWithJson("GridViewGames", this.JsonData, new { isLoggedIn = Profile.IsAuthenticated })%>
        <% } %>--%>

        <ol class="TablesList Container">
            <%if (this.JsonData.Length > 2)
               { %>
                <%= this.PopulateTemplateWithJson("TableListItem", this.JsonData, new { isLoggedIn = Profile.IsAuthenticated })%>
            <% } %>
        </ol>

        <%if (this.JsonData == "[]")
            {
              string msg = this.GetMetadataEx( ".No_Table_Available"
                  , Request.GetRealUserAddress()
                  , Profile.IpCountryID
                  , Profile.UserCountryID
                  );
               %>

            <%: Html.WarningMessage(msg) %>
        <% } %>

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

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="false" Enabled="false">
<script type="text/javascript">
    $(function () {
        var isLoggedIn = <%= this.Profile.IsAuthenticated.ToString().ToLowerInvariant() %>;
        var _game_map = {};
        var json = <%= JsonData %>;
        for( var i = 0; i < json.length; i++){
            _game_map[json[i].ID] = json[i];
        }

        var gameIdToOpen = $.cookie('loginDialogGameId');

        if (isLoggedIn && gameIdToOpen != null){
            $.cookie('loginDialogGameId', null, { expires: -1 });

            openLiveCasinoTable(_game_map[gameIdToOpen]);
        }

        $('ol.GamesCategories a.TabLink').click(function (e) {
            e.preventDefault();
            $('ol.GamesCategories li.ActiveCat').removeClass('ActiveCat');
            $(this).parent('li').addClass('ActiveCat');

            refreshTables();
        });

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

                refreshTables();
            });
        });

        function refreshTables() {
            $('ol.TablesList li.GLItem').show();

            var selectedCat = $('ol.GamesCategories li.ActiveCat a.TabLink').data('category');
            if (selectedCat != null) {
                $('ol.TablesList li.GLItem[data\-category!="' + selectedCat + '"]').hide();
            }

            $(':checkbox[name="filterVendors"]:not(:checked)').each(function (el) {
                var v = $(this).val();
                $('ol.TablesList li.GLItem[data\-vendor="' + v + '"]').hide();
            });

            var existings = {};
            $('ol.TablesList li.GLItem:visible').each(function(el){
                var id = $(this).data('tableid');
                if( existings[id] != null )
                    $(this).hide();
                else
                    existings[id] = true;
            });

            $('#livecasino-game-popup').hide();
        }


        function positionPopup($popup, $anchor) {
            var pos = $anchor.offset();
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

        $(document.body).append($('#livecasino-hall-popups'));
        $('a.GameThumb, a.Game', $('ol.TablesList li.GLItem')).click(function (e) {
            e.preventDefault();

            var $anchor = $(this).parents('.GLItem');
            var game = _game_map[$anchor.data('tableid')];
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

                openLiveCasinoTable(game);
            });
        });

        function openLiveCasinoTable(game){
            if( !game.Opened )
                return;
            if( !isLoggedIn ){
                $.cookie('loginDialogGameId', game.ID);
                $('iframe.LoginDialog').remove();
                $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Login/Dialog?_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="LoginDialog"></iframe>').appendTo(top.document.body);
                    var $iframe = $('iframe.LoginDialog', top.document.body).eq(0);
                    $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
                } else {
                    
                    var w = screen.availWidth * 9 / 10;
                    var h = screen.availHeight * 9 / 10;
                    var l = (screen.width - w)/2;
                    var t = (screen.height - h)/2;
                    var scrollbars='no';
                    if(game.V=='BetGames')
                        scrollbars='yes';
                    var params = [
                        'height=' + h,
                        'width=' + w,
                        'fullscreen=no',
                        'scrollbars='+scrollbars,
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
                }
        }

        //<%-- search games --%>
        var _timer = null;
        function searchGames(){
            _timer = null;

            var keywords = $('#txtTableSearchKeywords').val();
            if( keywords.length == 0 ){
                $('ol.GamesCategories li.ActiveCat a').trigger('click');
            }
            else{
                $('ol.TablesList > li.GLItem').each( function(){
                    var text = $('> .GameTitle > a', $(this)).text();
                    if( text != null && text.toUpperCase().indexOf(keywords.toUpperCase()) >= 0 )
                        $(this).show();
                    else
                        $(this).hide();
                });
            }
        }
        $('#txtTableSearchKeywords').keyup( function(e){
            if( _timer != null )
                clearTimeout(_timer);
            _timer = setTimeout( searchGames, 300);
        });

        $(window).on('load', function(){
            $('li.ClosedTable img.GT').each( function() {
                grayscaleImage(this);
            });
        });

        $('ol.GamesCategories > li.TabItem:last > a').trigger('click');
    });
</script>

</ui:MinifiedJavascriptControl>
<script> 
    function checkSeatStatus(){
        try{
            var url = '/livecasino/Hall/GetSeatsData';
            jQuery.getJSON( url, function(json){ 
                if (json.success) {
                    var seats =  json.data ;
                    for(var item in seats){
                        var $item =   $(".GLItem[data-tableid='"+ item + "']");  
                        //if(seats[item].totalSeats > 0 ){
                            $item.find(".SeatInfos").removeClass("Hidden");
                            $item.find(".TakenSeats").html(seats[item].takenSeats);
                            $item.find(".TotalSeats").html(seats[item].totalSeats);
                       // }   else{
                         //   $item.find(".SeatInfos").removeClass("Hidden").addClass("Hidden");
                        //}
                    }
                    setTimeout(function(){
                        checkSeatStatus();
                    },20000);
                }
            });
        }catch(err){
            console.log(err);
        }
    };
    checkSeatStatus(); 
</script>