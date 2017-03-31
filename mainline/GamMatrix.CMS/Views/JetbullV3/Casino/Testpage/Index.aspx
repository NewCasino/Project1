<%@ Page Language="C#" PageTemplate="/SinglePageMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server"><p>&nbsp;</p>
<p>&nbsp;</p>
<p>The more you bet, the more you can win.</p>
<p>Between 4th of Aug (00:00 am UTC) and 11th of Aug (11.59 pm UTC) place bets on any sports game and you gain points, as follows:</p>
<p>Single bets (odds equal or greater than 1.50)</p>
<p><span style="white-space: pre;"> </span>&bull; If bet is lost, points will be calculated by multiplying the stake (EUR equivalent) with 1.</p>
<p><span style="white-space: pre;"> </span>&bull; If bet is won, points will be calculated by multiplying the winnings (EUR equivalent) with 1.</p>
<p>Multiple bets (any kind of multiple bet)</p>
<p><span style="white-space: pre;"> </span>&bull; If bet is lost, points will be calculated by multiplying the stake (EUR equivalent) with 2.</p>
<p><span style="white-space: pre;"> </span>&bull; If bet is won, points will be calculated by multiplying the winnings (EUR equivalent) with 2</p>
At the end of the week, the Top 10 bettors become Jetbull Sports Masters!&nbsp;
<p>Are you up for the challenge?</p>
<p>Start Betting!</p>
<p>&nbsp;</p>
<table class="tg user-table">
<thead> 
<tr>
<th class="tg-031e"><span style="color: #ffffff;">Position</span></th> <th class="tg-031e"><span style="color: #ffffff;">Username</span></th> <th class="tg-031e"><span style="color: #ffffff;">Points</span></th> <th class="tg-031e"><span style="color: #ffffff;">Prize</span></th>
</tr>
</thead> 
<tbody>
<tr>
<td class="tg-4eph"><span style="color: #ffffff;">1</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">Ronaldo</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">x</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">100 EUR &amp; 100% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-031e"><span style="color: #ffffff;">2</span></td>
<td class="tg-031e"><span style="color: #ffffff;">Messi</span></td>
<td class="tg-031e"><span style="color: #ffffff;">x</span></td>
<td class="tg-031e"><span style="color: #ffffff;">50 EUR &amp; 100% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-4eph"><span style="color: #ffffff;">3</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">Djokovic</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">x</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">25 EUR &amp; 100% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-031e"><span style="color: #ffffff;">4</span></td>
<td class="tg-031e"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-031e"><span style="color: #ffffff;">x</span></td>
<td class="tg-031e"><span style="color: #ffffff;">100% Deposit Bonus</span></td>
</tr>
</tbody>
<tbody class="expandable-rows" style="display: none;">
<tr>
<td class="tg-4eph"><span style="color: #ffffff;">5</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">x</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">100% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-031e"><span style="color: #ffffff;">6</span></td>
<td class="tg-031e"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-031e"><span style="color: #ffffff;">x</span></td>
<td class="tg-031e"><span style="color: #ffffff;">75% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-4eph"><span style="color: #ffffff;">7</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">x</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">75% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-031e"><span style="color: #ffffff;">8</span></td>
<td class="tg-031e"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-031e"><span style="color: #ffffff;">x</span></td>
<td class="tg-031e"><span style="color: #ffffff;">75% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-4eph"><span style="color: #ffffff;">9</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">x</span></td>
<td class="tg-4eph"><span style="color: #ffffff;">75% Deposit Bonus</span></td>
</tr>
<tr>
<td class="tg-031e"><span style="color: #ffffff;">10</span></td>
<td class="tg-031e"><span style="color: #ffffff;">Abcd</span></td>
<td class="tg-031e"><span style="color: #ffffff;">x</span></td>
<td class="tg-031e"><span style="color: #ffffff;">75% Deposit Bonus</span></td>
</tr>
</tbody>
</table>
<p><a href="#" class="hidden expand-user-table">View More</a> <a href="#" class="collapse-user-table">View Less</a></p>
<p>&nbsp;</p>
<p><a href="http://www.jetbull.com/TermsConditions">Terms &amp; Conditions apply.</a></p>
<p>This is an exclusive offer available for a limited number of players.&nbsp;</p>
<p>&nbsp;</p>
<script type="text/javascript">// <![CDATA[
jQuery(function($){
  // EXPAND / COLLAPSE MECHANISM FOR THE JETBULL USER RANKING
  var $expandableTableSection = $('.user-table .expandable-rows');
  var $expandBtn = $('.expand-user-table');
  var $collapseBtn = $('.collapse-user-table');
  
  // Actions
  $expandBtn.click(function(){
    $expandableTableSection.show();
    $expandBtn.addClass('hidden');
    $collapseBtn.removeClass('hidden');
    return false;
  });
  $collapseBtn.click(function(){
    $expandableTableSection.hide();
    $expandBtn.removeClass('hidden');
    $collapseBtn.addClass('hidden');
    return false;
  });
  
  // Make sure it starts collapsed
  $expandableTableSection.hide();
  $collapseBtn.click();
});
// ]]></script></asp:Content>

