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

<% if (Profile.IsAuthenticated) { %>

<%-- 
<ul id="balance-list" class="WalletMenu">
</ul>
--%>

<script id="balance-item-template" type="text/html">
<#
    var columnCount = <%= this.GetColumnCount() %>.0;
    var d=arguments[0];

    for(var i=0; i < Math.ceil( d.length/columnCount) * columnCount; i++) {
#> 
        <# if( i < d.length ) {
            var item = d[i]; 
        #>
        <li class="balance-item balance-item-<#= item.EnglishName.htmlEncode() #> balance-vendor-<#= item.VendorID.htmlEncode() #>">
            <span class="name"><#= item.DisplayName.htmlEncode() #></span>
            <span class="currency"><span id="currency-<#= item.EnglishName.htmlEncode() #>" class="currency-<#= item.VendorID.htmlEncode() #>" ><#= item.IsBalanceAvailable ? item.BalanceCurrencySymbol.htmlEncode() : '' #></span></span>
            <span class="balance"><span id="balance-<#= item.EnglishName.htmlEncode() #>"  class="balance-<#= item.VendorID.htmlEncode() #>" ><#=item.IsBalanceAvailable ? item.FormattedAmount.htmlEncode() : '<%=this.GetMetadata(".NA").SafeJavascriptStringEncode()%>' #></span></span>
        </li>
        <# }   #> 
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

            $('#balance-list').html('<li class="balance-item"><%= this.GetMetadata(".Loading_Balances").SafeJavascriptStringEncode() %></li>');
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
                $('#balance-list').html('<li class="balance-item"><%= this.GetMetadata(".Load_Balances_Failed").SafeJavascriptStringEncode() %></li>');
                return;
            }
            $('#balance-list').html($('#balance-item-template').parseTemplate(json.accounts));
        }
    };
    $(document).ready(function () { BalanceList.refresh(true);setInterval(BalanceList.refresh(false),5000); });
    try { top.reloadBalance = function () { BalanceList.refresh(false); }; } catch (e) { }

    $(document).bind("BALANCE_UPDATED", function () { BalanceList.refresh(false); });
    //]]>   
</script>

<% } %>