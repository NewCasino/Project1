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
<ul id="balance-list">	
</ul>

<script id="balance-item-template" type="text/html">
<#
    var columnCount = <%= this.GetColumnCount() %>.0;
    var d=arguments[0];

    for(var i=0; i < Math.ceil( d.length/columnCount) * columnCount; i++)     
    {
#>
    <#  if( (i % columnCount) == 0 ) { #>
        <li>
    <#  } else {  #>
        <li class="separator">|</li>
    <# } #>

    <# if( i < d.length ) {
        var item = d[i]; 
    #>
        <span class="name"><span><#= item.DisplayName.htmlEncode() #></span></span>
        <span class="currency"><span id="currency-<#= item.EnglishName.htmlEncode() #>" ><#= item.IsBalanceAvailable ? item.BalanceCurrencySymbol.htmlEncode() : '' #></span></span>
        <span class="balance"><span id="balance-<#= item.EnglishName.htmlEncode() #>" ><#=item.IsBalanceAvailable ? item.FormattedAmount.htmlEncode() : '<%=this.GetMetadata(".NA").SafeJavascriptStringEncode()%>' #></span></span>
    <# } else { #>
        <span class="name">&#160;</span>
        <span class="currency">&#160;</span>
        <span class="balance">&#160;</span>
    <# } #>

    <#  if( ((i+1) % columnCount) == 0 ) { #> </li> <#  }  #>
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

            $('#balance-list').html('<li><%= this.GetMetadata(".Loading_Balances").SafeJavascriptStringEncode() %></li>');
            var url = BalanceList.url + ((useCache == false) ? "False" : "True");
            jQuery.getJSON(url, null, BalanceList.onload);
        },
        onload: function (json) {
            BalanceList.isLoadingInProgress = false;
            if (!json.success) {
                if (json.isSessionTimedOut == true) {
                    alert('<%= this.GetMetadata("/Head/_BalanceList_ascx.Session_Timedout").SafeJavascriptStringEncode() %>');
                    self.location = self.location;
                }
                $('#balance-list').html('<li><%= this.GetMetadata(".Load_Balances_Failed").SafeJavascriptStringEncode() %></li>');
                return;
            }
            $('#balance-list').html($('#balance-item-template').parseTemplate(json.accounts)); ;
        }
    };
    $(document).ready(function () { BalanceList.refresh(true); });
    try { top.reloadBalance = function () { BalanceList.refresh(false); }; } catch (e) { }

    $(document).bind("BALANCE_UPDATED", function () { BalanceList.refresh(false); });
//]]>
</script>

<% } %>