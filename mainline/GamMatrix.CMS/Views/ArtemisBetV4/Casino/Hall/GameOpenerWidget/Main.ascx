<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script type="text/C#" runat="server">
    /* Options
     * InlineContainerID    string, default = "casino-inline-game-container"
     * DialogWidth          int, default = 400
     * DialogHeight         int, default = 300
     */

    private string InlineContainerID {
        get { return (this.ViewData["InlineContainerID"] as string) ?? "casino-inline-game-container"; }
    }

    private int DialogWidth {
        get {
            try {
                return int.Parse(this.ViewData["DialogWidth"] as string, CultureInfo.InvariantCulture);
            } catch {
                return 400;
            }
        }
    }

    private int DialogHeight {
        get {
            try {
                return int.Parse(this.ViewData["DialogHeight"] as string, CultureInfo.InvariantCulture);
            } catch {
                return 300;
            }
        }
    }

    private bool GetAvailablity() {
        if (!Profile.IsAuthenticated)
            return false;
        if (!Profile.IsEmailVerified) {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(Profile.UserID);
            if (!user.IsEmailVerified)
                return false;
            else if (!Profile.IsEmailVerified)
                Profile.IsEmailVerified = true;
        }

        return true;
    }
</script>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    function _openCasinoGame(slug, real) {

        var isAvailable = <%= GetAvailablity().ToString().ToLowerInvariant() %>;
        if( real && !isAvailable ){ 
            $(document).trigger('OPEN_OPERATION_DIALOG',{'returnUrl':'/Casino/Game/Info/'+ slug});
            return false;
        }

        var openType = $.cookie('_cot');

        $(document).trigger('GAME_TO_BE_OPENED');
        var el = document.getElementById('<%= this.InlineContainerID.SafeJavascriptStringEncode() %>');
        if (el != null)
            $(el).empty();

        if (openType == 'inline') {
            if (el != null) {
                var url = '/Casino/Hall/Inline?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
                $(el).empty().load(url);
                return;
            }
        }

        if (openType == 'popup') {
            var url = '/Casino/Hall/Popup?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
            var $popup = $('<div></div>').appendTo(document.body);
            $popup.load(url);
            $("html").addClass("OverflowLock");
            return;
        }

        if (openType == 'fullscreen') {
            var w = screen.availWidth * 9 / 10;
            var h = screen.availHeight * 9 / 10;
            var l = (screen.width - w)/2;
            var t = (screen.height - h)/2;
            var params = [
                'height=' + h,
                'width=' + w,
                'fullscreen=no',
                'scrollbars=no',
                'status=yes',
                'resizable=yes',
                'menubar=no',
                'toolbar=no',
                'left=' + l,
                'top=' + t,
                'location=no',
                'centerscreen=yes'
            ].join(',');

            var url = '/Casino/Game/Play/?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
            try{
                window.open(url, 'casino_game_window_' + slug.replace('-','_'), params);
            }catch(err){
                window.open(url, 'casino_game_window_' + slug, params);
            }
            return;
        }

        var url = '/Casino/Game/Info/?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
        try{
            window.open(url, 'casino_game_page_' + slug.replace('-','_'));
        }catch(err){
            window.open(url, 'casino_game_page_' + slug);
        }
    }

    $(function () {
        $(document).bind('OPEN_OPERATION_DIALOG', function (e, data) {
            var url = '/Casino/Hall/Dialog?_=<%= DateTime.Now.Ticks %>';
            if( data != null && data.returnUrl != null ){
                url += "&returnUrl=" + encodeURIComponent(data.returnUrl);
            }
            $('iframe.CasinoHallDialog').remove();
            $('<iframe style="border:0px;width:<%=DialogWidth %>px;height:<%=DialogHeight %>px;display:none" frameborder="0" scrolling="no" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo( self.document.body);
            var $iframe = $('iframe.CasinoHallDialog', self.document.body).eq(0);
            $iframe.attr('src', url);
            $iframe.modalex($iframe.width(), $iframe.height(), true, self.document.body);
            if($(".simplemodal-wrap .CasinoHallDialog").length < 1){
                $('iframe.CasinoHallDialog', self.document.body).eq(0).show().appendTo($(".simplemodal-wrap"));
            }
            $iframe.parents('#simplemodal-container').addClass('simplemodal-login');
            try{ HideGameFlashFromGameWindow(); } catch(ex){}
            setTimeout(function () {
                $('.simplemodal-login a.simplemodal-close').click(function(){
                    try {
                        $('.simplemodal-login iframe').attr('src', 'about:blank');
                        ShowGameFlashFromGameWindow(); 
                    } catch(ex){}
                });
            }, 1000);
        });
    });

    <%-- Backward compatibility  --%>
    function __loadGame(id, real){
        if( typeof(real) != 'boolean' )
            real = <%= Profile.IsAuthenticated.ToString().ToLowerInvariant() %>;

        _openCasinoGame( id, real);
    }
</script>

</ui:MinifiedJavascriptControl>