<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private   bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }

    private InPayBank GetInPayBank()
    {
        return this.ViewData["inPayBank"] as InPayBank;
    }

    private string GetInPayApiResponseXml()
    {
        return this.ViewData["inPayApiResponseXml"].ToString();
    }

    // To be deposited into {0} account
    private string GetCreditMessage()
    {
        return this.GetMetadataEx(".Credit_Account"
            , this.GetMetadataEx("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.CreditPayItemVendorID.ToString())
            );
    }

    // To be debited from {0}
    private string GetDebitMessage()
    {
        if (GetPaymentMethod().VendorID != VendorID.PaymentTrust)
            return this.GetMetadataEx(".Debit_Account", GetPaymentMethod().GetTitleHtml()).HtmlEncodeSpecialCharactors();

        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.DebitPayCardID);
        if (payCard != null)
            return this.GetMetadataEx(".Debit_Card", payCard.DisplayNumber).SafeHtmlEncode();

        return string.Empty;
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

<%------------------------
    The confirmation table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">
    <tr class="confirmation_row_credit">
        <td class="name"><%= GetCreditMessage() %></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(this.Model.Record.CreditRealCurrency, this.Model.Record.CreditRealAmount)%></td>
    </tr>

    <% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
       {
           foreach (var fee in this.Model.FeeList)
           {%>
    <tr class="confirmation_row_fee">
        <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount)%></td>
    </tr>
    <%      }
       } %>


    <tr class="confirmation_row_debit">
        <td class="name"><%= GetDebitMessage() %></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitRealCurrency, this.Model.Record.DebitRealAmount) %></td>
    </tr>
</table>



<% using (Html.BeginRouteForm("Deposit", new { @action = "InPayFormPost", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid, @_sid = Profile.SessionID }, FormMethod.Post, new { @method = "post", @target = "_blank", @id = "formInPay" }))
   { %>
<!--
    <%=this.Model.Record.Sid %>
    <%=this.Reference %>
-->
<br />
<% if (IsThirdParty)
   { %>
<%: Html.H3(this.GetMetadataEx(".RedirectionForm_Title", GetInPayBank().Name)) %>
<br />
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
<br />
<div>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousDepositStep(); return false;", @type="button" })%>
    <% if (IsThirdParty)
       { %>
    <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type="submit", @onclick="__onBtnDepositConfirmClicked();", @id="btnDepositConfirm" })%>
    <% } %>
    <% else %>
    <% { %>
    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @type="submit", @onclick="__onBtnDepositContinueClicked();", @id="btnDepositConfirm" })%>
    <% } %>
</div>

<% } %>

<div id="deposit-block-dialog" style="display:none">
    <h3><%= this.GetMetadata(".Block_Dialog_Title").SafeHtmlEncode() %></h3>
    <hr />

    <ul class="deposit-block-dialog-operations">
        <li>
            <strong><%= this.GetMetadata(".Success").SafeHtmlEncode() %></strong> : 
            <a href="<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = this.Model.Record.Sid, @paymentMethodName = GetPaymentMethod().UniqueName }).SafeHtmlEncode() %>" target="_top"><%= this.GetMetadata(".Success_Link_Text").SafeHtmlEncode()%></a>
        </li>
        <li>
            <strong><%= this.GetMetadata(".Failure").SafeHtmlEncode()%></strong> : 
            <a href="mailto:<%= this.GetMetadata("/Metadata/Settings.Email_SupportAddress").SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".Failure_Link_Text").SafeHtmlEncode()%></a>
        </li>
    </ul>
</div>


<script type="text/javascript">
    var paymentPopupEnable  = <%= SafeParseBoolString(Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnablePopup"), true)  ? ((Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnabledPopup_Vendors").Contains(GetPaymentMethod().UniqueName) || Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnabledPopup_Vendors").Contains(GetPaymentMethod().VendorID.ToString())) ? "true" : "false") : "false" %>;
    if (paymentPopupEnable) {
        $("#formInPay").attr("target", "ConfirmationIframe");
    }
    var hidePopupFrame = function () {
        $(".ConfirmationBox.simplemodal-container").hide();
    };
    //<![CDATA[
    function __onLinkRedirectClicked() {
        $('#formInPay').get(0).submit();
        return true;
    }

    var submitted = false;
    function __onBtnDepositConfirmClicked() {
        $('#deposit-block-dialog').modalex(400, 150, false);
        $('#deposit-block-dialog').parents("#simplemodal-container").addClass("deposit-block-dialog-container");
        if (paymentPopupEnable) {
            $(".ConfirmationBox.simplemodal-container").appendTo("body").show();
            $(".ConfirmationBox.simplemodal-container").click(function () {
                hidePopupFrame();
            });
        }
        return true;
         //????
        $('#formInPay').get(0).submit();
        return true;
        $('#btnDepositConfirm .button_Center').html('<%=this.GetMetadataEx(".Button_Verify").SafeJavascriptStringEncode() %>');
        if (!submitted) {
            $('#formInPay').get(0).submit();
            submitted = true;
        }
        else {
            var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = this.Model.Record.Sid, @paymentMethodName = GetPaymentMethod().UniqueName }).SafeJavascriptStringEncode() %>';
            window.location = url;
            return false;
        }
        return true;
    }

    function __onBtnDepositContinueClicked() {
        window.open('<%= BankUrl %>');
    }

    //]]>
</script>
