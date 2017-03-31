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
        switch (gameType)
        {
            case "1098": gameType = "Hold'em"; break;
            case "2098": gameType = "Omaha"; break;
            case "3098": gameType = "Omaha Hi Low"; break;
            case "4098": gameType = "Seven Card Stud"; break;
            case "5098": gameType = "7SHiLo"; break;
            case "6098": gameType = "Heads Up"; break;
            case "7098": gameType = "Heads Up Omaha"; break;
            case "8098": gameType = "Heads Up 7CS"; break;
            case "9098": gameType = "Heads Up OmahaHiLo"; break;
            case "10098": gameType = "Heads Up 7CSHiLo"; break;
            case "11098": gameType = "Teen Patti"; break;
            case "12098": gameType = "Heads Up Teen Patti"; break;
            default: return string.Empty;
        }

        return gameType;
    }
</script>


<div id="enet-poker-tournament-list">

<ul class="tabs">
    <li class="tab" data-type="Current">
      <a href="#tabTournaments">
       <div class="tab_left">
          <div class="tab_right">
             <div class="tab_center"><span><%= this.GetMetadata(".Current_Tournaments").SafeHtmlEncode() %></span></div>
          </div>
       </div>
      </a>
    </li>

    <li class="tab" data-type="RegistrationOpening">
      <a href="#tabFreerolls">
       <div class="tab_left">
          <div class="tab_right">
             <div class="tab_center"><span><%= this.GetMetadata(".RegistrationOpening_Tournaments").SafeHtmlEncode()%></span></div>
          </div>
       </div>
      </a>
    </li>

    <li class="tab" data-type="Completed">
      <a href="#tabGuaranteeds">
       <div class="tab_left">
          <div class="tab_right">
             <div class="tab_center"><span><%= this.GetMetadata(".Completed_Tournaments").SafeHtmlEncode()%></span></div>
          </div>
       </div>
      </a>
    </li>
</ul>

<ul class="tournaments">
    <li class="header">
        <span class="name"><%= this.GetMetadata(".Name").SafeHtmlEncode() %></span>
        <span class="gametype"><%= this.GetMetadata(".Game_Type").SafeHtmlEncode()%></span>
        <span class="buyin"><%= this.GetMetadata(".Buy_In").SafeHtmlEncode() %></span>
        <span class="entryfee"><%= this.GetMetadata(".Entry_Fee").SafeHtmlEncode()%></span>
        <span class="registrationtime"><%= this.GetMetadata(".Registration_Time").SafeHtmlEncode()%></span>
        <span class="starttime"><%= this.GetMetadata(".Start_Time").SafeHtmlEncode()%></span>
        <span class="entrants"><%= this.GetMetadata(".Entrants").SafeHtmlEncode()%></span>
    </li>
<%
    bool isAlternateItem = false;
    foreach (Tournament tournament in this.Model.OrderBy( t => t.Type))
    {
        isAlternateItem = !isAlternateItem;
        %>
    <li class="tournament <%= tournament.Type %> <%= isAlternateItem ? "odd" : "" %>">
        <span class="name"><%= tournament.Name.SafeHtmlEncode() %></span>
        <span class="gametype"><%= GetGameType(tournament.GameType).SafeHtmlEncode() %></span>

        <span class="buyin"><%= MoneyHelper.FormatWithCurrencySymbol( tournament.Currency, tournament.BuyIn)  %></span>
        <span class="entryfee"><%= MoneyHelper.FormatWithCurrencySymbol( tournament.Currency, tournament.EntryFee)  %></span>



        <% int countDownSeconds = GetCountDownSeconds(tournament.RegistrationTime); %>
        <span class="registrationtime" <%= (countDownSeconds > 0) ? string.Format("data-countDownSeconds=\"{0}\"", countDownSeconds) : "" %>>
            <% if (tournament.RegistrationTime.HasValue)
               { %>
            <%= tournament.RegistrationTime.Value.ToString("dd/MM/yyyy HH:mm")%>
            <% } %>
        </span>

        <% countDownSeconds = GetCountDownSeconds(tournament.StartTime); %>
        <span class="starttime" <%= (countDownSeconds > 0) ? string.Format("data-countDownSeconds=\"{0}\"", countDownSeconds) : "" %> >
            <% if (tournament.StartTime.HasValue)
               { %>
            <%= tournament.StartTime.Value.ToString("dd/MM/yyyy HH:mm")%>
            <% } %>
        </span>


        <span class="entrants"><%= tournament.Entrants %></span>
    </li>
<%  } %>

    <li class="footer">
        <span class="name"><%= this.GetMetadata(".Name").SafeHtmlEncode() %></span>
        <span class="gametype"><%= this.GetMetadata(".Game_Type").SafeHtmlEncode()%></span>
        <span class="buyin"><%= this.GetMetadata(".Buy_In").SafeHtmlEncode() %></span>
        <span class="entryfee"><%= this.GetMetadata(".Entry_Fee").SafeHtmlEncode()%></span>
        <span class="registrationtime"><%= this.GetMetadata(".Registration_Time").SafeHtmlEncode()%></span>
        <span class="starttime"><%= this.GetMetadata(".Start_Time").SafeHtmlEncode()%></span>
        <span class="entrants"><%= this.GetMetadata(".Entrants").SafeHtmlEncode()%></span>
    </li>
</ul>


</div>


<script type="text/javascript">
    $(function () {
        $('#enet-poker-tournament-list').data('startTime', Math.floor((new Date()).getTime() / 1000));

        function paddingZero(str) {
            while (str.length < 2)
                str = '0' + str;
            return str;
        }

        function refreshCountDown() {
            var elapsedSeconds = Math.floor((new Date()).getTime() / 1000) - $('#enet-poker-tournament-list').data('startTime');
            var items = $('#enet-poker-tournament-list ul.tournaments span[data-countDownSeconds]:visible');
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

        $('#enet-poker-tournament-list ul.tabs li').click(function (e) {
            e.preventDefault();
            $(this).siblings('.selected').removeClass('selected');
            $(this).addClass('selected');
            $('#enet-poker-tournament-list ul.tournaments li.tournament').hide();

            var type = $(this).data('type') || $(this).attr('data-type');
            $('#enet-poker-tournament-list ul.tournaments li.' + type).show();

        });
        $('#enet-poker-tournament-list ul.tabs li.tab:first').trigger('click');
    });
</script>