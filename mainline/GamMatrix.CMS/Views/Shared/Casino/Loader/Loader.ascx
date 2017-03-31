<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Casino.Game>" %>

<script language="C#" runat="server" type="text/C#">
    private string GetGameUrl(bool realMoney)
    {
        string url = this.Url.RouteUrl("CasinoLoader", new { 
            @action = this.Model.VendorID.ToString(),
            @gameID = this.Model.ID,
            @realMoney = realMoney
        });
        return url;
    }
</script>

<style type="text/css">
#ifmGameLoader { width:800px; height:600px; overflow:hidden; }
#game-loader-wrapper .toolbar { width:800px; margin:0 auto; height:50px; line-height:50px; vertical-align:middle;  }
</style>

<div id="game-loader-wrapper" class="content-wrapper">
<%: Html.H1( this.Model.Title ) %>
<ui:Panel runat="server" ID="pnGameLoader">
<center>
<% if( !Profile.IsAuthenticated ) { %>
<%: Html.InformationMessage( this.GetMetadata(".AnonymousMessage") ) %>
<% } %>
<div class="toolbar">

<%: Html.Button( this.GetMetadata(".Fullscreen"), new { @id = "btnOpenGameInFullscreen", @onclick = "openGameInFullscreen()" })%>

<% if (!string.IsNullOrWhiteSpace(this.Model.HelpFile))
   { %>
<%: Html.Button(this.GetMetadata(".GameRules"), new { @id = "btnOpenGameRules", @onclick = "openGameRules()" })%>
<% } %>

<% if( Profile.IsAuthenticated )
   { %>
<%: Html.Button(this.GetMetadata(".PlayWithRealMoney"), new { @id = "btnPlayWithRealMoney", @onclick = "openGame()" })%>
<% } %>

<%: Html.Button(this.GetMetadata(".PlayForFun"), new { @id = "btnPlayForFun", @onclick = "openFunGame()" })%>
</div>
<iframe frameborder="0" scrolling="no" id="ifmGameLoader" allowTransparency="true" src="<%= GetGameUrl(Profile.IsAuthenticated) %>">
</iframe>
</center>

</ui:Panel>
</div>


<script language="javascript" type="text/javascript">
    function openGameInFullscreen() {
        window.open($('#ifmGameLoader').attr('src')
        , "_blank"
        , "status=1,toolbar=0,location=0,menubar=0,resizable=1,scrollbars=0,left=0,top=0,width=" + window.screen.width + ",height=" + window.screen.height
        );
    }

    function openGameRules() {
        var url = '<%= Settings.Casino_NetEntGameRulesBaseUrl.SafeJavascriptStringEncode() %><%= this.Model.HelpFile.SafeJavascriptStringEncode()%>';
        window.open(url
        , "_blank"
        , "status=1,toolbar=0,location=0,menubar=0,resizable=1,scrollbars=1,left=0,top=0,width=450,height=" + window.screen.height
        );
    }

    var g_isRealMoneyMode = <%= Profile.IsAuthenticated.ToString().ToLowerInvariant() %>;
    function openGame() {
        $('#ifmGameLoader').attr('src', '<%= GetGameUrl(true).SafeJavascriptStringEncode() %>');
        g_isRealMoneyMode = true;
        refreshButtons();
    }

    function openFunGame() {
        $('#ifmGameLoader').attr('src', '<%= GetGameUrl(false).SafeJavascriptStringEncode() %>');
        g_isRealMoneyMode = false;
        refreshButtons();
    }

    function refreshButtons(){
        if( g_isRealMoneyMode ){
            $('#btnPlayForFun').show();
            $('#btnPlayWithRealMoney').hide();
        }
        else{
            $('#btnPlayForFun').hide();
            $('#btnPlayWithRealMoney').show();
        }
    }
    $(function(){refreshButtons(); });
</script>
