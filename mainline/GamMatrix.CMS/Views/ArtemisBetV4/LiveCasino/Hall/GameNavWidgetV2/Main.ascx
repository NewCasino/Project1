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
    private string[] Vendors;




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
        <span class=""Button LVButton""><span class=""ButtonText"">{3}</span></span>
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

        json1.Append("[");
        foreach (KeyValuePair<string, List<LiveCasinoTable>> category in categories)
        {
            string name = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, "/Metadata/LiveCasino/GameCategory/{0}.Text", category.Key)).DefaultIfNullOrEmpty(category.Key);
            html.AppendFormat(CultureInfo.InvariantCulture, CATEGORY_FORMAT
                , category.Key.ToString()
                , category.Value.Count
                , name.SafeHtmlEncode()
                , this.GetMetadata(".PlayNow_Button").DefaultIfNullOrWhiteSpace("PLAY NOW")
                );
            TotalTableCount = TotalTableCount + category.Value.Count;

            foreach (LiveCasinoTable table in category.Value)
            {
                vendors[table.VendorID] = table.VendorID.ToString();
                string limitVal = table.GetLimit(Profile.UserCurrency.DefaultIfNullOrEmpty("EUR")).SafeJavascriptStringEncode();
                if (!string.IsNullOrEmpty(limitVal))
                {
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
                    , "{{\"ID\":{0},\"P\":{1},\"V\":\"{2}\",\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"R\":{6},\"S\":\"{7}\",\"N\":{8},\"T\":{9},\"H\":{10},\"O\":{11},\"C\":\"{12}\",\"Opened\":{13},\"Limit\":\"{14}\",\"OpeningHours\":\"{15}\",\"VIP\":\"{16}\",\"NewTable\":\"{17}\",\"TurkishTable\":\"{18}\"}},"
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
                    , limitVal
                    , table.OpeningHours.SafeJavascriptStringEncode()
                    , table.IsVIPTable ? "1" : "0"
                    , table.IsNewTable ? "1" : "0"
                    , table.IsTurkishTable ? "1" : "0"
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
                    string.Format(CultureInfo.InvariantCulture
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
            <strong class="TitleText"><%= this.GetMetadataEx(".Title_Tables", this.TotalTableCount).HtmlEncodeSpecialCharactors() %></strong>
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
                        <a class="GFDLink GFSLink" id="gfl-summary" href="#" title="Bu oyun listesi i&#231;in filtreleri g&#246;rmek">
                            <span class="GFDText"><span class="Hidden">t&#252;m bak</span><span class="ActionSymbol">&#9660;</span></span>
                            <span class="GFDInfo">Filter</span>
                        </a>
                    </div>
                    <div class="GlobalFilterCollection">
                        <%=this.GetMetadata(".GLFilterTitle")%>
                        <%----------------------------
                        Vendor Filter
                    ----------------------------%>
                        <%= this.VendorFilterHtml %>

                        <div class="GFListWrapper GLVIPFilter GFL1">
                            <ul class="GFilterList GFSingleItems Container">
                                <li class="GFilterItem VIPTables GFActive  ">
                                    <label for="filterVIPTables" class="GFLabel" title="VIPTables">
                                        <input type="checkbox" id="filterVIPTables" name="filterVIPTables" value="VIPTables" class="hidden" />
                                        <span class="GFText"><%=this.GetMetadata(".VIPTable_Text") %></span>
                                        <span class="GFVendorName"><%=this.GetMetadata(".Table_Text") %></span>
                                    </label>
                                </li>
                            </ul>
                        </div>
                         
                        <div class="GFListWrapper GFL1 GLLimitFilter ">
                            <!--ActiveDrop--> 
                            <ul class="GFilterList Container" id="gfl-limits">
                                <li class="GFilterItem GFilterDropdown">
                                    <a class="GFDLink GFDSymbol" id="gfl-openingLimits" href="#" title="See all Limits">
                                        <span class="GFDText"><span class="Hidden">See all</span><span class="ActionSymbol">▼</span></span>
                                        <span class="GFDInfo GFPopup"><span class="GFDVar" id="gfdVar-opening">Limits</span></span>
                                    </a>
                                </li>
                                <li class="GFilterItem Limit1 GFActive">
                                    <label for="gfPopup" class="GFLabel" title="Opens the game in an exclusive overlay.">
                                        <input type="radio" checked="checked" id="gfPopup" name="openType" value="popup" class="hidden">
                                        <span class="GFText">Limit 1</span>
                                        <span class="GFVendorName">Limit 1</span>
                                    </label>
                                </li>
                                <li class="GFilterItem Limit2">
                                    <label for="gfInline" class="GFLabel" title="Open games within the page">
                                        <input type="radio" id="gfInline" name="openType" value="inline" class="hidden">
                                        <span class="GFText">Limit 2</span>
                                        <span class="GFVendorName">Limit 2</span>
                                    </label>
                                </li>
                                <li class="GFilterItem Limit3">
                                    <label for="gfNewTab" class="GFLabel" title="Open games in a new page">
                                        <input type="radio" id="gfNewTab" name="openType" value="newtab" class="hidden">
                                        <span class="GFText">Limit 3</span>
                                        <span class="GFVendorName">Limit 3</span>
                                    </label>
                                </li>
                                <li class="GFilterItem Limit4">
                                    <label for="gfFullScreen" class="GFLabel" title="Open games in fullscreen mode">
                                        <input type="radio" id="gfFullScreen" name="openType" value="fullscreen" class="hidden">
                                        <span class="GFText">Limit 4</span>
                                        <span class="GFVendorName">Limit 4</span>
                                    </label>
                                </li>
                            </ul>
                        </div>
                        <div class="GFListWrapper GLTurkishTablesFilter">
                            <ul class="GFilterList GFSingleItems Container">
                                <li class="GFilterItem TurkishTables GFActive  ">
                                    <label for="filterTurkishTables" class="GFLabel" title="VIPTables">
                                        <input type="checkbox" id="filterTurkishTables" name="filterTurkishTables" value="TurkishTables" class="hidden" />
                                        <span class="GFText">&nbsp;</span>
                                        <span class="GFVendorName"><%=this.GetMetadata(".TurkishTables")%></span>
                                    </label>
                                </li>
                            </ul>
                        </div>
                        <div class="GFListWrapper GLLastPlayTablesFilter">
                            <ul class="GFilterList GFSingleItems Container">
                                <li class="GFilterItem LastPlayTables GFActive  ">
                                    <label for="filterLastPlayTables" class="GFLabel" title="LastPlayTables">
                                        <input type="checkbox" id="filterLastPlayTables" name="filterLastPlayTables" value="LastPlayTables" class="hidden" />
                                        <span class="GFText">&nbsp;</span>
                                        <span class="GFVendorName"><%=this.GetMetadata(".LastPlayedTables")%></span>
                                    </label>
                                </li>
                            </ul>
                        </div> 
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
            <%= CategoryHtml %>
            <%--        <li class="TabItem Last All">
    <a href="/Casino/Hall" class="Button TabLink AllViewLink" title="<%= this.GetMetadata(".Category_All_Title").SafeHtmlEncode() %>">
    <span class="CatIcon">&para;</span>
                    <span class="CatNumber"><%= this.TotalTableCount %></span>                    
    <span class="CatText"><%= this.GetMetadata(".Category_All").SafeHtmlEncode() %></span>
    </a>
    </li>--%>
        </ol>
        <div class="LiveCasinobanner TableExclusive">
            <div class="BannerContent">
                <%=this.GetMetadata(".LiveCasinoBanner") %>
            </div>
        </div>
    </div>


    <div class="TablesContainer">
        <ol class="TablesList Container">
            <%=this.GetMetadata(".TimeTable_Html") %>
            <%if (this.JsonData.Length > 2) // []
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
            <%: Html.WarningMessage(msg + " on " + HttpContext.Current.Server.MachineName.Replace("CMS", "***").Replace("PROD-ENV", "***-**")) %>
            <% } %>
        </ol>
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
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
<script type="text/javascript">
    $(function () {
        var isLoggedIn = <%= this.Profile.IsAuthenticated.ToString().ToLowerInvariant() %>;
        var _game_map = {};
        var json = <%= JsonData %>;
        for( var i = 0; i < json.length; i++){
            _game_map[json[i].ID] = json[i];
        }

        $('ol.GamesCategories a.TabLink').click(function (e) {
            e.preventDefault();
            var _targetTop = jQuery(".TablesContainer").offset().top - 340;
            jQuery("html,body").animate({scrollTop:_targetTop},1000);
            try{
                var activeTab = $(this).parent();
                var classList = $(activeTab).className;
                var cls = $(activeTab).attr('class').split(' ');       
                for (var i = 0; i < cls.length; i++) { 
                    if (cls[i].indexOf("cat-") > -1) {   
                        cls = cls[i];
                    }
                }
                ChangebodyClass(cls);

                $('ol.GamesCategories li.ActiveCat').removeClass('ActiveCat');
                $(this).parent('li').addClass('ActiveCat');
            }catch(err){}
            refreshTables();
            if ($('.ShowMoreTablesBox').is('.Hidden')){ 
                $('.ShowMoreTablesBox').removeClass('Hidden');
            }
            /* 
        $(activeTab).siblings().removeClass('ActiveCat');
        $(activeTab).toggleClass('ActiveCat');
        */
        });
        $('li.VIPTables,li.TurkishTables').click(function(e){
            e.preventDefault(); 
            var $checkbox = $(this).find(":checkbox");
            $checkbox.is(':checked') ? $(this).addClass('GFActive'): $(this).removeClass('GFActive');             
            var s = !$checkbox.is(':checked');
            $checkbox.attr('checked', s);
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
            !($(':checkbox[name="filterTurkishTables"]:not(:checked)').length > 0) ?  
                $('ol.TablesList li.GLItem[data\-turkishtable="0"]').hide() : "";
            !($(':checkbox[name="filterVIPTables"]:not(:checked)').length > 0) ?  
                $('ol.TablesList li.GLItem[data\-viptable="0"]').hide() : "";

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
            $(".BannerGLItem").show();
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
                if( !game.Opened )
                    return;
                if( !isLoggedIn ){
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
                    if($(this).data('vendorid')=='BetGames')
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
                    window.open( '/LiveCasino/Hall/Start?tableID=' + $anchor.data('tableid'), 'live_casino_table', params);
                }
            });
        });
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

        //$('ol.GamesCategories > li.TabItem:last > a').trigger('click');
        
        $(".GLItem").hide();
        if($(".GamesCategories > li").length == 1){
            $('ol.GamesCategories a.TabLink').click();
            $('.GamesCategories').hide();
        }
        $("body").addClass("Style-Default");

    });

    function ChangebodyClass(cls){
        var cls = cls;
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
        ChangeLiveCasinoSlide(cls);
    }

    function ChangeLiveCasinoSlide(cls) {
        var cls = cls;
        var pre = "LCSlide-";
        $('.LiveCasinoSlide').removeClass('Active');
        var currentSlide = '#'+ pre + cls; 
        $(currentSlide).addClass('Active');
    }
    $('#show-MoreTables').on('click', function(evt){
        evt.preventDefault();
        console.log('show-MoreTables');
        //show-MoreTables
    });
</script>
</ui:MinifiedJavascriptControl>
