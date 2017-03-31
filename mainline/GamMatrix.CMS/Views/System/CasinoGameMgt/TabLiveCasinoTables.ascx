<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="CasinoEngine" %>
<script language="C#" type="text/C#" runat="server">
    private string GetEnabledVendor()
    {
        return string.Join(",", CasinoEngineClient.GetEnabledLiveCasinoVendors(this.Model));
    }
</script>

<div id="live-casino-tables-links" class="casino-mgt-operations">
    <ul>
        <li>
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                @action = "Dialog",
                @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                @relativePath = "/.config/live_casino_category.xml".DefaultEncrypt(),
                @searchPattner = "",
                } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
        </li>
    </ul>
</div>
<div id="flash-place-holder"></div>
<script language="javascript" type="text/javascript">
    $(function () {
        var flashvars = {
            cmSession: '<%= Profile.AsCustomProfile().SessionID.SafeJavascriptStringEncode() %>',
            vendors: '<%= GetEnabledVendor().SafeJavascriptStringEncode() %>',
            getGameXmlUrl: '<%= this.Url.RouteUrl("CasinoGameMgt", new { @action = "GetLiveCasinoTableCategoryXml", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>',
            getGridXmlUrl: '<%= this.Url.RouteUrl("CasinoGameMgt", new { @action = "GetLiveCasinoTableListXml", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>',
            saveGameCategoryUrl : '<%= this.Url.RouteUrl("CasinoGameMgt", new { @action = "SaveTableCategoryXml", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @_sid = Profile.AsCustomProfile().SessionID }).SafeJavascriptStringEncode() %>',
            hideCreateCategoryMenu: "true",
            hideCreateGroupMenu: "true",
            disableCategoryDeleteButton : "true",
            showGameEditButton : "true"
        };
        var params = {
            menu: "false",
            wmode: "transparent",
            allowScriptAccess: "always",
            allowNetworking: "all",
            allowFullscreen: "true",
            allowFullScreenInteractive: "true"
        };
        var attributes = {
            id: "ctlCategoryTree",
            name: "ctlCategoryTree"
        };

        swfobject.embedSWF("/images/CategoryTree.swf", "flash-place-holder", "100%", $(document.body).height() - 100, "10.0.0", "/images/expressInstall.swf", flashvars, params, attributes);

        $('#live-casino-tables-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });
    });

    function openLiveCasinoEditor( isCategory, id, label){
        var url = '<%= this.Url.RouteUrl("CasinoGameMgt", new { @action = "EditLiveCasinoTranslation", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?isCategory=';
        url += isCategory ? "true" : "false";
        url = url + '&id=' + encodeURIComponent(id) + '&label=' + encodeURIComponent(label);
        window.open( url, '_blank');
    }
</script>