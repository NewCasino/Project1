<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>


<script language="C#" type="text/C#" runat="server">
    private int GetColumnCount() {
        int columnCount = 0;
        if ( int.TryParse( this.ViewData["ColumnCount"] as string, out columnCount) )
            return columnCount;
        return 2;
    }
</script>

<% if (Profile.IsAuthenticated) { %>
<h3 class="BalanceTitle"><%= this.GetMetadata(".Wallet") %></h3>
<ul id="balance-list2" class="WalletMenu hidden"></ul>
<div class="totalBalance">
    <span class="totalBalanceValue"></span>
    <span class="totalBalanceCurrency"></span>
</div>
<script id="balance-item-template2" type="text/html">
<#
    var columnCount = <%= this.GetColumnCount() %>.0;
    var d=arguments[0];
    for(var i=0; i < Math.ceil( d.length/columnCount) * columnCount; i++) {
#> 
    <# if( i < d.length ) {
        var item = d[i]; 
    #>
        <li class="balance-item">
            <span class="currency"><span id="currency-<#= item.EnglishName.htmlEncode() #>" class="currency-<#= item.VendorID.htmlEncode() #>" ><#= item.IsBalanceAvailable ? item.BalanceCurrencySymbol.htmlEncode() : '' #></span></span>
            <span class="balance"><span id="balance-<#= item.EnglishName.htmlEncode() #>"  class="balance-<#= item.VendorID.htmlEncode() #>" ><#=item.IsBalanceAvailable ? item.FormattedAmount.htmlEncode() : '<%=this.GetMetadata(".NA").SafeJavascriptStringEncode()%>' #></span></span>
        </li>
        <# }   #> 
 
<#   }  #>
    
</script>

<script type="text/javascript">
//<![CDATA[
    BalanceList2 = {
        isLoadingInProgress: false,
        url: '/_get_balance.ashx?separateBonus=false&useCache=',
        refresh: function (useCache) {
            if (BalanceList2.isLoadingInProgress)
                return;
            if (!useCache)
                BalanceList2.isLoadingInProgress = true;

            $('#balance-list2').html('<li class="balance-item"><%= this.GetMetadata(".Loading_Balances").SafeJavascriptStringEncode() %></li>');
            var url = BalanceList2.url + ((useCache == false) ? "False" : "True");
            jQuery.getJSON(url, null, BalanceList2.onload);
        },
        onload: function (json) {
            BalanceList2.isLoadingInProgress = false;
            if (!json.success) {
                if (json.isSessionTimedOut == true) {
                    alert('<%= this.GetMetadata("/Head/_BalanceList2_ascx.Session_Timedout").SafeJavascriptStringEncode() %>');
                    self.location = self.location;
                }
                $('#balance-list2').html('<li class="balance-item"><%= this.GetMetadata(".Load_Balances_Failed").SafeJavascriptStringEncode() %></li>');
                return;
            }
            $('#balance-list2').html($('#balance-item-template2').parseTemplate(json.accounts));
            var totalBalanceAmount=0;
            $("#balance-list2 li .balance span").each(function(){ totalBalanceAmount+=parseFloat($(this).text().replace(',','')) });
            $(".totalBalanceValue").html(totalBalanceAmount.toFixed(2));
            $(".totalBalanceCurrency").html($("#balance-list2 li:first .currency span").text());
        }
    };
    $(document).ready(function () { 
        BalanceList2.refresh(true); 
        setInterval(BalanceList2.refresh(false),5000); 
    });
    try { top.reloadBalance = function () { BalanceList2.refresh(false); }; } catch (e) { }

    $(document).bind("BALANCE_UPDATED", function () { BalanceList2.refresh(false); });
    //]]>   
</script> 
<% } %>