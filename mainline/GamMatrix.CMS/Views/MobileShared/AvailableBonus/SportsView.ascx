<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.AvailableBonus.BonusInfo<GamMatrixAPI.AvailableBonusData>>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% if (Model.HasBonuses())
{
	foreach(var bonus in Model.Bonuses)
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
				<% if (bonus.Percentage > 0)
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_Percentage").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Percentage%></span>
					</div>
				</li>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_PercentageMaxAmount").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.PercentageMaxAmount%></span>
					</div>
				</li>
				<% } %>
				<%if (bonus.IsMinDepositRequirement) 
				{ %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Bonus_MinDepositAmount").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.MinDepositCurrency, bonus.MinDepositAmount).SafeHtmlEncode()%></span>
					</div>
				</li>
				<% } %>
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
				<%if (bonus.WagerRequirementCoefficient > 0.00m)
                { %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Wager_Requirement").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.WagerRequirementCoefficient%></span>
					</div>
				</li>
				<% } %>
				<%-- 
				<%if (!string.IsNullOrWhiteSpace(bonus.TermsAndConditions)) 
                { %>
				<li>
					<div class="ProfileDetail">
						<a href="<%= bonus.TermsAndConditions.HtmlEncodeSpecialCharactors()%>"><%= this.GetMetadata(".Bonus_TermsConditions").SafeHtmlEncode()%></a>
					</div>
				</li>
				<% } %>
				--%>
			</ol>
		</div>
	<% }
} 
else
{
	if (Model.HasError())
		Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, Model.ErrorMessage));
	else
		Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".No_Bonus")) { IsHtml = true });
} %>