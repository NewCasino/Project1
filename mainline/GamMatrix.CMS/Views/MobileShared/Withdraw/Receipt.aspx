<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script language="C#" type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }
    
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
        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
        {
            return string.Format(this.GetMetadata(".DebitAccount_MoneyMatrix"));
        }

        return string.Format(this.GetMetadata(".DebitAccount"),
            this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetPrepareTransRequest().Record.DebitPayItemVendorID)));
    }

    private string GetCreditMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard( GetPrepareTransRequest().Record.CreditPayCardID);

        if (GetPaymentMethod().VendorID != VendorID.Bank)
        {
            if (GetPaymentMethod().VendorID == VendorID.Nets)
            {
                return string.Format(this.GetMetadata(".CreditCard"), this.GetMetadata(".YourBankAccount"));
            }
            else if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().UniqueName == "MoneyMatrix")
            {
                return string.Format(this.GetMetadata(".CreditCard_MoneyMatrix"), payCard.DisplayName);
            }
            else if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            {
                return string.Format(this.GetMetadata(".CreditCard"), GetPaymentMethod().GetTitleHtml());
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


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache" />
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
<meta http-equiv="expires" content="0" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box UserBox WithDrawBox CenterBox">
	<div class="BoxContent">
	    <% var paymentMethod = this.GetPaymentMethod();

	       if (paymentMethod.UniqueName.Equals("MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase) ||
	           paymentMethod.UniqueName.Equals("MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase) ||
	           paymentMethod.UniqueName.Equals("MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase))
	       {
	           Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 3, CurrentStep = 2 });
	       }
	       else
	       {
	           Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 });
	       }
        %>

        <%--------------------
            Cancelled Message
          ----------------------%>
        <% if( GetTransactionInfo().TransData.TransStatus == TransStatus.Cancelled )
           { %>
				<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, this.GetMetadata(".Cancelled_Message")) { IsHtml = true }); %>
        <% } %>

        <%--------------------
            Rollback Message
          ----------------------%>
        <% if( GetTransactionInfo().TransData.TransStatus == TransStatus.RollBack )
           { %>
				<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, this.GetMetadata(".Rollback_Message")) { IsHtml = true }); %>
        <% } %>

        <%--------------------
            Success Message
          ----------------------%>
        <% if( GetTransactionInfo().TransData.TransStatus == TransStatus.Success )
           { %>
				<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, this.GetMetadata(".Success_Message")) { IsHtml = true }); %>
        <% } %>

        <%--------------------
            Pending Message
          ----------------------%>
        <% if( GetTransactionInfo().TransData.TransStatus == TransStatus.Pending ||
               GetTransactionInfo().TransData.TransStatus == TransStatus.PendingNotification )
           { %>
				<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Pending_Message")) { IsHtml = true }); %>
        <% } %>

		<%------------------------
			The receipt info
        ------------------------%>
		<div class="MenuList L DetailContainer">
			<ol class="DetailPairs ProfileList">

                <% if( GetTransactionInfo().TransID > 0 ) { %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></span> <span class="DetailValue"><%= GetTransactionInfo().TransID %></span>
					</div>
				</li>
                <% } %>

				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= GetDebitMessage().SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(GetPrepareTransRequest().Record.DebitCurrency
																										 , GetPrepareTransRequest().Record.DebitAmount) %></span>
					</div>
				</li>
				<% if (GetPrepareTransRequest().FeeList != null && GetPrepareTransRequest().FeeList.Count > 0)
				   {
					   foreach (TransFeeRec fee in GetPrepareTransRequest().FeeList)
					   {%>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency
																												, fee.RealAmount) %></span>
					</div>
				</li>
				<% }} %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= GetCreditMessage().SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(GetPrepareTransRequest().Record.CreditRealCurrency
																										  , GetPrepareTransRequest().Record.CreditRealAmount)%></span>
					</div>
				</li>
			</ol>
		</div>
    </div>
</div>

    <script type="text/javascript">
        (function ($) {
            var cmsViews = CMS.views;

            cmsViews.BackBtn = function (selector) {
                $(selector).click(function () {
                    window.location = '/Withdraw';
                    return false;
                });
            }
        })(jQuery);

    </script>
</asp:Content>