<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="LiveCasino" %>
<% 
List<Game> games = GameManager.GetGameList();
foreach (Game game in games)
{
    bool isOpen = game.IsOpen;
   
    LimitSet limitSet = null;
    int index = 0;
    if( game.LimitSets.Count > 0)
        limitSet = game.LimitSets[0];
    do
    {
        %>
            <div class="live_casino_game" type="<%= game.GameType.ToString() %>">
                <div class="<%= isOpen ? "open" : "close" %>_container container">
                    <%: Html.H3(game.GameName, new { @class="game_name" })%>
                    <div class="game_status"><%= this.GetMetadata( isOpen ? ".Status_Online" : ".Status_Offline").SafeHtmlEncode() %></div>
                    <div class="game_type game_type_<%= game.GameType.ToString() %>"></div>
                    <div class="game_info">
                        <ul>
                            <% if (limitSet != null && limitSet.MinBet.HasValue && limitSet.MaxBet.HasValue)
                               { %>
                            <li><span class="info_name"><%= this.GetMetadata(".Limits").SafeHtmlEncode() %>:</span>
                                <%= limitSet.MinBet.Value.ToString("F2") %>
                                -
                                <%= limitSet.MaxBet.Value.ToString("F2") %>
                            </li>
                            <% } %>
                            <li><span class="info_name"><%= this.GetMetadata(".OpenHour").SafeHtmlEncode()%>:</span><%= game.GetOpenHour().SafeHtmlEncode() %></li>
                            <li><span class="info_name"><%= this.GetMetadata(".CloseHour").SafeHtmlEncode()%>:</span><%= game.GetCloseHour().SafeHtmlEncode() %></li>

                            <% if (!string.IsNullOrWhiteSpace(game.DealerName))
                               { %>
                            <li><span class="info_name"><%= this.GetMetadata(".DealerName").SafeHtmlEncode()%>:</span><%= game.DealerName.SafeHtmlEncode()%></li>
                            <% } %>
                        </ul>
                    </div>
                    <div class="game_button" align="center">
                        <% if (isOpen)
                           {
                               string script = "AnonymousAlert()";
                               if (Profile.IsAuthenticated)                               
                               {
                                   string limitSetID = null;
                                   if (limitSet != null)
                                       limitSetID = limitSet.ID;
                                   script = string.Format("javascript:window.open('{0}', 'livecasinogame', {1})"
                                       , this.Url.RouteUrl("LiveCasinoLobby", new { @action = "XPROLoader", @gameID = game.GameID, @limitSetID = limitSetID }).SafeJavascriptStringEncode()
                                       , game.WindowParams
                                       );
                               }
                                %>
                            <%: Html.LinkButton(this.GetMetadata(".ViewTable"), new { @onclick = script, @class = "button_view_table" })%>
                        <% } else { %>
                            <%: Html.LinkButton(this.GetMetadata(".ViewTable"), new { @onclick = "javascript:void(0)", @class = "button_view_table", @disabled = "disabled" })%>
                        <% } %>
                    </div>
                </div>
            </div>

        <%
        index++;
        if (isOpen && index < game.LimitSets.Count)
            limitSet = game.LimitSets[index];
        else
            break;
    } while (true);
    
}
%>

<div style="clear:both"></div>
<script>
    function AnonymousAlert()
    {
        alert('<%=this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode()%>');
    }
</script>