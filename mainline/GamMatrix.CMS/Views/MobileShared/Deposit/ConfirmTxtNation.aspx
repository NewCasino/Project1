<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

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
        return this.GetMetadataEx(".Credit_Account"
            , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.CreditPayItemVendorID.ToString()))
            );
    }

    // To be debited from {0}
    private string GetDebitMessage()
    {
        return this.GetMetadataEx(".Debit_Account", GetPaymentMethod().GetTitleHtml()).HtmlEncodeSpecialCharactors();
    }

    private bool EnableBackButton
    {
        get
        {
            return true;
        }
    }
    private bool IsThreeSteps()
    {
        return false;
    }

    protected int TotalSteps;
    protected int CurrentSteps;
    protected override void OnInit(EventArgs e)
    {
        if (IsThreeSteps())
        {
            TotalSteps = 3;
            CurrentSteps = 2;
        }
        else
        {
            TotalSteps = 4;
            CurrentSteps = 3;
        }
        base.OnInit(e);
    }

    private string GetConfirmationMetadataPath()
    {
        var result = ".Confirmation_Notes";

        return result;
    }

    private long GetTransID()
    {
        if (ViewData["TransID"] == null)
            return long.MinValue;
        
        return (long)(ViewData["TransID"]);
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = TotalSteps, CurrentStep = CurrentSteps }); %>
        <form action="<%= this.Url.RouteUrl("Deposit", new { @action = "Confirm", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid }).SafeHtmlEncode() %>" method="post" id="formPrepareNeteller">
            
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

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { BackButtonEnabled = EnableBackButton }); %>
        </form>
    </div>
</div>
<div id="deposit-block-dialog" style="display: none">
    <h3><%=this.GetMetadata(".Block_Dialog_Title").SafeHtmlEncode() %></h3>
    <hr />
    <ul class="deposit-block-dialog-operations">
        <li><strong><%= this.GetMetadata(".Success").SafeHtmlEncode() %></strong> : <a href="/Deposit/ReceiptTxtNation?txtNationTransID=<%=GetTransID() %>" target="_top"><%= this.GetMetadata(".Success_Link_Text").SafeHtmlEncode()%></a> </li>
        <li><strong><%= this.GetMetadata(".Failure").SafeHtmlEncode()%></strong> : <a href="mailto:<%= this.GetMetadata("/Metadata/Settings.Email_SupportAddress").SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".Failure_Link_Text").SafeHtmlEncode()%></a> </li>
    </ul>
</div>
    <script type="text/javascript" src="/js/jquery/jquery.simplemodal.extension.js"></script>
    <script type="text/javascript" src="/js/jquery/jquery.simplemodal-1.4.1.js"></script>

<script type="text/javascript">
    $(CMS.mobile360.Generic.init);
    $(function () {
        var btnSubmit = $('button');
        var receiptUrl = "/Deposit/ReceiptTxtNation?txtNationTransID=<%=GetTransID() %>";
        var redirectUrl = "<%=ViewData["Url"] as string %>";
        btnSubmit.bind("click", function (e) {
            window.redirectToReceiptPage = function (url) {
                if (url.indexOf('Error') > -1) {
                    setTimeout(function () {
                        document.location.href = '<%= this.Url.RouteUrl("Deposit", new { @action = "Error" }).SafeJavascriptStringEncode() %>';
                    }, 1000);
                } else {
                    setTimeout(function () {
                        document.location.href = receiptUrl;
                    }, 1000);
                }

                return '1';
            }

            window.txtNationPopup = window.open(redirectUrl, '_blank');

            try
            {
            
                //show pop-up
                $('#deposit-block-dialog').modalex(400, 150, false);
                $('#deposit-block-dialog').parents("#simplemodal-container").addClass("deposit-block-dialog-container");
            } catch (e)
            {
                if (console && console.log)
                    console.log(e);
            }

            return false;
        });
    });
</script>
</asp:content>

