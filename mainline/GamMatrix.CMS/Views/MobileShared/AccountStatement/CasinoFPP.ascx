<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrixAPI.TransInfoRec>>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private string GetAccountName(TransInfoRec trans)
    {
        return string.Format(this.GetMetadata(".ToAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", trans.CreditPayItemVendorID.ToString()))
           );
    }

    private string GetStatusHtml(TransInfoRec trans)
    {
        return string.Format("<span class=\"{0}\">{1}</span>"
            , trans.TransStatus.ToString().ToLowerInvariant()
            , this.GetMetadata(string.Format(".Status_{0}", trans.TransStatus.ToString())).SafeHtmlEncode()
            );
    }
</script>

<ol class="CardList TransactionList">
<% 
    foreach (TransInfoRec trans in Model)
    {
%>
        <li>
        <div class="CardHeader">
        <span class="HeaderLable"><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span><span class="HeaderValue"><%= trans.TransID.ToString() %></span>
        <span class="HeaderLable"><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span><span class="HeaderValue"><%= trans.TransCompleted.ToString("dd/MM/yyyy HH:mm")%></span>
        </div>
        <table class="DetailTable Cols-4">
        <tr>
        <th class="col-account"><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></th>
        <th><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></th>
        <th><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></th>
        <th><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></th>
        </tr>
        <tr>
        <td class="col-account"><%= GetAccountName(trans).SafeHtmlEncode() %></td>
        <td><%= MoneyHelper.FormatWithCurrency( trans.CreditRealCurrency, trans.CreditRealAmount) %></td>
        <td><%= trans.DebitPayItemName.SafeHtmlEncode() %></td>
        <td><%= GetStatusHtml(trans) %></td>
        </tr>
        </table>
        </li>
<%  } %>
</ol>