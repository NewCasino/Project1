<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script type="text/C#" runat="server">    
    private bool RealMoney { get { return (bool)this.ViewData["RealMoney"]; } }
    private string ID { get; set; }

    private object GetData()
    {
        StringBuilder url = new StringBuilder();
        url.AppendFormat( CultureInfo.InvariantCulture, "{0}?funMode={1}", this.Model.Url, !this.RealMoney);
        if( Profile.IsAuthenticated )
            url.AppendFormat( CultureInfo.InvariantCulture, "&_sid={0}", Profile.SessionID);
        url.AppendFormat(CultureInfo.InvariantCulture, "&language={0}", MultilingualMgr.GetCurrentCulture());

        CasinoFavoriteGameAccessor cfga = CasinoFavoriteGameAccessor.CreateInstance<CasinoFavoriteGameAccessor>();
        long clientIdentity = 0;
        if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
        {
            long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out clientIdentity);
        }
        bool isFavorite = cfga.IsFavoriteGame( SiteManager.Current.DomainID, Profile.UserID, clientIdentity, this.Model.ID);
        string tc = this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_" + this.Model.VendorID.ToString());
        string tc_default = this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default");
        if (Settings.IsUKLicense)
        {
            string tc_uk = this.GetMetadata(string.Format("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_{0}_UKLicense", this.Model.VendorID.ToString()));
            string tc_default_uk = this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default_UKLicense");
            if (!string.IsNullOrWhiteSpace(tc_uk))
                tc = tc_uk;
            if (!string.IsNullOrWhiteSpace(tc_default_uk))
                tc_default = tc_default_uk;
        }
        string tc_License = this.Model.LicenseType.Substring(0, 1).ToUpper() + this.Model.LicenseType.Substring(1, this.Model.LicenseType.Length - 1);
        string tcTxt = !string.IsNullOrEmpty(tc) ? string.Format(tc, tc_License) : string.Format(tc_default, tc_License);
        return new
        {
            ElementID = this.ID,
            Name = this.Model.Name,
            Width = this.Model.Width.HasValue ? this.Model.Width.Value : 1024,
            Height = this.Model.Height.HasValue ? this.Model.Height.Value : 768,
            License = this.Model.LicenseType.ToString().ToLowerInvariant(),
            Url = url.ToString(),
            IsFavorite = isFavorite,
            RealMoney = this.RealMoney,
            VendorID = this.Model.VendorID.ToString(),
            TCTxt = tcTxt,
            Slug = this.Model.Slug,
            HasHelpUrl = !string.IsNullOrWhiteSpace(this.Model.HelpUrl),
        };
    }

    private string GetCasinoWalletCurrency()
    {
        if (Profile.IsAuthenticated)
        {
            var accounts = GmCore.GamMatrixClient.GetUserGammingAccounts(Profile.UserID, true);
            if (accounts.Exists(a => a.Record.VendorID == GamMatrixAPI.VendorID.CasinoWallet))
                return accounts.FirstOrDefault(a => a.Record.VendorID == GamMatrixAPI.VendorID.CasinoWallet).BalanceCurrency;
        }
        return string.Empty;
    }
    
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
    }
</script>

<%= this.PopulateTemplate( "GameFrame", this.GetData())  %>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
    function HideGameFlashFromGameWindow() {
        var $frameGame = $('#<%= this.ID %> iframe.GameLoaderIframe');
        var holderHtml = '<div style="height:{0}px; width:{1}px; background-color:#000000;"></div>'.format($frameGame.height(), $frameGame.width());
        $frameGame.data('src', $frameGame.attr('src')).attr('src', 'about:blank').hide();
        $frameGame.after($(holderHtml));

    }

    function ShowGameFlashFromGameWindow() {
        var $frameGame = $('#<%= this.ID %> iframe.GameLoaderIframe');
        $frameGame.attr('src',  $frameGame.data('src'));
        $frameGame.parent().find("div").remove();
        $frameGame.show();
    }

    $(function () {
        $('ul.ControllerButtons li.CBFav a.Button').click(function (e) {
            e.preventDefault();
            var FavStatus = $('ul.ControllerButtons li.CBFav').hasClass('Actived') ;
            var url = FavStatus ? '/Casino/Lobby/RemoveFromFavorites' : '/Casino/Lobby/AddToFavorites';
            var FavText = FavStatus ? "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.Button_AddToFav").SafeJavascriptStringEncode()%>" : "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.Button_RemoveFav").SafeJavascriptStringEncode()%>";
            var fun = (function (o) {
                return function () {
                    //o.fadeOut();
                    FavStatus ? $('ul.ControllerButtons li.CBFav').removeClass("Actived") :$('ul.ControllerButtons li.CBFav').addClass("Actived") ;
                    $('ul.ControllerButtons li.CBFav a.Button span').text(FavText);
                    $(document).trigger(FavStatus ? 'GAME_REMOVE_FROM_FAV' : 'GAME_ADDED_TO_FAV'  , '<%= this.Model.ID %>');
                };
            })($(this));
            $.getJSON(url, { gameID: '<%= this.Model.ID %>' }, fun);
        });

        $('ul.ControllerButtons li.CBInfo a.Button').click(function (e) {
            e.preventDefault();
            var url = '/Casino/Game/Rule/<%= this.Model.Slug.DefaultIfNullOrEmpty(this.Model.ID) %>';
            window.open(url
                , 'game_rule'
                , 'width=300,height=200,menubar=0,toolbar=0,location=0,status=1,resizable=1,centerscreen=1'
                );
        });

        $('.CBReal .Button').click(function (e) {
            e.preventDefault();
            _openCasinoGame('<%=this.Model.Slug %>', true);
        });
    });
</script>
</ui:MinifiedJavascriptControl>

