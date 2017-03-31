<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
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
        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetProcessTransRequest().Record.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".CreditAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetProcessTransRequest().Record.CreditPayItemVendorID.ToString()))
           );
    }
</script>



<center>
    <%: Html.SuccessMessage( this.GetMetadata(".Success_Message") ) %>
</center>


<%------------------------
    The confirmation table
    ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table"> 
    <tr>
        <td class="name"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></td>
        <td class="value"><%= GetTransactionInfo().TransID.ToString() %></td>
    </tr>

    <tr>
        <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(GetProcessTransRequest().Record.DebitRealCurrency
                                                                , GetProcessTransRequest().Record.DebitRealAmount)%></td>
    </tr>

    <% if (GetTransactionInfo().FeeData != null)
       {
           foreach (TransFeeData fee in GetTransactionInfo().FeeData)
           {
               %>
    <tr class="receipt_row_fee">
        <td class="name"><%= this.GetMetadata(".Receipt_Fee")%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.Record.RealCurrency , fee.Record.RealAmount ) %></td>
    </tr>
    <%     }
       } %>

    <tr>
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(GetProcessTransRequest().Record.CreditRealCurrency
                                                                , GetProcessTransRequest().Record.CreditRealAmount)%></td>
    </tr>
</table>

<script type="text/javascript">
    $(function () {
        try {
            $(top.document).trigger('BALANCE_UPDATED');
        } catch (ex) { }
    });
</script>