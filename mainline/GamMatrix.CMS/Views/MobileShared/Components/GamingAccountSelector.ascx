<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.GamingAccountSelectorViewModel>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>

<div class="WalletContainer" <%= this.Model.GetComponentIdProperty("id=\"", "Selector\"")%>>
	<ul class="AmountFields">
		<li class="FormItem">
			<label class="FormLabel" for="<%= Model.ComponentId %>"><%= this.Model.SelectorLabel.SafeHtmlEncode()%></label>
			<select class="FormInput AccountInput" id="selectAccount" autocomplete="off">
				<option selected="selected" value=""><%= this.GetMetadata(".Account_Select").SafeHtmlEncode()%></option>
				<% 
					foreach (AccountData account in Model.Accounts)
					{  
				%>
				<option value="<%= account.Record.ID%>" data-account="<%= Model.GetAccountDetailsJson(account).SafeHtmlEncode()%>" data-bonus="<%= Model.GetBonusDetailsJson(account).SafeHtmlEncode()%>"><%= account.Record.VendorID.GetDisplayName()%></option>
				<% 
					}
				%>
			</select>
		</li>
	</ul>
	
	<div class="FormItem">
		<%: Html.Hidden(Model.ComponentId, "", new Dictionary<string, object>()
		{
			{ "class", "GamingSelectorHidden" },
			{ "required", "required" },
			{ "autocomplete", "off" },
			{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Account_Empty")) }
		}) %>
		<span class="FormHelp"></span>
	</div>
</div>

<% 
	if (!Model.DisableJsCode)
	{
%>
	<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		function GamingAccountSelector(domSelector, defaultSelection) {

			var selector = $('.AccountInput', domSelector),
				currentData = {};

			var dispatcher = new CMS.utils.Dispatcher();

			function clearSelection() {
				selector.val('');

	    		currentData = {};
				$('.GamingSelectorHidden', domSelector).val('');
			}

			function selectItem(data) {
				currentData = data;

				var account = getAccountData(),
					bonus = data.bonus || {};
				
				$('.GamingSelectorHidden', domSelector).val(account.ID).valid();

				dispatcher.trigger('change', account);
				dispatcher.trigger('bonus', bonus);
			}

			function getAccountData() {
        		return currentData.account || {};
			}

			selector.change(function () {
				selectItem($(':selected', selector).data());
			});

			if (defaultSelection !== false) {
				$(document).ready(function () {
					var option = $('option', selector).eq(1);
					selector.val(option.val());
					selectItem(option.data());
				});
			}

			return {
        		evt: dispatcher,
        		data: getAccountData,
        		clear: clearSelection
			}
		}
	</script>
	</ui:MinifiedJavascriptControl>
<%
	}
%>