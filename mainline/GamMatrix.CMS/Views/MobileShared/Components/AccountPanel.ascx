<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.AccountPanelViewModel>" %>

<div class="MenuList MainMenuList Container L BalanceList BalanceZone">
	<a id="balanceRefresh" class="BalanceRefresh" href="<%= this.Model.GetBalanceUrl().SafeHtmlEncode()%>"><span class="RefreshIcon">Refresh</span><span class="RefreshName"><%= this.GetMetadata(".Balance_Refresh").SafeHtmlEncode()%></span></a>
	<div id="spBalanceZone" class="BalanceInfo"></div>
</div>

<script id="account-panel-balance-template" type="text/html">
<#
    var d=arguments[0];

    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i];
#>
        <span class="BalanceAccount Container <#= item.EnglishName.htmlEncode() #>Balance <#= item.VendorID.htmlEncode() #>_Account">
            <span class="BalanceIcon"><#= item.EnglishName.htmlEncode() #></span>
			<span class="BalanceName"><#= item.DisplayName.htmlEncode() #></span>
			<span class="BalanceSum"> 
				<span class="BalanceAmount">
					<#= item.IsBalanceAvailable ? item.BalanceCurrencySymbol.htmlEncode() : '' #>
					<#= item.IsBalanceAvailable ? item.FormattedAmount.htmlEncode() : 'N/A' #>
				</span>
			</span>
        </span>
<#   }  #>
</script>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="false">
<script type="text/javascript">
    function M360_AccountPanel(storage) {
		var refreshButton = $('#balanceRefresh'),
			balanceZone = $('.BalanceZone'),
			panelOpen = false,
			balanceData;

		<% 
			if (!this.Model.IsLocalSite)
			{
		%>
        $.fn.parseTemplate = function (data) {
            var str = (this).html();
            var _tmplCache = {}
            var err = "";
            try {
                var func = _tmplCache[str];
                if (!func) {
                    var strFunc =
                    "var p=[],print=function(){p.push.apply(p,arguments);};" +
                                "with(obj){p.push('" +
                    str.replace(/[\r\t\n]/g, " ")
                       .replace(/'(?=[^#]*#>)/g, "\t")
                       .split("'").join("\\'")
                       .split("\t").join("'")
                       .replace(/<#=(.+?)#>/g, "',$1,'")
                       .split("<#").join("');")
                       .split("#>").join("p.push('")
                       + "');}return p.join('');";

                    //alert(strFunc);
                    func = new Function("obj", strFunc);
                    _tmplCache[str] = func;
                }
                return func(data);
            } catch (e) { err = e.message; }
            return "< # ERROR: " + err.toString() + " # >";
        }

        String.prototype.htmlEncode = function () {
	        var $str = this;

	        var $regex = new RegExp("((\\<\\%(.*?)%\\>)|[^\\x00-\\x7F]|&|\\\"|\\<|\\>|')", "g");
	        return $str.replace($regex, function ($1) {
	            if ($1 != null) {
	                if ($1.length == 1)
	                    return "&#" + $1.charCodeAt(0).toString(10) + ";";
	                else if ($1.length > 1)
	                    return $1;
	            }
	            return "";
	        });
        };
		<%
			}
		%>
        var isLoading = false;

		function parseBalanceData(data){
			balanceData = data;
			$($('#account-panel-balance-template').parseTemplate(balanceData)).appendTo($('#spBalanceZone'));
		}

        
        function onGetUserBalance(json) {
            isLoading = false;
			refreshButton
				.find('.RefreshName')
					.text('<%= this.GetMetadata(".Balance_Refresh").SafeJavascriptStringEncode() %>')
					.end()
				.find('.RefreshIcon')
					.removeClass('rotating');

            if (!json.success) {
                <%-- session timed out --%>
                if (json.isLoggedIn === false) {
                    alert('<%= this.GetMetadata(".Session_Timedout").SafeJavascriptStringEncode() %>');
                    location.reload(true);
                    return;
                }
                <%-- generic errors --%>
                $('<span class="BalanceMessage"></span>').text('<%= this.GetMetadata(".Load_Balances_Failed").SafeJavascriptStringEncode() %>').appendTo($('#spBalanceZone'));
                return;
            }

			storage.setItem('M360_Balances', JSON.stringify(json));
			parseBalanceData(json.accounts);
        }
        self.onGetUserBalance = onGetUserBalance;

		function queryForBalance(url){
            url =  url + '&jsoncallback=?';

			$.ajax({
                crossDomain: true,
                url: url,
                dataType: 'jsonp',
                cache: false,
                success: function(json) { onGetUserBalance(json); },
                error: function() { },
                complete: function() { }
            });

		}

		function refreshBalance(){
			if(isLoading)
				return;
			isLoading = true;

			storage.removeItem('M360_Balances');

			$('.BalanceAccount, .BalanceMessage', $('#spBalanceZone')).remove();
			refreshButton
				.find('.RefreshName')
					.text('<%= this.GetMetadata(".Balance_Loading").SafeJavascriptStringEncode() %>')
					.end()
				.find('.RefreshIcon')
					.addClass('rotating');

			var url = refreshButton.attr('href');
			queryForBalance(url);
		}
		refreshButton.click(function(){
			refreshBalance();
			return false;
		});

		var data = storage.getItem('M360_Balances');
		if (data)
			parseBalanceData($.parseJSON(data).accounts);

		return{
			refresh: refreshBalance,
			ready: function(){ return !!balanceData; }
		}
	};
</script>
</ui:MinifiedJavascriptControl>


