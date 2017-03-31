<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>


<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Globalization" %>

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

    private List<SelectListItem> GetAmountList()
    {

        List<decimal> amounts = new List<decimal> { 10.00M, 20.00M, 50.00M, 100.00M, 200.00M, 500.00M };
        var list = amounts.Select(a => new SelectListItem()
        {
            Value = a.ToString("N0", CultureInfo.InvariantCulture),
            Text = a.ToString("F2", CultureInfo.InvariantCulture)
        }).ToList();
        return list;
    }

    private PayCardInfoRec GetPayCard()
    {
        return GamMatrixClient.GetPayCards(VendorID.IPSToken).First();
    }

</script>



<%---------------------------------------------------------------
IPS Token
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        
        <%---------------------------------------------------------------
                Issue a new Card
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabIssue" Caption="<%$ Metadata:value(.Tab_IssuePayCard) %>">
            <form id="formIssueIPSTokenPayCard" method="post" onsubmit="return false">

            <%: Html.DropDownList("issueCurrency", GetCurrencyList(), new { @id="ddlIssueCardCurrency", @class="ddlMoneyCurrency select"  })%>
            <%: Html.DropDownList("issueAmount", GetAmountList(), new { @id = "ddlIssueCardAmount", @class = "select txtMoneyAmount" })%>


            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnWithdrawWithIPSPayCard" })%>
            </center>

            
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript" language="javascript">

    $(function () {
        $('#formIssueIPSTokenPayCard').initializeForm();
        $('#tabbedPayCards').selectTab('tabIssue');
        $('#tabbedPayCards').showTab('tabIssue', true);

        //$('#fldCurrencyAmount').hide();

        $('#ddlIssueCardCurrency').insertAfter($('#fldCurrencyAmount #ddlCurrency'));
        $('#fldCurrencyAmount #ddlCurrency').removeAttr('style').hide()[0].className = '';
        $('#ddlIssueCardCurrency').change(function (e) {
            $('#fldCurrencyAmount #ddlCurrency').val($(this).val());
            onCurrencyChange();
        }).change();

        $('#ddlIssueCardAmount').insertBefore($('#fldCurrencyAmount #txtAmount'));
        $('#fldCurrencyAmount #txtAmount').removeAttr('style').width(1).height(1)[0].className = '';
        $('#ddlIssueCardAmount').change(function () {
            $('#fldCurrencyAmount #txtAmount').val($(this).val());
            onAmountChange();
        }).change();

        $(document.body).bind('GAMING_ACCOUNT_SEL_CHANGED', function (e, data) {
            $('#ddlIssueCardCurrency').val(data.BalanceCurrency);
        });

        $('#btnWithdrawWithIPSPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid())
                return;

            // <%-- RequestCreditCurrency --%>
            $('#hRepareTransactionRequestCreditCurrency').val($('#ddlIssueCardCurrency').val());

            $('#btnWithdrawWithIPSPayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm('<%= GetPayCard().ID %>'
            , function () { $('#btnWithdrawWithIPSPayCard').toggleLoadingSpin(false); });
        });
    });

</script>

