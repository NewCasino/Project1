<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.AvailableBonus.BonusInfo<GamMatrixAPI.BonusData>>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="GmCore" %>

<% if (Model.HasBonuses())
{
	foreach (var bonus in Model.Bonuses)
    { %>
		<div class="MenuList L DetailContainer">
			<ol class="DetailPairs ProfileList">
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_Type").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Type.SafeHtmlEncode()%></span>
					</div>
				</li>
				<% if (bonus.BonusID != "0")
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_ID").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.BonusID.SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
				<%if (!string.IsNullOrWhiteSpace(bonus.Name))
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_Name").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Name.SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_Amount").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.Currency, bonus.Amount).SafeHtmlEncode()%></span>
					</div>
				</li>
				<% if (!string.IsNullOrWhiteSpace(bonus.WagerRequirementCurrency) )
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Wager_Requirement").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.WagerRequirementCurrency, bonus.WagerRequirementAmount).SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Remaining_Wagering").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.RemainingWagerRequirementCurrency, bonus.RemainingWagerRequirementAmount).SafeHtmlEncode()%></span>
					</div>
				</li>
				<%if (bonus.Created.HasValue)
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_Granted_Date").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0:dd/MM/yyyy}", bonus.Created.Value).SafeHtmlEncode()%></span>
					</div>
				</li>
				<%} %>
				<%if (bonus.ExpiryDate.HasValue)
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Expiry_Date").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0:dd/MM/yyyy}", bonus.ExpiryDate.Value).SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
				<%if (!string.IsNullOrWhiteSpace(bonus.Status))
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_Status").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Status.SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
				<%if (bonus.ConfiscateAllFundsOnExpiration.HasValue)
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Confiscate_All_Funds_On_Expiration").SafeHtmlEncode()%></span> <span class="DetailValue"><%= (bonus.ConfiscateAllFundsOnExpiration.Value ? this.GetMetadata(".YES") : this.GetMetadata(".NO")).SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
				<%if (bonus.ConfiscateAllFundsOnForfeiture.HasValue)
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Confiscate_All_Funds_On_Forfeiture").SafeHtmlEncode()%></span> <span class="DetailValue"><%= (bonus.ConfiscateAllFundsOnForfeiture.Value ? this.GetMetadata(".YES") : this.GetMetadata(".NO")).SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
			</ol>
		</div>
		
		<%if (bonus.VendorID == VendorID.CasinoWallet && bonus.ConfiscateAllFundsOnForfeiture.HasValue) //Forfeit Casino Wallet Bonus
		{ 
			using( Html.BeginRouteForm( "AvailableBonus", new { @action="ForfeitCasinoBonus"},FormMethod.Post, new { @id="formForfeitCasinoBonus" + bonus.ID }) )
			{ %>
                
				<%: Html.Hidden( "bonusID", bonus.ID) %>     
				<button id="btnForfeitCasinoBonus<%=bonus.ID %>" class="Button AccountButton" type="submit">
					<strong class="ButtonText"><%= this.GetMetadata(".Forfeit").SafeHtmlEncode()%></strong>
				</button> 
			<% } %>
			<script type="text/javascript">
				$(function () {
					$('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click( function(e){
						e.preventDefault();
						var confiscateAll = <%= bonus.ConfiscateAllFundsOnForfeiture.Value.ToString().ToLowerInvariant() %>;
						var ret = false;
						if( confiscateAll )
							ret = window.confirm( '<%= this.GetMetadata(".Confiscate_All_Warning").SafeJavascriptStringEncode() %>' );
						else
							ret = window.confirm( '<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>' );

						if(ret){
							$('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').attr("disabled","disabled");
							var options = {
								dataType: "json",
								type: 'POST',
								url: $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').attr('action'),
							    data: {__RequestVerificationToken: $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %> input[name=__RequestVerificationToken]').val(),
							        "bonusID":$('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').find("#bonusID").val()},
								success: function (json) {
									$('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
									if( !json.success ){
										alert(json.error);
									}else{
										self.location = self.location.toString().replace(/(\#.*)$/, '');
									}
								},
								error: function (xhr, textStatus, errorThrown) {
									$('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
								}
							};
								$.ajax(options);
							}
					});
				});
			</script>
		<% } %> <%-- /Forfeit Casino Wallet Bonus --%>

		<%if (bonus.VendorID == VendorID.NetEnt) //Forfeit Classic NetEnt Bonus
			{ %>
		<% using (Html.BeginRouteForm("AvailableBonus", new { @action = "ForfeitNetEntBonus" }, FormMethod.Post, new { @id = "formForfeitNetEntBonus" + bonus.ID }))
		{ %>
            
			<%: Html.Hidden( "bonusID", bonus.ID) %>                
			<button id="btnForfeitNetEntBonus<%= bonus.ID%>" class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Forfeit").SafeHtmlEncode()%></strong>
			</button>
			<% } %>

			<script type="text/javascript">
				$(function () {
					$('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click(function (e) {
						e.preventDefault();
						var ret = window.confirm('<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>');

						if (ret) {
							$('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').attr("disabled", "disabled");
							var options = {
								dataType: "json",
								type: 'POST',
								url: $('#formForfeitNetEntBonus<%=bonus.ID.SafeJavascriptStringEncode() %>').attr('action'),
							    data: { __RequestVerificationToken: $('#formForfeitNetEntBonus<%=bonus.ID.SafeJavascriptStringEncode() %> input[name=__RequestVerificationToken]').val(),
							        "bonusID": $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').find("#bonusID").val() },
								success: function (json) {
									$('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
									if (!json.success) {
										alert(json.error);
									} else {
										self.location = self.location.toString().replace(/(\#.*)$/, '');
									}
								},
								error: function (xhr, textStatus, errorThrown) {
									$('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
								}
							};
								$.ajax(options);
							}
					});
				});
			</script>
		<% } %>  <%-- /Forfeit Classic NetEnt Bonus --%>
   
	<% }
} 
else
{
	if (Model.HasError())
		Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, Model.ErrorMessage));
	else
		Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".No_Bonus")) { IsHtml = true });
} %>

<%------------------------------------
    CasinoWallet - Bonus Code
 ------------------------------------%>
<%
var gammingAccounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID);
if( gammingAccounts.Exists( a => a.Record.VendorID == VendorID.CasinoWallet ) )
{ %>
	<hr />
	<% using( Html.BeginRouteForm( "AvailableBonus", new { @action = "ApplyCasinoBonusCode" }, FormMethod.Post, new { @id = "formApplyCasinoBonusCode" }) )
	{ %>
<%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
 <%} %>
      
        
		<%: Html.H5( this.GetMetadata(".Enter_Bonus_Code") )  %>
		<ul class="FormList">
			<li class="FormItem" id="fldFirstName" runat="server">
				<label class="FormLabel" for="bonusCode"><%= this.GetMetadata(".Bonus_Code").SafeHtmlEncode()%></label>
				<%: Html.TextBox("bonusCode", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "id", "bonusCode" },
					{ "maxlength", "50" },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Bonus_Code_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
		</ul>
		<button id="btnApplyCasinoBonus" class="Button AccountButton" type="submit">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit").SafeHtmlEncode()%></strong>
		</button>
            
		<script type="text/javascript">
			$(function () {
				$('#formApplyCasinoBonusCode').initializeForm();

				$('#btnApplyCasinoBonus').click(function (e) {
            		e.preventDefault();

            		if (!$('#formApplyCasinoBonusCode').valid())
            			return;
            		$('#btnApplyCasinoBonus').attr("disabled", "disabled");
            		var options = {
            			dataType: "json",
            			type: 'POST',
            			url: $('#formApplyCasinoBonusCode').attr('action'),
            			data: { __RequestVerificationToken: $('#formApplyCasinoBonusCode input[name=__RequestVerificationToken]').val(),
            			    "bonusCode": $("#bonusCode").val(),"iovationBlackBox": (typeof io_blackbox_value == 'undefined') ? "" : io_blackbox_value },
            			success: function (json) {
            				$('#btnApplyCasinoBonus').removeAttr("disabled");
            				if (!json.success) {
            					alert(json.error);
            					return;
            				}
            				alert('<%= this.GetMetadata(".Bonus_Code_Applied").SafeJavascriptStringEncode() %>');
							self.location = self.location.toString().replace(/(\#.*)$/, '');
						},
						error: function (xhr, textStatus, errorThrown) {
							$('#btnApplyCasinoBonus').removeAttr("disabled");
						}
					};
					$.ajax(options);
				});
			});
		</script>
	<% } %>
<% } %>