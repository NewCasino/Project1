<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<Casino.Game>" %>

<%@ Import Namespace="Casino" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<script language="C#" type="text/C#" runat="server">
    protected override void OnPreInit(EventArgs e)
    {
        this.Title = this.Model.Title;
        this.MetaDescription = this.Model.Description;
        base.OnPreInit(e);
    }

    private bool DisableAudio { get { return (bool)this.ViewData["disableAudio"]; } }
    private bool RealMoney { get { return (bool)this.ViewData["realMoney"]; } }
    private bool MaintainAspectRatio { get { return (bool)this.ViewData["maintainAspectRatio"]; } }
    private string TicketID { get { return this.ViewData["ticketId"] as string; } }
    private bool IsDeniedGames {
        get{ 
            string DeniedGamesList = this.GetMetadata(".DeniedGameList");
            if (!string.IsNullOrEmpty(DeniedGamesList))
            {
                if(this.Model.ID == DeniedGamesList){
                    return true;
                }
                string[] DeniedGames = Regex.Split(DeniedGamesList, ",",RegexOptions.IgnoreCase);
                if( Array.Exists (DeniedGames , element => element ==  this.Model.ID )){
                    return true;
                }
                return false;
            }else{
                return false;
            } 
        }
    }
    private string GetGameHtml()
    {
        if (IsDeniedGames) return "";
        StringBuilder html = new StringBuilder();
        var parameters = GameManager.GetNetEntGameParameters(this.Model.ID);

        string src = parameters["src"];
        if (!string.IsNullOrWhiteSpace(Settings.Casino_NetEntGameSkinName))
        {
            Match m = Regex.Match(src, @"^(\/flash\/)(?<sub>.+)$", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
            if (m.Success)
            {
                src = string.Format("/flash/{0}/{1}", Settings.Casino_NetEntGameSkinName, m.Groups["sub"].Value);
            }
        }
        src = string.Format("{0}{1}", Settings.Casino_NetEntGameLoadBaseUrl, src);

        string flashVars = string.Format("{0}&server={1}&disableAudio={2}"
            , parameters["vars"]
            , HttpUtility.UrlEncode(Settings.Casino_NetEntGamePlayBaseUrl)
            , this.DisableAudio.ToString().ToLowerInvariant()
            );

        if (RealMoney)
        {
            flashVars = string.Format("{0}&sessid={1}", flashVars, GameManager.GetNetEntSessionID());
            if( !string.IsNullOrWhiteSpace(TicketID) )
                flashVars = string.Format("{0}&ticketId={1}", flashVars, HttpUtility.UrlEncode(TicketID));
        }

        html.AppendFormat(@"
<object classid=""clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"" 
width=""100%"" height=""100%"" id=""ctlFlash"">
    <param name=""movie"" value=""{0}"" />
    <param name=""quality"" value=""high"" />
    <param name=""bgcolor"" value=""#000000"" />
    <param name=""scale"" value=""exactfit"" />
    <param name=""flashVars"" value=""{1}"" />
    <param name=""base"" value=""{2}"" />
    <param name=""allowScriptAccess"" value=""always"" />
    <param name=""allowNetworking"" value=""all"" />
    <param name=""allowFullScreen"" value=""true"" />
    <param name=""wmode"" value=""direct"" />
                    
    <embed src=""{0}"" 
            quality=""high"" 
            bgcolor=""#000000"" 
            scale = ""exactfit""
            width=""100%"" 
            height=""100%"" 
            flashVars=""{1}""
            id=""ctlFlash""
            base=""{2}""
            type=""application/x-shockwave-flash"" 
            allowScriptAccess=""always""
            allowNetworking=""all""
            allowFullScreen=""true""
            wmode = ""direct""
            pluginspage=""https://get.adobe.com/cn/flashplayer/"">
    </embed>
</object>

<script language=""javascript"" type=""text/javascript"">
$(document).ready( function(){{
    var flashvars = false;
    var params = {{
      menu: ""false"",
      flashvars: ""{3}"",
      base: ""{5}"",
      allowScriptAccess: 'always',
      allowNetworking: 'all',
      allowFullScreen: 'true',
      wmode: 'direct',
      scale: 'exactfit',
      bgcolor: '#000000',
      quality: 'high'
    }};
    var attributes = {{
      id: ""ctlFlash"",
      name: ""ctlFlash""
    }};
    $('#game-wrapper').empty();
    $('<div id=""flash_place_holder""></div>').appendTo($('#game-wrapper'));
    swfobject.embedSWF(""{4}"", ""flash_place_holder"", ""100%"", ""100%"", ""10.0.0"", ""/js/expressInstall.swf"", flashvars, params, attributes);
}});
</"
            , src.SafeHtmlEncode()
            , flashVars.SafeHtmlEncode()
            , parameters["base"].SafeHtmlEncode()
            , flashVars.SafeJavascriptStringEncode()
            , src.SafeJavascriptStringEncode()
            , parameters["base"].SafeJavascriptStringEncode()
            );

        html.Append("script>");


        return html.ToString(); 
    }
    
    
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">
html, body { width:100%; height:100%; padding:0px; margin:0px; background-color:transparent; overflow:hidden; background-image:none; }
#game-wrapper { margin:0 auto; display:block; }
</style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="game-wrapper" style="width:100%; height:100%;" valign="middle">
    <%= GetGameHtml() %>
</div>


<% if( this.MaintainAspectRatio )
   { %>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        resizeGame();
        $(window).bind( 'resize', resizeGame);

    });

    function resizeGame() {
        var initialWidth = <%= this.Model.InitialWidth %> * 1.00;
        var initialHeight = <%= this.Model.InitialHeight %> * 1.00;

        var width = $(document.body).width() * 1.00;
        var height = $(document.body).height() * 1.00;
        

        var newWidth = width;
        var newHeight = newWidth * initialHeight / initialWidth;
        if( newHeight > height ){
            newHeight = height;
            newWidth = newHeight * initialWidth / initialHeight;
        } 
        $('#game-wrapper').width(newWidth).height(newHeight);
    }

    function rules(url)
    {
        url = '<%= Settings.Casino_NetEntGameRulesBaseUrl.SafeJavascriptStringEncode ()%>' + url;
        try{ top.gamerules(url); }
        catch(e) {
            window.open(  url, '_blank', 'status=1,toolbar=0,location=0,menubar=0,resizable=1,scrollbars=1');
        }
    }
</script>
<% } %>



</asp:Content>

