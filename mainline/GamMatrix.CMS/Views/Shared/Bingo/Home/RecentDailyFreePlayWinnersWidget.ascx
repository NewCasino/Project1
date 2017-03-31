<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Winner>>" %>

<%@ Import Namespace="Bingo" %>

<div id="bingo-recent-free_play-winners">

<div id="bingo-recent-free_play-winners-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>

<div class="entry entry-header">
<div class="winners-date"><%= this.GetMetadata(".Date").SafeHtmlEncode()%></div>
<div class="winners-name"><%= this.GetMetadata(".Alias").SafeHtmlEncode()%></div>
<div class="winners-amount"><%= this.GetMetadata(".EndBalance").SafeHtmlEncode()%></div>
</div>
<div id="bingo-recent-free_play-winners-entries">
<% 
    bool inversion = false;
    foreach (Winner winner in this.Model)
    {
        inversion = !inversion;
         %>
    <div class="entry <%=inversion ? "Odd" : "Even" %>">
        <div class="winners-date"><%= winner.DateWon.DayOfWeek%> &nbsp; <%= winner.DateWon.ToString("dd.MM.yyyy")%></div>
        <div class="winners-name"><%= winner.NickName.SafeHtmlEncode()%></div>
        <div class="winners-amount"><span class="winners-amount-currency"><%= winner.Currency.SafeHtmlEncode()%></span><span class="winners-amount-amount"><%= winner.Amount.ToString("N2")%></span></div>
    </div>

<%} %>
</div>

<div id="bingo-recent-free_play-winners-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>