<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetCreditMessage()
    {
        UserAccessor ua = UserAccessor.CreateInstance <UserAccessor>();
        cmUser user = ua.GetByID(this.Model.Record.ContraUserID);
        return string.Format(this.GetMetadata(".CreditAccount")
            , string.Format("{0} {1}({2})", user.FirstName, user.Surname, user.Username)
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

    <tr>
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.CreditRealCurrency
                              , this.Model.Record.CreditRealAmount) %></td>
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

</table>

<% using (Html.BeginRouteForm("BuddyTransfer", new { @action = "Confirm",  @sid = this.Model.Record.Sid }, FormMethod.Post, new { @method="post", @target = "_self" }))
   { %>
<center>
    <br />
    <% Html.RenderPartial("/Components/ForfeitBonusWarning", this.ViewData.Merge(new { @VendorID = this.Model.Record.DebitPayItemVendorID, @DebitAmount = this.Model.Record.DebitRealAmount })); %>
    <br />
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousBuddyTransferStep(); return false;", @type="button" })%>
    <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "submit", @onclick = "$(this).toggleLoadingSpin(true);" })%>
    
</center>

<% } %>