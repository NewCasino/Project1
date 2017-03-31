<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %> 

<% using (Html.BeginRouteForm("BuddyTransfer"
       , new { @action = "PrepareTransaction" }
       , FormMethod.Post
       , new { @id = "formBuddyTransfer" }))
   { %>

            <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
 <%} %>

<ul class="FormList">
	<li class="FormItem" id="fldFriendUsername" runat="server">
            <%------------------------------------------
                 Friend's Username
            -------------------------------------------%> 
               <label class="FormLabel" for="friendUsername"><%= this.GetMetadata(".FriendUsername_Label").SafeHtmlEncode()%></label>
  
                    <%: Html.TextBox("friendUsername", this.Model.Username, new { @class =  "FormInput",@readonly = "readonly" })%>
	      	<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
     </li>
    
	<li class="FormItem" id="fldFriendFullname" runat="server">
            <%------------------------------------------
                 Friend's Full Name
            -------------------------------------------%> 
                <label class="FormLabel" for="friendFullname"><%= this.GetMetadata(".FriendFullname_Label").SafeHtmlEncode()%> </label>
   
                    <%: Html.TextBox("friendFullname", string.Format("{0} {1}", this.Model.FirstName, this.Model.Surname), new {@class =  "FormInput", @readonly = "readonly" })%>
	   

            <%: Html.Hidden("creditUserID", this.Model.ID.ToString()) %>
        <span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
     </li></ul>
<table cellpadding="0" cellspacing="0" border="0" width="100%">
    <tr>
        <td valign="top">
            <%------------------------------------------
                 Debit Gamming Accounts
            -------------------------------------------%> 
            <% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
                    {
                        ComponentId = "debitGammingAccountID",
                        SelectorLabel = this.GetMetadata(".DebitGammingAccount_Label"),
                        EnableDisplayAmount = true,
                        DisableJsCode = true
                    }); %> 
        </td>
        <td></td>
        <td valign="top">
            <%------------------------------------------
                 Credit Gamming Accounts
            -------------------------------------------%> 
            <% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
                    {
                        ComponentId = "creditGammingAccountID",
                        SelectorLabel = this.GetMetadata(".CreditGammingAccount_Label"),
                        UserId = this.Model.ID,
                        DisableJsCode = true
                    }); %>
        </td>
    </tr> 
</table>
    <% Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel
                    {
                        TransferType = TransType.User2User
                    }); %>

<center>    
    <button type="button" class="Button RegLink DepLink BackLink" id="btnBuddyTransferBack" onclick = "returnPreviousBuddyTransferStep(); return false;">
        <span class="ButtonText"><%= this.GetMetadata(".Button_Back").SafeHtmlEncode()%></span>
    </button>     
    <button type="submit" class="Button RegLink DepLink NextStepLink" id="btnBuddyTransferMoney">
        <span class="ButtonText"><%= this.GetMetadata(".Button_Transfer").SafeHtmlEncode()%></span>
    </button>  
</center>
<% } %>
<script> 
    InitPrepare(); 
</script>
