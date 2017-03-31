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
    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
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
<div class="MenuList L DetailContainer">
					<ol class="DetailPairs ProfileList">
						<li>
							<div class="ProfileDetail">
								<span class="DetailName"><%= GetDebitMessage().SafeHtmlEncode()%></span> 
								<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitRealCurrency
    , this.Model.Record.DebitRealAmount) %></span>
							</div>
						</li>
<li>
							<div class="ProfileDetail">
								<span class="DetailName"><%= GetCreditMessage().SafeHtmlEncode()%></span> 
								<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.CreditRealCurrency
    , this.Model.Record.CreditRealAmount) %></span>
							</div>
						</li>
<% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
{
    foreach (var fee in this.Model.FeeList)
    {
    %>
    <li>
							<div class="ProfileDetail">
								<span class="DetailName"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></span> 
								<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount)%></span>
							</div>
						</li>
<%      }
} %>
</ol>
    </div>
<% using (Html.BeginRouteForm("BuddyTransfer", new { @action = "Confirm", @sid = this.Model.Record.Sid }, FormMethod.Post, new { @method = "post", @target = "_self" }))
{ %>     
    <div class="ForfeitBonusWarning">
        <% Html.RenderPartial("/Components/ForfeitBonusWarning", new GamMatrix.CMS.Models.MobileShared.Components.ForfeitBonusWarningViewModel(this.Model.Record.DebitPayItemVendorID, this.Model.Record.DebitRealAmount)); %> 
    </div>
    <div class="BuddyTransferButtons">
        <button type="button" class="Button RegLink DepLink BackLink" id="btnBuddyTransferBack" onclick = "returnPreviousBuddyTransferStep(); return false;">
            <span class="ButtonText"><%= this.GetMetadata(".Button_Back").SafeHtmlEncode()%></span>
        </button>     
        <button type="submit" class="Button RegLink DepLink NextStepLink" id="btnBuddyTransferConfirm">
            <span class="ButtonText"><%= this.GetMetadata(".Button_Confirm").SafeHtmlEncode()%></span>
        </button>   
    </div>     
<% } %>