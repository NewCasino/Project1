<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script runat="server">
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
        if (ThreeStepsVendors.Contains(this.Model.VendorID))
            return true;

        if (this.Model.UniqueName == "EnterCash_OnlineBank" ||
            this.Model.UniqueName.Equals("MoneyMatrix_PayKwik", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PaySafeCard", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_Zimpler", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_OchaPay", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_EPro_CashLib", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.StartsWith("MoneyMatrix_Adyen_", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.StartsWith("MoneyMatrix_EnterPays_", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.StartsWith("MoneyMatrix_GPaySafe_", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.StartsWith("MoneyMatrix_PaySera_", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_AstroPayCard", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_BanContact", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_Eps", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_Ideal", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_MultiBanco", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_MyBank", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_PaySafeCard", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_SafetyPay", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PPro_TrustPay", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_EcoPayz", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase))
        {
            return true;
        }

        return false;
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }

    public string LockCurrency;
    public bool IsAmountVisible = true;
    protected int TotalSteps;
    protected string ActionUrl;
    protected string PartialViewPath;

    protected override void OnInit(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");

        var paymentId = Model.UniqueName;

        if (paymentId == "Envoy_FundSend")
            LockCurrency = "EUR";

        if (paymentId.Contains("ArtemisSMS") || paymentId.Contains("TurkeySMS"))
            LockCurrency = "TRY";

        if (paymentId == "TurkeyBankWire")
            LockCurrency = "TRY";

        if (paymentId == "TLNakit" || paymentId == "MoneyMatrix_TLNakit")
            LockCurrency = "TRY";
        if (Model.VendorID == VendorID.Envoy && !Model.UniqueName.Equals("Envoy_FundSend", StringComparison.InvariantCultureIgnoreCase))
            IsAmountVisible = false;

        if (paymentId == "MoneyMatrix_PayKwik")
        {
            LockCurrency = "EUR";
        }

        if (paymentId == "MoneyMatrix_PayKasa" ||
            paymentId == "MoneyMatrix_OtoPay" ||
            paymentId == "MoneyMatrix_GPaySafe_PayKasa" ||
            paymentId == "MoneyMatrix_GPaySafe_CashIxir" ||
            paymentId == "MoneyMatrix_GPaySafe_EPayCode" ||
            paymentId == "MoneyMatrix_GPaySafe_GsCash" ||
            paymentId == "MoneyMatrix_GPaySafe_Jeton" ||
            paymentId == "MoneyMatrix_EnterPays_PayKasa")
        {
            LockCurrency = "EUR";
            PartialViewPath = "MoneyMatrixPayKasaPartial";
        }

        if (paymentId == "MoneyMatrix_IBanq")
        {
            LockCurrency = "USD";
        }

        if (IsThreeSteps())
        {
            TotalSteps = 3;
        }
        else
        {
            TotalSteps = 4;
            ActionUrl = Url.RouteUrl("Deposit", new { action = "Prepare", paymentMethodName = Model.UniqueName });
        }
        base.OnInit(e);
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server"> 
	<div class="UserBox CenterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = TotalSteps, CurrentStep = 0 }); %>
			<%--<form action="<%= this.Url.RouteUrl("Deposit", new { action = "Prepare", paymentMethodName = Model.UniqueName }).SafeHtmlEncode() %>" method="post" id="formDepositAmount">--%>
            <form action="<%= ActionUrl.SafeHtmlEncode() %>" method="post" id="formDepositAmount">
                
				<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
                    {
                        ComponentId = "creditAccountID",
                        SelectorLabel = this.GetMetadata(".GammingAccount_Label")
                    }); %>
				
				<%
 
                    Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel
                            {
                                PaymentDetails = Model,
                                TransferType = TransType.Deposit,
                                IsDebitSource = false
                            });
             
                    %>

				<% Html.RenderPartial("/Components/BonusSelector", new BonusSelectorViewModel()); %>
                <% if (!string.IsNullOrEmpty(PartialViewPath))
                   {
                       Html.RenderPartial(PartialViewPath);
                   }
                %>
                <div id="Account_UserFlow_step1" style="display:none;"><% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { BackButtonEnabled = !IsThreeSteps() }); %></div>
			</form>
			<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
				<script type="text/javascript">
				    $(function () {
				        window.onload = function(){
				            $("#Account_UserFlow_step1").css("display","block");
				        }
				        var IsAmountVisible = <% = IsAmountVisible? "true" : "false"%>;
				        var accountSelector = new GamingAccountSelector('#creditAccountIDSelector', true),
							bonusSelector = new BonusSelector();				        
				        var amountSelector;
				        IsAmountVisible ?  amountSelector = new AmountSelector()  : $("#fldAmount").remove();

				        accountSelector.evt.bind('bonus', function (data) {
				            bonusSelector.update(data);
				        });

				        accountSelector.evt.bind('change', function (data) {
				            amountSelector.update(data);
				        });

						<% if (LockCurrency != null && IsAmountVisible)
         { 
						%>
				        amountSelector.lock('<%= LockCurrency.SafeJavascriptStringEncode()%>');
				        <% 
                            }
						%>

				        window.amountSelector = amountSelector;
				        if (window.amountSelectorInitialized) {
				            window.amountSelectorInitialized();
				        }
				    });

				    $(CMS.mobile360.Generic.input);
				</script>
			</ui:MinifiedJavascriptControl>
		</div>
	</div>
</asp:content>
