<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<script language="C#" type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }

    private LocalBankPaymentRequest GetLocalBankPaymentRequest()
    {
        return this.ViewData["localBankPaymentRequest"] as LocalBankPaymentRequest;
    }

    private string GetDebitMessage()
    {
        AccountData account = GamMatrixClient.GetUserGammingAccounts(Profile.UserID).FirstOrDefault(a => a.ID == GetLocalBankPaymentRequest().Payment.AccountID);        
            
        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", account.Record.VendorID))
           );
    }

    private string GetCreditMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard(GetLocalBankPaymentRequest().Payment.PaycardID);

        if (GetPaymentMethod().VendorID != VendorID.Bank)
        {
            return string.Format(this.GetMetadata(".CreditCard")
                , string.Format("{0}, {1}", GetPaymentMethod().GetTitleHtml(), payCard.DisplayName)
                );
        }
        else
        {
            return string.Format(this.GetMetadata(".CreditCard")
                , string.Format("{0}, {1}", payCard.BankName, payCard.DisplayName)
                );
        }
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache" />
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
<meta http-equiv="expires" content="0" />
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">

<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>
<div id="receipt_step">
<%--------------------
    Cancelled Message
  ----------------------%>
<% if(GetLocalBankPaymentRequest().Payment.TransStatus == TransStatus.Cancelled )
   { %>
   <center>
        <%: Html.WarningMessage( this.GetMetadata(".Cancelled_Message") ) %>
        <br />
   </center>
<% } %>

<%--------------------
    Rollback Message
  ----------------------%>
<% if (GetLocalBankPaymentRequest().Payment.TransStatus == TransStatus.RollBack)
   { %>
   <center>
        <%: Html.WarningMessage( this.GetMetadata(".Rollback_Message") ) %>
        <br />
   </center>
<% } %>

<%--------------------
    Success Message
  ----------------------%>
<% if (GetLocalBankPaymentRequest().Payment.TransStatus == TransStatus.Success)
   { %>
   <center>
        <%: Html.SuccessMessage(this.GetMetadata(".Success_Message"))%>
        <br />
   </center>
<% } %>

<%--------------------
    Pending Message
  ----------------------%>
<% if (GetLocalBankPaymentRequest().Payment.TransStatus == TransStatus.Pending ||
       GetLocalBankPaymentRequest().Payment.TransStatus == TransStatus.PendingNotification)
   { %>
   <center>
        <%: Html.InformationMessage(this.GetMetadata(".Pending_Message"), false, new { @id = "receiptPendingMessage" })%>
        <br />
   </center>
<% } %>

<%--------------------
    Setup Message
  ----------------------%>
<% if (GetLocalBankPaymentRequest().Payment.TransStatus == TransStatus.Setup)
   { %>
   <center>
        <%: Html.InformationMessage(this.GetMetadata(".Setup_Message"), false, new { @id = "receiptSetupMessage" })%>
        <br />
   </center>
<% } %>

<center>
  <%------------------------
    The receipt table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table"> 
    <tr class="receipt_row_credit">
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(GetLocalBankPaymentRequest().Payment.Currency
                                          , GetLocalBankPaymentRequest().Payment.Amount)%></td>
    </tr>
    
    <%--<tr class="receipt_row_debit">
        <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(GetLocalBankPaymentRequest().Payment.Currency
                                                            , GetLocalBankPaymentRequest().Payment.Amount)%></td>
    </tr> --%>

    <tr class="receipt_row_transactionid">
        <td class="name"><%= this.GetMetadata(".Reference_ID").SafeHtmlEncode()%></td>
        <td class="value"><%= GetLocalBankPaymentRequest().Payment.ID%></td>
    </tr>
</table>

</center>

</div>
</ui:Panel>
</div>

<script language="javascript" type="text/javascript">
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
    });
</script>
</asp:Content>

