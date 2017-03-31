<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.TransInfoRec>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private string GetAccountName(TransInfoRec trans)
    {
        return string.Format(this.GetMetadata(".FromAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", trans.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetStatusHtml(TransInfoRec trans)
    {
        return string.Format("<span>{0}</span>"
            , this.GetMetadata(string.Format(".Status_{0}", trans.TransStatus.ToString())).SafeHtmlEncode()
            );
    }

    private bool IsRollbackButtonVisible(TransInfoRec trans)
    {
        if (trans.TransStatus == TransStatus.Pending &&
            trans.TransType == TransType.Withdraw)
        {
            if (Settings.PendingWithdrawal_EnableApprovement)
                return !trans.ApprovalStatus;
            return true;
            /*return trans.CreditPayItemVendorID != VendorID.PaymentTrust
                   && trans.CreditPayItemVendorID != VendorID.PayPoint
                   && trans.CreditPayItemVendorID != VendorID.Envoy
                   && trans.CreditPayItemVendorID != VendorID.Bank
                   && trans.DebitPayItemVendorID != VendorID.PaymentTrust
                   && trans.DebitPayItemVendorID != VendorID.PayPoint
                   && trans.DebitPayItemVendorID != VendorID.Envoy
                   && trans.DebitPayItemVendorID != VendorID.Bank;*/
        }
        return false;
    }
    private string GetTimeForJavaScript(DateTime dateTime)
    {
        return string.Format("\"Year\":{0}, \"Month\":{1}, \"Day\":{2}, \"Hour\":{3}, \"Minute\":{4}, \"Second\":{5}",
            dateTime.Year,
            dateTime.Month,
            dateTime.Day,
            dateTime.Hour,
            dateTime.Minute,
            dateTime.Second).SafeHtmlEncode();
    }
</script>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="pending-withdrawal-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnPendingWithdrawal">


<center>
    <%: Html.InformationMessage( this.GetMetadata(".Message") , true ) %>
</center>


<table cellpadding="0" cellspacing="0" border="0" class="transaction-table">
    <thead>
        <tr>
            <th class="col-1"><span><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span></th>
            <th class="col-2"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></th>
            <th class="col-3"><span><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></span></th>
            <th class="col-4"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></th>
            <th class="col-5"><span><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></span></th>
            <th class="col-6"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></th>
            <th class="col-7"></th>
        </tr>
    </thead>
    <tbody>

<% 
    bool isAlternate = true;
    foreach (TransInfoRec trans in this.Model)
    {
        isAlternate = !isAlternate; %>
        <tr class="<%= isAlternate ? "odd" : "" %> <%= trans.TransStatus.ToString().ToLowerInvariant() %>">
            <td class="col-1"><span><%= trans.TransID.ToString() %></span></td>
            <td class="col-2 col-time" date-time="<%= GetTimeForJavaScript(trans.TransCreated) %>"><span><%= trans.TransCreated.ToString("dd/MM/yyyy HH:mm")%></span></td>
            <td class="col-3"><span><%= GetAccountName(trans).SafeHtmlEncode() %></span></td>
            <td class="col-4"><span><%= MoneyHelper.FormatWithCurrency( trans.DebitRealCurrency, trans.DebitRealAmount) %></span></td>
            <td class="col-5"><span><%= trans.CreditPayItemName %></span></td>
            <td class="col-6">
                <%= GetStatusHtml(trans) %>
            </td>
            <td>
                <% if (this.IsRollbackButtonVisible(trans))
                   { %>
                        <%: Html.Button(this.GetMetadata(".Button_Rollback"), new
                        {
                            @onclick = string.Format("self.location='{0}';return false;"
                                , this.Url.RouteUrl("PendingWithdrawal", new { @sid = trans.Sid, @action = "Rollback" }).SafeJavascriptStringEncode()
                                )
                        })%>
                <% } %>
            </td>
        </tr>
<%  } %>

    </tbody>
    <tfoot>
    </tfoot>
</table>



</ui:Panel>
</div>
<script type="text/javascript">
    function onTransactionsLoad() {
        var t = $("#pending-withdrawal-wrapper .transaction-table");
        $.each(t.find("td.col-time"), function (i, n) {
            var t = $(n);
            var s = t.data("time") || t.attr("date-time");
            var dateJson = $.parseJSON('{' + s + '}');
            var d = new Date(dateJson.Year, dateJson.Month - 1, dateJson.Day, dateJson.Hour, dateJson.Minute, dateJson.Second);
            d = d.convertUTCTimeToLocalTime(d);
            var s = d.format("dd/mm/yyyy hh:nn");
            t.find("span").html(d.format("dd/mm/yyyy hh:nn"));
        });
    }

    $(function () {
        onTransactionsLoad();
    });
</script>
</asp:Content>

