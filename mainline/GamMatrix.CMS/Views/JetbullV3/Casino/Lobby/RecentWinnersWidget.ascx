<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    public bool ShowCapitalName
    {
        get
        {
            if (this.ViewData["ShowCapitalName"] != null)
            {
                return (bool)this.ViewData["ShowCapitalName"];
            }
            else
            {
                return false;
            }
        }
    }

    public bool NeedConvert
    {
        get
        {
            if (this.ViewData["needConvert"] != null)
            {
                return (bool)this.ViewData["needConvert"];
            }
            else
            {
                return false;
            }
        }
    }
    
    private int _RollingCount = -1;
    public int RollingCount
    {
        get {
            if (_RollingCount == -1)
            {
                if (this.ViewData["RollingCount"]!=null)
                    int.TryParse(this.ViewData["RollingCount"].ToString(), out _RollingCount);
                if (_RollingCount < 1)
                    _RollingCount = 1;   
            }            

            return _RollingCount;
        }
    }

    private string GetJquerySelectorForRolling()
    { 
        StringBuilder sb = new StringBuilder("li:first");
        if (RollingCount > 1)
        {
            for (int i = 1; i < RollingCount; i++)
            {
                sb.AppendFormat(", li:nth-child({0})",i+1);
            }
        }
        return sb.ToString();
    }
</script>



<script type="text/html" id="recent-winner-template">
<#
    var item=arguments[0];

#>

<li class="Winner country-flags" data-WinTimeTicks="<#= item.WinTimeTicks #>">

<img class="FlagImage <#= item.CountryFlagName.htmlEncode() #>"
        src="/images/transparent.gif" width="16" height="11" alt="<#= item.CountryName.htmlEncode() #>" title="<#= item.CountryName.htmlEncode() #>" />
<span class="WinnerInfo">
<span class="WinnerName"><#= item.DisplayName.htmlEncode() #></span>
<span class="WinTime"></span>
</span>
<span class="WinnerDetails">
<span class="WinAmmount Cash"><#= item.FormattedAmount.htmlEncode() #></span>

        

        <# if( item.Url.length > 0 )
        { #>

<a href="<#= item.Url.htmlEncode() #>" class="WinGame" title="<#= item.GameName.htmlEncode() #>" data-gameID="<#= item.GameID.htmlEncode() #>">
            <#= item.GameName.htmlEncode() #>
        </a>
        <# } #>
</span>
</li>
</script>

<% string wrapperID = Guid.NewGuid().ToString("N"); %>

<div id="<%= wrapperID %>" class="Box Winners WinnersNow">
<h2 class="BoxTitle WinnersTitle">
<span class="TitleIcon">&sect;</span>
<strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %></strong>
</h2>
<div class="WinnersContainer Canvas">
<ol class="WinnersList Container">


</ol>
</div>
</div>

<script type="text/javascript">
    $(function () {        
        var _rolling_loop_index=0;
        var winnersAnimationTimer = null;
        function startAnimation() {            
            if(_rolling_loop_index == 1800) return;
            var temp = ++_rolling_loop_index;
            if(winnersAnimationTimer)
                window.clearTimeout(winnersAnimationTimer);
            var $container = $('ol.WinnersList', $('#<%= wrapperID %>'));
            var $li = $('<%= GetJquerySelectorForRolling() %>', $container);
            $li.animate({ 'marginTop': -1 * $li.eq(0).outerHeight() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $li.css('marginTop', 0).detach().appendTo($container);
                        if(temp==_rolling_loop_index)
                        {
                            temp-=1;
                            innersAnimationTimer = setTimeout(startAnimation, 2000);
                        }
                    }
                });
        }

        var maxCount = 50;
        var maxTime = 0;
        function loadData() {

            var url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "GetRecentWinners", @currency = this.ViewData["Currency"] as string, @showCapitalName = ShowCapitalName,@needConvert = NeedConvert }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                if (!json.success) {
                    alert(json.error);
                }

                var container = $('ol.WinnersList', $('#<%= wrapperID %>'));
                var max = 0;
                
                for (var i = 0; i < json.winners.length; i++) {
                    <% 
                        int registerCountry=0;
                        if(Profile.IsAuthenticated){
                           registerCountry = Profile.UserCountryID;
                       } %>
                    <% 
                    if (Profile.IpCountryID == 230 || registerCountry == 230)
                    { %>
                    if((",al,dz,ao,hy,br,ec,gy,ve,gf,ky,gp,mq,vi,cr,ni,pa,us,af,bh,bd,bt,bn,kh,cn,fr,hm,hk,in,id,ir,iq,il,ja,jo,kw,kg,lb,my,mv,yt,mm,na,nl,kp,om,pk,pg,qa,sa,sg,za,kr,es,sd,sy,tw,th,tn,tr,ug,ae,uz,va,ye,zw,").indexOf(json.winners[i].CountryFlagName.toString().toLocaleLowerCase() + ',') <= 0){
                            if (json.winners[i].WinTimeTicks > maxTime)
                                $($('#recent-winner-template').parseTemplate(json.winners[i])).appendTo(container);
                    
                            var liWinners = container.find('li.Winner')
                            if(liWinners.length > maxCount)
                            {
                                liWinners.sort(function(a,b){
                                    return $(a).attr('data-WinTimeTicks') < $(b).attr('data-WinTimeTicks');
                                });
                        
                                for(var j = maxCount; j<liWinners.length;j++)
                                {
                                    liWinners.eq(j).remove();   
                                }                       
                            }
                            
                            max = Math.max(max, json.winners[i].WinTimeTicks);
                        }
                    <%}%>
                    <% else{%>
                        if (json.winners[i].WinTimeTicks > maxTime)
                            $($('#recent-winner-template').parseTemplate(json.winners[i])).appendTo(container);
                    
                        var liWinners = container.find('li.Winner')
                        if(liWinners.length > maxCount)
                        {
                            liWinners.sort(function(a,b){
                                return $(a).attr('data-WinTimeTicks') < $(b).attr('data-WinTimeTicks');
                            });
                        
                            for(var j = maxCount; j<liWinners.length;j++)
                            {
                                liWinners.eq(j).remove();   
                            }                       
                        }
                    
                        max = Math.max(max, json.winners[i].WinTimeTicks);
                    <%}%>
                }

                if (maxTime == 0 && container.find("li").length><%=RollingCount %>)
                    startAnimation();

                if (max > maxTime)
                    maxTime = max;
                
                bindEvent();

                setTimeout(loadData, 100000);
            });
        }
        loadData();

        function bindEvent() {
            $('#<%= wrapperID%>').find('a.WinGame').click(function (e) {
            try {
                var playForFun = <%= (!Profile.IsAuthenticated).ToString().ToLowerInvariant() %>;
                var gameID = $(this).data('gameID') || $(this).attr('data-gameID');
                if(gameID.length>0)
                    __loadGame(gameID, playForFun);
                e.preventDefault();
            }
            catch (e) {alert(e);
            }
        });
        }
    });
</script>