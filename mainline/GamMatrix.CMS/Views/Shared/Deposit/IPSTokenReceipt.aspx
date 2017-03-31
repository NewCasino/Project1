<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>
<script language="C#" type="text/C#" runat="server">
    private GetTransInfoRequest GetTransactionInfo()
    {
        return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
    }

    private IPSTokenDepositNoAmountRequest GetIPSTokenDepositNoAmountRequest()
    {
        return this.ViewData["requestIPSTokenDepositNoAmount"] as IPSTokenDepositNoAmountRequest;
    }

    private AccountData GetCreditAccount()
    {
        return this.ViewData["creditAccount"] as AccountData;
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".Receipt_Credit")
            , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetCreditAccount().Record.VendorID.ToString()))
            );
    }

    private string GetDebitMessage()
    {        

        return string.Empty;
    }

    private string GetTranJson()
    {
        return string.Format(CultureInfo.InvariantCulture, "{{ 'CreditCurrency':'{0}', 'CreditAmount':{1:F2}, 'TransactionID':'{2:D}' }}"
            , GetIPSTokenDepositNoAmountRequest().ResponeCurrency
            , GetIPSTokenDepositNoAmountRequest().ResponeAmount
            , GetIPSTokenDepositNoAmountRequest().Sid
            );
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache" />
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
<meta http-equiv="expires" content="0" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnDeposit">

<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<div id="receipt_step">
<center>
    <br />
    <%: Html.SuccessMessage( this.GetMetadata(".Success_Message") ) %>
    <br />
    
    <%: Html.InformationMessage(this.GetMetadata(".Information_Message"), false, new { @id = "receiptInformationMessage" })%>
    <br />

  <%------------------------
    The receipt table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table receipt_table"> 
    <tr class="receipt_row_credit">
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode() %></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( GetIPSTokenDepositNoAmountRequest().ResponeCurrency
                              , GetIPSTokenDepositNoAmountRequest().ResponeAmount 
                              ) %></td>
    </tr>

    <tr class="receipt_row_transactionid">
        <td class="name"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></td>
        <td class="value"><%= GetTransactionInfo().TransID %></td>
    </tr>

</table>



    <br />
    <%  %>
    <center>
    <%: Html.Button(this.GetMetadata(".Button_Print"), new { @onclick = "window.print()", @type = "button", @class="PrintButton button" })%>
    <%: Html.Button( this.GetMetadata(".Button_Back")
    , new { @onclick = string.Format("self.location='{0}';", this.Url.RouteUrl( "Deposit", new { @action = "Index" }).SafeJavascriptStringEncode())
    , @type = "button", @class="BackButton button" }
    )%>
    </center>

</center>
</div>

</ui:Panel>

</div>

<script type="text/javascript">
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
    });
    $(function () {
        $(document).trigger("DEPOSIT_COMPLETED", <%= GetTranJson() %>);
    });
    <%=this.GetMetadata(".Receipt_Script").SafeJavascriptStringEncode()%>
</script>
<%  Html.RenderPartial("ReceiptBodyPlus", this.ViewData); %>
</asp:Content>

