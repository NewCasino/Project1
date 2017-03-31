<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
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
    private int DefaultSize
    {
        get
        {
            string strSize = (this.ViewData["DefaultSize"] as string) ?? "9";
            return int.Parse(strSize);
        }
    }
    private string DefaultVender
    {
        get
        {
            return (this.ViewData["DefaultVender"] as string) ?? string.Empty;
        }
    }
    private string JsonUrl
    {
        get
        {
            return string.Format(CultureInfo.InvariantCulture
                , "/Casino/Hall/GameData?maxNumOfNewGame={0}&maxNumOfPopularGame={1}&includeDesc=True&_={2}"
                , this.MaxNumOfNewGames
                , this.MaxNumOfPopularGames
                , DateTime.Now.Ticks
                );
        }
    }
    
    private string strVendorTabs = string.Empty;
    private string categoryJson = string.Empty;
    private int defaultVid = 0;
    Dictionary<string, string> VendorDic = null;
    
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        strVendorTabs = RenderVendorTabs();
        categoryJson = GetJsonDataForCategory();
    }
    private string GetJsonDataForCategory()
    {
        StringBuilder json = new StringBuilder();

        json.Append("{");
        {
            List<GameCategory> categories = GameMgr.GetCategories();
            foreach (GameCategory category in categories)
            {
                if (category.Games.Count == 0)
                    continue;

                json.AppendFormat(CultureInfo.InvariantCulture, "'{0}':{{ID:'{0}',Name:'{1}'}},"
                    , category.FriendlyID.SafeJavascriptStringEncode()
                    , category.Name.SafeJavascriptStringEncode()
                    );
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("}");
        }
        return json.ToString();
    }
    private string RenderVendorTabs(){
        StringBuilder html = new StringBuilder();

        Func<VendorInfo, bool> isAvailableVendor = (VendorInfo vendor) =>
        {
            if (vendor.VendorID == VendorID.XProGaming || vendor.VendorID == VendorID.EvolutionGaming)
                return false;

            if (Profile.IsAuthenticated && vendor.RestrictedTerritories.Exists(c => c == Profile.UserCountryID))
                return false;

            if (Profile.IpCountryID > 0 && vendor.RestrictedTerritories.Exists(c => c == Profile.IpCountryID))
                return false;

            return true;
        };
        VendorInfo[] vendors = CasinoEngineClient.GetVendors().Where(v => isAvailableVendor(v)).ToArray();
        VendorDic = vendors.ToDictionary(v => ((int)v.VendorID).ToString(), v => v.VendorID.ToString());

        for (int i = 0; i < vendors.Length; i++)
        {
            string strStyle = string.Empty;
            VendorInfo vendor = vendors[i];
            string name = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, ".Vendor_{0}", vendor.VendorID.ToString()))
                .DefaultIfNullOrEmpty(vendor.VendorID.ToString());

            if ((string.IsNullOrEmpty(DefaultVender) && i == 0) || string.Compare(DefaultVender, vendor.VendorID.ToString(), true) == 0)
            {
                strStyle = "selected";
                defaultVid = (int)vendor.VendorID;
            }
            
            html.AppendFormat(@"
<li class=""vendor_items {2}"" data-vendorid=""{0}"">
    <label class=""vendorLabel"" title=""{1}"">{1}</label>
</li>"
                , (int)vendor.VendorID
                , name
                , strStyle
                );
        }
        return html.ToString();
    }
</script>
<div class="gamestablistwidget">
    <div class="gtl_toolbar">
        <div class="vendor_tabs">
            <ul class="vendors">
                <%=this.strVendorTabs %>
            </ul>
        </div>
        <div class="category_tabs">
            <ul class="categorys" id="categorys_section">
                
            </ul>
        </div>
    </div>
    <div class="gtl_logo"></div>
    <div class="gamestablistwidget_ct">
        <div class="games_list">
            <div class="games_list_content">

            </div>
            <div class="pages_nav">
                <span class="pre_btn">
                </span>
                <span class="pagesinfo"></span>
                <span class="nex_btn">
                </span>
            </div>
        </div>
    </div>
</div>
<%------------------------
    this is the container for all the popups in the page. they will need to be positioned with JavaScript
------------------------%>
<div class="PopupsContainer" id="casino-hall-popups">
<div class="Popup GamePopup" id="casino-game-popup">


</div>

<div class="Popup TooltipPopup" id="tooltipPopup">
<div class="PopupIcon">Info about this item:</div>
<span class="PopupText">This is some info about this item</span>
</div>

</div>
<%= this.ClientTemplate("GameListItem", "casino-game-item", new { isLoggedIn = Profile.IsAuthenticated })%>
<%= this.ClientTemplate("CategoryTab", "casino-category-tab")%>
<%= this.ClientTemplate("/Casino/Hall/GameNavWidget/GamePopup", "casino-game-popup-template", new { vendors = this.VendorDic, isLoggedIn = Profile.IsAuthenticated })%>

<script type="text/javascript">
    var GameManager = (function () {
        var isAvailableLogin = <%= (Profile.IsAuthenticated && Profile.IsEmailVerified).ToString().ToLowerInvariant() %>;
        var game_datas = null, category_data = <%=this.categoryJson%>,
             _VendorData = {},_SelectedVendor=null,defaultVid=<%=this.defaultVid %>,
            isLoaded = false , _game_map={};
        
        function initData() {
            $.getJSON('<%= JsonUrl.SafeJavascriptStringEncode() %>', function (data) {
                data && (game_datas = data);
                vendor_Click(defaultVid);
                isLoaded=true;
            });
        }
        
        var PageNav=function(items){
            var self=this;
            this.totalPages=0;
            this.totalNumb=0;
            this.currentPage=0;
            this.size = <%=this.DefaultSize %>;
            this.Items=[];
            this.PageItems = [];
            this.disable_pre=false;
            this.disable_nex=false;
            this.init = function(options){
                if(options){
                    self.currentPage = 1;
                    self.totalNumb = options?options.length:0;
                    self.Items=options;
                    self.totalPages = Math.ceil(self.totalNumb/self.size)
                    self.disable_pre = true;
                    if(self.totalNumb > self.size){
                        self.PageItems = options.slice(0,self.size);
                    }else{
                        self.disable_nex=true;
                        self.PageItems = options;
                    }
                }
            };
            //function
            (function(){
                self.init(items);
            })();
            
            this.reset=function(items){
                if(typeof(items)==="undefined")return;
                
                self.Items=items;
                self.PageItems=[];
                self.totalNumb=0;
                self.totalPages=0;
                self.currentPage=1;
                self.disable_nex=false;
                self.disable_pre=false;
                self.init(items);
            };
            this.nex_click=function(){
                var c_n;
                if(!self.disable_nex){
                    self.disable_pre = false;
                    c_items = self.currentPage * self.size;
                    self.currentPage++;
                    if(self.currentPage == self.totalPages){
                        self.disable_nex = true;
                        c_n = self.currentPage * self.size;
                        self.PageItems=self.Items.slice(c_items,self.totalNumb);
                    }else if(self.currentPage<self.totalPages){
                        c_n = self.currentPage * self.size;
                        self.PageItems=self.Items.slice(c_items,c_items+self.size);
                    }
                }
                populate_Games(null);
            };
            this.pre_click=function(){
                var c_n;
                if(!self.disable_pre){
                    self.disable_nex = false;
                    self.currentPage--;
                    if(self.currentPage <= 1){
                        self.disable_pre = true;
                    }
                    c_n = self.currentPage * self.size;
                    self.PageItems = self.Items.slice((c_n-self.size),c_n);
                }
                populate_Games(null);
            };
        }
        function vendor_Click(id) {
            if(typeof(id)==="undefined")return;

            var t_v,t_gs,rlt_v={};

            if(_VendorData[id]){ 
                _SelectedVendor = _VendorData[id];
            }else{
                for (c in game_datas) {
                    t_gs = game_datas[c];
                    $.each(t_gs,function(i,g){
                        if(id===g.V){
                            if(!rlt_v[c]){
                                rlt_v[c]=[];
                            }
                            rlt_v[c].push(g);
                            if(!rlt_v.selectedId) rlt_v.selectedId = c;
                        }
                        _game_map[g.ID] = g;
                    });
                }
                rlt_v.pageNav = new PageNav(rlt_v[rlt_v.selectedId]);
                _SelectedVendor = _VendorData[id] = rlt_v;
            }
            //populate ui
            populate_Tabs(id);
            populate_Games(_SelectedVendor.selectedId);
        }
        function category_Click(id){
            _SelectedVendor.pageNav.reset(_SelectedVendor[id]);
            _SelectedVendor.selectedId = id;
            populate_Games(id);
        }
        function getCategoryNameById(id){
            if(typeof(id)==="undefined")return;

            var n=null;
            $.each(category_data,function(i,opt){
                if(opt.ID===id){
                    n = opt.Name;
                    return false;
                }
            })
            if(n==null) n=id;
            return n;
        }
        function positionPopup( $popup, $anchor ) {
            var pos = $anchor.offset();
            var left = Math.floor(pos.left);

            if ( left + $popup.width() > $(document.body).width() ) {
                var dx = ( $popup.width() + left ) - $(document.body).width();
                left = left - dx;
            }

            var top = Math.floor(pos.top-$("div.content").offset().top);

            $popup.css({ 'left' : (left-$("div#container").offset().left+15) + 'px', 'top' : top+'px' });

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
        function populate_Tabs(id){
            $("#categorys_section").html($('#casino-category-tab').parseTemplate(_SelectedVendor));

            if(!isLoaded){
                $(".gamestablistwidget .vendor_items").click(function(){
                    vendor_Click($(this).data('vendorid'));
                });
            }
            $(".gamestablistwidget .categorys_item").click(function(e){
                category_Click($(this).data('categoryid'));
            });
            if(id !== null){
                $(".vendor_items.selected").removeClass("selected");
                $(".gamestablistwidget .vendor_items[data-vendorid='"+id+"']").addClass("selected");
            }
            $("#casino-game-popup a.Close").trigger("click");
        }
        function populate_Games(id){
            $(".games_list_content").html($('#casino-game-item').parseTemplate((_SelectedVendor.pageNav.PageItems || [])));

            $(".gamestablistwidget .pagesinfo").html(_SelectedVendor.pageNav.currentPage+"/"+_SelectedVendor.pageNav.totalPages);
            $(".gamestablistwidget .games_list_content>li").click(function(){

            });
            if(!isLoaded){
                $(".gamestablistwidget .pre_btn").click(function(){
                    _SelectedVendor.pageNav.pre_click();
                });
                $(".gamestablistwidget .nex_btn").click(function(){
                    _SelectedVendor.pageNav.nex_click();
                });
            }
            bindPopupEvent($(".games_list_content"));
            if(id !== null){
                $(".categorys_item.selected").removeClass("selected");
                $(".gamestablistwidget .categorys_item[data-categoryid='"+id+"']").addClass("selected");
            }
            $("#casino-game-popup a.Close").trigger("click");
        }
        // <%-- the game info popup --%>
        function bindPopupEvent($containers){
            
            $('a.GameThumb,a.Game', $containers).click( function(e){
                e.preventDefault();
                var $anchor = $(this).parents('.GLItem');
                var game = _game_map[$anchor.data('gameid')];

                var $popup = $('#casino-game-popup');
                var html = $('#casino-game-popup-template').parseTemplate(game);
                
                $popup.empty().html( html );
                $popup.show();
                positionPopup( $popup, $anchor);

                $('#casino-game-popup a.Close').click( function(e){
                    e.preventDefault();
                    $('#casino-game-popup').hide();
                });

                

                $('#casino-game-popup .AddFav a').click( function(e){
                    e.preventDefault();
                    var url = '/Casino/Lobby/AddToFavorites';

                    $.getJSON( url, { gameID : game.ID }, function(){
                        $('#casino-game-popup .AddFav').addClass('Hidden');
                        $('#casino-game-popup .RemoveFav').removeClass('Hidden');
                        $('#casino-game-popup span.GTfav').removeClass('Hidden');

                        $(document).trigger( 'GAME_ADDED_TO_FAV', game.ID);
                    });
                });

                $('#casino-game-popup .RemoveFav a').click( function(e){
                    e.preventDefault();
                    var url = '/Casino/Lobby/RemoveFromFavorites';
                    $.getJSON( url, { gameID : game.ID }, function(r){
                        $('#casino-game-popup .AddFav').removeClass('Hidden');
                        $('#casino-game-popup .RemoveFav').addClass('Hidden');
                        $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav').addClass('Hidden');
                        $('#casino-game-popup span.GTfav').addClass('Hidden');
                        game.Fav = 0;
                        removeFavGame(game);
                    });
                });

                $('#casino-game-popup li.Info.GOItem a').click( function(e){
                    e.preventDefault();
                    var url = '/Casino/Game/Rule/' + game.S;
                    window.open(url
                        , 'game_rule'
                        , 'width=300,height=200,menubar=0,toolbar=0,location=0,status=1,resizable=1,centerscreen=1'
                        );
                });

                // <%-- play buttons --%>
                function showAdditional(real){

                    if( (!isAvailableLogin && real) ||
                        (game.C == null && real && game.R != 1) ||
                        (game.C == null && !real && game.F != 1) ){
                        //{'a':'c'}
                        $(document).trigger( 'OPEN_OPERATION_DIALOG',{'returnUrl':'/Casino/Game/Info/'+ game.S} );
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

                    var $extra = $('#casino-game-popup .PopupAdditional');
                    if( $extra.length == 0 ){
                        _openCasinoGame( game.S, real == true);
                    }
                    else{
                        $extra.show();
                        $('ol.GameVariants a.GVLink').off( 'click' );
                        $('ol.GameVariants a.GVLink').on( 'click', function(e){
                            e.preventDefault();
                            _openCasinoGame( $(this).data('gameid'), real == true);
                        });
                    }
                }

                $('#casino-game-popup .Fun a').click( function(e){
                    e.preventDefault();
                    showAdditional(false);
                });

                $('#casino-game-popup a.CTAButton').click( function(e){
                    e.preventDefault();
                    showAdditional(true);
                });
            });
        }

        //init data
        initData();
        return {
            GetCategoryNameById:getCategoryNameById
        }
    })();
</script>
