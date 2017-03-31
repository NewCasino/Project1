<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Poker.Winner>>" %>

<%@ Import Namespace="Poker" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>

<script type="text/C#" runat="server">
    private string GetGameType(string gameType)
    {
        string key = Regex.Replace(gameType, @"[^a-z]", string.Empty, RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        return this.GetMetadata(string.Format(".GameType_{0}", key)).DefaultIfNullOrEmpty(gameType);
    }

    private string GetLimitType(string limitType)
    {
        string key = Regex.Replace(limitType, @"[^a-z]", string.Empty, RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        return this.GetMetadata(string.Format(".LimitType_{0}", key)).DefaultIfNullOrEmpty(limitType);
    }
</script>

<div id="everleaf-poker-winner-list">


<ul class="winners">    
    <li class="header">
        <span class="nickname"><%= this.GetMetadata(".Nickname").SafeHtmlEncode() %></span>
        <span class="gametype"><%= this.GetMetadata(".Game_Type").SafeHtmlEncode()%></span>
        <span class="gameswon"><%= this.GetMetadata(".Games_Won").SafeHtmlEncode()%></span>
        <span class="limit"><%= this.GetMetadata(".Limit").SafeHtmlEncode()%></span>
        <span class="stake"><%= this.GetMetadata(".Stake").SafeHtmlEncode()%></span>
        <span class="time"><%= this.GetMetadata(".Time").SafeHtmlEncode()%></span>
    </li>

<%
    bool isAlternateItem = false;
    if (this.Model != null)
    {
        int _loopindex = 0;
        foreach (Winner winner in this.Model)
        {
        
            isAlternateItem = !isAlternateItem;
        %>
    <li class="winner <%= isAlternateItem ? "odd" : "" %>">

        <span class="nickname">
            <%= winner.Nickname.SafeHtmlEncode() %>
        </span>

        <span class="gametype">
            <%= GetGameType(winner.GameType).SafeHtmlEncode()%>
        </span>

        <span class="gameswon">
            <%= winner.GamesWon %>
        </span>

        <span class="limit">
            <%= GetLimitType(winner.Limit).SafeHtmlEncode() %>
        </span>

        <span class="stake">
            <span class="currency"><%= winner.Currency.SafeHtmlEncode()%></span>
            <%= winner.StakeLow.ToString("N2") %> / <%= winner.StakeHigh.ToString("N2") %>
        </span>

        <span class="time">
            <% if( winner.StartTime.HasValue && winner.EndTime.HasValue )
               { %>
                <span class="starttime"><%= winner.StartTime.Value.ToString("dd/MM/yyyy HH:mm")%></span>
                 - 
                <span class="endtime"><%= winner.EndTime.Value.ToString("dd/MM/yyyy HH:mm")%></span>
            <% } %>
        </span>

    </li>
<%      }
    } %>
    
</ul>

</div>
