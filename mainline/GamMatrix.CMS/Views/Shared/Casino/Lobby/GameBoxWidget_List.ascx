<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<CasinoEngine.GameRef>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="System.Globalization" %>
<script language="C#" type="text/C#" runat="server">
    private string WrapperID
    {
        get;
        set;
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
                return 250;
            }
        }
    }

    private SelectList GetPageSizeList()
    {
        List<int> list = new List<int>();
        
        string[] items = this.GetMetadata(".Page_Size_Option").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        foreach (string item in items)
        {
            int pageSize = 0;
            if (int.TryParse(item, NumberStyles.Integer, CultureInfo.InvariantCulture, out pageSize))
            {
                list.Add(pageSize);
            }
        }

        if (list.Count > 0)
            return new SelectList(list, list[0]);
        return new SelectList(new int[] { 15, 20, 25, 30 });
    }
</script>

<%
    this.WrapperID = "casinolobbygames";
 %>
 <!-- <%= "javascript:window.open".SafeHtmlEncode() %> -->
<!-- My IP = <%= Request.GetRealUserAddress().SafeHtmlEncode()  %> -->
<div id="<%=WrapperID%>">


<%-------------------------
    Games List Start
 -------------------------%>
<ol class="GamesList Grid">
<%
{
    foreach (GameRef gameRef in this.Model)
    {
        Game game = null;

        if (!gameRef.IsGameGroup)
        {
            game = gameRef.Game;
        }
        else
        {
            int numberOfAlternates = gameRef.Children.Count;
            if (numberOfAlternates == 0)
                continue;

            if (numberOfAlternates == 1)
            {
                game = gameRef.Children[0].Game;
            }
            else if (numberOfAlternates > 1)
            {  %>

                <%---------------------------- Game Group Start ------------------------%>
			    <li class="GLItem GLMultiple" data-gameID="<%= gameRef.ID %>">
				    <div class="GameThumb">
					    <ul class="GTPopup">
						    <li class="GTPItem GTPLarge">
							    <a href="#" class="GTPLink" title="<%= this.GetMetadataEx(".See_Alternates_Tip_Format").SafeHtmlEncode()%>">
                                    <span class="ActionIcon Variants">&#9658;</span> 
                                    <%= this.GetMetadataEx(".See_Alternates_Format", numberOfAlternates).HtmlEncodeSpecialCharactors()%>
                                </a>
						    </li>
					    </ul>
					    <div class="GTPopupVariants">
						    <ol class="GamesList Grid">
                            
                        <%
                            foreach (GameRef childRef in gameRef.Children)
                            {
                                if (childRef.Game == null)
                                    continue;
                            %>
                        
                            <%---------------------------- Normal Game Start ----------------------------%>
			                <% Html.RenderPartial("GameBoxWidget_ListItem", childRef.Game, this.ViewData); %>
                            <%---------------------------- Normal Game End ----------------------------%>					

                    <%  } %>

						    </ol>
					    </div>
					    <img class="GT" src="<%= gameRef.ThumbnailUrl.SafeHtmlEncode() %>" width="120" height="70" alt="<%= gameRef.ShortName.SafeHtmlEncode() %>" />
				    </div>
				    <h3 class="GameTitle">
					    <a href="#" class="InfoIcon GameInfo" title="<%= gameRef.Description.SafeHtmlEncode() %>">
                            <%= this.GetMetadata(".Info").SafeHtmlEncode()%>
                        </a>
					    <a href="#" class="Game" title="<%= this.GetMetadataEx(".See_Alternates_Tip_Format", numberOfAlternates).SafeHtmlEncode()%>">
                            <%= gameRef.ShortName.SafeHtmlEncode()%>
                            <sup class="MoreVariants">(<%= numberOfAlternates%>)</sup>
                        </a>
				    </h3>
			    </li>
                <%---------------------------- Game Group End ----------------------------%>
                    
        <%    
                continue;
            } // if (numberOfAlternates > 1) end  
        } // if_else

        if (game != null)
        { %>
            <%---------------------------- Normal Game Start ----------------------------%>
			<% Html.RenderPartial("GameBoxWidget_ListItem", game, this.ViewData); %>
            <%---------------------------- Normal Game End ----------------------------%>
<%          }
                
    }// foreach
}%>
</ol>
<%-------------------------
    Games List End
 -------------------------%>


<div class="GamesControls">
	<a href="#" class="Button PrevButton" title="<%= this.GetMetadata(".Button_Previous_Tip").SafeHtmlEncode()%>">
        <span class="ActionSymbol">&#9668;</span>
        <%= this.GetMetadata(".Button_Previous_HTML").HtmlEncodeSpecialCharactors()%>
    </a>
	<a href="#" class="Button NextButton" title="<%= this.GetMetadata(".Button_Next_Tip").SafeHtmlEncode()%>">
        <%= this.GetMetadata(".Button_Next_HTML").HtmlEncodeSpecialCharactors()%>
        <span class="ActionSymbol">&#9658;</span>
    </a>
	<form class="Main" action="#" method="get" onsubmit="return false">
		<fieldset>
			<label class="GCSelector" for="gamesNumber">
				<span class="GCText"><%= this.GetMetadata(".Viewing").SafeHtmlEncode()%></span>
                <%: Html.DropDownList("pageSize", GetPageSizeList(), new { @id = "gamesNumber", @class = "GCSelect PageSizeSelect", @size = "1" })%>
				<span class="GCText PaginationText">
                </span>
			</label>
		</fieldset>
	</form>
</div>

</div>



<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    var isAvailableLogin = <%= (Profile.IsAuthenticated && Profile.IsEmailVerified).ToString().ToLowerInvariant() %>;

    $(document).bind('OPEN_OPERATION_DIALOG', function () {
        $('iframe.CasinoHallDialog').remove();
        $('<iframe style="border:0px;width:<%=DialogWidth %>px;height:<%=DialogHeight %>px;display:none" frameborder="0" scrolling="no" src="/Casino/Hall/Dialog?_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo(top.document.body);
        var $iframe = $('iframe.CasinoHallDialog', top.document.body).eq(0);
        $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
    });

    function __updateGamePage() {
        var items = $('#<%=WrapperID %> > ol.GamesList > li');

        // <%-- adjust visibilities --%>
        if (items.length == 0) {
            $('div.GamesControls > *', $('#<%=WrapperID %>')).css('visibility', 'hidden');
        }
        else {
            $('div.GamesControls > *', $('#<%=WrapperID %>')).css('visibility', 'visible');
            $('#<%=WrapperID %> div.GamesControls').show();
            $('#<%=WrapperID %> > ol.GamesList > li').hide();
            var pageSize = $('select.PageSizeSelect', $('#<%=WrapperID %>')).val();
            var totalPageNum = Math.ceil(items.length / (1.0 * pageSize));
            var pageIndex = $('#<%=WrapperID %>').data("pageIndex") || 0;
            if (pageIndex < 0) pageIndex = 0;
            if (pageIndex >= totalPageNum) pageIndex = totalPageNum - 1;

            var endIndex = Math.min(items.length, (pageIndex + 1) * pageSize);
            for (var i = pageIndex * pageSize; i < endIndex; i++) {
                $(items[i]).show();
                var $img = $('img.GT', items[i]);
                $img.attr('src', $img.data('image') || $img.attr('data-image'));
            }

            // <%-- pre button visibility --%>
            if (pageIndex == 0)
                $('a.PrevButton', $('#<%=WrapperID %>')).css('visibility', 'hidden');
            else
                $('a.PrevButton', $('#<%=WrapperID %>')).css('visibility', 'visible');

            // <%-- next button visibility --%>
            if (pageIndex >= totalPageNum - 1)
                $('a.NextButton', $('#<%=WrapperID %>')).css('visibility', 'hidden');
            else
                $('a.NextButton', $('#<%=WrapperID %>')).css('visibility', 'visible');

            // <%-- update pagination text 
            // {0} / {1} (<span class="PageItems">{2} &ndash; {3}</span> out of <span class="TotalPageNum">{4}</span> shown).
            // --%>
            var format = '<%= this.GetMetadata(".Pagination_HTML").SafeJavascriptStringEncode() %>';
            format = format.replace(/(\{0\})/g, (pageIndex + 1).toString(10));
            format = format.replace(/(\{1\})/g, totalPageNum.toString(10));
            format = format.replace(/(\{2\})/g, Math.min(pageIndex * pageSize + 1, items.length).toString(10));
            format = format.replace(/(\{3\})/g, ((pageIndex + 1) * pageSize).toString(10));
            format = format.replace(/(\{4\})/g, items.length.toString(10));
            $('#<%=WrapperID %> span.PaginationText').html(format);

            $(document).trigger( 'GAME_BOX_PAGE_UPDATED', {
                container: $('div.GamesControls', $('#<%=WrapperID %>')),
                pageIndex: pageIndex,
                totalPageNum: totalPageNum,
                wrapper: $('#<%=WrapperID %>')
            });
        }


    };

    function __setGames($container) {
        $('#<%=WrapperID %>').data("pageIndex", 0);
        $('> li', $container).detach().appendTo($('#<%=WrapperID %> > ol.GamesList').empty());
        __updateGamePage();

        // <%-- the popup event --%>
        $('.GTPLarge .GTPLink', $('#<%=WrapperID %>')).click(function (event) {
            event.preventDefault();
            $(this).parents('.GLMultiple').addClass('GTPVShow');
            return false;
        });
        $('.GTPLarge .GTPLink', $('#<%=WrapperID %>')).parents(".GLMultiple").find(".GameTitle a").click(function (event) {
            event.preventDefault();
            $(this).parents('.GLMultiple').addClass('GTPVShow');
            return false;
        });
        $('.GLMultiple', $('#<%=WrapperID %>')).delegate('.GTPopupVariants', 'mouseleave', function (event) {
            event.preventDefault();
            $(this).parents('.GLMultiple').removeClass('GTPVShow');
        });

        // <%-- play now button click event --%>
        $('ol.GamesList a.BtnPlayReal', $('#<%=WrapperID %>')).unbind('click').click(function (evt) {
<% 
    if( !Profile.IsAuthenticated )
    { %>
            evt.preventDefault();
            try {
                var gameid = $(this).parents(".GLItem").attr("data-gameid");
                showAdditional(true, gameid);
            } catch(e) {
                alert( '<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>' );
            }
            
            return;
<%  } %>

            var $li = $(this).parents('li[data-gameID]');
            var gameID = $li.data('gameID') || $li.attr('data-gameID');
            try {
                __loadGame(gameID, false);
                evt.preventDefault();
            }
            catch (e) {
                //alert(e);
            }
        });

        // <%-- play for fun button click event --%>
        $('ol.GamesList a.BtnPlayFun', $('#<%=WrapperID %>')).unbind('click').click(function (evt) {
            
            var $li = $(this).parents('li[data-gameID]');
            <% 
    if( !Profile.IsAuthenticated )
    { %>
            var isAnonymousFunModeEnabled = $li.data('isAnonymousFunModeEnabled') || $li.attr('data-isAnonymousFunModeEnabled');
            if(isAnonymousFunModeEnabled != "1")
            {
                evt.preventDefault();
                alert( '<%= this.GetMetadata(".FunModelAnonymousMessage").SafeJavascriptStringEncode() %>' );
                return;
            }
<%  } %>
            

            var gameID = $li.data('gameID') || $li.attr('data-gameID');
            try {
                __loadGame(gameID, true);
                evt.preventDefault();
            }
            catch (e) {
                //alert(e);
            }
        });


        // <%-- add favorite button click event --%>
        $('ol.GamesList a.BtnAddFavorite', $('#<%=WrapperID %>')).unbind('click').click(function (evt) {
            evt.preventDefault();
            var $li = $(this).parents('li[data-gameID]');
            var gameID = $li.data('gameID') || $li.attr('data-gameID');
            var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "AddToFavorites" }).SafeJavascriptStringEncode()%>';
            var found = false;
            for( var i = 0; i < GDATA["Favorites"].length; i++ ){
                if( GDATA["Favorites"][i] == gameID ){
                    found = true;
                    break;
                }
            }
            if( !found ) GDATA["Favorites"].push(gameID);
            var callback = (function (o) {
                return function () {
                    $('li.GLItem[data-gameID="' + o.scriptEncode() + '"] a.BtnAddFavorite').parent('li.GTPItem').fadeOut();
                };
            })(gameID);

            $.getJSON(url, { gameID: gameID }, callback);
        });

        // <%-- add favorite button click event --%>
        $('ol.GamesList a.BtnRemoveFavorite', $('#<%=WrapperID %>')).click(function (evt) {
            evt.preventDefault();
            var $li = $(this).parents('li[data-gameID]');
            var gameID = $li.data('gameID') || $li.attr('data-gameID');
            var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "RemoveFromFavorites" }).SafeJavascriptStringEncode()%>';
            for( var i = GDATA["Favorites"].length - 1; i >= 0; i-- ){
                if( GDATA["Favorites"][i] == gameID ){
                    GDATA["Favorites"].splice( i, 1);
                }
            }
            var callback = (function (o) {
                return function () {
                    $('#<%=WrapperID %> li.GLItem[data-gameID="' + o.scriptEncode() + '"]').fadeOut();
                };
            })(gameID);

            $.getJSON(url, { gameID: gameID }, callback);
        });
    }


    $(function () {
        // <%-- page size changed event --%>
        $('select.PageSizeSelect', $('#<%=WrapperID %>')).change(function () {
            var regex = /(\{0\})/g;
            var format = '<%= this.GetMetadata(".Button_Previous_HTML").SafeJavascriptStringEncode() %>';
            format = format.replace(regex, $(this).val());
            $('a.PrevButton', $('#<%=WrapperID %>')).html('<span class="ActionSymbol">&#9668;</span> ' + format);

            format = '<%= this.GetMetadata(".Button_Next_HTML").SafeJavascriptStringEncode() %>';
            format = format.replace(regex, $(this).val());
            $('a.NextButton', $('#<%=WrapperID %>')).html(format + ' <span class="ActionSymbol">&#9658;</span>');

            __updateGamePage();
        }).trigger('change');


        // <%-- pre button click event --%>
        $('a.PrevButton', $('#<%=WrapperID %>')).click(function (evt) {
            evt.preventDefault();
            var pageIndex = $('#<%=WrapperID %>').data("pageIndex") || 0;
            $('#<%=WrapperID %>').data("pageIndex", --pageIndex);
            __updateGamePage();
        });

        // <%-- next button click event --%>
        $('a.NextButton', $('#<%=WrapperID %>')).click(function (evt) {
            evt.preventDefault();
            var pageIndex = $('#<%=WrapperID %>').data("pageIndex") || 0;
            $('#<%=WrapperID %>').data("pageIndex", ++pageIndex);
            __updateGamePage();
        });
        __updateGamePage();

        
    });
</script>
</ui:MinifiedJavascriptControl>

