<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<BingoRoom>>" %>

<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Bingo" %>
<script runat="server" language="C#" type="text/C#">
    public bool RefreshAutomatilly { get; set; }
    private int _RefreshRate = 20;
    public int RefreshRate { get { return _RefreshRate; } set { _RefreshRate = value; } }
    protected List<BingoRoom> BingoRooms
    {
        get {
            return ViewData.Model?? new List<BingoRoom>();       
        }
    }
    //arrows,bar
    private string _ScrollBarStyle = "arrows";
    public string ScrollBarStyle {
        get {
            if (this.ViewData["ScrollBarStyle"] !=null)
                _ScrollBarStyle= this.ViewData["ScrollBarStyle"].ToString();
            return _ScrollBarStyle;
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);       
    }
</script>

<div id="bingoroom" class="bingoroom bingoroom_<%=this.ViewData["Model"] %>">
    <div id="bingoroom-head"><asp:Literal ID="Literal1" runat="server" Text="<%$ Metadata:value(.BingoRooms) %>"></asp:Literal></div>
    <div id="bingoroom-body">
    <div class="bingroom-title">
        <div class="bingroom-title-type"><%=this.GetMetadata(".Type").SafeHtmlEncode()%></div>
        <div class="bingroom-title-room"><%=this.GetMetadata(".Room").SafeHtmlEncode()%></div>
        <div class="bingroom-title-jackpot"><%=this.GetMetadata(".Jackpot").SafeHtmlEncode()%></div>
        <div class="bingroom-title-win"><%=this.GetMetadata(".Winnings").SafeHtmlEncode()%></div>
        <div class="bingroom-title-price"><%=this.GetMetadata(".Price").SafeHtmlEncode()%></div>
        <div class="bingroom-title-num"><%=this.GetMetadata(".Num").SafeHtmlEncode()%></div>
        <div class="bingroom-title-start"><%=this.GetMetadata(".Start").SafeHtmlEncode()%></div>
        <div class="bingroom-title-button">
        </div>
    </div>
    <div class="bingoroom-list-wrapper">
        <div id="bingoroom-list" class="bingoroom-list">
            <ul>
<%
    var roomIndex = 0;
    foreach (BingoRoom room in BingoRooms)
{ %>
<li>
    <div class="bingroom-list-field bingroom-list-type bingotype<%=room.roomTypeField %>">&nbsp;</div>
    <div class="bingroom-list-field bingroom-list-room"><%=room.roomNameField %></div>
    <div class="bingroom-list-field bingroom-list-jackpot"><%=room.jackpotField %><%=room.currencyCodeField %></div>
    <div class="bingroom-list-field bingroom-list-win"><%=room.bingoPrizesField %><%=room.currencyCodeField %></div>
    <div class="bingroom-list-field bingroom-list-price"><%=room.cardPriceField %><%=room.currencyCodeField %></div>
    <div class="bingroom-list-field bingroom-list-num"><%=room.numPlayersField %></div>
    <div class="bingroom-list-field bingroom-list-start" id="bingo-start-<%=roomIndex%>"><%=room.nextStartField %></div>
    <div class="bingroom-list-field bingroom-list-button">
    <a onclick="this.blur(); onPlayClicked('<%=room.roomIdField %>', '<%=room.roomNameField.SafeJavascriptStringEncode() %>');return false;" class="linkbutton" target="_self" href="#" id="A1">
    <span class="linkbutton_Right">
        <span class="linkbutton_Left">
            <span class="linkbutton_Center">
                <span><%=this.GetMetadata(".Button_Play")%></span>
            </span>
        </span>
    </span>
    </a>               
    </div>
</li>
<% roomIndex++;} %>
</ul>
        </div>
        <%if (ScrollBarStyle.Equals("arrows", StringComparison.OrdinalIgnoreCase))
          {%>
        <div class="bingoroom-list-scroll">
            <a class="bingroom-scroll-up" href="javascript:void(0)"></a> <a class="bingroom-scroll-down" href="javascript:void(0)"></a>
        </div>
        <%}%>
        <div style="clear: both;"></div>
     </div>
     </div>
</div>

<script type="text/javascript" src="/js/jquery/jScrollPane-1.2.3.min.js"></script>

<script type="text/javascript" language="javascript">
        onPlayClicked = function(roomID, roomName) {
            //<% if( !ProfileCommon.Current.IsAuthenticated ) { %>
            alert('<%= this.GetMetadata(".Anonymous_User").SafeJavascriptStringEncode() %>');
            //<% } else { %>
            var url = '/bingo/loader?roomID=' + roomID;
            window.open(url, '_blank', "status=0,toolbar=0,menubar=0,location=0,width=800,height=600");
            //$('#ifmBingoRoom').attr('src', url).width(980).height(699).modalex(980, 699);
            //<% } %>
        };

    function BingoRoomUtility<%=this.ViewData["Model"] %>() {
        var _this = this;
        
        this.refreshRate = <%=RefreshRate %>;

        this.container= $(".bingoroom_<%=this.ViewData["Model"] %>")
        
        this.roomlist = this.container.find(".bingoroom-list");
        this.roomslide = this.container.find("#bingoroom-slider");

        this.scrollStyle = "<%=ScrollBarStyle.SafeJavascriptStringEncode() %>";
        this.scrollBar = this.container.find(".bingo-scroll-bar");
        this.scrolltop = this.container.find(".bingroom-scroll-up");
        this.scrolldown = this.container.find(".bingroom-scroll-down");

        this.scrollBarIsCatched = false;
        this.scrollBarStartedX = 0;
        this.slideItemCount = 0;
        this.singleHeight = 45;

        this.scrollNum = 5;
        
        this.getSecondForStart =function(){
            $.each(_this.roomlist.find("div.bingroom-list-start"), function(i,n){
                var timeHolder = $(n);
                var startTime = new Date(timeHolder.html()).getTime();
                var d = new Date();
                var nowTime = d.getTime();
                nowTime = d.getTimezoneOffset()*60000+nowTime;
                
                var difftime = startTime-nowTime;
                if(difftime<=0)
                {
                    timeHolder.html('<%=this.GetMetadata("Started").ToString().SafeJavascriptStringEncode() %>');
                }
                else
                {                       
                    d = new Date(d.getTime()+difftime);
                    var startHtml = d.getHours()+":";
                    var mins = d.getMinutes();
                    startHtml+= mins<10?"0"+mins:mins;
                    timeHolder.html(startHtml);
                }              
            });
            
        };
                        
        this.onScrollUp = function() {
            _this.roomlist.filter(':not(:animated)').animate({ scrollTop: '-=' + _this.singleHeight * _this.scrollNum }, 500, function() {
            });
        };

        this.onScrollDown = function() {
            _this.roomlist.filter(':not(:animated)').animate({ scrollTop: '+=' + _this.singleHeight * _this.scrollNum }, 500, function() {
            });
        };

        this.initScrollBar = function(){
            this.container.find(".bingoroom-list").jScrollPane({ '': true, scrollbarWidth: 5 });
            this.container.find(".bingoroom-list").find(".jspDragBottom").appendTo(this.container.find(".bingoroom-list").find(".jspDragTop"));
            this.container.find(".bingoroom-list").find(".jspDragBottom").height(this.container.find(".bingoroom-list").find(".jspDrag").height()-12);
        };
        
        this.RoomsHandle = function() {
            if (_this.roomlist.length > 0) {
                $.each(_this.roomlist.find("li"), function(i, n) {
                    var c_i = $(n);
                    c_i.mouseover(function() { c_i.addClass("cur") });
                    c_i.mouseout(function() { c_i.removeClass("cur") });
                });
            }
        };
       
        this.updateRooms = function() {
            this.container.find(".bingoroom-list").parent().load('<%= this.Url.RouteUrl( "Bingo", new { @action="Rooms"}).SafeJavascriptStringEncode() %>');
            _this.getSecondForStart();
            setTimeout("_this.updateRoomsForHorizontal()", 1000 * _this.refreshRate);
        };

        this.writeRooms = function(result) {
            var temphtml = $("#MyTemplete").parseTemplate(result);
            this.container.find(".bingoroom-list").html(temphtml);
            _this.roomlist = this.container.find(".bingoroom-list");
            _this.RoomsHandleForHorizontal();
        };

        this.init = function() {
            _this.getSecondForStart();
            //<%if(RefreshAutomatilly) {%>
            _this.updateRooms();
            //<%}else{ %>            
            _this.RoomsHandle();
            //<%} %>

            if(this.scrollStyle=="bar")
            {
                this.initScrollBar();
            }
            else
            {
                if (this.scrolltop.length > 0) this.scrolltop.click(this.onScrollUp);
                if (this.scrolldown.length > 0) this.scrolldown.click(this.onScrollDown);
            }
            this.singleHeight = this.roomlist.find("li").height();

        };        

        this.init();
    }
    $(function() { new BingoRoomUtility<%=this.ViewData["Model"] %>(); });
</script>
