<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".CreditAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.CreditPayItemVendorID.ToString()))
           );
    }
</script>


<%------------------------
    The confirmation table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table"> 
    
    <tr>
        <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitRealCurrency
                              , this.Model.Record.DebitRealAmount) %></td>
    </tr>

    <% if( this.Model.FeeList != null && this.Model.FeeList.Count > 0 )
       {
           foreach (var fee in this.Model.FeeList)
           {%>
                <tr class="confirmation_row_fee">
                    <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
                    <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount)%></td>
                </tr>
    <%      }           
       } %>

    <tr>
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.CreditRealCurrency
                              , this.Model.Record.CreditRealAmount) %></td>
    </tr>

</table>


<center>
    <br />
    <% Html.RenderPartial("/Components/ForfeitBonusWarning", this.ViewData.Merge(new { @VendorID = this.Model.Record.DebitPayItemVendorID, @DebitAmount = this.Model.Record.DebitRealAmount })); %>
    <br />
    <% Html.RenderPartial("/Components/WarnAboutWithdrawRestriction", this.Model); %>
    <br />
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousTransferStep(); return false;", @type="button", @class="BackButton button" })%>
    <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "submit", @class="ConfirmButton button", @onclick = string.Format("showTransferReceipt('{0}'); return false;", this.Model.Record.Sid.SafeJavascriptStringEncode()) })%>
    
</center>

