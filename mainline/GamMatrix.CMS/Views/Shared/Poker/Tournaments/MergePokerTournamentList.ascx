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
</script>

<div id="merge-poker-tournament-list">

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

    <li class="tab" data-type="UpcommingFreerolls">
      <a href="#tabFreerolls">
       <div class="tab_left">
          <div class="tab_right">
             <div class="tab_center"><span><%= this.GetMetadata(".Upcomming_Freerolls").SafeHtmlEncode()%></span></div>
          </div>
       </div>
      </a>
    </li>

    <li class="tab" data-type="UpcommingGuaranteeds">
      <a href="#tabGuaranteeds">
       <div class="tab_left">
          <div class="tab_right">
             <div class="tab_center"><span><%= this.GetMetadata(".Upcomming_Guaranteeds").SafeHtmlEncode()%></span></div>
          </div>
       </div>
      </a>
    </li>
</ul>

<ul class="tournaments">
    <li class="header">
        <span class="name"><%= this.GetMetadata(".Name").SafeHtmlEncode() %></span>
        <span class="prize"><%= this.GetMetadata(".Prize_Pool").SafeHtmlEncode() %></span>
        <span class="buyin"><%= this.GetMetadata(".Buy_In").SafeHtmlEncode() %></span>
        <span class="entryfee"><%= this.GetMetadata(".Entry_Fee").SafeHtmlEncode()%></span>
        <span class="starttime"><%= this.GetMetadata(".Start_Time").SafeHtmlEncode()%></span>
        <span class="registrationtime"><%= this.GetMetadata(".Registration_Time").SafeHtmlEncode()%></span>
        <span class="entrants"><%= this.GetMetadata(".Entrants").SafeHtmlEncode()%></span>
    </li>
<%
    bool isAlternateItem = false;
    foreach (Tournament tournament in this.Model)
    {
        isAlternateItem = !isAlternateItem;
        %>
    <li class="tournament <%= tournament.Type %> <%= isAlternateItem ? "odd" : "" %>">
        <span class="name"><%= tournament.Name.SafeHtmlEncode() %></span>
        <span class="prize"><%= MoneyHelper.FormatWithCurrencySymbol( tournament.Currency, tournament.PrizePool)  %></span>
        <span class="buyin"><%= MoneyHelper.FormatWithCurrencySymbol( tournament.Currency, tournament.BuyIn)  %></span>
        <span class="entryfee"><%= MoneyHelper.FormatWithCurrencySymbol( tournament.Currency, tournament.EntryFee)  %></span>

        <% int countDownSeconds = GetCountDownSeconds(tournament.StartTime); %>
        <span class="starttime" <%= (countDownSeconds > 0) ? string.Format("data-countDownSeconds=\"{0}\"", countDownSeconds) : "" %> >
            <% if (tournament.StartTime.HasValue)
               { %>
            <%= tournament.StartTime.Value.ToString("dd/MM/yyyy HH:mm")%>
            <% } %>
        </span>

        <% countDownSeconds = GetCountDownSeconds(tournament.RegistrationTime); %>
        <span class="registrationtime" <%= (countDownSeconds > 0) ? string.Format("data-countDownSeconds=\"{0}\"", countDownSeconds) : "" %>>
            <% if (tournament.RegistrationTime.HasValue)
               { %>
            <%= tournament.RegistrationTime.Value.ToString("dd/MM/yyyy HH:mm")%>
            <% } %>
        </span>


        <span class="entrants"><%= tournament.Entrants %></span>
    </li>
<%  } %>

    <li class="footer">
        <span class="name"><%= this.GetMetadata(".Name").SafeHtmlEncode() %></span>
        <span class="prize"><%= this.GetMetadata(".Prize_Pool").SafeHtmlEncode() %></span>
        <span class="buyin"><%= this.GetMetadata(".Buy_In").SafeHtmlEncode() %></span>
        <span class="entryfee"><%= this.GetMetadata(".Entry_Fee").SafeHtmlEncode()%></span>
        <span class="starttime"><%= this.GetMetadata(".Start_Time").SafeHtmlEncode()%></span>
        <span class="registrationtime"><%= this.GetMetadata(".Registration_Time").SafeHtmlEncode()%></span>
        <span class="entrants"><%= this.GetMetadata(".Entrants").SafeHtmlEncode()%></span>
    </li>
</ul>


</div>

<script type="text/javascript">
    $(function () {
        $('#merge-poker-tournament-list').data('startTime', Math.floor((new Date()).getTime() / 1000));

        function paddingZero(str) {
            while (str.length < 2)
                str = '0' + str;
            return str;
        }

        function refreshCountDown() {
            var elapsedSeconds = Math.floor((new Date()).getTime() / 1000) - $('#merge-poker-tournament-list').data('startTime');
            var items = $('#merge-poker-tournament-list ul.tournaments span[data-countDownSeconds]:visible');
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

        $('#merge-poker-tournament-list ul.tabs li').click(function (e) {
            e.preventDefault();
            $(this).siblings('.selected').removeClass('selected');
            $(this).addClass('selected');
            $('#merge-poker-tournament-list ul.tournaments li.tournament').hide();

            var type = $(this).data('type') || $(this).attr('data-type');
            $('#merge-poker-tournament-list ul.tournaments li.' + type).show();

        });
        $('#merge-poker-tournament-list ul.tabs li.tab:first').trigger('click');
    });
</script>