<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% 
    if (Profile.IsAuthenticated && this.Model.WarnAboutWithdrawRestriction )
    {
        VendorID vendorID = (VendorID)this.ViewData["VendorID"];
        var accounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID);
        var account = accounts.FirstOrDefault(a => a.ID == this.Model.Record.CreditAccountID);
        if (account != null )
        {
            string accountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name"
                , account.Record.VendorID)
                );
            string msg = this.GetMetadata(".Message").Replace( "$ACCOUNT_NAME$", accountName);
            %>
                <%: Html.WarningMessage( msg ) %>
            <%
        }
    }
%>