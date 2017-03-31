<%@ Page Title="Casino Engine - Configuration" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" 
    Inherits="System.Web.Mvc.ViewPage<CE.db.ceDomainConfigEx>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<script language="C#" type="text/C#" runat="server">


    private string GetEnabledVendorCheckboxes()
    {
        CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
        List<VendorID> enabledVendors = cva.GetEnabledVendors(DomainManager.CurrentDomainID);
        List<VendorID> liveCasinoVendors = cva.GetLiveCasinoVendors(DomainManager.CurrentDomainID);
        StringBuilder html = new StringBuilder();
        var domainVendors = DomainManager.GetDomainVendors();
        VendorID[] vendors = GlobalConstant.AllVendors.OrderBy(x => x.ToString()).ToArray();
        html.Append("<ul>");

        foreach (VendorID vendor in vendors)
        {
            StringBuilder domainsHtml = new StringBuilder();
            if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
            {
                domainsHtml.Append("<a target=\"_self\" href=\"#\" class=\"operatorsListToggle\" data-vendorid=\"" + vendor + "\">List of Operators</a>");
                domainsHtml.Append("<div id=\"enabledOperatorsList" + vendor + "\" class=\"enabledOperatorsList\"><span>This Vendor enabled for following operators:</span>");
                var domains = domainVendors.Where(d => d.VendorID == (long) vendor);
                foreach (var domain in domains)
                {
                    domainsHtml.AppendFormat(@"<a target='_self' href='/Configuration/{0}'>{1}</a><br/>", domain.DomainID, domain.Name);
                }
                domainsHtml.Append("</div>");
            }
            html.AppendFormat("\n<li data-vendor=\"{0}\"><label style=\"width:150px; float:left; display:inline-block;\">{0}</label><input type=\"checkbox\" autocomplete=\"off\" {1} name=\"enabledVendors\" id=\"vendor{0}\" value=\"{2}\" vendor=\"{3}\" /><label for=\"vendor{0}\">Enabled</label>&nbsp;&nbsp;<input type=\"checkbox\" autocomplete=\"off\" {4} name=\"liveCasinoVendors\" id=\"liveCasinoVendor{0}\" value=\"{2}\" vendor=\"{3}\" /><label for=\"liveCasinoVendor{0}\">Has Live Casino</label>{5}</li>"
                , vendor.ToString()
                , enabledVendors.Exists( v => vendor == v) ? "checked=\"checked\"" : string.Empty
                , (int)vendor
                , vendor.ToString()
                , liveCasinoVendors.Exists(v => vendor == v) ? "checked=\"checked\"" : string.Empty
                , domainsHtml.ToString()
                );
        }
        
        html.Append("</ul>");

        return html.ToString();
    }

    private bool IsTestMode()
    {
        return !string.IsNullOrWhiteSpace(Request.QueryString["TestMode"]);
    }

    private SelectList GetPopularityCaculationMethod()
    {
        Dictionary<PopularityCalculationMethod, string> dic = new Dictionary<PopularityCalculationMethod, string>();
        dic[PopularityCalculationMethod.ByTimes] = "By Times";
        dic[PopularityCalculationMethod.ByTurnover] = "By Turnover";

        return new SelectList(dic, "Key", "Value", this.Model.PopularityCalculationMethod);
    }

    private string GetGamesJson()
    {
        List<ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(this.Model.DomainID).Where(d => d.Key == d.Value.ID.ToString()).Select(d => d.Value).ToList();
        //games = games.Take(5).ToList();
        StringBuilder json = new StringBuilder();
        json.Append("[");
        foreach (ceCasinoGameBase game in games)
            json.AppendFormat("'{0}@{1}',", game.VendorID.ToString(), game.GameCode.SafeJavascriptStringEncode());
        if (games.Any())
            json.Remove(json.Length - 1, 1);
        json.Append("]");
        return json.ToString();
    }

    private static List<SelectListItem> s_Countries;
    private List<ceCasinoGameBaseEx> s_DesktopGames;
    private List<ceCasinoGameBaseEx> s_MobileGames;
    private List<VendorID> s_DesktopVendors;
    private List<VendorID> s_MobileVendors;

    private Dictionary<string, string> GetClientTypes()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllClientType();
    }

    private bool IsExist(string clientCompatibility, List<string> clientTypes)
    {
        if (string.IsNullOrWhiteSpace(clientCompatibility))
            return false;

        string[] clientCompatibilities = clientCompatibility.Split(",".ToArray(), StringSplitOptions.RemoveEmptyEntries);
        foreach (string clientType in clientTypes)
        {
            if (clientCompatibilities.Contains(clientType))
                return true;
        }
        return false;
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        if (s_Countries == null)
        {
            LocationAccessor la = LocationAccessor.CreateInstance<LocationAccessor>();
            s_Countries = la.GetCountries().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key }).ToList();
            s_Countries.Insert(0, new SelectListItem() { Selected = true, Text = "< Country >", Value = string.Empty });
        }

        if (s_DesktopGames == null || s_MobileGames == null)
        {
            List<ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(this.Model.DomainID).Where(d => d.Key == d.Value.ID.ToString()).Select(d => d.Value).ToList();
            Dictionary<string, string> clientTypes = GetClientTypes();

            List<string> desktopTypes = clientTypes.Select(ct => ct.Key).Where(ct => ct == "PC").ToList();
            s_DesktopGames = games.Where(g => IsExist(g.ClientCompatibility, desktopTypes)).ToList();

            List<string> mobileTypes = clientTypes.Select(ct => ct.Key).Where(ct => ct != "PC").ToList();
            s_MobileGames = games.Where(g => IsExist(g.ClientCompatibility, mobileTypes)).ToList();

            s_DesktopVendors = s_DesktopGames.Select(g => g.VendorID).Distinct().ToList();
            s_MobileVendors = s_MobileGames.Select(g => g.VendorID).Distinct().ToList();
        }
    }

    private string GetDesktopGamesJson()
    {
        StringBuilder json = new StringBuilder();
        json.Append("[");
        foreach (ceCasinoGameBase game in s_DesktopGames)
            json.AppendFormat("\"{0} ({1})\",", game.GameName.SafeJavascriptStringEncode(), game.GameCode.SafeJavascriptStringEncode());
        if (s_DesktopGames.Any())
            json.Remove(json.Length - 1, 1);
        json.Append("]");
        return json.ToString();
    }

    private string GetMobileGamesJson()
    {
        StringBuilder json = new StringBuilder();
        json.Append("[");
        foreach (ceCasinoGameBase game in s_MobileGames)
            json.AppendFormat("\"{0} ({1})\",", game.GameName.SafeJavascriptStringEncode(), game.GameCode.SafeJavascriptStringEncode());
        if (s_MobileGames.Any())
            json.Remove(json.Length - 1, 1);
        json.Append("]");
        return json.ToString();
    }

    private string GetGameNameIDMappingJson()
    {
        List<ceCasinoGameBaseEx> games = new List<ceCasinoGameBaseEx>();
        games.AddRange(s_DesktopGames);
        games.AddRange(s_MobileGames);

        StringBuilder json = new StringBuilder();
        json.Append("{");
        foreach (ceCasinoGameBase game in games)
            json.AppendFormat("\"{0} ({1})\":{2},", game.GameName.SafeJavascriptStringEncode(), game.GameCode.SafeJavascriptStringEncode(), game.ID.ToString(CultureInfo.InvariantCulture));
        if (s_DesktopGames.Any())
            json.Remove(json.Length - 1, 1);
        json.Append("}");
        return json.ToString();
    }

    private string GetGameIDNameMappingJson()
    {
        List<ceCasinoGameBaseEx> games = new List<ceCasinoGameBaseEx>();
        games.AddRange(s_DesktopGames);
        games.AddRange(s_MobileGames);

        StringBuilder json = new StringBuilder();
        json.Append("{");
        foreach (ceCasinoGameBase game in games)
            json.AppendFormat("{0}:\"{1} ({2})\",", game.ID.ToString(CultureInfo.InvariantCulture), game.GameName.SafeJavascriptStringEncode(), game.GameCode.SafeJavascriptStringEncode());
        if (s_DesktopGames.Any())
            json.Remove(json.Length - 1, 1);
        json.Append("}");
        return json.ToString();
    }

    private string GetPopularityManualPlacementsText(List<long> ids)
    {
        if (ids == null || ids.Count == 0)
            return "None";
        
        List<ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(this.Model.DomainID).Where(d => d.Key == d.Value.ID.ToString()).Select(d => d.Value).ToList();
        games = games.Where(g => ids.Contains(g.ID)).ToList();

        if (games.Count == 0)
            return "None";

        string text = string.Empty;
        int index = 0;
        foreach (ceCasinoGameBaseEx game in games)
        {
            if (index >= 3)
                break;
            text += string.Format("{0} ({1}), ", game.GameName, game.GameCode);
            index++;
        }
        if (games.Count > 3)
            text += "...";
        else
            text = text.Substring(0, text.Length - 2);
        return text;
    }

    private string GetPopularityExcludeGamesText(List<long> ids)
    {
        if (ids == null || ids.Count == 0)
            return "None";
        
        List<ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(this.Model.DomainID).Where(d => d.Key == d.Value.ID.ToString()).Select(d => d.Value).ToList();
        games = games.Where(g => ids.Contains(g.ID)).ToList();

        if (games.Count == 0)
            return "None";

        string text = string.Empty;
        int index = 0;
        foreach (ceCasinoGameBaseEx game in games)
        {
            if (index >= 3)
                break;
            text += string.Format("{0} ({1}), ", game.GameName, game.GameCode);
            index++;
        }
        if (games.Count > 3)
            text += "...";
        else
            text = text.Substring(0, text.Length - 2);
        return text;
    }
</script>

<asp:Content ContentPlaceHolderID="phMain" runat="server">



 
<style type="text/css" media="all">
    #wrapper .container .ui-accordion-content { overflow:hidden !important; }
    #btnSaveVendors { float:right; }
    #btnSaveWcfApiCredentials { float:right; }
    #btnSaveApiCredentials { float:right; }
    #formSaveGenericCfg ul { list-style-type:none; margin:0px; padding:0px; }
    .country_textbox { text-align:right; border:0; background-color:transparent; color:white; cursor:default; }
    .enabledOperatorsList { display: none;margin: 5px 0;padding: 10px;width: 440px;background-color: grey; }
    .enabledOperatorsList span { display: block; }
    .enabledOperatorsList a { margin-left: 10px; color: #9EDA29; text-decoration: none; }
    .enabledOperatorsList a:hover { color: #fff;text-decoration: underline; }
    a.operatorsListToggle {
        color: #9EDA29;
        text-decoration: none;
        padding-left: 17px;
        padding-right: 10px;
        background: url(/images/dropdown.gif) no-repeat scroll right 8px;
    }
    a.operatorsListToggle:hover { color: #fff; }

    #popularity-country-specific-editor-tabs .LeftColumn { width: 49%; float: left; }
    #popularity-country-specific-editor-tabs .RightColumn { width: 49%; float: left; }
    #popularity-country-specific-editor-tabs .Clear { clear: both; }
    #popularity-country-specific-editor-tabs .ui-tabs-panel { height: 520px; overflow: auto; }
    #popularity-country-specific-editor-tabs .manualPlacement { width: 250px; }

    ul.fancytree-container { border: 0px; }
    ul.fancytree-focus { border: 0px; }
    span.fancytree-icon { display: none; }
    span.fancytree-selected span.fancytree-title { font-style: normal; }
</style>
<script type="text/javascript">
    $(function () {
        var $acc = $("#configuration-accordion").accordion({ autoHeight: false });

        // <%-- Vendors --%>
        function onVendorsCheckboxChanged() {
            var $lis = $('#formSaveGenericCfg ul li');

            for (var i = 0; i < $lis.length; i++) {
                var vendor = $lis.eq(i).data('vendor');
                if ($(':checked', $lis.eq(i)).length == 0) {
                    $('h3[id="' + vendor + '"]').hide();
                }
                else {
                    $('h3[id="' + vendor + '"]').show();
                }
            }
        };
        onVendorsCheckboxChanged();
        $("#formSaveGenericCfg ul input[type='checkbox']").change(onVendorsCheckboxChanged);

        $(".operatorsListToggle").click(function (e) {
            e.preventDefault();
            $('#enabledOperatorsList' + $(this).data("vendorid")).toggle();
        });
    });
</script>

<div id="configuration-accordion">
<% if( this.Model != null )
   { %>
    

    <% if (CurrentUserSession.IsSuperUser)
       { %>

    <%------------------------------
         Generic
     -------------------------------%>
	<h3><a href="#">Generic</a></h3>
	<div>
        <form id="formSaveGenericCfg" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveVendors").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5" style="width:100%">
                <tr>
                	<td valign="top" style="width:400px"><label>Vendors :</label></td>
                    <td><%= GetEnabledVendorCheckboxes()%></td>
                </tr>
                <tr>
                    <td>Cashier URL:</td>
                    <td><input autocomplete="off" type="textbox" id="txtCashierUrl" name="cashierUrl" class="textbox" maxlength="255" value="<%= this.Model.CashierUrl.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Lobby URL:</td>
                    <td><input autocomplete="off" type="textbox" id="txtLobbyUrl" name="lobbyUrl" class="textbox" maxlength="255" value="<%= this.Model.LobbyUrl.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Account history URL:</td>
                    <td><input autocomplete="off" type="textbox" id="txtAccountHistory" name="accountHistoryUrl" class="textbox" maxlength="255" value="<%= this.Model.AccountHistoryUrl.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Mobile cashier URL:</td>
                    <td><input autocomplete="off" type="textbox" id="txtMobileCashierUrl" name="mobileCashierUrl" class="textbox" maxlength="255" value="<%= this.Model.MobileCashierUrl.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Mobile lobby URL:</td>
                    <td><input autocomplete="off" type="textbox" id="txtMobileLobbyUrl" name="mobileLobbyUrl" class="textbox" maxlength="255" value="<%= this.Model.MobileLobbyUrl.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Mobile account history URL:</td>
                    <td><input autocomplete="off" type="textbox" id="txtMobileAccountHistoryUrl" name="mobileAccountHistoryUrl" class="textbox" maxlength="255" value="<%= this.Model.MobileAccountHistoryUrl.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Domain default currency code:</td>
                    <td><input autocomplete="off" type="textbox" id="txtDomainDefaultCurrencyCode" name="domainDefaultCurrencyCode" class="textbox" maxlength="10" value="<%= this.Model.DomainDefaultCurrencyCode %>" /></td>
                </tr>
                <tr>
                    <td>Google Analytics account:</td>
                    <td><input autocomplete="off" type="textbox" id="txtGoogleAnalyticsAccount" name="googleAnalyticsAccount" class="textbox" maxlength="255" value="<%= this.Model.GoogleAnalyticsAccount.SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Game loader domain:</td>
                    <td><input autocomplete="off" type="textbox" id="txtGameLoaderDomain" name="gameLoaderDomain" class="textbox" maxlength="50" value="<%= this.Model.GameLoaderDomain.DefaultIfNullOrEmpty("casino.gammatrix.com").SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Game resource domain:</td>
                    <td><input autocomplete="off" type="textbox" id="txtGameResourceDomain" name="gameResourceDomain" class="textbox" maxlength="50" value="<%= this.Model.GameResourceDomain.DefaultIfNullOrEmpty("cdn.everymatrix.com").SafeHtmlEncode() %>" /></td>
                </tr>
                <tr>
                    <td>Remove Casino Games from the "New Games" list after N days:</td>
                    <td><input autocomplete="off" type="textbox" id="txtNewStatusCasinoGameExpirationDays" name="newStatusCasinoGameExpirationDays" class="textbox digits required" maxlength="3" value="<%= this.Model.NewStatusCasinoGameExpirationDays %>" /></td>
                </tr>
                <tr>
                    <td>Remove Live Casino Games from the "New Games" list after N days:</td>
                    <td><input autocomplete="off" type="textbox" id="txtNewStatusLiveCasinoGameExpirationDays" name="newStatusLiveCasinoGameExpirationDays" class="textbox digits required" maxlength="3" value="<%= this.Model.NewStatusLiveCasinoGameExpirationDays %>" /></td>
                </tr>

            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSaveVendors">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                
                $("#formSaveGenericCfg").validate();
                $('#btnSaveVendors').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveGenericCfg").valid())
                        return;

                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveGenericCfg").ajaxSubmit(options);
                });
            });
        </script>
	</div>

    <% Html.RenderPartial("DomainConfig", typeof(Authentic)); %>
    <% Html.RenderPartial("DomainConfig", typeof(BallyGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(BetGames)); %>
    <% Html.RenderPartial("DomainConfig", typeof(BetOnFinance)); %>
    <% Html.RenderPartial("DomainConfig", typeof(BetSoft)); %>
    <% Html.RenderPartial("DomainConfig", typeof(CTXM)); %>
    <% Html.RenderPartial("DomainConfig", typeof(EGB)); %>
    <% Html.RenderPartial("DomainConfig", typeof(EGT)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Endorphina)); %>
    <% Html.RenderPartial("DomainConfig", typeof(EvolutionGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Ezugi)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Gamevy)); %>
    <% Html.RenderPartial("DomainConfig", typeof(GTS)); %>
    <% Html.RenderPartial("DomainConfig", typeof(GreenTube)); %>
    <% Html.RenderPartial("DomainConfig", typeof(PokerKlas)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Genii)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Opus)); %>
    <% Html.RenderPartial("DomainConfig", typeof(ISoftGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(AsiaGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Oriental)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Habanero)); %>
    <% Html.RenderPartial("DomainConfig", typeof(HoGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(IGT)); %>
    <% Html.RenderPartial("DomainConfig", typeof(ISoftBet)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Lega)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Microgaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Mrslotty)); %>
    <% Html.RenderPartial("DomainConfig", typeof(NetEnt)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Norske)); %>
    <% Html.RenderPartial("DomainConfig", typeof(NYXGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(OMI)); %>
    <% Html.RenderPartial("DomainConfig", typeof(OneXTwoGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Pariplay)); %>
    <% Html.RenderPartial("DomainConfig", typeof(PlaynGO)); %>
    <% Html.RenderPartial("DomainConfig", typeof(LiveGames)); %>
    <% Html.RenderPartial("DomainConfig", typeof(RCT)); %>
    <% Html.RenderPartial("DomainConfig", typeof(StakeLogic)); %>
    <% Html.RenderPartial("DomainConfig", typeof(QuickSpin)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Sheriff)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Spigo)); %>
    <% Html.RenderPartial("DomainConfig", typeof(TTG)); %>
    <% Html.RenderPartial("DomainConfig", typeof(ViG)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Vivo)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Williams)); %>
    <% Html.RenderPartial("DomainConfig", typeof(WorldMatch)); %>
    <% Html.RenderPartial("DomainConfig", typeof(XProGaming)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Yggdrasil)); %>
    
    <% Html.RenderPartial("DomainConfig", typeof(Realistic)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Spinomenal)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Parlay)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Hybrino)); %>
    <% Html.RenderPartial("DomainConfig", typeof(JoinGames)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Kiron)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Multislot)); %>
    <% Html.RenderPartial("DomainConfig", typeof(CandleBets)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Eyecon)); %>
    <% Html.RenderPartial("DomainConfig", typeof(LuckyStreak)); %>    
    <% Html.RenderPartial("DomainConfig", typeof(Odobo)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Globalbet)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Tombala)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Playson)); %>
    <% Html.RenderPartial("DomainConfig", typeof(Igrosoft)); %>
    <% Html.RenderPartial("DomainConfig", typeof(BoomingGames)); %>
    <% Html.RenderPartial("DomainConfig", typeof(GaminGenius)); %>
    <% Html.RenderPartial("DomainConfig", typeof(GoldenRace)); %>
    <% Html.RenderPartial("DomainConfig", typeof(PlayStar)); %>


    <%------------------------------
        API Credentials 
     -------------------------------%>
    <h3><a href="#">API Configuration</a></h3>
	<div>
        <form id="formSaveApiCredentials" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveApiCredentials").SafeHtmlEncode() %>">
            <p>
                <label for="txtApiUsername">API username :</label>
                <em>*</em>
                <input readonly="readonly" 
                value="<%= this.Model.ApiUsername.DefaultIfNullOrEmpty( Regex.Replace(this.Model.Name, @"[^a-zA-Z0-9]", "_") ).SafeHtmlEncode() %>"
                autocomplete="off" type="text" id="txtApiUsername" name="apiUsername" class="textbox required" maxlength="25" />
            </p>
            <p>
                <label for="txtApiPassword">API password :</label>
                <em>&#160;</em>
                <input autocomplete="off" value="" type="password" id="txtApiPassword" name="apiPassword" class="textbox" maxlength="30"/>
            </p>
            <p>
                <label for="txtWhitelistIP">API whitelist IP address(es) :</label>
                <em>*</em>
                <input
                value="<%= this.Model.ApiWhitelistIP.SafeHtmlEncode() %>"
                autocomplete="off" type="text" id="txtWhitelistIP" name="apiWhitelistIP" class="textbox required" maxlength="500" />
            </p>
            <p>
                <label for="txtGameListChangedNotificationUrl">GameList-changed-notification URL (one line per URL):</label>
                <br />
                <textarea cols="100" rows="3" id="txtGameListChangedNotificationUrl" name="gameListChangedNotificationUrl" autocomplete="off"><%= this.Model.GameListChangedNotificationUrl.SafeHtmlEncode() %></textarea>
                <% if(DomainManager.AllowEdit()) { %>
                <button type="submit" id="btnSaveApiCredentials">Save</button>
                <% } %>
            </p>
        </form>

        <script type="text/javascript">
            $(function () {
                $("#formSaveApiCredentials").validate();
                $('#btnSaveApiCredentials').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveApiCredentials").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveApiCredentials").ajaxSubmit(options);
                });
            });
        </script>
	</div>
    

    <%------------------------------
         Internal WCF API Credentials
     -------------------------------%>
    <h3><a href="#">Internal WCF API Credentials</a></h3>
	<div>
        <form id="formSaveWcfApiCredentials" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveWcfApiCredentials").SafeHtmlEncode() %>">
            <p>
                <label for="txtWcfApiUsername">API username :</label>
                <em>*</em>
                <input autocomplete="off"
                value="<%= this.Model.WcfApiUsername.DefaultIfNullOrEmpty( "_Api_CE" ).SafeHtmlEncode() %>"
                type="text" id="txtWcfApiUsername" name="wcfApiUsername" class="textbox required" maxlength="20" />
            </p>
            <p>
                <label for="txtWcfApiPassword">API password :</label>
                <em>*</em>
                <input autocomplete="off" type="password"
                 id="txtWcfApiPassword" name="wcfApiPassword" class="textbox required" maxlength="30"/>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSaveWcfApiCredentials">Save</button>
                <% } %>
            </p>
        </form>

        <script type="text/javascript">
            $(function () {
                $("#formSaveWcfApiCredentials").validate();
                $('#btnSaveWcfApiCredentials').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveWcfApiCredentials").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveWcfApiCredentials").ajaxSubmit(options);
                });
            });        
        </script>
	</div>
    

    <%------------------------------
         Scalable Thumbnail
     -------------------------------%>
    <h3><a href="#">Scalable Thumbnail Setting</a></h3>
	<div>
        <form id="formSaveScalableThumbnailSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveScalableThumbnailSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                <tr>
                	<td><label>Enable Scalable Thumbnail :</label></td>
                    <td>
                    <%: Html.CheckBox("enableScalableThumbnail", this.Model.EnableScalableThumbnail, new { @id="btnEnableScalableThumbnail" }) %>
                    <label for="btnEnableScalableThumbnail">Enabled</label>
                    </td>
                </tr>
                <tr>
                	<td><label>Scalable Thumbnail Width :</label></td>
                    <td>
                    <%: Html.TextBox("scalableThumbnailWidth"
                            , this.Model.ScalableThumbnailWidth == 0 ? 376 : this.Model.ScalableThumbnailWidth
                            , new { @id = "txtScalableThumbnailWidth", @class="textbox digits required", @maxlength="3" }
                        ) %>
                    </td>
                </tr>
                <tr>
                	<td><label>Scalable Thumbnail Height :</label></td>
                    <td>
                    <%: Html.TextBox("scalableThumbnailHeight"
                           , this.Model.ScalableThumbnailHeight == 0 ? 250 : this.Model.ScalableThumbnailHeight
                           , new { @id = "txtScalableThumbnailHeight", @class = "textbox digits required", @maxlength = "3" }
                        )%>
                    </td>
                </tr>
                
            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSaveScalableThumbnail">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSaveScalableThumbnailSetting").validate();
                $('#btnSaveScalableThumbnail').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveScalableThumbnailSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                            if ($('#btnEnableScalableThumbnail').is(':checked'))
                                alert('The thumbnails will be scaled in background, you may need wait for a while before its completion.');
                        }
                    };
                    $('#loading').show();
                    $("#formSaveScalableThumbnailSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>
    
    <% } %>

    <%------------------------------
         Top Winners Default Setting
     -------------------------------%>
    <h3><a href="#">Top Winners Default Setting</a></h3>
	<div>
        <form id="formSaveTopWinnersDefaultSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveTopWinnersDefaultSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                <tr>
                	<td valign="top" style="width:400px"><label>The number of recent days in which to query the top winners :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.TopWinnersDaysBack %>" style="text-align:right"
                        type="text" id="txtTopWinnersDaysBack" name="topWinnersDaysBack" class="textbox digits required" maxlength="3" />
                    </td>
                </tr>
                <tr>
                	<td><label>Max number of the top winners :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.TopWinnersMaxRecords %>" style="text-align:right"
                        type="text" id="txtTopWinnersMaxRecords" name="topWinnersMaxRecords" class="textbox digits required" maxlength="3" />
                    </td>
                </tr>
                <tr>
                	<td><label>Minimum of the win amount in EUR currency :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.TopWinnersMinAmount %>" style="text-align:right"
                        type="text" id="txtTopWinnersMinAmount" name="topWinnersMinAmount" class="textbox number required" maxlength="10" />
                    </td>
                </tr>
                <tr>
                	<td><label>Exclude winners from other operators :</label></td>
                    <td>
                        <%: Html.CheckBox("topWinnersExcludeOtherOperators", this.Model.TopWinnersExcludeOtherOperators, new { @id = "btnTopWinnersExcludeOtherOperators" })%>
                        <label for="btnTopWinnersExcludeOtherOperators">Only returns the winners from current operator</label>
                    </td>
                </tr>
            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSaveTopWinnersDefaultSetting">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSaveTopWinnersDefaultSetting").validate();
                $('#btnSaveTopWinnersDefaultSetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveTopWinnersDefaultSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveTopWinnersDefaultSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>
     <%------------------------------
         Last Played Games Default Setting
     -------------------------------%>
    <%--<h3><a href="#">Last Played Games Default Setting</a></h3>
	<div>
        <form id="formSaveLastPlayedGamesDefaultSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveLastPlayedGamesDefaultSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                
            </table>
            <p>
                <button id="btnSaveLastPlayedGamesDefaultSetting">Save</button>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSaveLastPlayedGamesDefaultSetting").validate();
                $('#btnSaveLastPlayedGamesDefaultSetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveLastPlayedGamesDefaultSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveLastPlayedGamesDefaultSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>--%>



     <%------------------------------
         Player Casino Configuration
     -------------------------------%>
    <h3><a href="#">Player Casino Configuration</a></h3>
	<div>
        <form id="formSavePlayerCasinoConfigurationDefaultSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SavePlayerCasinoConfigurationDefaultSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                
                <tr class="TrSubTitle">
                    <td colspan="2">
                       <strong>Last Played Games</strong>
                    </td>
                </tr>
                <tr>
                	<td><label>Max number of records  to display :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.LastPlayedGamesMaxRecords %>" style="text-align:right"
                        type="text" id="txtLastPlayedGamesMaxRecords" name="lastPlayedGamesMaxRecords" class="textbox digits required" maxlength="3" />
                    </td>
                </tr>
                 
                <tr>
                	<td><label>The number of recent days to query the records :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.LastPlayedGamesLastDayNum %>" style="text-align:right"
                        type="text" id="txtLastPlayedGamesLastDayNum" name="lastPlayedGamesLastDayNum" class="textbox digits required" maxlength="4" />
                    </td>
                </tr>
                <tr>
                	<td><label>Unique Game:</label></td>
                    <td>
                        <%: Html.CheckBox("lastPlayedGamesIsDuplicated", this.Model.LastPlayedGamesIsDuplicated, new { @id = "btnLastPlayedGamesIsDuplicated" })%>
                        <label for="btnLastPlayedGamesIsDuplicated"></label>
                    </td>
                </tr>
                <tr class="TrSubTitle">
                    <td colspan="2">
                        <strong>Most Played Games</strong>
                    </td>
                </tr>
                <tr>
                	<td><label>The number of recent days to count the bets  :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.MostPlayedGamesLastDayNum %>" style="text-align:right"
                        type="text" id="txtMostPlayedGamesLastDayNum" name="mostPlayedGamesLastDayNum" class="textbox digits required" maxlength="4" />
                    </td>
                </tr> 
                 
                <tr>
                	<td><label>Min.Game round to qualify  :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.MostPlayedGamesMinRoundCounts %>" style="text-align:right"
                        type="text" id="txtMostPlayedGamesMinRoundCounts" name="mostPlayedGamesMinRoundCounts" class="textbox digits required" maxlength="6" />
                    </td>
                </tr>
                <tr class="TrSubTitle">
                    <td colspan="2">
                        <strong>Biggest Wins</strong>
                    </td>
                </tr>
                 <tr>
                	<td><label>The number of recent days in which to query the wins :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.PlayerBiggestWinGamesLastDayNum %>" style="text-align:right"
                        type="text" id="Text1" name="playerBiggestWinGamesLastDayNum" class="textbox digits required" maxlength="4" />
                    </td>
                </tr> 
                <tr>
                	<td><label>Min win amount(EUR):</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.PlayerBiggestWinGamesMinWinEURAmounts %>" style="text-align:right"
                        type="text" id="Text2" name="playerBiggestWinGamesMinWinEURAmounts" class="textbox number required" maxlength="10" />
                    </td>
                </tr>
                <tr>
                	<td><label>Unique game:</label></td>
                    <td>
                        <%: Html.CheckBox("playerBiggestWinGamesIsDuplicated", this.Model.PlayerBiggestWinGamesIsDuplicated, 
                        new { @id = "btnPlayerBiggestWinGamesIsDuplicated" })%>
                        <label for="btnPlayerBiggestWinGamesIsDuplicated"></label>
                    </td>
                </tr>
            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSavePlayerCasinoConfigurationDefaultSetting">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSavePlayerCasinoConfigurationDefaultSetting").validate();
                $('#btnSavePlayerCasinoConfigurationDefaultSetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSavePlayerCasinoConfigurationDefaultSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSavePlayerCasinoConfigurationDefaultSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>
    

    <%------------------------------
         Save Player Biggest Win Games  Default Setting
     -------------------------------%>
    <%--<h3><a href="#">Player Biggest Win Games  Default Setting</a></h3>
	<div>
        <form id="formSavePlayerBiggestWinGamesDefaultSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SavePlayerBiggestWinGamesDefaultSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
               
            </table>
            <p>
                <button id="btnSavePlayerBiggestWinGamesDefaultSetting">Save</button>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSavePlayerBiggestWinGamesDefaultSetting").validate();
                $('#btnSavePlayerBiggestWinGamesDefaultSetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSavePlayerBiggestWinGamesDefaultSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSavePlayerBiggestWinGamesDefaultSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>--%>
    <%------------------------------
     Most Popular Games Default Setting
     -------------------------------%>
    <%--<h3><a href="#">
     Most Popular Games Default Setting</a></h3>
	<div>
        <form id="formSaveMostPopularGamesDefaultSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveMostPopularGamesDefaultSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                <tr>
                	<td><label>Recent day number of the Most Played Games :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.MostPopularGamesLastDayNum %>" style="text-align:right"
                        type="text" id="Text3" name="mostPopularGamesLastDayNum" class="textbox digits required" maxlength="4" />
                    </td>
                </tr> 
                  
                <tr>
                    <td><label>Most popular games is game rounds :</label></td>
                    <td>
                        <%: Html.CheckBox("mostPopularGamesIsGameRounds", this.Model.MostPopularGamesIsGameRounds, 
                        new { @id = "btnMostPopularGamesIsGameRounds" })%>
                        <label for="btnMostPopularGamesIsGameRounds">Most popular games is game rounds</label>
                    </td>
                </tr>
            </table>
            <p>
                <button id="btnSaveMostPopularGamesDefaultSetting">Save</button>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSaveMostPopularGamesDefaultSetting").validate();
                $('#btnSaveMostPopularGamesDefaultSetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveMostPopularGamesDefaultSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveMostPopularGamesDefaultSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>--%>
    <%------------------------------
         Recent Winners Default Setting
     -------------------------------%>
    <h3><a href="#">Recent Winners Default Setting</a></h3>
	<div>
        <form id="formSaveRecentWinnersDefaultSetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveRecentWinnersDefaultSetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                <tr>
                	<td><label>Max number of the top winners :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.RecentWinnersMaxRecords %>" style="text-align:right"
                        type="text" id="txtRecentWinnersMaxRecords" name="recentWinnersMaxRecords" class="textbox digits required" maxlength="3" />
                    </td>
                </tr>
                <tr>
                	<td><label>Minimum of the win amount in EUR currency :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.RecentWinnersMinAmount %>" style="text-align:right"
                        type="text" id="txtRecentWinnersMinAmount" name="recentWinnersMinAmount" class="textbox number required" maxlength="10" />
                    </td>
                </tr>
                <tr>
                	<td><label>Exclude winners from other operators :</label></td>
                    <td>
                        <%: Html.CheckBox("recentWinnersExcludeOtherOperators", this.Model.RecentWinnersExcludeOtherOperators, new { @id = "btnRecentWinnersExcludeOtherOperators" })%>
                        <label for="btnRecentWinnersExcludeOtherOperators">Only returns the winners from current operator</label>
                    </td>
                </tr>
                <tr>
                	<td><label>Distinct winner :</label></td>
                    <td>
                        <%: Html.CheckBox("recentWinnersReturnDistinctUserOnly", this.Model.RecentWinnersReturnDistinctUserOnly, new { @id = "btnRecentWinnersReturnDistinctUserOnly" })%>
                        <label for="btnRecentWinnersReturnDistinctUserOnly">Only returns one record for the same user</label>
                    </td>
                </tr>
            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSaveRecentWinnersDefaultSetting">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                $("#formSaveRecentWinnersDefaultSetting").validate();
                $('#btnSaveRecentWinnersDefaultSetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveRecentWinnersDefaultSetting").valid())
                        return;
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveRecentWinnersDefaultSetting").ajaxSubmit(options);
                });
            });
        </script>
	</div>
    

    <%------------------------------
         Popularity
     -------------------------------%>
    <h3><a href="#">Popularity Setting</a></h3>
	<div>
        <form id="formSavePopularitySetting" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SavePopularitySetting").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                <tr>
                	<td><label>The number of recent days in which to caculate the popularity :</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.PopularityDaysBack %>" style="text-align:right"
                        type="text" id="txtPopularityDaysBack" name="popularityDaysBack" class="textbox digits required" maxlength="4" />
                    </td>
                </tr>
                <tr>
                	<td><label>Caculation method :</label></td>
                    <td>
                        <%: Html.DropDownList("popularityCalculationMethod", GetPopularityCaculationMethod(), new { @id = "btnPopularityCalculationMethod", @class="ddl" })%>
                    </td>
                </tr>
                <tr>
                	<td><label>Exclude other operators :</label></td>
                    <td>
                        <%: Html.CheckBox("popularityExcludeOtherOperators", this.Model.PopularityExcludeOtherOperators, new { @id = "btnPopularityExcludeOtherOperators" })%>
                        <label for="btnPopularityExcludeOtherOperators">Only caculate popularity within current operator.</label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <label>Not by country :</label></td>
                    <td>
                        <%: Html.CheckBox("popularityNotByCountry", this.Model.PopularityNotByCountry, new { @id = "btnPopularityNotByCountry" })%>
                        <input type="hidden" name="popularityConfigurationByCountry" id="txtPopularityConfigurationByCountry" value="<%=this.Model.PopularityConfigurationByCountry %>" />
                        <label for="btnPopularityNotByCountry"></label>
                    </td>
                </tr>
                <%
                    Dictionary<string, PopularityConfigurationByCountry> configurations = this.Model.GetPopularityConfigurationByCountry();
                    PopularityConfigurationByCountry configurationForAllCountries;
                    if (!configurations.TryGetValue("all", out configurationForAllCountries))
                        configurationForAllCountries = new PopularityConfigurationByCountry();
                %>
                <tr class="popularity_all_countries" style="display: none;">
                    <td style="text-align: right">All Countries = 
                    </td>
                    <td>
                        <a href="javascript:void(0)" data-selection="<%=Newtonsoft.Json.JsonConvert.SerializeObject(configurationForAllCountries).SafeHtmlEncode() %>">
                            Desktop Place: <span class="desktop_placed"><%=GetPopularityManualPlacementsText(configurationForAllCountries.DesktopPlaced).SafeHtmlEncode() %></span><br />
                            Mobile Place: <span class="mobile_placed"><%=GetPopularityManualPlacementsText(configurationForAllCountries.MobilePlaced).SafeHtmlEncode() %></span><br />
                            Desktop Exclude: <span class="desktop_excluded"><%=GetPopularityExcludeGamesText(configurationForAllCountries.DesktopExcluded).SafeHtmlEncode() %></span><br />
                            Mobile Exclude: <span class="mobile_excluded"><%=GetPopularityExcludeGamesText(configurationForAllCountries.MobileExcluded).SafeHtmlEncode() %></span><br />
                        </a>
                    </td>
                </tr>
                <% foreach (string countryCode in configurations.Keys)
                    {
                        if (countryCode == "all")
                            continue;

                        PopularityConfigurationByCountry configurationForSpecificCountry = configurations[countryCode];
                        %>
                <tr class="popularity_specific_country" style="display: none;">
                    <td style="text-align: right">
                        <%: Html.DropDownList( "country", new SelectList(s_Countries, "Value", "Text", countryCode), new { @style = "width:140px", @class = "country_selection" })%> =
                    </td>
                    <td>
                        <a href="javascript:void(0)" data-selection="<%=Newtonsoft.Json.JsonConvert.SerializeObject(configurationForSpecificCountry).SafeHtmlEncode() %>">
                            Desktop Place: <span class="desktop_placed"><%=GetPopularityManualPlacementsText(configurationForSpecificCountry.DesktopPlaced).SafeHtmlEncode() %></span><br />
                            Mobile Place: <span class="mobile_placed"><%=GetPopularityManualPlacementsText(configurationForSpecificCountry.MobilePlaced).SafeHtmlEncode() %></span><br />
                            Desktop Exclude: <span class="desktop_excluded"><%=GetPopularityExcludeGamesText(configurationForSpecificCountry.DesktopExcluded).SafeHtmlEncode() %></span><br />
                            Mobile Exclude: <span class="mobile_excluded"><%=GetPopularityExcludeGamesText(configurationForSpecificCountry.MobileExcluded).SafeHtmlEncode() %></span><br />
                        </a>
                    </td>
                </tr>
                <% } %>
                <tr class="popularity_specific_country" style="display: none;">
                    <td style="text-align: right">
                        <%: Html.DropDownList( "country", s_Countries, new { @style = "width:140px", @class = "country_selection" })%> =
                    </td>
                    <td>
                        <a href="javascript:void(0)" data-selection="{}">
                            Desktop Place: <span class="desktop_placed">None</span><br />
                            Mobile Place: <span class="mobile_placed">None</span><br />
                            Desktop Exclude: <span class="desktop_excluded">None</span><br />
                            Mobile Exclude: <span class="mobile_excluded">None</span><br />
                        </a>
                    </td>
                </tr>
            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSavePopularitySetting">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/javascript">
            $(function () {
                if ($('#btnPopularityNotByCountry').prop('checked')) {
                    $('.popularity_all_countries').hide();
                    $('.popularity_specific_country').hide();
                }
                else {
                    $('.popularity_all_countries').show();
                    $('.popularity_specific_country').show();
                }

                $('#btnPopularityNotByCountry').click(function (e) {
                    if ($('#btnPopularityNotByCountry').prop('checked')) {
                        $('.popularity_all_countries').hide();
                        $('.popularity_specific_country').hide();
                    }
                    else {
                        $('.popularity_all_countries').show();
                        $('.popularity_specific_country').show();
                    }
                });

                var $ddls = $('select.country_selection', $('#formSavePopularitySetting'));
                $ddls.each(function (i, ddl) {
                    var $ddl = $(ddl);
                    $ddl.change(function (e) {
                        var $row = $(this).parent().parent().eq(0);

                        // if value is selected
                        if ($(this).val() != '') {
                            // if this is the last row
                            if ($row.next('tr').length == 0) {
                                var $newRow = $row.clone(true);
                                var html = 'Desktop Place: <span class="desktop_placed">None</span><br />';
                                html += 'Mobile Place: <span class="mobile_placed">None</span><br />';
                                html += 'Desktop Exclude: <span class="desktop_excluded">None</span><br />';
                                html += 'Mobile Exclude: <span class="mobile_excluded">None</span><br />';
                                $('a', $newRow).html(html);
                                $('a', $newRow).data('selection', '');
                                $newRow.insertAfter($row);

                                $('input', $row).focus();
                            }
                        }
                        //updateCountrySpecificCfg($row.data('for'));
                    });
                });

                $('.popularity_all_countries a, .popularity_specific_country a').click(function (e) {
                    e.preventDefault();

                    var json = $(this).data('selection');
                    setTimeout(function () {
                        $('#popularity-country-specific-editor-tabs').tabs("option", "selected", 0);
                        setDesktopManualPlacements(json.desktopPlaced);
                        setMobileManualPlacements(json.mobilePlaced);
                        setDesktopExcludeGames(json.desktopExcluded);
                        setMobileExcludeGames(json.mobileExcluded);
                    }, 10);
                        
                    $('#dlgPopularityCountrySpecific').data('a', $(this));
                    $('#dlgPopularityCountrySpecific').dialog({
                        width: 700,
                        minHeight: 630,
                        //height: $(document.body).height() - 50,
                        //dataCss: { padding: "0px" },
                        modal: true,
                        resizable: false,
                        buttons: {
                            Ok: function () {
                                onDialogButtonOkClick();
                                $(this).dialog("close");
                            },
                            Cancel: function () {
                                $(this).dialog("close");
                            }
                        }
                    });
                });

                $("#formSavePopularitySetting").validate();
                $('#btnSavePopularitySetting').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSavePopularitySetting").valid())
                        return;
                    var json = {};
                    if (!$('#btnPopularityNotByCountry').prop('checked')) {
                        if ($('.popularity_all_countries a').data('selection'))
                            json["all"] = $('.popularity_all_countries a').data('selection');
                        else
                            json["all"] = {};
                            
                        $('.popularity_specific_country').each(function () {
                            var countryCode = $('select', $(this)).val();
                            if (countryCode == '')
                                return;
                                    
                            if ($('a', $(this)).data('selection'))
                                json[countryCode] = $('a', $(this)).data('selection');
                            else
                                json[countryCode] = {};
                        });
                    }
                    $('#txtPopularityConfigurationByCountry').val(JSON.stringify(json));
                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSavePopularitySetting").ajaxSubmit(options);
                });
            });

            function onDialogButtonOkClick() {
                var desktopManualPlacements = getDesktopManualPlacements();
                var mobileManualPlacements = getMobileManualPlacements();
                var desktopExcludeGames = getDesktopExcludeGames();
                var mobileExcludeGames = getMobileExcludeGames();

                var $a = $('#dlgPopularityCountrySpecific').data('a');
                    
                $('.desktop_placed', $a).html(getDisplayText(desktopManualPlacements.names));
                $('.mobile_placed', $a).html(getDisplayText(mobileManualPlacements.names));
                $('.desktop_excluded', $a).html(getDisplayText(desktopExcludeGames.names));
                $('.mobile_excluded', $a).html(getDisplayText(mobileExcludeGames.names));

                var json = {};
                json.desktopPlaced = desktopManualPlacements.ids;
                json.mobilePlaced = mobileManualPlacements.ids;
                json.desktopExcluded = desktopExcludeGames.ids;
                json.mobileExcluded = mobileExcludeGames.ids;
                $a.data('selection', json);
            }

            function getDisplayText(names) {
                if (names.length == 0)
                    return "None";

                var text = "";
                for (var i = 0; i < names.length; i++) {
                    if (i >= 3)
                        break;
                    text += names[i] + ", ";
                }
                if (names.length > 3)
                    return text + " ...";
                else
                    return text.substring(0, text.length - 2);
            }
        </script>
	</div>

     <%------------------------------
         Recommendation Config
     -------------------------------%>
    <h3><a href="#">Recommendation Config</a></h3>
	<div>
        <form id="formSaveRecommendationConfig" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("SaveRecommendationConfig").SafeHtmlEncode() %>">
            <table border="0" cellspacing="0" cellpadding="5">
                <tr>
                	<td><label>Exclude from Game Rec List:</label></td>
                    <td class="exclude_games_section">
                        <div class="excludeGames">
                        </div>
                        <input autocomplete="off" style="text-align:right"
                        type="text" id="txtRecommendationExcludeGame" name="recommendationExcludeGame" class="textbox" />
                        <input value="<%= this.Model.RecommendationExcludeGames %>" type="hidden" id="hRecommendationExcludeGames" name="recommendationExcludeGames"  />
                    </td>
                </tr>                
                <tr class="TrSubTitle">
                    <td colspan="2">
                       <strong>Player Rec List</strong>
                    </td>
                </tr>
                <tr>
                	<td><label>Top Games (maximum 50):</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.RecommendationMaxPlayerRecords %>" style="text-align:right"
                        type="text" id="txtRecommendationMaxPlayerRecords" name="recommendationMaxPlayerRecords" class="textbox digits required" maxlength="4" />
                    </td>
                </tr>
                <tr class="TrSubTitle">
                    <td colspan="2">
                        <strong>Game Rec List</strong>
                    </td>
                </tr>
                <tr>
                	<td><label>Top Games (maximum 50):</label></td>
                    <td>
                        <input autocomplete="off" value="<%= this.Model.RecommendationMaxGameRecords %>" style="text-align:right"
                        type="text" id="txtRecommendationMaxGameRecords" name="recommendationMaxGameRecords" class="textbox digits required" maxlength="4" />
                    </td>
                </tr>
            </table>
            <p>
                <% if(DomainManager.AllowEdit()) { %>
                <button id="btnSaveRecommendationConfig">Save</button>
                <% } %>
            </p>
        </form>
        <script type="text/html" id="exclude-game-template">
            <# var d=arguments[0]; #>
            <span class="excludeGame" title="<#= d.htmlEncode() #>"><#= d.htmlEncode() #><a href="javascript:void(0)"><span onclick="removeExcludeGame(this)"></span></a></span>
        </script>
        <script type="text/javascript">
            var allGames = <%=GetGamesJson()%>;
            function removeExcludeGame(el) {
                var $el = $(el);
                var $c = $el.parents('.exclude_games_section');
                $el.parents('span.excludeGame').remove();
                syncExcludeGames($c);
            }

            function syncExcludeGames($c) {
                var games = ',';
                var $games = $c.find('div.excludeGames span.excludeGame');
                for (var i = 0; i < $games.length; i++) {
                    games = games + $games[i].title + ',';
                }
                $c.find('#hRecommendationExcludeGames').val(games);
            }

            function createExcludeGame($el) {
                var $c = $el.parents('.exclude_games_section');

                var newExcludeGame = $el.val();
                if (newExcludeGame == null)
                    return;
                if (allGames.indexOf(newExcludeGame) < 0)
                    return;
                if (newExcludeGame.length > 0) {
                    $($('#exclude-game-template').parseTemplate(newExcludeGame)).appendTo($c.find('div.excludeGames'));
                    $el.val('');
                    syncExcludeGames($c);
                }
            }

            $(function () {
                $("#txtRecommendationExcludeGame").autocomplete({
                    source: allGames
                });

                $('#txtRecommendationExcludeGame').keypress(function (e) {
                    if (e.keyCode == 13) {
                        e.preventDefault();
                        createExcludeGame($(this));
                    }
                });

                <% 
                    string[] excludeGames = this.Model.RecommendationExcludeGames.DefaultIfNullOrEmpty(string.Empty).Split(',');
                    foreach (string excludeGame in excludeGames)
                    {
                        if (string.IsNullOrWhiteSpace(excludeGame))
                            continue; %>
                var $c_excludeGames = $('#txtRecommendationExcludeGame').parents('.exclude_games_section').find('div.excludeGames');
                $($('#exclude-game-template').parseTemplate('<%= excludeGame.SafeJavascriptStringEncode() %>')).appendTo($c_excludeGames);
                        <%
                    }
                %>

                $("#formSaveRecommendationConfig").validate();
                $('#btnSaveRecommendationConfig').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();
                    if (!$("#formSaveRecommendationConfig").valid())
                        return;

                    var playerRecList = $('#txtRecommendationMaxPlayerRecords').val();
                    var gameRecList = $('#txtRecommendationMaxGameRecords').val();
                    if (playerRecList > 50 || gameRecList > 50) {
                        alert('Top games can\' exceed 50');
                        return;
                    }

                    var options = {
                        dataType: 'json',
                        success: function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                        }
                    };
                    $('#loading').show();
                    $("#formSaveRecommendationConfig").ajaxSubmit(options);
                });
            });
        </script>
	</div>

    <% if (this.Model.DomainID == Constant.SystemDomainID) { %>
       <%------------------------------
         Data Dictionary
     -------------------------------%>
	<h3><a href="#">Data Dictionary</a></h3>
    <div>
        <% Html.RenderPartial("DataDictionary", this.ViewData.Merge(new { Type = "GameCategory", Title = "Game Category" }));%>
        <% Html.RenderPartial("DataDictionary", this.ViewData.Merge(new { Type = "ReportCategory", Title = "Report Category" }));%>
        <% Html.RenderPartial("DataDictionary", this.ViewData.Merge(new { Type = "InvoicingGroup", Title = "Invoicing Group" }));%>
        <% Html.RenderPartial("DataDictionary", this.ViewData.Merge(new { Type = "ClientType", Title = "Client Type" }));%>

        <% Html.RenderPartial("DataDictionary", this.ViewData.Merge(new { Type = "LiveCasinoCategory", Title = "Live Casino Category" }));%>
    </div>
    <% } %>

<% } //if( this.Model != null ) %>

    
</div>

    <div id="dlgPopularityCountrySpecific" title="Popularity Country Specific" style="display: none;">
        <div id="popularity-country-specific-editor-tabs">
            <ul>
                <li><a href="#tabs-1">Manual Placements</a></li>
                <li><a href="#tabs-2">Exclude Games</a></li>
            </ul>
            <div id="tabs-1">
                <div class="LeftColumn">
                    <table border="0" cellspacing="0" cellpadding="5" id="popularityDesktopManualPlacements">
                        <tr class="fix-row">
                            <th></th>
                            <th>Desktop<br />
                                Place</th>
                        </tr>
                        <% for (int i = 1; i <= 10; i++)
                           { %>
                        <tr class="fix-row">
                            <td align="right">
                                <%=i.ToString(CultureInfo.InvariantCulture) %>
                            </td>
                            <td>
                                <input autocomplete="off" style="text-align: right"
                                    type="text" class="textbox manualPlacement" maxlength="100" />
                            </td>
                        </tr>
                        <% } %>
                        <tr class="fix-row">
                            <td></td>
                            <td>
                                <a href="javascript:void(0)" id="btnAddPopularityDesktopPlacements">Add</a>
                                <input autocomplete="off" style="text-align: right; width: 100px;" id="txtPopularityDesktopPlacementsCount"
                                    type="text" name="popularityPlacementsCount" class="textbox digits" maxlength="2" />
                            </td>
                        </tr>
                        <tr class="fix-row">
                            <td></td>
                            <td>
                                <a href="javascript:void(0)" id="btnRemoveAllPopularityDesktopPlacements">Remove All</a>
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="RightColumn">
                    <table border="0" cellspacing="0" cellpadding="5" id="popularityMobileManualPlacements">
                        <tr class="fix-row">
                            <th></th>
                            <th>Mobile<br />
                                Place</th>
                        </tr>
                        <% for (int i = 1; i <= 10; i++)
                           { %>
                        <tr class="fix-row">
                            <td align="right">
                                <%=i.ToString(CultureInfo.InvariantCulture) %>
                            </td>
                            <td>
                                <input autocomplete="off" style="text-align: right"
                                    type="text" class="textbox manualPlacement" maxlength="100" />
                            </td>
                        </tr>
                        <% } %>
                        <tr class="fix-row">
                            <td></td>
                            <td>
                                <a href="javascript:void(0)" id="btnAddPopularityMobilePlacements">Add</a>
                                <input autocomplete="off" style="text-align: right; width: 100px;" id="txtPopularityMobilePlacementsCount"
                                    type="text" name="popularityPlacementsCount" class="textbox digits" maxlength="2" />
                            </td>
                        </tr>
                        <tr class="fix-row">
                            <td></td>
                            <td>
                                <a href="javascript:void(0)" id="btnRemoveAllPopularityMobilePlacements">Remove All</a>
                            </td>
                        </tr>
                    </table>
                </div>
            </div>
            <div id="tabs-2">
                <div class="LeftColumn">
                    <div style="text-align: center;">
                        <strong>Desktop</strong>
                    </div>
                    <div id="desktopExcludeTree">
                        <ul>
                            <% foreach (VendorID vendor in s_DesktopVendors)
                               { %>
                            <li>
                                <%=vendor.ToString() %>
                                <% 
                                   List<ceCasinoGameBaseEx> games = s_DesktopGames.Where(g => g.VendorID == vendor).ToList();
                                %>
                                <% if (games.Any())
                                   { %>
                                <ul>
                                    <% foreach (ceCasinoGameBaseEx game in games)
                                       { %>
                                    <li id="<%=game.ID.ToString(CultureInfo.InvariantCulture) %>">
                                        <%=string.Format("{0} ({1})", game.GameName, game.GameCode).SafeHtmlEncode() %>
                                    </li>
                                    <% } %>
                                </ul>
                                <% } %>
                            </li>
                            <% } %>
                        </ul>
                    </div>
                </div>
                <div class="RightColumn">
                    <div style="text-align: center;">
                        <strong>Mobile</strong>
                    </div>
                    <div id="mobileExcludeTree">
                        <ul>
                            <% foreach (VendorID vendor in s_MobileVendors)
                               { %>
                            <li>
                                <%=vendor.ToString() %>
                                <% 
                                   List<ceCasinoGameBaseEx> games = s_MobileGames.Where(g => g.VendorID == vendor).ToList();
                                %>
                                <% if (games.Any())
                                   { %>
                                <ul>
                                    <% foreach (ceCasinoGameBaseEx game in games)
                                       { %>
                                    <li id="<%=game.ID.ToString(CultureInfo.InvariantCulture) %>">
                                        <%=string.Format("{0} ({1})", game.GameName, game.GameCode).SafeHtmlEncode() %>
                                    </li>
                                    <% } %>
                                </ul>
                                <% } %>
                            </li>
                            <% } %>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
        <script type="text/javascript">
            var desktopGames = <%=GetDesktopGamesJson()%>;
            var mobileGames = <%=GetMobileGamesJson()%>;
            var gameNameIDMapping = <%=GetGameNameIDMappingJson()%>;
            var gameIDNameMapping = <%=GetGameIDNameMappingJson()%>;

            function getDesktopManualPlacements() {
                return getManualPlacements('popularityDesktopManualPlacements');
            }

            function getMobileManualPlacements() {
                return getManualPlacements('popularityMobileManualPlacements');
            }

            function getDesktopExcludeGames() {
                return getExcludeGames('desktopExcludeTree');
            }

            function getMobileExcludeGames() {
                return getExcludeGames('mobileExcludeTree');
            }

            function setDesktopManualPlacements(ids) {
                setManualPlacements('popularityDesktopManualPlacements', ids);
            }

            function setMobileManualPlacements(ids) {
                setManualPlacements('popularityMobileManualPlacements', ids);
            }

            function setDesktopExcludeGames(ids) {
                setExcludeGames('desktopExcludeTree', ids);
            }

            function setMobileExcludeGames(ids) {
                setExcludeGames('mobileExcludeTree', ids);
            }

            function getManualPlacements(tableName) {
                var ids = [];
                var names = [];

                var items = $('#' + tableName + ' .manualPlacement');
                for (var i = 0; i < items.length; i++) {
                    var id = gameNameIDMapping[$(items[i]).val()];
                    if (id && ids.indexOf(id) < 0) {
                        ids.push(id);
                        names.push($(items[i]).val());
                    }
                }

                var json = {};
                json.ids = ids;
                json.names = names;
                return json;
            }

            function getExcludeGames(treeName) {
                var ids = [];
                var names = [];

                var rootNode = $('#' + treeName).fancytree('getTree').rootNode;
                for (var i = 0; i < rootNode.children.length; i++) {
                    var vendorNode = rootNode.children[i];
                    for (var j = 0; j < vendorNode.children.length; j++) {
                        var gameNode = vendorNode.children[j];
                        var id = parseInt(gameNode.key);
                        if (isNaN(id))
                            continue;

                        if (gameNode.selected) {
                            ids.push(id);
                            names.push(gameNode.title);
                        }
                    }
                }

                var json = {};
                json.ids = ids;
                json.names = names;
                return json;
            }

            function setManualPlacements(tableName, ids) {
                if (!ids)
                    ids = [];

                $("#" + tableName + " tr:not(.fix-row)").remove();
                $("#" + tableName + " input").val('');

                for (var i = 10; i < ids.length; i++) {
                    var $row = $('#popularityDesktopManualPlacements tr').slice(-3).first();
                    var $newRow = $row.clone(false);
                    $(".manualPlacement", $newRow).val('');
                    $("td", $newRow).first().html($('#popularityDesktopManualPlacements tr').length - 2);
                    $newRow.removeAttr('class');
                    $newRow.insertAfter($row)

                    $(".manualPlacement", $newRow).autocomplete({
                        source: desktopGames,
                        minLength: 0
                    }).focus(function(){            
                        $(this).trigger('keydown.autocomplete');
                    });
                }

                var items = $('#' + tableName + ' .manualPlacement');
                for (var i = 0; i < ids.length; i++) {
                    var name = gameIDNameMapping[ids[i]];
                    $(items[i]).val(name);
                }
            }

            function setExcludeGames(treeName, ids) {
                if (!ids)
                    ids = [];

                var rootNode = $('#' + treeName).fancytree('getTree').rootNode;
                for (var i = 0; i < rootNode.children.length; i++) {
                    var vendorNode = rootNode.children[i];
                    vendorNode.setExpanded(false);
                    for (var j = 0; j < vendorNode.children.length; j++) {
                        var gameNode = vendorNode.children[j];
                        gameNode.setExpanded(false);
                        var id = parseInt(gameNode.key);
                        if (isNaN(id))
                            continue;
                        if (ids.indexOf(id) >= 0) {
                            gameNode.setSelected(true);
                        }
                        else {
                            gameNode.setSelected(false);
                        }
                    }
                }
            }

            $(function () {
                $('#popularity-country-specific-editor-tabs').tabs();

                $("#popularityDesktopManualPlacements .manualPlacement").autocomplete({
                    source: desktopGames,
                    minLength: 0
                }).focus(function(){            
                    $(this).trigger('keydown.autocomplete');
                });

                $("#popularityDesktopManualPlacements .manualPlacement").blur(function (e) {
                    if (desktopGames.indexOf($(this).val()) < 0)
                        $(this).val('');
                });

                $("#popularityMobileManualPlacements .manualPlacement").autocomplete({
                    source: mobileGames,
                    minLength: 0
                }).focus(function(){            
                    $(this).trigger('keydown.autocomplete');
                });

                $("#popularityMobileManualPlacements .manualPlacement").blur(function (e) {
                    if (mobileGames.indexOf($(this).val()) < 0)
                        $(this).val('');
                });

                $('#btnAddPopularityDesktopPlacements').unbind('click').click(function (e) {
                    e.preventDefault();
                    var number = parseInt($('#txtPopularityDesktopPlacementsCount').val());
                    if (isNaN(number))
                        return;

                    if (number <= 0)
                        return;

                    //alert($('#popularityDesktopManualPlacements tr').length);

                    for (var i = 0; i < number; i++) {
                        var $row = $('#popularityDesktopManualPlacements tr').slice(-3).first();
                        var $newRow = $row.clone(false);
                        $(".manualPlacement", $newRow).val('');
                        $("td", $newRow).first().html($('#popularityDesktopManualPlacements tr').length - 2);
                        $newRow.removeAttr('class');
                        $newRow.insertAfter($row)

                        $(".manualPlacement", $newRow).autocomplete({
                            source: desktopGames,
                            minLength: 0
                        }).focus(function(){            
                            $(this).trigger('keydown.autocomplete');
                        });
                    }
                });

                $('#btnRemoveAllPopularityDesktopPlacements').unbind('click').click(function (e) {
                    $("#popularityDesktopManualPlacements tr:not(.fix-row)").remove();
                    $("#popularityDesktopManualPlacements input").val('');
                });

                $('#btnAddPopularityMobilePlacements').unbind('click').click(function (e) {
                    var number = parseInt($('#txtPopularityMobilePlacementsCount').val());
                    if (isNaN(number))
                        return;

                    if (number <= 0)
                        return;

                    //alert($('#popularityMobileManualPlacements tr').length);

                    for (var i = 0; i < number; i++) {
                        var $row = $('#popularityMobileManualPlacements tr').slice(-3).first();
                        var $newRow = $row.clone(false);
                        $(".manualPlacement", $newRow).val('');
                        $("td", $newRow).first().html($('#popularityMobileManualPlacements tr').length - 2);
                        $newRow.removeAttr('class');
                        $newRow.insertAfter($row)

                        $(".manualPlacement", $newRow).autocomplete({
                            source: mobileGames,
                            minLength: 0
                        }).focus(function(){            
                            $(this).trigger('keydown.autocomplete');
                        });
                    }
                });

                $('#btnRemoveAllPopularityMobilePlacements').unbind('click').click(function (e) {
                    $("#popularityMobileManualPlacements tr:not(.fix-row)").remove();
                    $("#popularityMobileManualPlacements input").val('');
                });

                $('#desktopExcludeTree').fancytree({
                    checkbox: true,
                    selectMode: 3
                });

                $('#mobileExcludeTree').fancytree({
                    checkbox: true,
                    selectMode: 3
                });

                $('#btnSave').button({
                    icons: {
                        primary: "ui-icon-disk"
                    }
                }).click(function (e) {
                    e.preventDefault();

                    
                });

                $('#btnCancel').button({
                    icons: {
                        primary: "ui-icon-cancel"
                    }
                }).click(function (e) {
                    e.preventDefault();
                });
            });
        </script>

    </div>

    <br /><br />


         <script>
     $(".ui-accordion .ui-accordion-header:contains('Player')").hide();
     if(this.location.href.indexOf("#testMode")>0){
          $(".ui-accordion .ui-accordion-header:contains('Player')").show();
     }
     </script>
</asp:Content>
