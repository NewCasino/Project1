<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.RgDepositLimitInfoRec>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
	private string GetExpirationDate()
	{
		if (this.Model.ExpiryDate.Date == DateTime.MaxValue.Date)
			return this.GetMetadata(".No_Expiration");

		return this.Model.ExpiryDate.ToString("dd/MM/yyyy");
	}

	private bool GetRemoved()
	{
		return this.Model.UpdateFlag && this.Model.UpdatePeriod == RgDepositLimitPeriod.None;
	}

	private bool GetScheduled()
	{
		return this.Model.UpdateFlag && this.Model.UpdatePeriod != RgDepositLimitPeriod.None;
	}
</script>

<form action="<%= Url.RouteUrl("DepositLimit", new { @action = "Edit", @limitID=this.Model.ID }) %>" method="post">
    
	<ol class="DetailPairs ProfileList">
		<li>
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Period.ToString().SafeHtmlEncode()%></span>
			</div>
		</li>
		<li>
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Currency.SafeHtmlEncode()%></span>
			</div>
		</li>
		<li>
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Amount.ToString().SafeHtmlEncode()%></span>
			</div>
		</li>
		<li>
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".ExpirationDate_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetExpirationDate().SafeHtmlEncode()%></span>
			</div>
		</li>
	</ol>
	<%
		if (GetRemoved())
		{
			Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Limit_Removed")));
		}
		else if (GetScheduled())
		{
			Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Limit_Scheduled")));
	%>
		<ol class="DetailPairs ProfileList">
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.UpdatePeriod.ToString().SafeHtmlEncode()%></span>
				</div>
			</li>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.UpdateCurrency.SafeHtmlEncode()%></span>
				</div>
			</li>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.UpdateAmount.ToString().SafeHtmlEncode()%></span>
				</div>
			</li>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".ValidFrom_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetExpirationDate().SafeHtmlEncode()%></span>
				</div>
			</li>
		</ol>
	<%
		}
		else
		{
	%>
	<div class="AccountButtonContainer">
		<button class="Button AccountButton" type="submit">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_Change").SafeHtmlEncode()%></strong>
		</button>
	</div>
	<%
		}
	%>
</form>