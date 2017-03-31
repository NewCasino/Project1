<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.AccountStatement.TransferViewModel>" %>
<%@ Import Namespace="GamMatrixAPI" %>

<ol class="CardList TransactionList">
<% 
    foreach (TransInfoRec trans in Model.GetTransactions())
    {
%>
    <li>
		<div class="CardHeader">
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span><span class="HeaderValue"><%= Model.GetId(trans) %></span>
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span><span class="HeaderValue"><%= Model.GetDate(trans)%></span>
		</div>
		<table class="DetailTable Cols-4">
			<tr>
				<th><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></th>
			</tr>
			<tr>
				<td><%= Model.GetDebitAccountName(trans, this.GetMetadata(".FromAccount")).SafeHtmlEncode()%></td>
				<td>
					<span class="TransDebit">-<%= Model.GetDebitAmount(trans) %></span>
					<span class="TransCredit"><%= Model.GetCreditAmount(trans) %></span>
				</td>
				<td><%= Model.GetCreditAccountName(trans, this.GetMetadata(".ToAccount")).SafeHtmlEncode()%></td>
				<td><span class="<%= Model.GetStatus(trans).ToLowerInvariant()%>"><%= this.GetMetadata(string.Format(".Status_{0}", Model.GetStatus(trans))) %></span></td>
			</tr>
		</table>
    </li>
<%  } %>
</ol>