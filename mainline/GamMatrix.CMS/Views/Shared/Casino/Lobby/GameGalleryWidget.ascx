<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<CasinoEngine.Game>>" %>

<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>

<div class="Box GameGallery">
	<h2 class="BoxTitle GameGalleryTitle">
		<span class="TitleIcon">&sect;</span>

		<strong class="TitleText">
            <%= this.GetMetadata(".Title").SafeHtmlEncode() %>
        </strong>
	</h2>
	<ul class="GameGalleryControl Controls">
		<li class="Prev">
			<a href="#" class="PreviousLink" title="<%= this.GetMetadata(".Previous_Game").SafeHtmlEncode()%>">&#9668;</a>
		</li>
		<li class="Next">
			<a href="#" class="NextLink" title="<%= this.GetMetadata(".Next_Next").SafeHtmlEncode()%>">&#9658;</a>
		</li>
	</ul>
	<div class="GameGalleryCanvas">
		<ul class="GameGalleryList">

    <%  foreach( Game game in this.Model )
        { %>
                
			<% Html.RenderPartial("GameBoxWidget_ListItem", game); %>
    <%  } %>

		</ul>
	</div>
</div>

<script type="text/javascript">
    $(function () {
        $('div.GameGallery img.GT').each(function (i, el) {
            var src = $(el).data('image');
            $(el).attr('src', src);

            $('div.GameGallery ul.GameGalleryControl a.PreviousLink').click(function (e) {
                e.preventDefault();
            });

            $('div.GameGallery ul.GameGalleryControl a.NextLink').click(function (e) {
                e.preventDefault();
            });

            var direction = 0;
            $('div.GameGallery ul.GameGalleryControl a.PreviousLink').mouseover(function (e) {
                direction = -1;
                startAnimation();
            });

            $('div.GameGallery ul.GameGalleryControl a.NextLink').mouseover(function (e) {
                direction = 1;
                startAnimation();
            });

            $('div.GameGallery ul.GameGalleryControl a.NextLink,div.GameGallery ul.GameGalleryControl a.PreviousLink').mouseout(function (e) {
                direction = 0;
            });

            function startAnimation() {
                if ($('div.GameGallery ul.GameGalleryList li:animated').length > 0)
                    return;

                if (direction == 0) {
                    return;
                }
                if (direction < 0) {
                    var $first = $('div.GameGallery ul.GameGalleryList > li:first');
                    $first.clone(true).appendTo($('div.GameGallery ul.GameGalleryList'));
                    $first.animate({ 'marginLeft': -1 * $first.width() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () { $(this).remove(); $('div.GameGallery ul.GameGalleryList li:animated').stop(); startAnimation(); }
                });
                }
                else {
                    var $last = $('div.GameGallery ul.GameGalleryList > li:last');
                    var $first = $last.clone(true).prependTo($('div.GameGallery ul.GameGalleryList'));
                    $first.css('marginLeft', -1 * $last.width());
                    $first.animate({ 'marginLeft': 0 }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () { $('div.GameGallery ul.GameGalleryList > li:last').remove(); $('div.GameGallery ul.GameGalleryList li:animated').stop(); startAnimation(); }
                });
                }
            }

        });

        $("div.GameGallery ul.GameGalleryList").find("a.BtnPlayReal").unbind("click").click(function (evt) {
        <% 
        if( !Profile.IsAuthenticated )
        { %>
            evt.preventDefault();
            alert( '<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>' );
            return false;
        <%} %>
        });

        $("div.GameGallery ul.GameGalleryList").find("a.BtnPlayFun").unbind("click").click(function (evt) {
        <% 
        if( !Profile.IsAuthenticated )
        { %>
            var $li = $(this).parents('li[data-gameID]');
            var isAnonymousFunModeEnabled = $li.data('isAnonymousFunModeEnabled') || $li.attr('data-isAnonymousFunModeEnabled');
            if(isAnonymousFunModeEnabled != "1")
            {
                evt.preventDefault();
                alert( '<%= this.GetMetadata(".FunModelAnonymousMessage").SafeJavascriptStringEncode() %>' );
                return false;
            }
        <%} %>
        });
    });
</script>