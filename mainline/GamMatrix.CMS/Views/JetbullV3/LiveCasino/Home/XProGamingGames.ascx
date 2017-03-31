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
		int i = 0;
        %>

<div class="live_casino_game" type="<%= game.GameType.ToString() %>">
  <div class="<%= isOpen ? "open" : "close" %>_container container">
    <%: Html.H3(game.GameName, new { @class="game_name" })%>
    <div class="game_type game_type_<%= game.GameType.ToString() %>"></div>
    <div class="game_info">
      <ul>
        <li class="Odd" ><span class="info_name"><%= this.GetMetadata(".Status").SafeHtmlEncode()%>:</span><span class="info_data"><%= this.GetMetadata( isOpen ? ".Status_Online" : ".Status_Offline").SafeHtmlEncode() %></span>
        <div class="w2c"></div>
        </li>
        <% if (limitSet != null && limitSet.MinBet.HasValue && limitSet.MaxBet.HasValue)
                               { %>
        <li class="Even"><span class="info_name"><%= this.GetMetadata(".Limits").SafeHtmlEncode() %>:</span><span class="info_data"><%= limitSet.MinBet.Value.ToString("N0") %> - <%= limitSet.MaxBet.Value.ToString("N0") %></span>
        <div class="w2c"></div></li>
        <% 
		i++;
		
		} %>
        <li class="<%=i % 2 != 0 ?"Odd":"Even"%>"><span class="info_name"><%= this.GetMetadata(".OpenHour").SafeHtmlEncode()%>:</span><span class="info_data"><%= game.GetOpenHour().SafeHtmlEncode() %></span>
        <div class="w2c"></div></li>
        <% i++;%>
        <li class="<%=i % 2 != 0 ?"Odd":"Even"%>"><span class="info_name"><%= this.GetMetadata(".CloseHour").SafeHtmlEncode()%>:</span><span class="info_data"><%= game.GetCloseHour().SafeHtmlEncode() %></span>
        <div class="w2c"></div></li>
        <% i++;%>
        <% if (!string.IsNullOrWhiteSpace(game.DealerName)){ %>
        <li class="<%=i % 2 != 0 ?"Odd":"Even"%>"><span class="info_name"><%= this.GetMetadata(".DealerName").SafeHtmlEncode()%>:</span><span class="info_data"><%= game.DealerName.SafeHtmlEncode()%></span>
        <div class="w2c"></div></li>
        <% } %>
      </ul>
    </div>
    <div class="game_button" align="center">
      <% if (isOpen)
                           {
                               string limitSetID = null;
                               if (limitSet != null)
                                   limitSetID = limitSet.ID;                                       
                               string script = string.Format("javascript:window.open('{0}', 'livecasinogame', {1})"
                                   , this.Url.RouteUrl("LiveCasinoLobby", new { @action = "XPROLoader", @gameID = game.GameID, @limitSetID = limitSetID }).SafeJavascriptStringEncode()
                                   , !string.IsNullOrEmpty(game.WindowParams) ? game.WindowParams : "'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'"
                                   );
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
