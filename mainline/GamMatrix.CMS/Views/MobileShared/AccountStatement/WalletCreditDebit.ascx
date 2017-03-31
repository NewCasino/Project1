<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrixAPI.TransInfoRec>>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>

<script runat="server">
	public string GetAccountName(TransInfoRec trans)
	{
		if (trans.TransType == TransType.WalletCredit)
			return GetCreditAccountName(trans, "{0}");
		return GetDebitAccountName(trans, "{0}");
	}

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

	public string GetCreditAccountName(TransInfoRec trans, string format)
	{
		return string.Format(format, GetAccountMetaName(trans.CreditPayItemVendorID));
	}

	protected string GetAccountMetaName(VendorID accountId)
	{
		return this.GetMetadata(
			string.Format("/Metadata/GammingAccount/{0}.Display_Name",
				accountId.ToString()));
	}

	public string GetCreditAmount(TransInfoRec trans)
	{
		return MoneyHelper.FormatWithCurrency(trans.CreditRealCurrency, trans.CreditRealAmount);
	}

	public string GetDebitAmount(TransInfoRec trans)
	{
		return MoneyHelper.FormatWithCurrency(trans.DebitRealCurrency, trans.DebitRealAmount);
	}

	public string GetStatus(TransInfoRec trans)
	{
		return trans.TransStatus.ToString();
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
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span><span class="HeaderValue"><%= GetFormattedDate(trans.TransCompleted)%></span>
		</div>
		<table class="DetailTable Cols-4">
			<tr>
				<th class="col-account"><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></th>
			</tr>
			<tr>
				<td class="col-account"><%= GetAccountName(trans).SafeHtmlEncode()%></td>
				<% if (trans.TransType == TransType.WalletCredit) 
					{ %>
				<td><span class="TransCredit"><%= GetCreditAmount(trans)%></span></td>
				<% 
					}
					else
					{
				%>
				<td><span class="TransDebit">-<%= GetDebitAmount(trans)%></span></td>
				<% } %>
				<td><%= trans.TransNote.SafeHtmlEncode()%></td>
				<td><span class="<%= GetStatus(trans).ToLowerInvariant()%>"><%= this.GetMetadata(string.Format(".Status_{0}", GetStatus(trans))) %></span></td>
			</tr>
		</table>
    </li>
<%  } %>
</ol>
