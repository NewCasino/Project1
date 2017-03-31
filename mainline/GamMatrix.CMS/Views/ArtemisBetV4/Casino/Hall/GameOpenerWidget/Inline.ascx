<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
    private string ID { get; set; }

    protected override void OnPreRender(EventArgs e)
    {
        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        base.OnPreRender(e);
    }
</script>

<div class="CasinoInlineGame" id="<%= this.ID %>">
    <% Html.RenderPartial("/Casino/Hall/GameOpenerWidget/Game", this.Model, this.ViewData); %>
</div>

<% Html.RenderPartial("/Deposit/QuickDepositWidget/QuickDepositWidget", this.ViewData.Merge(new { })); %>
<script type="text/javascript">
    jQuery(function () {

        jQuery('body').addClass('InlineGamePage');
        jQuery('.SliderCol').hide("500");
        jQuery('#show-Casinoslider').removeClass('hidden');
        jQuery('#close-Casinoslider').addClass('hidden');

        var $c = $('#<%= this.ID %>');

        var pfnResize = function (e) {
            var $iframe = $('iframe', $c);
            var w = parseInt($iframe.data('width'), 10);
            var h = parseInt($iframe.data('height'), 10) * 1.0;
            $iframe.height($iframe.width() * h / w);
        };
        pfnResize();

        $c.hide().fadeIn();
        $(document).trigger('INLINE_GAME_OPENED', [{ bgImg : '<%= this.Model.BackgroundImageUrl.SafeJavascriptStringEncode() %>' }]);

        $('a.BackButton', $c).click(function (e) {

            e.preventDefault();
            jQuery('body').removeClass('InlineGamePage');
            jQuery('.SliderCol').show("500");
            jQuery('#show-Casinoslider').addClass('hidden');
            jQuery('#close-Casinoslider').removeClass('hidden');

            $c.slideUp(function () {
                $(document).trigger('INLINE_GAME_CLOSED');
                $(this).remove();
            });
        });
    });
</script>