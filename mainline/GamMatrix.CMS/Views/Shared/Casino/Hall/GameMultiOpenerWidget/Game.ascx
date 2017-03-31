<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="CM.State" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Security.Cryptography" %>

<script type="text/C#" runat="server">
    private bool RealMoney { get { return (bool)this.ViewData["RealMoney"]; } }
    private string ID { get; set; }
    private string Encrypt(string toEncrypt, string key, bool useHashing)
    {
        try
        {
            byte[] keyArray;
            byte[] toEncryptArray = UTF8Encoding.UTF8.GetBytes(toEncrypt);

            if (useHashing)
            {
                MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
                keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(key));
            }
            else
                keyArray = UTF8Encoding.UTF8.GetBytes(key);

            TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();

            tdes.Key = keyArray;
            tdes.Mode = CipherMode.ECB;
            tdes.Padding = PaddingMode.PKCS7;

            ICryptoTransform cTransform = tdes.CreateEncryptor();
            byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

            return Convert.ToBase64String(resultArray, 0, resultArray.Length);
        }
        catch (Exception ex)
        {
            return System.Web.HttpUtility.UrlEncode(ex.ToString());
        }
    }

    private static readonly string DefaultLicense = "/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default";
    private static readonly string DefaultLicenseFormat = "/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_{0}";
    private static readonly string DefaultUKLicense = "/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default_UKLicense";
    private static readonly string DefaultDKLicense = "/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default_{0}DKLicense";
    private object GetData()
    {
        StringBuilder url = new StringBuilder();
        string userAgentInfo = Request.GetRealUserAddress() + Request.UserAgent;
        string sid64 = System.Web.HttpUtility.UrlEncode(Encrypt(Profile.SessionID, userAgentInfo, true));
        url.AppendFormat(CultureInfo.InvariantCulture, "{0}?funMode={1}", this.Model.Url, !this.RealMoney);
        if (Profile.IsAuthenticated)
            url.AppendFormat(CultureInfo.InvariantCulture, "&_sid64={0}", sid64);
        url.AppendFormat(CultureInfo.InvariantCulture, "&language={0}", MultilingualMgr.GetCurrentCulture());
        var lobbyUrl = string.Format("{0}://{1}/Casino/", Request.IsHttps() ? "https" : "http", Request.Url.Host);
        var cashieurl = string.Format("{0}://{1}/deposit", Request.IsHttps() ? "https" : "http", Request.Url.Host);

        url.AppendFormat(CultureInfo.InvariantCulture, "&casinolobbyurl={0}",HttpUtility.UrlEncode( lobbyUrl));
        url.AppendFormat(CultureInfo.InvariantCulture, "&cashierurl={0}", HttpUtility.UrlEncode(cashieurl));

        CasinoFavoriteGameAccessor cfga = CasinoFavoriteGameAccessor.CreateInstance<CasinoFavoriteGameAccessor>();
        long clientIdentity = 0;
        if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
        {
            long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out clientIdentity);
        }
        bool isFavorite = cfga.IsFavoriteGame(SiteManager.Current.DomainID, Profile.UserID, clientIdentity, this.Model.ID);

        #region license
        string tc = string.Empty;
        string licenseType = this.Model.LicenseType;
        if (string.IsNullOrEmpty(licenseType) || string.IsNullOrEmpty(licenseType.Trim()) || licenseType.Trim().ToLower().Equals("none"))
        {
            if (this.Model.VendorID == GamMatrixAPI.VendorID.NetEnt)
                licenseType = "Malta";
            else
                licenseType = "Curacao";
        }
        if (this.Model.VendorID == GamMatrixAPI.VendorID.NetEnt)
                licenseType = "Malta";
        if (!licenseType.Equals("Malta"))
        {
            licenseType = "Curacao";
        }
        if (Settings.IsUKLicense)
        {
            tc = this.GetMetadata(DefaultUKLicense);
        }
        else if (Settings.IsDKLicense)
        {
            tc = this.GetMetadata(string.Format(DefaultDKLicense, licenseType + "_"))
                .DefaultIfNullOrWhiteSpace(this.GetMetadata(string.Format(DefaultDKLicense, string.Empty)));
        }
        else
        {
            tc = this.GetMetadata(string.Format(DefaultLicenseFormat, licenseType));
        }

        string tc_License = licenseType.Substring(0, 1).ToUpper() + licenseType.Substring(1, licenseType.Length - 1);
        string tcTxt = tc;

        #endregion

        return new
        {
            ID = this.Model.ID,
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

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
    }

    private bool IsProfileFullAndValid()
    {
        if (!CustomProfile.Current.IsAuthenticated)
            return false;

        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(CustomProfile.Current.UserID);

        // if the profile is uncompleted, redirect user to profile page
        if (string.IsNullOrWhiteSpace(user.Address1) ||
            string.IsNullOrWhiteSpace(user.Zip) ||
            string.IsNullOrWhiteSpace(user.Mobile) ||
            string.IsNullOrWhiteSpace(user.SecurityQuestion) ||
            string.IsNullOrWhiteSpace(user.SecurityAnswer) ||
            string.IsNullOrWhiteSpace(user.City) ||
            string.IsNullOrWhiteSpace(user.Title) ||
            string.IsNullOrWhiteSpace(user.FirstName) ||
            string.IsNullOrWhiteSpace(user.Surname) ||
            string.IsNullOrWhiteSpace(user.Currency) ||
            string.IsNullOrWhiteSpace(user.Language) ||
            user.CountryID <= 0 ||
            !user.Birth.HasValue ||
            CustomProfile.Current.IsInRole("Incomplete Profile"))
        {
            return false;
        }

        if (!user.IsEmailVerified)
            return false;

        return true;
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
        $frameGame.attr('src', $frameGame.data('src'));
        $frameGame.parent().find("div").remove();
        $frameGame.show();
    }

    $(function () {
        $('ul.ControllerButtons li.CBFav a.Button').click(function (e) {
            e.preventDefault();
            var FavStatus = $('ul.ControllerButtons li.CBFav').hasClass('Actived');
            var url = FavStatus ? '/Casino/Lobby/RemoveFromFavorites' : '/Casino/Lobby/AddToFavorites';
            var FavText = FavStatus ? "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.Button_AddToFav").SafeJavascriptStringEncode()%>" : "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.Button_RemoveFav").SafeJavascriptStringEncode()%>";
            var fun = (function (o) {
                return function () {
                    //o.fadeOut();
                    FavStatus ? $('ul.ControllerButtons li.CBFav').removeClass("Actived") : $('ul.ControllerButtons li.CBFav').addClass("Actived");
                    $('ul.ControllerButtons li.CBFav a.Button span').text(FavText);
                    $('ul.ControllerButtons li.CBFav a.Button').attr("title", FavText);
                    $(document).trigger(FavStatus ? 'GAME_REMOVE_FROM_FAV' : 'GAME_ADDED_TO_FAV', '<%= this.Model.ID %>');
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
