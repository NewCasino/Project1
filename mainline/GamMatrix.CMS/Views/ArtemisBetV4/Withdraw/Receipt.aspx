<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<script language="C#" type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }

    private GetTransInfoRequest GetTransactionInfo()
    {
        return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
    }

    private PrepareTransRequest GetPrepareTransRequest()
    {
        return this.ViewData["prepareTransRequest"] as PrepareTransRequest;
    }

    private ProcessTransRequest GetProcessTransRequest()
    {
        return this.ViewData["processTransRequest"] as ProcessTransRequest;
    }

    private string GetDebitMessage()
    {
        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
        {
            return string.Format(this.GetMetadata(".DebitAccount_MoneyMatrix"));
        }

        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetPrepareTransRequest().Record.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetCreditMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard( GetPrepareTransRequest().Record.CreditPayCardID);
        string creditMsgName = "";
        if (GetPaymentMethod().VendorID != VendorID.Bank)
        {
            if (GetPaymentMethod().VendorID == VendorID.Nets)
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard"), this.GetMetadata(".YourBankAccount"));
            }
            else if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().UniqueName == "MoneyMatrix")
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard_MoneyMatrix"), payCard.DisplayName);
            }
            else if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard"), GetPaymentMethod().GetTitleHtml());
            }
            else
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard")
                , string.Format("{0}, {1}", GetPaymentMethod().GetTitleHtml(), payCard.DisplayName)
                );
            }

            return string.IsNullOrEmpty(creditMsgName) ? "" : creditMsgName.Replace(", Dummy card", "");
        }
        else
        {
            creditMsgName = string.Format(this.GetMetadata(".CreditCard")
                , string.Format("{0}, {1}", payCard.BankName, payCard.DisplayName)
                );
            return string.IsNullOrEmpty(creditMsgName) ? "" : creditMsgName.Replace(", Dummy card", "");
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
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                 <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/WithdrawPage/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/WithdrawPage/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="javascript:;" itemprop="url" title="<%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>">
                    <span itemprop="title"><%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">

<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>
<div id="receipt_step">
<%if (GetProcessTransRequest() != null && GetProcessTransRequest().WarnKYCRequired) { %>
    <center>
        <%: Html.WarningMessage(this.GetMetadata(".WithdrawalLimit_Message"), true)%>
        <br />
   </center>
<%} %>

<%--------------------
    Cancelled Message
  ----------------------%>
<% if( GetTransactionInfo().TransData.TransStatus == TransStatus.Cancelled )
   { %>
   <center>
        <%: Html.WarningMessage( this.GetMetadata(".Cancelled_Message") ) %>
        <br />
   </center>
<% } %>

<%--------------------
    Rollback Message
  ----------------------%>
<% if( GetTransactionInfo().TransData.TransStatus == TransStatus.RollBack )
   { %>
   <center>
        <%: Html.WarningMessage( this.GetMetadata(".Rollback_Message") ) %>
        <br />
   </center>
<% } %>

<%--------------------
    Success Message
  ----------------------%>
<% if( GetTransactionInfo().TransData.TransStatus == TransStatus.Success )
   { %>
   <center>
        <%: Html.SuccessMessage(this.GetMetadata(".Success_Message"))%>
        <br />
   </center>
<% } %>

<%--------------------
    Pending Message
  ----------------------%>
<% if( GetTransactionInfo().TransData.TransStatus == TransStatus.Pending ||
       GetTransactionInfo().TransData.TransStatus == TransStatus.PendingNotification )
   { %>
   <center>
        <%: Html.InformationMessage(this.GetMetadata(".Pending_Message"), false, new { @id = "receiptPendingMessage" })%>
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
        <td class="value"><%= MoneyHelper.FormatWithCurrency(GetPrepareTransRequest().Record.CreditRealCurrency
            , GetPrepareTransRequest().Record.CreditRealAmount)%></td>
    </tr>

    <% if (GetPrepareTransRequest().FeeList != null && GetPrepareTransRequest().FeeList.Count > 0)
       {
           foreach (TransFeeRec fee in GetPrepareTransRequest().FeeList)
           {%>
    <tr class="receipt_row_fee">
        <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency
                              , fee.RealAmount) %></td>
    </tr>
    <%     }
       }%>   
    
    <tr class="receipt_row_debit">
        <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(GetPrepareTransRequest().Record.DebitCurrency
                              , GetPrepareTransRequest().Record.DebitAmount) %></td>
    </tr> 

    <tr class="receipt_row_transactionid">
        <td class="name"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></td>
        <td class="value"><%= GetTransactionInfo().TransID %></td>
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
    jQuery('body').addClass('WithdrawPage').addClass('WithdrawPageReceipt');

    try {
        if (parent.location.href != self.location.href) {
            if ($(".ConfirmationBox.simplemodal-container", parent.document.body).length > 0) {
                $(".ConfirmationBox.simplemodal-container", parent.document.body).hide();
                parent.location.href = self.location.href;
            }
        }
    } catch (err) { console.log(err); }
    </script>

</asp:Content>


