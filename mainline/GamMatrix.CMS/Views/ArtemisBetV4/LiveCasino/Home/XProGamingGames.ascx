<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="LiveCasino" %>
<script runat="server" type="text/C#">

    int index = 0;
    int gameCount = 0;
    string Field_Status_Title;
    string Field_Limits_Title;
    string Field_OpenHour_Title;
    string Field_CloseHour_Title;
    string Field_Dealer_Title;
    string Button_ViewTable_Text;
    string Field_Status_Online;
    string Field_Status_Offline;

    protected override void OnInit(EventArgs e)
    {
        Field_Status_Title = this.GetMetadata(".Status").SafeHtmlEncode();
        Field_Limits_Title = this.GetMetadata(".Limits").SafeHtmlEncode();
        Field_OpenHour_Title = this.GetMetadata(".OpenHour").SafeHtmlEncode();
        Field_CloseHour_Title = this.GetMetadata(".CloseHour").SafeHtmlEncode();
        Field_Dealer_Title = this.GetMetadata(".DealerName").SafeHtmlEncode();
        Button_ViewTable_Text = this.GetMetadata(".ViewTable").SafeHtmlEncode();
        Field_Status_Online = this.GetMetadata(".Status_Online").SafeHtmlEncode();
        Field_Status_Offline = this.GetMetadata(".Status_Offline").SafeHtmlEncode();
        base.OnInit(e);
    }

    private string BuildeGameHtml(Game game)
    {
        if (game == null)
            return string.Empty;
        StringBuilder sbGame = new StringBuilder();

        bool isOpen = game.IsOpen;

        int limitSetIndex = 0;
        LimitSet limitSet = null;

        if (game.LimitSets.Count > 0)
            limitSet = game.LimitSets[0];

        string limitSetID = string.Empty;
        string limitSetHtml = string.Empty;
        string script = string.Empty;

        do
        {
            if (limitSet != null)
            {
                limitSetID = limitSet.ID;
                limitSetHtml = string.Format("{0} - {1}", limitSet.MinBet.Value.ToString("N0"), limitSet.MaxBet.Value.ToString("N0"));
            }

            if (isOpen)
            {
                /*script = string.Format("this.blur();javascript:window.open('{0}', 'livecasinogame', {1})"
                                   , this.Url.RouteUrl("LiveCasinoLobby"
                                   , new { @action = "XPROLoader", @gameID = game.GameID, @limitSetID = limitSetID }).SafeJavascriptStringEncode()
                                   , !string.IsNullOrEmpty(game.WindowParams) ? game.WindowParams : "'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'"
                                   );*/
                script = string.Format("this.blur();openGame('{0}');", this.Url.RouteUrl("LiveCasinoLobby", new { @action = "XPROLoader", @gameID = game.GameID, @limitSetID = limitSetID }).SafeJavascriptStringEncode());
            }
//squarebox
            sbGame.AppendLine(string.Empty);
            sbGame.AppendFormat(@"<a class=""smallbox{11}"" href=""javascript:void(0);"" onclick=""{0}"" title=""{1}""><div class=""frame""><h4>{1}</h4><ul><li><span>{7}</span> {2}</li><li><span>{8}</span> {3}</li><li><span>{9}</span> {4}</li><li><span>{10}</span> {5}</li></ul><div class=""  GoldButton  LIVE {12}  ""><span  class=""GoldButtonText"">{6}</span></div></div></a>",
               script, 
               game.GameName,
               isOpen ? Field_Status_Online : Field_Status_Offline,
               limitSetHtml,
               string.Format("{0} - {1}",
               game.GetOpenHour().SafeHtmlEncode(),
               game.GetCloseHour().SafeHtmlEncode()),
               game.DealerName.SafeHtmlEncode(),
               isOpen ? Button_ViewTable_Text : Field_Status_Offline,
               Field_Status_Title,
               Field_Limits_Title,
               Field_OpenHour_Title,
               Field_Dealer_Title,
               index >= 1 ? " hide" : string.Empty,
               isOpen ? "online":"Offline"
               );

            index++;
            limitSetIndex++;
            if (isOpen && limitSetIndex < game.LimitSets.Count)
                limitSet = game.LimitSets[limitSetIndex];
            else
                break;

        } while (true);

        return sbGame.ToString();
    }    
</script>
<div id="livecasino_gameswrapper">
<div class="row-fluid" id="gamelist">
    <% 
        List<Game> games = GameManager.GetGameList();
        Type enumGameType = typeof(GameType);
        foreach (string gameTypeName in Enum.GetNames(enumGameType))
        {
            if (gameTypeName.Equals("AllGames", StringComparison.OrdinalIgnoreCase))
                continue;
            index = 0;
            GameType gameType = (GameType)Enum.Parse(enumGameType, gameTypeName, true);
    %><div class="Col4"><div class="Col4-Content <%=gameTypeName %>"><h3><%= this.GetMetadata("/MetaData/LiveCasino/GameCategory/" + gameTypeName + ".Text").SafeHtmlEncode()%></h3><span class="vgirl"></span><%
            if (games.Exists(g => g.GameType == gameType))
              {
gameCount = 0 ;
                  foreach (Game game in games.Where(g => g.GameType == gameType))
                  {
            %><%=BuildeGameHtml(game)%><%        
            gameCount++;                  
              }
          }%><span class="vmoregame"><%=string.Format(this.GetMetadata(".More_Games_Text"),
gameCount.ToString(),
this.GetMetadata("/MetaData/LiveCasino/GameCategory/" + gameTypeName + ".Text").SafeHtmlEncode()
              )%></span></div></div>
    <% } %>
    <div class="clear"></div>
</div>
<div class="row-fluid"><button id="btnShowMoreTables" class="button squarebutton"><span class="lightbg"><%=this.GetMetadata(".Button_More") %></span></button></div></div>

<div class="row-fluid" id="livecasino-dialog" style=" display:none; overflow:hidden;"><div style=" padding:10px; background-color:#999; border-radius:5px;"><button class="button squarebutton" onclick="closeGame();" style=" margin-bottom:10px;"><span class="GoldButtonText"><%=this.GetMetadata(".BacktoLobby").SafeHtmlEncode() %></span></button><div style="width:100%; height:690px;"><iframe id="livecasinoIframe" src="" style=" width:100%; height:690px;  overflow:hidden" allowTransparency="true" frameborder="0" scrolling="no"></iframe></div><button class="button squarebutton" onclick="closeGame();" style=" margin-top:8px;"><span class="GoldButtonText"><%=this.GetMetadata(".BacktoLobby").SafeHtmlEncode() %></span></button></div></div>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    function ShowMoreGames(evt) {
        if ($("#livecasino_gameswrapper").find(".smallbox.hide").length > 0) {
            $("#livecasino_gameswrapper").find(".smallbox.hide").addClass("unhide").removeClass("hide");
            $(this).hide();
            $(".vmoregame").hide();
        }
        else {
            $("#livecasino_gameswrapper").find(".smallbox.unhide").addClass("hide").removeClass("unhide");
        }
    }
    function openGame(_src) {
        $("#livecasinoIframe").attr("src", "");
        _src = _src.indexOf("?") > 0 ? (_src + "&_t=" + new Date().getTime()) : (_src + "?_t=" + new Date().getTime())
        //_src = "http://livegames.xprogaming.com/GeneralGame.aspx?audienceType=1&gameID=10&operatorID=79&languageID=9&loginToken=&securityCode=1D54E163CAB9CB02B5CF927119D2649E";
        $("#livecasinoIframe").attr("src", _src);
        $("#livecasino_gameswrapper").slideUp();
        $("#livecasino-dialog").slideDown();
        resetGameFrameHeight();
    }
    var resetGameFrameHeight = function(){
        $("#livecasinoIframe").height($("#livecasinoIframe").width()/1000*640);
        $("#livecasino-dialog div div").height($("#livecasinoIframe").height());
    };
    $(window).resize(function(){
        resetGameFrameHeight();
    });
    function closeGame() {
        $("#livecasino-dialog").slideUp();
        $("#livecasino_gameswrapper").slideDown();
        $("#livecasinoIframe").attr("src", "");
    }
    $(document).ready(function () {
        $("#btnShowMoreTables").bind("click", ShowMoreGames);

        var highestHeight = 0;
        $("#gamelist").find(".Col4-Content").each(function (i, n) {
            $n = $(n);
            if ($n.height() > highestHeight) {
                highestHeight = $n.height();
            }
        });
        $("#gamelist").find(".Col4-Content").css("min-height", highestHeight);
    });
</script>
</ui:MinifiedJavascriptControl>