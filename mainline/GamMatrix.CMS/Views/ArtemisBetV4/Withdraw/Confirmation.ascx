<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }
    
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetCreditMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.CreditPayCardID);

        if (GetPaymentMethod().VendorID != VendorID.Bank)
        {
            if (GetPaymentMethod().VendorID == VendorID.Ukash)
            {
                return string.Format(this.GetMetadata(".CreditCard")
                    , GetPaymentMethod().GetTitleHtml()
                    );
            }
            else
            {
                return string.Format(this.GetMetadata(".CreditCard")
                    , string.Format("{0}, {1}", GetPaymentMethod().GetTitleHtml(), payCard.DisplayName)
                    );
            }
        }
        else
        {
            return string.Format(this.GetMetadata(".CreditCard")
                    , string.Format("{0}, {1}", payCard.BankName, payCard.DisplayName)
                    );
        }
    }

</script>

<%------------------------
    The confirmation table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table"> 
    
    <tr class="confirmation_row_debit">
        <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitCurrency
                              , this.Model.Record.DebitAmount) %></td>
    </tr>

    <% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
       {
           foreach (TransFeeRec fee in this.Model.FeeList)
           {%>
    <tr class="confirmation_row_fee">
        <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency
                              , fee.RealAmount) %></td>
    </tr>
    <%     }
       }%>

    <tr class="confirmation_row_credit">
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.CreditRealCurrency
                              , this.Model.Record.CreditRealAmount) %></td>
    </tr>

</table>

<% using (Html.BeginRouteForm("Withdraw", new { @action = "Confirm", @paymentMethodName = GetPaymentMethod().UniqueName,  @sid = this.Model.Record.Sid }, FormMethod.Post, new { @method="post", @target = "_self" }))
   { %>

<div class="Container Box ConfirmBTNBox" id="ConfirmBTNBox">

    <% Html.RenderPartial("/Components/ForfeitBonusWarning", this.ViewData.Merge(new { @VendorID = this.Model.Record.DebitPayItemVendorID, @DebitAmount = this.Model.Record.DebitRealAmount })); %>

    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousWithdrawStep(); return false;", @type="button" })%>
    <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "submit", @onclick = "$(this).toggleLoadingSpin(true);" })%>
    
</div>

<% } %>