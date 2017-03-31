<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }

    private string GetDebitMessage()
    {
        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            return string.Format(this.GetMetadata(".DebitAccount_MoneyMatrix"));


        return string.Format(this.GetMetadata(".DebitAccount"),
            this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.DebitPayItemVendorID)));
    }

    private string GetCreditMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.CreditPayCardID);

        if (GetPaymentMethod().VendorID != VendorID.Bank)
        {
            if (GetPaymentMethod().VendorID == VendorID.APX)
            {
                return string.Format(this.GetMetadata(".CreditCard"),
                    string.Format("{0}, {1}", this.GetMetadata(".BankAccount"), payCard.DisplayName));
            }
            else if (GetPaymentMethod().VendorID == VendorID.Nets)
            {
                return string.Format(this.GetMetadata(".CreditCard"), this.GetMetadata(".YourBankAccount"));
            }
            else if(GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().UniqueName == "MoneyMatrix")
            {
                return string.Format(this.GetMetadata(".CreditCard"), string.Format("the card {0}", payCard.DisplayName));
            }
            else if(GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            {
                return string.Format(this.GetMetadata(".CreditCard"), GetPaymentMethod().GetTitleHtml());
            }
            else
            {
                return string.Format(this.GetMetadata(".CreditCard"),
                    string.Format("{0}, {1}", GetPaymentMethod().GetTitleHtml(), payCard.DisplayName));
            }
        }
        else
        {
            return string.Format(this.GetMetadata(".CreditCard"),
                string.Format("{0}, {1}", payCard.BankName, payCard.DisplayName));
        }
    }

    private VendorID[] ThreeStepsVendors = new VendorID[]
    {
        VendorID.Trustly,
        VendorID.IPG,
        VendorID.Nets,
    };

    private bool IsThreeSteps()
    {
        var paymentMethod = this.GetPaymentMethod();

        if (ThreeStepsVendors.Contains(paymentMethod.VendorID))
            return true;

        if (paymentMethod.UniqueName.Equals("MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase) ||
            paymentMethod.UniqueName.Equals("MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase))
        {
            return true;
        }

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
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box UserBox WithDrawBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = this.TotalSteps, CurrentStep = this.CurrentSteps }); %>
		<%------------------------
			The confirmation info
        ------------------------%>
		<div class="MenuList L DetailContainer">
			<ol class="DetailPairs ProfileList">
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= GetDebitMessage().SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitCurrency
																										 , this.Model.Record.DebitAmount) %></span>
					</div>
				</li>
				<% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
					{
						foreach (TransFeeRec fee in this.Model.FeeList)
						{%>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency
																												, fee.RealAmount)%></span>
					</div>
				</li>
				<% }} %>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= GetCreditMessage().SafeHtmlEncode()%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.CreditRealCurrency
																										  , this.Model.Record.CreditRealAmount) %></span>
					</div>
				</li>
			</ol>
		</div>

        <form action="<%= this.Url.RouteUrl("Withdraw", new { @action = "Confirm", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid }).SafeHtmlEncode() %>" method="post">
            
            <% Html.RenderPartial("/Components/ForfeitBonusWarning", new ForfeitBonusWarningViewModel(this.Model.Record.DebitPayItemVendorID, this.Model.Record.DebitRealAmount)); %>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { BackButtonEnabled = !IsThreeSteps() }); %>
		</form>

    </div>
</div>

<script type="text/javascript">
	$(CMS.mobile360.Generic.init);
</script>

</asp:Content>

