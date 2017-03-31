<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Winner>>" %>

<%@ Import Namespace="Bingo" %>

<div id="bingo-free_play_winners">

<div id="bingo-free_play_winners-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>


<div id="bingo-free_play_winners-entries">
<% 
    foreach (Winner winner in this.Model)
    {
         %>
    <div class="entry">
        <div class="winners-name"><%= winner.NickName.SafeHtmlEncode()%></div>
        <div class="winners-amount"><span class="winners-amount-currency"><%= winner.Currency.SafeHtmlEncode()%></span><span class="winners-amount-amount"><%= winner.Amount.ToString("N2")%></span></div>
    </div>

<%} %>
</div>

<div id="bingo-free_play_winners-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>