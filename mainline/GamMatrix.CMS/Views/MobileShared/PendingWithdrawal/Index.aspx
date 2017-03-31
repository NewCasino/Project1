<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.TransInfoRec>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private string LISTHEADER_TRANSACTIONID, LISTHEADER_DESCRIPTION, LISTHEADER_DATE, LISTHEADER_ACCOUNT, LISTHEADER_AMOUNT, LISTHEADER_STATUS;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        LISTHEADER_TRANSACTIONID = this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode();
        LISTHEADER_DESCRIPTION = this.GetMetadata(".ListHeader_Description").SafeHtmlEncode();
        LISTHEADER_DATE = this.GetMetadata(".ListHeader_Date").SafeHtmlEncode();
        LISTHEADER_ACCOUNT = this.GetMetadata(".ListHeader_Account").SafeHtmlEncode();
        LISTHEADER_AMOUNT = this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode();
        LISTHEADER_STATUS = this.GetMetadata(".ListHeader_Status").SafeHtmlEncode();
    }
    
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
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box UserBox">
    <div class="BoxContent">

    <div class="Box">
    <div class="BoxContent">
		<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Message")) { IsHtml = true }); %>
   </div>
   </div>

    <ol class="CardList TransactionList">
    <%
        if (this.Model != null)
        {
            foreach (TransInfoRec trans in this.Model)
            {%>
        <li>
        <div class="CardHeader">
        <span class="HeaderLable"><%= LISTHEADER_TRANSACTIONID%></span><span class="HeaderValue"><%= trans.TransID.ToString()%></span>
        <span class="HeaderLable"><%= LISTHEADER_DATE%></span><span class="HeaderValue"><%= trans.TransCreated.ToString("dd/MM/yyyy HH:mm")%></span>
        </div>
        <table class="DetailTable Cols-4">
        <tr>
        <th><%= LISTHEADER_ACCOUNT%></th>
        <th><%= LISTHEADER_AMOUNT%></th>
        <th><%= LISTHEADER_DESCRIPTION%></th>
        <th><%= LISTHEADER_STATUS%></th>
        </tr>
        <tr>
        <td><%= GetAccountName(trans).SafeHtmlEncode()%></td>
        <td><%= MoneyHelper.FormatWithCurrency(trans.DebitRealCurrency, trans.DebitRealAmount)%></td>
        <td><%= trans.CreditPayItemName%></td>
        <td>
        <%= GetStatusHtml(trans)%>
        <% if (this.IsRollbackButtonVisible(trans))
           { %>
            <span>
            <button onclick="self.location='<%= this.Url.RouteUrl("PendingWithdrawal", new { @sid = trans.Sid, @action = "Rollback" }).SafeJavascriptStringEncode()%>';return false;" class="Button RollBack" type="button">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_Rollback").SafeHtmlEncode()%></strong>
			</button>   
            </span>
        <% } %>
        </td>
        </tr>
        </table>
        </li>
        <%}
        }
         %>
    </ol>
</div>
<script type="text/javascript">
    $(CMS.mobile360.Generic.init);
</script>
</asp:Content>