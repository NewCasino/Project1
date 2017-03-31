<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% 
    if (Profile.IsAuthenticated)
    {
        VendorID vendorID = (VendorID)this.ViewData["VendorID"];
        decimal debitAmount = (decimal)this.ViewData["DebitAmount"];
        var accounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID, true);
        var account = accounts.FirstOrDefault(a => a.Record.VendorID == vendorID);
        if (account != null && account.IsBalanceAvailable && debitAmount > account.MaxWithdrawWithoutBonusLossAmount)
        {
            string accountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name"
                , vendorID.ToString())
                );
            string msg = string.Format( this.GetMetadata(".Message"), accountName);
            %>
                <%: Html.WarningMessage( msg ) %>
            <%
        }
    }
%>