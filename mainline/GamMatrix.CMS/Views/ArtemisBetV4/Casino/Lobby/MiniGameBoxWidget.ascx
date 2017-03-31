<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CasinoEngine" %>
<script runat="server" type="text/C#">
    
    protected bool OrderByInitialLetter
    {
        get {
            if(this.ViewData["SelectTheFirstGameAsDefault"] != null)
                return (bool)this.ViewData["SelectTheFirstGameAsDefault"];
            return false;
        }
    }
        
    protected bool ?_SelectTheFirstGameAsDefault = null;
    protected bool SelectTheFirstGameAsDefault
    {
        get {
            if (!_SelectTheFirstGameAsDefault.HasValue)
            {
                bool _temp = false;
                if (this.ViewData["SelectTheFirstGameAsDefault"] != null &&
                    bool.TryParse(this.ViewData["SelectTheFirstGameAsDefault"].ToString(), out _temp))
                {
                    _SelectTheFirstGameAsDefault = _temp;
                }
                else
                    _SelectTheFirstGameAsDefault = true;
            }
            return _SelectTheFirstGameAsDefault.Value;
        }
    }
    
    private List<MiniGame> _MiniGames;
    private List<MiniGame> MiniGames
    {
        get
        {
            if (_MiniGames == null)
            {
                string[] paths = Metadata.GetChildrenPaths("/Metadata/Casino/MiniGames");
                if (paths != null && paths.Length > 0)
                {
                    List<GameRef> allMiniGames = GameMgr.GetAllMiniGame();
                    Dictionary<string, LiveCasinoTable> allLiveTables = CasinoEngineClient.GetLiveCasinoTables();
                    
                    string gameID;
                    string tableID;
                    _MiniGames = new List<MiniGame>();
                    MiniGame miniGame;
                    GameRef gameRef;
                    int w=0, h=0;
                    foreach (string path in paths)
                    {
                        gameID = this.GetMetadata(path + ".ID").Trim();
                        tableID = this.GetMetadata(path + ".TableID").Trim();
                        
                        if (!string.IsNullOrWhiteSpace(tableID))
                        {
                            if (!allLiveTables.Keys.Contains(tableID))
                                continue;

                            miniGame = new MiniGame();
                            miniGame.ID = miniGame.TableID = tableID;
                            miniGame.IsLiveCasino = true;
                            miniGame.Image = this.GetMetadata(path + ".Image").Trim();
                            miniGame.Name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
                            miniGame.Title = allLiveTables[tableID].Name;
                            
                            int.TryParse(this.GetMetadata(path + ".Width").DefaultIfNullOrWhiteSpace("0").Trim(), out w);
                            miniGame.Width = w;
                            int.TryParse(this.GetMetadata(path + ".Height").DefaultIfNullOrWhiteSpace("h").Trim(), out h);
                            miniGame.Height = h;
                            
                            _MiniGames.Add(miniGame);
                        }
                        else if (!string.IsNullOrWhiteSpace(gameID) && allMiniGames.Exists(p => p.ID.Equals(gameID, StringComparison.OrdinalIgnoreCase)))
                        {
                            gameRef = allMiniGames.First(p => p.ID.Equals(gameID, StringComparison.OrdinalIgnoreCase));
                            if (!Profile.IsAuthenticated)
                            {
                                if (!gameRef.Game.IsFunModeEnabled || !gameRef.Game.IsAnonymousFunModeEnabled)
                                    continue;
                            }
                            else
                            {
                                if (!gameRef.Game.IsRealMoneyModeEnabled)
                                    continue;
                            }
                            
                            miniGame = new MiniGame();
                            miniGame.ID = miniGame.GameID = gameID;
                            miniGame.Image = this.GetMetadata(path + ".Image").Trim();                            
                            miniGame.Name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
                            miniGame.Title = gameRef.Name;                            
                                                        
                            _MiniGames.Add(miniGame);
                        }
                    }
                }
            }
            return _MiniGames;
        }
    }
    
    private SelectList GetMiniGames()
    {
        var list = (from game in MiniGames select new { key = game.ID, value = game.Title}).ToList();
        //if (OrderByInitialLetter)
            list = list.OrderByDescending(g => g.key).ToList();
        
        if (!SelectTheFirstGameAsDefault)
        {
            list.Insert(0, new { key = "0", value = this.GetMetadata(".Game_Select") });
        }
        return new SelectList(list, "key", "value","0");
    }

    private string GetMiniGameJson()
    {        
        StringBuilder sbImagesJson = new StringBuilder();
        if (MiniGames != null)
        {
            sbImagesJson.Append("{");
            for (int i = 0; i < MiniGames.Count; i++)
            {
                sbImagesJson.AppendFormat(@" ""{0}"" : {{""GameID"": ""{1}"",""Title"":""{2}"", ""Image"":""{3}"", ""IsLiveCasino"":{4}, ""TableID"":""{5}"", ""Width"":{6}, ""Height"":{7} }} "
                    , MiniGames[i].ID
                    , MiniGames[i].GameID
                    , MiniGames[i].Title                    
                    , MiniGames[i].Image.SafeJavascriptStringEncode()
                    , MiniGames[i].IsLiveCasino.ToString().ToLowerInvariant()
                    , MiniGames[i].TableID.DefaultIfNullOrWhiteSpace("0")
                    , MiniGames[i].Width
                    , MiniGames[i].Height
                    );
                if (i < MiniGames.Count-1) 
                    sbImagesJson.Append(",");
            }
            sbImagesJson.Append("}");
        }
        return sbImagesJson.ToString();
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
    }

    private class MiniGame
    {
        public string Name { get; set; }
        public string ID { get; set; }
        public string GameID { get; set; }
        public string Title { get; set; }
        public string Image { get; set; }
        public string TableID { get; set; }
        public bool IsLiveCasino { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
    }
</script>

<div class="Box Minigame">
    <h2 class="BoxTitle TopPromoTitle">
        <span class="TitleIcon">&nbsp;</span> <strong class="TitleText">
            <%= this.GetMetadata(".Title").SafeHtmlEncode() %></strong>
    </h2>
    <div class="GameSelector Container">
        <label for="ddlFilterGames" class="SelectorLable"><%= this.GetMetadata(".ChooseaGame").HtmlEncodeSpecialCharactors()%></label><%: Html.DropDownList("filterGames", GetMiniGames(), new { @class = "FilterSelect", id = "ddlFilterGames", size = "1" })%>
    </div>
    <div class="GameArea">
        <div id="GameCover"></div>
        <a title="<%=this.GetMetadata(".Button_PlayNow_Title").SafeHtmlEncode() %>" class="Button MiniGameButton" href="#">
        <%=this.GetMetadata(".Button_PlayNow_Text").SafeHtmlEncode() %>
        </a>
        <div id="GameBody" class="GameBody" style=" display:none;">
            <div class="GameContainer" align="center">
            </div>
        </div>
    </div>
</div>

<%--<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true"
    AppendToPageEnd="true">--%>
    <script type="text/javascript">
        if (window.location.toString().indexOf('.gammatrix-dev.net') > 0)
            document.domain = document.domain;
        else
            document.domain = '<%= SiteManager.Current.SessionCookieDomain.SafeJavascriptStringEncode() %>';

        var _IsAuthenticated = <%= Profile.IsAuthenticated?"true" : "false" %>;
        var _MiniGame_SelectTheFirstGameAsDefault  = <%= SelectTheFirstGameAsDefault ? "true" : "false" %>; 
        var _MiniGameContainer = null;
        var _MiniGameCover = null;
        var _MiniGame_Button_Play = null;
        $(document).ready(function () {
            preloadMinigameImg();

            _MiniGameContainer = GetContainer();
            _MiniGameCover = $("#GameCover");
            _MiniGame_Button_Play = $(".GameArea .MiniGameButton");
            if($("#ddlFilterGames").val())
            {
                switchMiniGame();
                window.setTimeout("initIframeHeight(); window.setTimeout('initIframeHeight()',2000); ",1000);
            }
            $("#ddlFilterGames").change(function () {
                switchMiniGame();
            });
        });

        function initIframeHeight()
        {
            _MiniGameContainer.height($("body").height());
        }
        var miniGameJson = <%=GetMiniGameJson() %>;
        function switchMiniGame()
        {
            $("#GameBody").hide();
            var _val = $("#ddlFilterGames").val();
            if(_val>0)
            {
                $("div.GameArea").show();
                _MiniGame_Button_Play.show();
                _MiniGameCover.show().html(miniGameJson[_val].Image);
                $('div.GameArea div.GameContainer').empty();
                //_MiniGame_Button_Play.click(function(){
                    onCoverClicked();
                //});
                //_MiniGameCover.click(function(){
                //    onCoverClicked();
                //});
            }
            else
            {
                $("div.GameArea").hide();
            }
            AdaptSize();
        }

        function onCoverClicked()
        {
            _MiniGame_Button_Play.hide();
            _MiniGameCover.hide();
            $("#GameBody").show();
            var id = $("#ddlFilterGames").val();
            var miniGame = miniGameJson[id];
            if(miniGame.IsLiveCasino)
                loadMiniLiveCasino(miniGame);
            else
                loadMiniGame(miniGame.GameID,!_IsAuthenticated);
        }

        function loadMiniLiveCasino(miniGame)
        {
            <%if (!Profile.IsAuthenticated)
              {%>
            window.alert('<%=this.GetMetadata("/LiveCasino/Home/_XProGamingGames_ascx.AnonymousMessage").SafeJavascriptStringEncode()%>');
            <%}
              else { %>
            var url = '/LiveCasino/Hall/Start?tableID=' + miniGame.TableID;
            $('div.GameArea div.GameContainer').empty();
            $('<iframe id="ifmMiniGame" frameborder="0" scrolling="no" width="100%" height="100%" style="margin:0 auto;" allowtransparency="true"></iframe>').attr('src', url).appendTo($('div.GameArea div.GameContainer'));
            
            var ifmMiniGame = $('#ifmMiniGame');

            width = ifmMiniGame.width(); 
            
            if (miniGame.Height > 0 && miniGame.Width > 0) {                
                var height = width * miniGame.Height / (miniGame.Width * 1.0);                
                ifmMiniGame.height(height);
                $('div.GameBody .GameContainer').height(height);
            }
            AdaptSize();
            <%}%>            
        }

        function loadMiniGame(gameID, playForFun) {
            var url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "GetGameInfo" }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, { gameID: gameID, playForFun: playForFun }, function (json) {                
                if (!json.success) {
                    switch (json.errorCode) {
                        case "-1": alert('<%= this.GetMetadata(".Error_FunModeNotAvailable").SafeJavascriptStringEncode() %>'); break;
                        case "-2": alert('<%= this.GetMetadata(".Error_FunModeNotAvailable").SafeJavascriptStringEncode() %>'); break;
                        case "-3": alert('<%= this.GetMetadata(".Error_FunModeNotAvailable").SafeJavascriptStringEncode() %>'); break;
                        case "-4": alert('<%= this.GetMetadata(".Error_SessionTimedout").SafeJavascriptStringEncode() %>'); self.location = self.location.toString().replace("realMoney=True", "realMoney=False"); return;
                        default: break;
                    }
                    return;
                }            

                $('div.GameArea div.GameContainer').empty();
                $('<iframe id="ifmMiniGame" frameborder="0" scrolling="no" width="100%" height="100%" style="margin:0 auto;" allowtransparency="true"></iframe>').attr('src', json.game.Url).appendTo($('div.GameArea div.GameContainer'));
            
                var ifmMiniGame = $('#ifmMiniGame');

                width = ifmMiniGame.width();  
                
                if (json.game.Height > 0 && json.game.Width > 0) {                
                    var height = width * json.game.Height / (json.game.Width * 1.0);                
                    ifmMiniGame.height(height);
                    $('div.GameBody .GameContainer').height(height);
                }
                AdaptSize();
                if($(".ifmKeepSessionAlive").length==0)
                    $('<iframe src="/_session_keep_alive.ashx?duration=30" style="display:none" class="ifmKeepSessionAlive"></iframe>').appendTo(document.body);
            });
        }

        function AdaptSize()
        {
            if(_MiniGameContainer != null)
            {   
                if($('html.safari').length > 0 ){
                    $("#GameCover img").css('height','auto');
                }             
                _MiniGameContainer.height($("body").height());
            }
            _MiniGame_Button_Play.css({"left": (_MiniGameCover.width()-_MiniGame_Button_Play.outerWidth())/2, "top": (_MiniGameCover.height()-_MiniGame_Button_Play.height())/2});
        }

        function GetContainer()
        {
            if(self.parent != null && self != self.parent)
            {
                var iframes = self.parent.document.getElementsByTagName('iframe');
                for( var i = 0; i < iframes.length; i++){
                    var f = iframes[i];
                    if($(f).attr('src'))
                    {
                        if( $(f).attr('src').toLowerCase().indexOf('/casino/minigame') >= 0 ){
                            return $(f);
                        }
                    }
                }
            }
            return null;
        }
        
        function preloadMinigameImg(){
            var _container = $('<div style="display:none"></div>').appendTo('body');
            try{
                for(var key in miniGameJson)
                {
                    $(miniGameJson[key].Image).appendTo(_container);
                }
            }catch(e){} 
        } 
    </script>
<%--</ui:MinifiedJavascriptControl>--%>
