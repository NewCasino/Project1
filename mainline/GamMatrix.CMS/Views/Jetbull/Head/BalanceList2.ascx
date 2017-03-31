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
        <span class="name name_<#=item.VendorID.htmlEncode()#>"><span><#= item.DisplayName.htmlEncode() #></span></span>
        <span class="currency currency_<#=item.VendorID.htmlEncode()#>"><span id="currency-<#= item.EnglishName.htmlEncode() #>" ><#= item.IsBalanceAvailable ? item.BalanceCurrencySymbol.htmlEncode() : '' #></span></span>
        <span class="balance balance_<#=item.VendorID.htmlEncode()#>"><span id="balance-<#= item.EnglishName.htmlEncode() #>" ><#=item.IsBalanceAvailable ? item.FormattedAmount.htmlEncode() : 'N/A' #></span></span>
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
            $('#balance-list').html($('#balance-item-template').parseTemplate(json.accounts));

            <% if (Settings.IsOMSeamlessWalletEnabled) { %>
            if (json.suspendedFundsAccount != null) {
                new SuspendedFunds(json.suspendedFundsAccount).Create();
            }
            <% } %>
        }
    };
    $(document).ready(function () { BalanceList.refresh(true); });
    try { top.reloadBalance = function () { BalanceList.refresh(false); }; } catch (e) { }

    $(document).bind("BALANCE_UPDATED", function () { BalanceList.refresh(false); });

    <% if (Settings.IsOMSeamlessWalletEnabled) { %>
    var SuspendedFunds = function (_data) {
        var self = this;

        self.data = _data;

        self.cookie = '_SuspendedFunds_Message_Displayed';

        self.messager = null;

        self.seamlessContainer = $('#balance-list .name_CasinoWallet').parent();

        self.Create = function () {
            if ($.cookie(self.cookie) != null)
                return;

            self.Remove();
            var _message = '<%=this.GetMetadata("/Head/_BalanceList_ascx.SuspendedFunds_Message").SafeJavascriptStringEncode()%>'.format(self.data.BalanceAmount);
            $('<div id="message_SuspendedFunds"><div class="message_SuspendedFunds-wrapper"><div class="message_SuspendedFunds-content">' + _message + '<div class="message_SuspendedFunds-close"><span id="message_SuspendedFunds-close-holder"><%=this.GetMetadata("/Head/_BalanceList_ascx.SuspendedFunds_Message_Close").SafeJavascriptStringEncode()%></span></div></div></div></div>').appendTo($('body'));
            self.messager = $('#message_SuspendedFunds');
            self.messager.find('#message_SuspendedFunds-close-holder').click(function () {
                self.Close();
            });

            self.initPosition();

            $(window).resize(function () {
                self.initPosition();
            });
        };

        self.Close = function () {
            $.cookie(self.cookie, '1');
            self.Remove();
        };

        self.Remove = function () {
            $('#message_SuspendedFunds').remove();
        };

        self.initPosition = function () {
            var _offset = self.seamlessContainer.offset();

            var isLeft = true;
            var _top = _offset.top-8;
            var _left = _offset.left + self.seamlessContainer.width();
            if ((_left + self.messager.width()) > $('body').width()) {
                _left = _offset.left - self.messager.width();
                isLeft = false;
            }
            
            self.messager.css({ 'position': 'absolute', 'z-index': '9999'});
            if (isLeft)
                self.messager.find('.message_SuspendedFunds-content').css('margin', '0 0 0 15px');
            else
                self.messager.find('.message_SuspendedFunds-content').css('margin', '0 15px 0 0');
            self.messager.offset({ top: _top, left: _left });
        };        
    };
    <% } %>
//]]>
</script>

<% } %>