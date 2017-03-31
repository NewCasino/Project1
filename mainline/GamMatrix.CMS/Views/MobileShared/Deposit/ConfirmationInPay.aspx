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

    private InPayBank GetInPayBank()
    {
        return this.ViewData["inPayBank"] as InPayBank;
    }

    private string GetInPayApiResponseXml()
    {
        return this.ViewData["inPayApiResponseXml"].ToString();
    }

    private bool IsThirdParty;

    private string Currency;
    private string Amount;
    private string Reference;

    private string BankUrl;

    private SortedList<string, string> BeneficiaryAccounts;

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        XDocument doc = XDocument.Parse(GetInPayApiResponseXml());

        //invoice -> is-third-party
        IsThirdParty = doc.Root.Element("invoice").GetElementValue("is-third-party", false);

        // invoice -> transfer-currency
        Currency = doc.Root.Element("invoice").GetElementValue("transfer-currency");

        // invoice -> transfer-amount
        Amount = doc.Root.Element("invoice").GetElementValue("transfer-amount");

        // invoice -> reference
        Reference = doc.Root.Element("invoice").GetElementValue("reference");

        if (!IsThirdParty)
        {
            //bank transfer
            // instructions -> bank -> url
            BankUrl = doc.Root.Element("bank").GetElementValue("url");

            BeneficiaryAccounts = new SortedList<string, string>();

            // detect domestic v.s. internaltional transfer by user's profile country
            string countryCode = doc.Root.Element("bank").GetElementValue("country");
            bool isDomestic = true; //  string.Equals(profile.UserCountry, countryCode, StringComparison.InvariantCultureIgnoreCase);

            // bank -> payment-instructions -> account-details -> fields
            var fields = doc.Root.Element("bank").Element("payment-instructions").Element("account-details").Element("fields").Elements("field");
            foreach (XElement field in fields)
            {
                // exclude the necessary field
                string type = field.GetElementValue("transfer-route");
                if (!string.Equals(type, "both", StringComparison.InvariantCultureIgnoreCase))
                {
                    if (isDomestic && !string.Equals(type, "domestic", StringComparison.InvariantCultureIgnoreCase))
                        continue;

                    if (!isDomestic && !string.Equals(type, "foreign", StringComparison.InvariantCultureIgnoreCase))
                        continue;
                }

                var labelName = field.GetElementValue("label-value");
                var labelValue = field.GetElementValue("value");
                BeneficiaryAccounts.Add(labelName, labelValue);
            }

        }
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>
        <form action="<%= this.Url.RouteUrl("Deposit", new { @action = "InPayFormPost", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid }).SafeHtmlEncode() %>" method="post" id="formPrepareNeteller">
            
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

			<%--<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Confirmation_Notes"))); %>--%>

            <div class="InfoStatus StatusContainer">
	            <div class="StatusBackground">
		            <div class="StatusIcon">Status</div>
		            <div class="StatusMessage">
<% if (IsThirdParty)
   { %>
<p>
    <%= this.GetMetadataEx(".RedirectionForm_Step1", GetInPayBank().Name) %>
</p>
<% } %>
<% else %>
<% { %>
<%: Html.H3(this.GetMetadata(".Instructions_Title")) %>
<br />
<p>
    <%= this.GetMetadataEx(".Instructions_Step1", BankUrl) %>
</p>
<p>
    <%= this.GetMetadataEx(".Instructions_Step2", Currency, Amount) %>
</p>
<br />
<% foreach (var item in BeneficiaryAccounts)
   { %>
<p><%=item.Key %>: <%=item.Value %></p>
<% } %>
<p>
    <%=this.GetMetadataEx(".Instructions_Reference") %>:<%=Reference %>
</p>
<% } %>
<br />
<p>
    <%=this.GetMetadata(".Bank_Transfer_Prompt") %>
</p>

		            </div>
	            </div>
            </div>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { NextButtonEnabled = true, IsFormSection = false, NextUrl = BankUrl }); %>
        </form>
    </div>
</div>
<script type="text/javascript">
    $(CMS.mobile360.Generic.init);
</script>
</asp:content>

