<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }

    // To be deposited into {0} account
    private string GetCreditMessage()
    {
        return this.GetMetadataEx(".Credit_Account");
    }

    // To be debited from {0}
    private string GetDebitMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.DebitPayCardID);

        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().UniqueName == "MoneyMatrix")
            return this.GetMetadataEx(".Debit_Card",   payCard.DisplayName).SafeHtmlEncode();

        if( GetPaymentMethod().VendorID != VendorID.PaymentTrust )
            return this.GetMetadataEx(".Debit_Account", GetPaymentMethod().GetTitleHtml()).HtmlEncodeSpecialCharactors();

        if( payCard != null )
            return this.GetMetadataEx(".Debit_Card", payCard.DisplayNumber).SafeHtmlEncode();

        return string.Empty;
    }

    private VendorID[] ThreeStepsVendors = new VendorID[]
    {
        VendorID.Trustly,
        VendorID.IPG,
        VendorID.APX,
        VendorID.GCE,
        VendorID.PugglePay
    };

    private bool IsThreeSteps()
    {
        var paymentMethod = this.GetPaymentMethod();

        if (ThreeStepsVendors.Contains(paymentMethod.VendorID))
            return true;

        if (paymentMethod.UniqueName == "EnterCash_OnlineBank" ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PayKwik", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PaySafeCard", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_Zimpler", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_OchaPay", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_EPro_CashLib", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.StartsWith("MoneyMatrix_Adyen_", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.StartsWith("MoneyMatrix_EnterPays_", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.StartsWith("MoneyMatrix_GPaySafe_", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.StartsWith("MoneyMatrix_PaySera_", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_AstroPayCard", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_BanContact", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_Eps", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_Ideal", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_MultiBanco", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_MyBank", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_PaySafeCard", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_SafetyPay", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PPro_TrustPay", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_EcoPayz", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase))
        {
            return true;
        }

        if (paymentMethod.UniqueName == "EnterCash_WyWallet" && Settings.MobileV2.IsV2DepositProcessEnabled)
            return true;

        return false;
    }

    protected int TotalSteps;
    protected int CurrentSteps;
    protected override void OnInit(EventArgs e)
    {
        if (IsThreeSteps())
        {
            TotalSteps = 3;
            CurrentSteps = 1;
        }
        else
        {
            TotalSteps = 4;
            CurrentSteps = 2;
        }
        base.OnInit(e);
    }

    private string GetConfirmationMetadataPath()
    {
        var result = ".Confirmation_Notes";

        if (GetPaymentMethod().VendorID== VendorID.MoneyMatrix)
        {
            result = ".Confirmation_Notes_MoneyMatrix";
        }

        if (GetPaymentMethod().UniqueName == "MoneyMatrix_PayKwik")
        {
            result = ".Confirmation_Notes_PayKwik";
        }

        return result;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = TotalSteps, CurrentStep = CurrentSteps }); %>
        <form action="<%= this.Url.RouteUrl("Deposit", new { @action = "Confirm", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid }).SafeHtmlEncode() %>" method="post" id="formPrepareNeteller">
            
            <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
 <%} %>
      

            <%------------------------
                The confirmation info
                ------------------------%>
			<div class="MenuList L DetailContainer">
				<ol class="DetailPairs ProfileList">
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= GetCreditMessage() %></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(this.Model.Record.CreditRealCurrency, this.Model.Record.CreditRealAmount)%></span>
						</div>
					</li>
					<%
						if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
						{
							foreach (var fee in this.Model.FeeList)
							{
					%>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount)%></span>
						</div>
					</li>
					<%
							}
						}
					%>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= GetDebitMessage() %></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitRealCurrency, this.Model.Record.DebitRealAmount) %></span>
						</div>
					</li>
				</ol>
			</div>
            
			<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(GetConfirmationMetadataPath()))); %>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { BackButtonEnabled = !IsThreeSteps() }); %>
        </form>
    </div>
</div>
<script type="text/javascript">
	$(CMS.mobile360.Generic.init);
</script>
</asp:Content>

