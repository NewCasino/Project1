<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="System.Linq" %>

<script language="C#" runat="server" type="text/C#">

    private SelectList GetCurrencyList()
    {
        
        List<string> currencies = new List<string> { "EUR", "GBP", "CAD", "USD", "NOK", "PLN", "SEK", "AUD" };
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .Where(c => currencies.Contains(c.ISO4217_Alpha) && this.Model.SupportedCurrencies.Exists(c.ISO4217_Alpha) )
                        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                        .ToList();
        string userCurrency = Profile.AsCustomProfile().UserCurrency;
        if (list.Exists(c => string.Equals(c.Key, userCurrency)))
            return new SelectList(list, "Key", "Value", userCurrency);
        else
            return new SelectList(list, "Key", "Value", "EUR");
    }

    private PayCardInfoRec GetPayCard()
    {
        if (string.Equals(SiteManager.Current.DistinctName, "ArtemisBet", StringComparison.InvariantCultureIgnoreCase))
            throw new Exception("Ukash payout is disallowed for ArtemisBet.");
        return GamMatrixClient.GetPayCards(VendorID.Ukash).First();
    }

</script>


<%---------------------------------------------------------------
Ukash
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        
        <%---------------------------------------------------------------
                Issue a new Card
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabIssue" Caption="<%$ Metadata:value(.Tab_IssuePayCard) %>">
            <form id="formIssueUkashPayCard" method="post" onsubmit="return false">

            <%---------------------------------------------------------------
                    Currency
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldCurrency" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.DropDownList("currency", GetCurrencyList(), new { @id="ddlIssueCardCurrency"  })%>
                </ControlPart>
            </ui:InputField>

            <br /><br />
            <%: Html.WarningMessage(this.GetMetadata(".UKash_Withdrawal_Notes"), true) %>

            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnWithdrawWithUkashPayCard" })%>
            </center>

            
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript" language="javascript">

$(function () {
    $('#formIssueUkashPayCard').initializeForm();
    $('#tabbedPayCards').selectTab('tabIssue');
    $('#tabbedPayCards').showTab('tabIssue', true);

    $('#btnWithdrawWithUkashPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid() )
            return;

        // <%-- RequestCreditCurrency --%>
        $('#hRepareTransactionRequestCreditCurrency').val($('#ddlIssueCardCurrency').val());

        $('#btnWithdrawWithUkashPayCard').toggleLoadingSpin(true);
        tryToSubmitWithdrawInputForm( '<%= GetPayCard().ID %>'
            , function () { $('#btnWithdrawWithUkashPayCard').toggleLoadingSpin(false); });
    });
});

</script>

