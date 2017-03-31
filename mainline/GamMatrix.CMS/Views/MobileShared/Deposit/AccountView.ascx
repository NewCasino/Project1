<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script runat="server">
    public string LockCurrency;
    protected Finance.PaymentMethod Model { get { return this.ViewData["DepositModel"] as Finance.PaymentMethod; } }
    public bool IsAmountVisible = true;
    protected override void OnInit(EventArgs e)
    {
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
        }

        if (paymentId == "MoneyMatrix_IBanq")
        {
            LockCurrency = "USD";
        }

        base.OnInit(e);
    }
</script>
<div id="TopGuide" class="TopGuide"> 
    <div class="goBackLink">
        <a class="SideMenuLink BackButton BackDeposit" href="/Deposit" id="BackBTN">
            <span class="ActionArrow icon-arrow-left"> </span>
            <span class="ButtonIcon icon Hidden">&nbsp;</span>
            <span class="ButtonText"><%=this.GetMetadata("/Deposit/_PaymentMethodListV2_ascx.Back_Text") %></span>
        </a>
    </div>
    <div class="paymentInfo">
         <img class="Card I" src="<%= Model.GetImageUrl().SafeHtmlEncode() 
         %>" width="66" height="66" alt="<%= Model.GetTitleHtml().SafeHtmlEncode() 
         %>" />              
    </div>
    <script>
        $(function(){
            $("body").addClass("DepositPage StyleV2");
        });
    </script>
</div>
<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
                    {
                        ComponentId = "creditAccountID",
                        SelectorLabel = this.GetMetadata("/Deposit/_Account_aspx.GammingAccount_Label")
                    }); %>
<% Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel
                {
                    PaymentDetails = Model,
                    TransferType = TransType.Deposit,
                    IsDebitSource = false
                }); %>
<% Html.RenderPartial("/Components/BonusSelector", new BonusSelectorViewModel()); %>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        $(function () {
            var IsAmountVisible = <% = IsAmountVisible? "true" : "false"%>;
            var accountSelector = new GamingAccountSelector('#creditAccountIDSelector', true),
                bonusSelector = new BonusSelector();
            var	amountSelector;
            IsAmountVisible ?  amountSelector = new AmountSelector()  : $("#fldAmount").remove();

            accountSelector.evt.bind('bonus', function (data) {
                bonusSelector.update(data);
            });

            <% if (this.Model.VendorID != VendorID.EnterCash)
               {%>
            accountSelector.evt.bind('change', function (data) {
                amountSelector.update(data);
            });
            <% } %>
        <% if (LockCurrency != null && IsAmountVisible)
           { 
						%>
            amountSelector.lock('<%= LockCurrency.SafeJavascriptStringEncode()%>');<% 
         }
          
        %>
        });
        $(CMS.mobile360.Generic.input);
    </script>
</ui:MinifiedJavascriptControl>

