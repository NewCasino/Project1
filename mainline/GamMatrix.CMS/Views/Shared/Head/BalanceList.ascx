<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script language="C#" type="text/C#" runat="server">
    private int GetColumnCount()
    {
        int columnCount = 0;
        if( int.TryParse( this.ViewData["ColumnCount"] as string, out columnCount) )
            return columnCount;
        return 2;
    }
</script>

<% if (Profile.IsAuthenticated)
   { %>

<table id="balance-list" cellpadding="0" cellspacing="0">
    <tbody>
    </tbody>
</table>

<script id="balance-item-template" type="text/html">
<#
    var columnCount = <%= this.GetColumnCount() %>.0;
    var d=arguments[0];

    for(var i=0; i < Math.ceil( d.length/columnCount) * columnCount; i++)     
    {      
        
#>
    <#  if( (i % columnCount) == 0 ) { #>
        <tr>
    <#  } else {  #>
        <td class="separator">|</td>
    <# } #>

    <# if( i < d.length ) {
        var item = d[i]; 
    #>
        <td class="name"><span><#= item.DisplayName.htmlEncode() #></span></td>
        <td class="currency"><span id="currency-<#= item.EnglishName.htmlEncode() #>" ><#= item.IsBalanceAvailable ? item.BalanceCurrencySymbol.htmlEncode() : '' #></span></td>
        <td class="balance"><span id="balance-<#= item.EnglishName.htmlEncode() #>" ><#=item.IsBalanceAvailable ? item.FormattedAmount.htmlEncode() : '<%=this.GetMetadata(".NA").SafeJavascriptStringEncode()%>' #></span></td>
    <# } else { #>
        <td class="name">&#160;</td>
        <td class="currency">&#160;</td>
        <td class="balance">&#160;</td>
    <# } #>

    <#  if( ((i+1) % columnCount) == 0 ) { #> </tr> <#  }  #>
<#   }  #>
    
</script>

<script type="text/javascript">
//<![CDATA[
    BalanceList = {
        isLoadingInProgress: false,
        url: '/_get_balance.ashx?separateBonus=True&useCache=',
        refresh: function (useCache) {
            if (BalanceList.isLoadingInProgress)
                return;
            if (!useCache)
                BalanceList.isLoadingInProgress = true;
            $('#balance-list > tbody').html('<td><%= this.GetMetadata(".Loading_Balances").SafeJavascriptStringEncode() %></td>');
            var url = BalanceList.url + ((useCache == false) ? "False" : "True");
            jQuery.getJSON(url, null, BalanceList.onload);
        },
        onload: function (json) {
            BalanceList.isLoadingInProgress = false;
            if (!json.success) {
                if (json.isSessionTimedOut == true) {
                    alert('<%= this.GetMetadata(".Session_Timedout").SafeJavascriptStringEncode() %>');
                    self.location = self.location;
                }
                $('#balance-list > tbody').html('<td><%= this.GetMetadata(".Load_Balances_Failed").SafeJavascriptStringEncode() %></td>');
                return;
            }
            $('#balance-list > tbody').html($('#balance-item-template').parseTemplate(json.accounts)); ;
        }
    };
$(document).ready(function () { BalanceList.refresh(true); });
try { top.reloadBalance = function () { BalanceList.refresh(false); }; } catch (e) { }

$(document).bind("BALANCE_UPDATED", function () { BalanceList.refresh(false); });
//]]>
</script>

<% } %>