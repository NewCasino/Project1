<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec DummyPayCard { get; set; }
    private List<PayCardInfoRec> ExistingPayCard { get; set; }

    private void InitPayCards()
    {
        if (!GamMatrixClient.GetPayCards(VendorID.MoneyMatrix).Any())
            throw new InvalidOperationException("This payment method is not configured in GmCore.");

        this.ExistingPayCard = GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy("Skrill").Where(p => !p.IsDummy).ToList();

        if (!this.ExistingPayCard.Any())
        {
            this.DummyPayCard = GamMatrixClient.GetPayCards(VendorID.MoneyMatrix).FirstOrDefault(p => p.IsDummy);
        }
    }

</script>
<style type="text/css">
    .inputfield .controls .lst-amounts.select {
        max-width: 500px;
        width: 90% !important;
    }

    #skrillAccountsArea .account-radio { margin-right: 6px; }

    #skrillAccountsArea .account-text { font-size: 18px; }

</style>
<% this.InitPayCards(); %>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <ui:Panel runat="server" ID="tabSkrillPayCard" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/MoneyMatrix_Skrill_1Tap.Title) %>" Selected="true">
            <form id="formSkrillPayCard" onsubmit="return false">
                <% if (this.DummyPayCard != null) %>
                <%
                   { %>
                    <div>
                        Skrill 1-Tap session is not set up yet.
                        <br/>
                        To have the ability to use 1-Tap you need to set it up first.
                        <br/>
                        Please note that the amount entered for the setup transaction will also be configured as the maximum deposit amount allowed for the subsequent Skrill 1-Tap transactions.
                        <br/>
                    </div>
                <% } %>
                <ui:InputField ID="fldSkrillEmailAddress" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                    <ControlPart>
                        <% if (this.DummyPayCard == null) %>
                        <%
                           { %>
                            <% foreach (var card in this.ExistingPayCard)
                               { %>
                                <ul id="skrillAccountsArea" class="mm-skrill-account-area">
                                    <li name="descrArea" data-id="<%: card.ID %>" style="display: none">
                                        <% var skrillOneTapMaxAmount = card.DisplaySpecificFields.FirstOrDefault(x => x.Key == "SkrillOneTapMaxAmount");
                                           var skrillOneTapMaxCurrency = card.DisplaySpecificFields.FirstOrDefault(x => x.Key == "SkrillOneTapMaxCurrency");
                                           var skrillDepositPaymentType = card.DisplaySpecificFields.FirstOrDefault(x => x.Key == "SkrillDepositPaymentType");
                                           var skrillOneTapId = card.DisplaySpecificFields.FirstOrDefault(x => x.Key == "SkrillOneTapId");
                                           var maxAmountValue = skrillOneTapMaxAmount != null ? skrillOneTapMaxAmount.Value : string.Empty;
                                           var maxCurrencyValue = skrillOneTapMaxCurrency != null ? skrillOneTapMaxCurrency.Value : string.Empty;
                                           var paymentTypeValue = skrillDepositPaymentType != null ? skrillDepositPaymentType.Value : string.Empty;
                                           var oneTapId = skrillOneTapId != null ? skrillOneTapId.Value : string.Empty;
                                        %>
                                        <% if (!string.IsNullOrEmpty(maxAmountValue) && !string.IsNullOrEmpty(maxCurrencyValue) && !string.IsNullOrEmpty(paymentTypeValue) && !string.IsNullOrEmpty(oneTapId))
                                           { %>
                                            <div>
                                                Skrill 1-Tap session was set up with <b><% = paymentTypeValue %></b> and with maximum allowed amount <b><% = maxAmountValue %> <% = maxCurrencyValue %></b>.
                                                <br/>
                                                To use the current 1-Tap session, please enter the amount you wish to deposit without exceeding the maximum and "Continue"
                                                <br/>
                                            </div>
                                            <input type="checkbox"
                                                   class="account-radio"
                                                   id="resetup1tap"
                                                   name="resetup1tap"
                                                   data-id="<%: card.ID.ToString() %>"
                                                   data-email="resetup1tap">
                                            <label>
                                                Select to re-setup Skrill 1-Tap session
                                            </label>
                                        <% } %>
                                    </li>
                                    <li>
                                        <% var cardId = card.ID.ToString(); %>
                                        <input type="radio"
                                               class="account-radio"
                                               id="option_<%: card.ID.ToString() %>"
                                               name="skrillOptions"
                                               value="<%: card.ID.ToString() %>"
                                               data-id="<%: card.ID.ToString() %>"
                                               data-email="<%: card.DisplayName %>"
                                               <%: card.ID == this.ExistingPayCard.FirstOrDefault().ID ? "checked" : "" %>>
                                        <label for="option_<%: card.ID.ToString() %>"
                                               class="account-text">
                                            <%: card.DisplayName %>
                                        </label>
                                    </li>
                                </ul>
                                <br/>
                            <% } %>
                        <% } %>
                        <%
                           else %>
                        <%
                           { %>
                            <div>
                                <%= this.GetMetadata(".SkrillEmailAddress_Label") %>
                            </div>
                            <ul class="mm-skrill-account-area">
                                <li>
                                    <input type="radio"
                                           style="display: none;"
                                           name="skrillOptions"
                                           value="<%: this.DummyPayCard.ID.ToString() %>"
                                           data-id="<%: this.DummyPayCard.ID.ToString() %>"
                                           checked="checked">
                                    <%: Html.TextBox("SkrillEmailAddress", this.Profile.Email, new
                                        {
                                            @id = "txtSkrillEmailAddress",
                                            @dir = "ltr",
                                            @value = this.Profile.Email,
                                            @style = "display:inline",
                                            @validator = ClientValidators.Create().Email(this.GetMetadata(".SkrillEmailAddress_Invalid")),
                                        }) %>
                                </li>
                            </ul>
                        <% } %>

                    </ControlPart>
                </ui:InputField>
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new {@id = "btnDepositWithSkrillPayCard", @class = "ContinueButton button"}) %>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    $(document)
        .ready(function() {
            $('#formSkrillPayCard').initializeForm();
            $('#formPrepareDeposit')
                .append($('<input type="hidden" name="SkrillEmailAddress" id="hdnSkrillEmailAddress"/>'))
                .append($('<input type="hidden" name="SkrillReSetupOneTap" id="hdnSkrillReSetup1Tap"/>'))
                .append($('<input type="hidden" name="SkrillUseOneTap" id="hdnSkrillUseOneTap"/>'));

            $('#btnDepositWithSkrillPayCard')
                .click(function(e) {
                    e.preventDefault();

                    var useDummyCard = <%= (this.DummyPayCard != null).ToString().ToLowerInvariant() %>;

                    if (useDummyCard) {
                        $('#hdnSkrillEmailAddress').val($('#txtSkrillEmailAddress').val());
                        $('#hdnSkrillReSetup1Tap').val(false);
                        $('#hdnSkrillUseOneTap').val(true);
                    } else {
                        $('#hdnSkrillEmailAddress').val($('input[name=skrillOptions]:checked').data("email"));
                        $('#hdnSkrillReSetup1Tap').val($('#resetup1tap').is(":checked"));
                        $('#hdnSkrillUseOneTap').val(true);
                    }

                    if (!isDepositInputFormValid() || !$('#formSkrillPayCard').valid())
                        return false;

                    $(this).toggleLoadingSpin(true);

                    var payCardID = $('input[name=skrillOptions]:checked').data("id");

                    <%-- post the prepare form --%>   
                    tryToSubmitDepositInputForm(payCardID,
                        function() {
                            $('#btnDepositWithSkrillPayCard').toggleLoadingSpin(false);
                        });
                });

            // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
            $(document)
                .bind('DEPOSIT_TRANSACTION_PREPARED',
                    function(e, sid) {

                    });
        });
</script>
<script>
    $('li[name=descrArea]').first().show();
    $('input[name=skrillOptions]')
        .click(function() {
            var checkedId = $('input[name=skrillOptions]:checked').data("id");
            var allLi = $('li[name=descrArea]');
            var allCheckBoxes = $('input[name=resetup1tap]');
            $.each(allLi,
                function(id, elm) {
                    if ($(elm).data("id") !== checkedId) {
                        $(elm).hide();
                    } else {
                        $(elm).show();
                    }
                });
            $.each(allCheckBoxes,
                function(idcb, elmCb) {
                    if ($(elmCb).data("id") !== checkedId) {
                        $(elmCb).attr('checked', false);
                    }
                });
        });
</script>
<script>
    $('input[name=resetup1tap]')
        .click(function() {
            $(this).attr('checked', $('#hdnSkrillReSetup1Tap').val($('#resetup1tap').is(":checked")));
        });
</script>