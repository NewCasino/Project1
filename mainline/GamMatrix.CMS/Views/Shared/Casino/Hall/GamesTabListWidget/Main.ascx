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

    private bool ShowPopupOnMouseHover
    {
        get
        {
            var result = false;

            try
            {
                result = (bool)this.ViewData["ShowPopupOnMouseHover"];
            }
            catch
            {
                result = false;
            }

            return result;
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
    private int DefaultSize
    {
        get
        {
            string strSize = (this.ViewData["DefaultSize"] as string) ?? "9";
            return int.Parse(strSize);
        }
    }
    private string defaultVender = string.Empty;
    private string DefaultVender
    {
        get
        {
            if (string.IsNullOrEmpty(defaultVender))
            {
                HttpCookie cookie = Request.Cookies["_vvv"];
                if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                {
                    defaultVender = cookie.Value;
                }
                else
                {
                    defaultVender = this.ViewData["DefaultVender"] as string;
                }
            }
            return defaultVender;
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
    private int intDefaultVid = -1;
    private string strCurrentCategory = string.Empty;
    Dictionary<string, string> VendorDic = null;
    
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        strCurrentCategory = this.ViewData["CurrentCategory"] as string;
        if (string.IsNullOrEmpty(strCurrentCategory))
        {
            HttpCookie cookie = Request.Cookies["_ccc"];
            if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                strCurrentCategory = cookie.Value;
            else
                strCurrentCategory = string.Empty;
        }
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
        vendors = SortTheVendor(vendors);

        html.Append("<li class='vendor_items' data-vendorid='all'><label class='vendorLabel' title='All'>" + this.GetMetadata(".All").DefaultIfNullOrEmpty("All") + "</label></li>");
        for (int i = 0; i < vendors.Length; i++)
        {
            string strStyle = string.Empty;
            VendorInfo vendor = vendors[i];
            int vid = (int)vendor.VendorID;
            
            string name = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, ".Vendor_{0}", vendor.VendorID.ToString()))
                .DefaultIfNullOrEmpty(vendor.VendorID.ToString());

            if (i == 0 ||
                string.Compare(vid.ToString(), DefaultVender, false) == 0)
            {
                intDefaultVid = vid;
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
    private VendorInfo[] SortTheVendor(VendorInfo[] vendors)
    {
        string[] v_paths = Metadata.GetChildrenPaths("/Casino/Hall/GamesTabListWidget/Vendors");
        List<VendorInfo> lstVendors=new List<VendorInfo>();
        VendorInfo vendor = null;
        string v_id = string.Empty;

        if (v_paths.Length == 0)
            return vendors;
        foreach (string p in v_paths)
        {
            v_id=this.GetMetadata(p+".ID");
            try
            {
                vendor = vendors.SingleOrDefault(c =>
                {
                    if (string.Compare(v_id, c.VendorID.ToString(),true)==0)
                        return true;
                    else
                        return false;
                });
            }
            catch
            {
                vendor = null;
            }
            if (vendor != null)
                lstVendors.Add(vendor);
        }
        return lstVendors.ToArray();
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
<div class="Popup GamePopup" id="casino-game-popup">	
</div>
<%= this.ClientTemplate("GameListItem", "casino-game-item", new { isLoggedIn = Profile.IsAuthenticated })%>
<%= this.ClientTemplate("CategoryTab", "casino-category-tab")%>
<%= this.ClientTemplate("/Casino/Hall/GameNavWidget/GamePopup", "casino-game-popup-template", new { vendors = this.VendorDic, isLoggedIn = Profile.IsAuthenticated })%>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    var GameManager = (function () {
        var showPopupOnMouseHover = <%= ShowPopupOnMouseHover ? "true" : "false" %>;

        var mouse = {x: 0, y: 0};
        var popupOpened = false;

        var gamePopup = $('#casino-game-popup');

        if (showPopupOnMouseHover == true){
            $(document).mousemove(function(e){ 
                mouse.x = e.pageX; 
                mouse.y = e.pageY;

                if (gamePopup.css('display') == 'block'){
                    var width = gamePopup.outerWidth(false);
                    var height = gamePopup.outerHeight(false);
                    var left = parseFloat(gamePopup.css('left'));
                    var top = parseFloat(gamePopup.css('top'));

                    if (mouse.x < left || mouse.x > left + width ||
                        mouse.y < top || mouse.y > top + height){
                        popupOpened = false;
                        gamePopup.hide();
                    }
                }
            });

            gamePopup.mouseout(function(event){
                if (popupOpened){
                    var width = gamePopup.outerWidth(false);
                    var height = gamePopup.outerHeight(false);
                    var left = parseFloat(gamePopup.css('left'));
                    var top = parseFloat(gamePopup.css('top'));

                    if (mouse.x > left && mouse.x < left + width &&
                        mouse.y > top && mouse.y < top + height){
                        return;
                    }

                    popupOpened = false;
                    gamePopup.hide();
                }
            });
        }

        var isAvailableLogin = <%= (Profile.IsAuthenticated && Profile.IsEmailVerified).ToString().ToLowerInvariant() %>;
        var game_datas = null, category_data = <%=this.categoryJson%>,
             _VendorData = {},_SelectedVendor=null,defaultVid=<%=this.intDefaultVid %>,
            isLoaded = false , _game_map={},defaultCategory="<%=this.strCurrentCategory %>",
            _delayTime=10;
        var Ratings={
            data:[],
            maps:{},
            levels:[{rate:'0.1',lvl:1},{rate:'0.25',lvl:2},{rate:'0.3',lvl:3},{rate:'0.25',lvl:4},{rate:'0.1',lvl:5}],
            //function
            init:function(){
                var self=this,lth = self.data.length+1,min=0,max=0,rate_s=0,rate_m=0;
                self.data.sort(function(a,b){
                    if(a.P>b.P)
                        return 1;
                    else
                        return -1;
                });
                $.each(self.levels,function(i,opt){
                    opt.min = rate_m;
                    rate_s += +opt.rate;
                    opt.max = Math.ceil(lth*rate_s);
                    rate_m = opt.max;
                });
                $.each(self.data,function(i,opt){
                    $.each(self.levels,function(l_i,l_opt){
                        if(i>=l_opt.min && i<l_opt.max){
                            self.maps[opt.ID] = l_opt.lvl;
                            return false;
                        }
                    })
                })
            },
            getLevelById:function(id){
                if(typeof(id)==="undefined") return 0;
                var self=this,index = -1;
                return self.maps[id] || 0;
            }
        };

        function initData() {
            $.getJSON('<%= JsonUrl.SafeJavascriptStringEncode() %>', function (data) {
                data && (game_datas = data);
                vendor_Click(defaultVid);
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

            var t_v,t_gs;

            if(!isLoaded){
                var allVendor = {};
                var rlt_v={};
                for (c in game_datas) {
                    t_gs = game_datas[c];
                    $.each(t_gs,function(i,g){
                        if(!_VendorData[g.V]){
                            _VendorData[g.V] = {};
                        }
                        rlt_v = _VendorData[g.V];
                        if(!rlt_v[c]){
                            rlt_v[c]=[];
                        }

                        if (!allVendor[c]){
                            allVendor[c]=[];
                        }

                        rlt_v[c].push(g);
                        allVendor[c].push(g);

                        _game_map[g.ID] = g;
                        if(!rlt_v.selectedId){
                            rlt_v.selectedId = c;
                            allVendor.selectedId = c;
                        }
                        if(c === self.defaultCategory){
                            rlt_v.selectedId = c;
                            allVendor.selectedId = c;
                        }
                        Ratings.data.push({ID:g.ID,P:g.P});
                    });
                }
                _VendorData['all'] = allVendor;
            }
            Ratings.init();
            _SelectedVendor = _VendorData[id];
            if(!isLoaded){
                _SelectedVendor = _VendorData["all"];
                defaultVid = "all";
                id="all";
            }
            if(!_SelectedVendor){
                alert("<%:this.GetMetadata(".NoDataInVendor").HtmlEncodeSpecialCharactors() %>");
                return;
            }
            if(!_SelectedVendor.pageNav){
                _SelectedVendor.pageNav = new PageNav(_SelectedVendor[_SelectedVendor.selectedId]);
            }
            //populate ui
            setTimeout(function(){
                populate_Tabs(id);
                populate_Games(_SelectedVendor.selectedId);
                isLoaded=true;
            },_delayTime);
            $.cookie('_vvv', id);
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
        function getLevelById(id){
            return Ratings.getLevelById.call(Ratings,id);
        }
        function populate_Tabs(id){
            $("#categorys_section").html($('#casino-category-tab').parseTemplate(_SelectedVendor));

            if(!isLoaded){
                $(".gamestablistwidget .vendor_items").click(function(e){
                    vendor_Click($(this).data('vendorid'));
                });
            }
            $(".gamestablistwidget .categorys_item>a").click(function(e){
                e.preventDefault();
                var cid = $(this).parent().data('categoryid');
                $.cookie("_ccc",cid)
                category_Click(cid);
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

            if (showPopupOnMouseHover){
                $(".games_list_content .GLItem").mouseenter(function() {
                    popupOpened = true;
                    $(this).find('.GameThumb').click();
                });
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
                
                $popup.empty().html( html ).appendTo("body").show();
                GameManager.positionPopup( $popup, $anchor);

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
                        , 'width=400,height=200,menubar=0,toolbar=0,location=0,status=1,resizable=1,centerscreen=1'
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
        var self = {
            GetCategoryNameById:getCategoryNameById,
            GetLevelById:getLevelById,
            VendorClick: vendor_Click,
            VendorClickedCallback: null,
            CategoryClick: category_Click,
            defaultVid: defaultVid,
            defaultCategory: "<%=this.strCurrentCategory %>"
        };

        return self;
    })();
    GameManager.positionPopup=function( $popup, $anchor ) {
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
</script>
</ui:MinifiedJavascriptControl>
