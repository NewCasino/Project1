<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrixAPI.TransInfoRec>>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>

<script runat="server">
	public string GetId(TransInfoRec trans)
	{
		return trans.TransID.ToString();
	}

	public string GetFormattedDate(DateTime date)
	{
		return date.ToString("dd/MM/yyyy HH:mm");
	}

	public string GetDebitAccountName(TransInfoRec trans, string format)
	{
		return string.Format(format, GetAccountMetaName(trans.DebitPayItemVendorID));
	}

	protected string GetAccountMetaName(VendorID accountId)
	{
		return this.GetMetadata(
			string.Format("/Metadata/GammingAccount/{0}.Display_Name",
				accountId.ToString()));
	}

	public string GetDebitAmount(TransInfoRec trans)
	{
		return MoneyHelper.FormatWithCurrency(trans.DebitRealCurrency, trans.DebitRealAmount);
	}

	public string GetStatus(TransInfoRec trans)
	{
		return trans.TransStatus.ToString();
	}

	public bool IsRollbackButtonVisible(TransInfoRec trans)
	{
		if (trans.TransStatus == TransStatus.Pending &&
			trans.TransType == TransType.Withdraw)
		{
			if (Settings.PendingWithdrawal_EnableApprovement)
				return !trans.ApprovalStatus;

			return trans.CreditPayItemVendorID != VendorID.PaymentTrust
				&& trans.CreditPayItemVendorID != VendorID.PayPoint
				&& trans.CreditPayItemVendorID != VendorID.Envoy
				&& trans.CreditPayItemVendorID != VendorID.Bank
				&& trans.DebitPayItemVendorID != VendorID.PaymentTrust
				&& trans.DebitPayItemVendorID != VendorID.PayPoint
				&& trans.DebitPayItemVendorID != VendorID.Envoy
				&& trans.DebitPayItemVendorID != VendorID.Bank;
		}
		return false;
	}
</script>

<ol class="CardList TransactionList">
<% 
    foreach (TransInfoRec trans in Model)
    {
%>
    <li>
		<div class="CardHeader">
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span><span class="HeaderValue"><%= GetId(trans) %></span>
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span><span class="HeaderValue"><%= GetFormattedDate(trans.TransCreated)%></span>
		</div>
		<table class="DetailTable Cols-4">
			<tr>
				<th class="col-account"><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></th>
			</tr>
			<tr>
				<td class="col-account"><%= GetDebitAccountName(trans, this.GetMetadata(".FromAccount")).SafeHtmlEncode()%></td>
				<td><%= GetDebitAmount(trans)%></td>
				<td><%= ((trans.TransType == TransType.User2Vendor) ? trans.Note : trans.CreditPayItemName).SafeHtmlEncode()%></td>
				<td>
					<span class="<%= GetStatus(trans).ToLowerInvariant()%>"><%= this.GetMetadata(string.Format(".Status_{0}", GetStatus(trans))) %></span>
					<% if (IsRollbackButtonVisible(trans))
					{ %>
					<span>
						<button onclick="self.location='<%= this.Url.RouteUrl("PendingWithdrawal", new { @sid = trans.Sid, @action = "Rollback" }).SafeJavascriptStringEncode()%>';return false;" class="Button" type="button">
							<strong class="ButtonText"><%= this.GetMetadata(".Button_Rollback").SafeHtmlEncode()%></strong>
						</button>   
					</span>
					<% } %>
				</td>
			</tr>
		</table>
    </li>
<%  } %>
</ol>