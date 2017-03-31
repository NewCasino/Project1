<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script language="C#" type="text/C#" runat="server">    
    private AccountData GetCreditAccount()
    {
        return this.ViewData["creditAccount"] as AccountData;
    }

    private GetTransInfoRequest GetTransactionInfo()
    {
        return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".Receipt_Credit")
            , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetCreditAccount().Record.VendorID.ToString()))
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
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 4 }); %>
        <h2 class="SubHeading"><%= this.GetMetadata(".Receipt").SafeHtmlEncode()%></h2>
		<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, this.GetMetadata(".Success_Message"))); %>

        <%: Html.InformationMessage(this.GetMetadata(".Information_Message"), false, new { @id = "receiptInformationMessage" })%>

        <div class="MenuList L DetailContainer">
			<ol class="DetailPairs ProfileList">
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></span> <span class="DetailValue"><%= GetTransactionInfo().TransID %></span>
					</div>
				</li>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= GetCreditMessage().SafeHtmlEncode() %></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( GetTransactionInfo().PostingData[1].Record.Currency
																															  , GetTransactionInfo().PostingData[1].Record.Amount 
																															  ) %></span>
					</div>
				</li>				
			</ol>
		</div>
    </div>
</div>
<script type="text/javascript">
    $(CMS.mobile360.Generic.init);
</script>
</asp:Content>

