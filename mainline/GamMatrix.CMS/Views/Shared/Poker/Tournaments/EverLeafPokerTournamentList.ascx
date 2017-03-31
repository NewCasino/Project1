<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Poker.Tournament>>" %>

<%@ Import Namespace="Poker" %>
<%@ Import Namespace="Finance" %>

<script type="text/C#" runat="server">
   
    
    private int GetCountDownSeconds(DateTime? time)
    {
        if( time.HasValue )
            return (int)Math.Truncate( (time.Value - DateTime.Now).TotalSeconds );

        return 0;
    }


    private string GetGameType(string gameType)
    {
        return this.GetMetadata(string.Format(".GameType_{0}", gameType)).DefaultIfNullOrEmpty(gameType);
    }

    private string GetLimitType(string limitType)
    {
        return this.GetMetadata(string.Format(".LimitType_{0}", limitType)).DefaultIfNullOrEmpty(limitType);
    }
</script>


<div id="everleaf-poker-tournament-list">


<ul class="tournaments">    
<%
    bool isAlternateItem = false;
    if (this.Model != null)
    {
        int _loopindex = 0;
        foreach (Tournament tournament in this.Model)
        {
            _loopindex++;            
            isAlternateItem = !isAlternateItem;
        %>
    <li class="tournament <%= tournament.Type %> <%= isAlternateItem ? "odd" : "" %> <%= _loopindex==1 ? "first" : "" %>">

        <% int countDownSeconds = GetCountDownSeconds(tournament.StartTime); %>
        <span class="starttime" <%= (countDownSeconds > 0) ? string.Format("data-countDownSeconds=\"{0}\"", countDownSeconds) : "" %>>
            <% if (tournament.StartTime.HasValue)
               { %>
            <%= tournament.StartTime.Value.ToString("dd/MM/yyyy HH:mm")%>
            <% } %>
        </span>

        <span class="buyin"><%= MoneyHelper.FormatWithCurrencySymbol(tournament.Currency, tournament.BuyIn)%></span>
        <span class="name"><%= tournament.Name.SafeHtmlEncode()%></span>
    </li>
<%  }
    } %>
    
</ul>

<%= Html.LinkButton(this.GetMetadata(".AllTournaments"), new { @href = this.Url.RouteUrlEx("PokerTournaments", new { @action = "EverLeafPoker" }), @class = "btnalltournametns" })%>
</div>


<script type="text/javascript">
    $(function () {
        $('#cake-poker-tournament-list').data('startTime', Math.floor((new Date()).getTime() / 1000));

        function paddingZero(str) {
            while (str.length < 2)
                str = '0' + str;
            return str;
        }

        function refreshCountDown() {
            var elapsedSeconds = Math.floor((new Date()).getTime() / 1000) - $('#cake-poker-tournament-list').data('startTime');
            var items = $('#cake-poker-tournament-list ul.tournaments span[data-countDownSeconds]:visible');
            for (var i = 0; i < items.length; i++) {
                var countDownSeconds = items.eq(i).data('countDownSeconds') || items.eq(i).attr('data-countDownSeconds');
                countDownSeconds = parseInt(countDownSeconds, 10);
                if (countDownSeconds > 0) {

                    var remainedSec = countDownSeconds - elapsedSeconds;
                    if (remainedSec < 0)
                        remainedSec = 0;

                    var str = paddingZero(Math.floor(remainedSec / 3600).toString()) + ':';
                    remainedSec = remainedSec % 3600;
                    str = str + paddingZero(Math.floor(remainedSec / 60).toString()) + ':';
                    remainedSec = remainedSec % 60;
                    str = str + paddingZero(remainedSec.toString());
                    items.eq(i).text(str);
                }
            }
        }
        setInterval(refreshCountDown, 1000);
    });
</script>