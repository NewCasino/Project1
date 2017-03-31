<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="System.Globalization" %>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="LiveCasinoTab" id="<%= this.ID %>">
    <div class="LiveCasinoTabContainer">
        <div class="LiveCasinoTabTableContainer">
        </div>

        <div class="ControlBar">
			<ul class="ControllerButtons">
			    <li class="CB CBQuickDeposit"></li>
                <li class="CB CBFullScreen" style="display: none;">
				    <a class="Button" href="javascript:void(0)" title="<%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_FullScreen").SafeHtmlEncode() %>">
					    <span class="InfoIcon FullScreen"></span>
					    <span><%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_FullScreen").SafeHtmlEncode() %></span>
				    </a>
			    </li>
			    <li class="CB CBFav">
				    <a class="Button" href="javascript:void(0)" title="<%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_AddToFav").SafeHtmlEncode() %>">
					    <span class="InfoIcon AddToFav"></span>
					    <span><%= this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_AddToFav").SafeHtmlEncode() %></span>
				    </a>
			    </li>
            </ul>
            <% Html.RenderPartial("/Deposit/QuickDepositWidget/QuickDepositWidget", this.ViewData.Merge(new { RealMoney = true })); %>
        </div>
    </div>
</div>
    
<script type="text/C#" runat="server">
    
    private bool GetFavorites()
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

        var cfga = LiveCasinoFavoriteTableAccessor.CreateInstance<LiveCasinoFavoriteTableAccessor>();
        string[] favs = cfga.GetByUser(SiteManager.Current.DomainID, CM.State.CustomProfile.Current.UserID, clientIdentity).ToArray();
        return favs.Contains(Request.QueryString["tableID"]);
    }
    
</script>

<script>
    $(function () {
        var gameId = <%= Request.QueryString["tableID"] %>;
        var fav = <%= GetFavorites().ToString().ToLower() %>;

        setFavButtonState(fav);

        $('.ControllerButtons .CB.CBFav .Button').data('gameId', gameId);
        var container = $('.LiveCasinoTabTableContainer');
        if (container != null) {
            var $iframe = $('<iframe>', {
                src: '/LiveCasino/Hall/Start?tableID=' + gameId,
                id: 'LiveCasinoTabTableFrame',
                frameborder: 0,
                scrolling: 'auto',
            });

            $iframe.appendTo(container);
            //var w = screen.availWidth * 5 / 10;
            //var h = screen.availHeight * 5 / 10;
            //$iframe.width(w).height(h);
            
            
            $iframe.width($iframe.width()).height($iframe.height());

            //adjusting game window dimentions
            var fw = parseInt($iframe.width(), 10);
            var fh = parseInt($iframe.height(), 10) * 1.0;
            var finalHeight = container.width() * fh / fw;

            $iframe.width('100%');
            $iframe.height(finalHeight);
        }

        $(document).trigger('LIVECASINO_TABLE_TAB_GAME_LOADED', gameId);
    });

    var fullscreenButton = $('.ControllerButtons .CB.CBFullScreen');
    var fullScreenText = "<%=this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_FullScreen").SafeJavascriptStringEncode()%>";
    var exitFullScreenText = "<%=this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_ExitFullScreen").SafeJavascriptStringEncode()%>";

    $('.CB.CBFullScreen').click(function () {
        switchFullScreen();
    });

    function switchFullScreen() {
        if (fullscreenButton.hasClass("isfull")) {
            fullscreenButton.addClass('Actived');
            fullscreenButton.find('span').text(fullScreenText);
            fullscreenButton.find('.Button').attr('title', fullScreenText);
        } else {
            fullscreenButton.removeClass('Actived');
            fullscreenButton.find('span').text(exitFullScreenText);
            fullscreenButton.find('.Button').attr('title', exitFullScreenText);
        }

        EnterFullScreen('#<%= this.ID %>', fullscreenButton);
    }

    function EnterFullScreen(selector, target) {
        if (typeof (target) === "undefined" || !target) return;
        var elem = $(selector), hasApply = false;
        if (elem.length == 0)
            return;

        elem = elem.get(0);
        if (!target.hasClass("isfull")) {
            if (elem.requestFullscreen) {
                // This is how to go into fullscren mode in Firefox
                elem.requestFullscreen();
                hasApply = true;
            }
            else if (elem.mozRequestFullScreen) {
                // This is how to go into fullscren mode in Firefox
                elem.mozRequestFullScreen();
                hasApply = true;
            } else if (elem.webkitRequestFullscreen) {
                // This is how to go into fullscreen mode in Chrome and Safari
                elem.webkitRequestFullscreen();
                hasApply = true;
            } else if (elem.msRequestFullscreen) {
                elem.msRequestFullscreen();
                hasApply = true;
            } else {
                alert("Sorry, Fullscreen is not supported in your browser");
            }
            if (hasApply && !target.hasClass("isfull")) target.addClass("isfull");
        }
        else {
            if (document.cancelFullscreen) {
                document.cancelFullscreen();
                hasApply = true;
            }
            else if (document.mozCancelFullScreen) {
                document.mozCancelFullScreen();
                hasApply = true;
            }
            else if (document.webkitCancelFullScreen) {
                document.webkitCancelFullScreen();
                hasApply = true;
            }
            else if (document.msExitFullscreen) {
                document.msExitFullscreen();
                hasApply = true;
            }
            if (hasApply && target.hasClass("isfull")) target.removeClass("isfull");
        }
    }

    
    var addToFavText = "<%=this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_AddToFav").SafeJavascriptStringEncode()%>";
    var removeFromFavText = "<%=this.GetMetadata("/LiveCasino/Hall/GameNavWidgetV2/_Popup_ascx.Button_RemoveFav").SafeJavascriptStringEncode()%>";

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
</script>

</asp:Content>