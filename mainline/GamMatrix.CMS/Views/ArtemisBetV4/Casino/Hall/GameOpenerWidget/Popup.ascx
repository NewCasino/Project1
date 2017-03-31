<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
    private string ID { get; set; }
    protected override void OnPreRender(EventArgs e) {
        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        base.OnPreRender(e);
    }
</script>

<div class="CasinoGameOverlay" style="background-image:url(<%= this.Model.BackgroundImageUrl %>)" id="<%= this.ID %>">
    <div class="Wrapper1">
        <div class="Wrapper2">
            <div class="PopupContainer">
                <a class="ClosePopup" href="#" title="<%= this.GetMetadata(".Close_Tip").SafeHtmlEncode() %>">
                    <%= this.GetMetadata(".Close").SafeHtmlEncode() %>
                </a>
                <div class="PanelGameFrame">
                    <% Html.RenderPartial("/Casino/Hall/GameOpenerWidget/Game", this.Model, this.ViewData); %>
                </div>
                <div class="AddOnBar"></div>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    $(function () {
        var $c = $('#<%= this.ID %>');
        var $parent = $c.parent();
        $('body > div.CasinoGameOverlay').remove();
        $c.appendTo(document.body).fadeIn(700);
        $parent.remove();

        $(document).trigger('LOAD_CASINO_POPUP_ADDON_BAR', 
            { RealMoney : <%=  this.ViewData["RealMoney"].ToString().ToLowerInvariant() %>
            , Container: $('div.AddOnBar', $c)
            , GameID: '<%= this.Model.ID.SafeJavascriptStringEncode() %>' 
        });

        var pfnResize = function () {
            $iframe = $('iframe', $c);
            var h = $c.height() / 2;
            var w = $c.width() / 2;
            $iframe.height(h).width(w);
            $iframe.parent().width(w).height(h);
            var $ic = $('.PopupContainer', $c);
            var outerW = $ic.outerWidth(true) - w;
            var outerH = $ic.outerHeight(true) - h;

            var availableW = $c.width() - outerW;
            var availableH = $c.height() - outerH;

            w = parseInt($iframe.data('width'), 10);
            h = parseInt($iframe.data('height'), 10);

            var nW = availableW;
            var nH = h / (w * 1.0) * availableW;
            if (nH > availableH) {
                nH = availableH;
                nW = w / (h * 1.0) * availableH;
            }
            $iframe.width(nW).height(nH);
            $iframe.parent().width(nW).height(nH);
            $('div.AddOnBar', $c).width(nW);
        };
        pfnResize();
        $(window).bind('resize', pfnResize);

        $(document).trigger('POPUP_GAME_CLOSED');

        $('div.TitleBar  a.BackButton').remove();

        $('a.ClosePopup', $c).click(function (e) {
            e.preventDefault();
            $c.hide();
            $(window).unbind('resize', pfnResize);
            $(document).trigger('POPUP_GAME_CLOSED');
            $c.remove();
                $("html").removeClass("OverflowLock");
        });
 
    });
</script>

