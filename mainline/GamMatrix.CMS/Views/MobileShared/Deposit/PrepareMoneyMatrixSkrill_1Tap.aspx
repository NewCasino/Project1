<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneyMatrixSkrill_1Tap_ViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec DummyPayCard { get; set; }
    private List<PayCardInfoRec> ExistingPayCard { get; set; }

    private void InitPayCards()
    {
        if (!GamMatrixClient.GetPayCards(VendorID.MoneyMatrix).Any())
            throw new InvalidOperationException("This payment method is not configured in GmCore.");

        this.ExistingPayCard = GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy("Skrill")
            .Where(p => !p.IsDummy).ToList();

        if (!this.ExistingPayCard.Any())
        {
            this.DummyPayCard = GamMatrixClient.GetPayCards(VendorID.MoneyMatrix).FirstOrDefault(p => p.IsDummy);
        }
    }

</script>

<asp:content contentplaceholderid="cphMain" runat="Server">
    <% this.InitPayCards(); %>
    <div class="UserBox DepositBox CenterBox">
        <div class="BoxContent">
            <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel {FlowSteps = 4, CurrentStep = 2}); %>
            <form action="<%= this.Url.RouteUrl("Deposit", new {action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName}).SafeHtmlEncode() %>" method="post" id="formPrepareSkrill">
                <% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
                <fieldset>
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
                    <% if (this.DummyPayCard == null) %>
                    <%
                       { %>
                        <% foreach (var card in this.ExistingPayCard)
                           { %>
                            <ul id="skrillAccountsArea"
                                class="mm-skrill-account-area FormList">
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
                                <br/>
                                <li class="FormItem">
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
                        <% } %>
                    <% } %>
                    <%
                       else %>
                    <%
                       { %>
                        <div>
                            <%= this.GetMetadata(".SkrillEmailAddress_Label") %>
                        </div>
                        <ul class="mm-skrill-account-area FormList">
                            <li class="FormItem">
                                <input type="radio"
                                       style="display: none;"
                                       name="skrillOptions"
                                       value="<%: this.DummyPayCard.ID.ToString() %>"
                                       data-id="<%: this.DummyPayCard.ID.ToString() %>"
                                       checked="checked">
                                <%: Html.TextBox("SkrillEmailAddress", this.Profile.Email, new Dictionary<string, object>
                                    {
                                        {"id", "txtSkrillEmailAddress"},
                                        {"dir", "ltr"},
                                        {"autocomplete", "off"},
                                        {"value", this.Profile.Email},
                                        {"style", "display:inline"},
                                        {"class", "FormInput"},
                                        {
                                            "data-validator", ClientValidators.Create()
                                                .Email(this.GetMetadata(".SkrillEmailAddress_Invalid"))
                                        }
                                    }
                                        ) %>
                                <span class="FormStatus">Status</span>
                                <span class="FormHelp"></span>
                            </li>
                        </ul>
                    <% } %>
                </fieldset>

                <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
            </form>
        </div>
    </div>

    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
        <script type="text/javascript">
            (function() {
                $('#formPrepareSkrill')
                    .append($('<input type="hidden" name="SkrillEmailAddress" id="hdnSkrillEmailAddress"/>'))
                    .append($('<input type="hidden" name="payCardID" id="payCardID"/>'))
                    .append($('<input type="hidden" name="SkrillReSetupOneTap" id="hdnSkrillReSetup1Tap"/>'))
                    .append($('<input type="hidden" name="SkrillUseOneTap" id="hdnSkrillUseOneTap"/>'));

                var useDummyCard = <%= (this.DummyPayCard != null).ToString().ToLowerInvariant() %>;

                setFields();

                $('input[name=skrillOptions]')
                    .click(function(e) {
                        setFields();
                    });

                function setFields() {
                    if (useDummyCard) {
                        $('#hdnSkrillEmailAddress').val($('#txtSkrillEmailAddress').val());
                        $('#hdnSkrillReSetup1Tap').val(false);
                        $('#hdnSkrillUseOneTap').val(true);
                    } else {
                        $('#hdnSkrillEmailAddress').val($('input[name=skrillOptions]:checked').data("email"));
                        $('#hdnSkrillReSetup1Tap').val($('#resetup1tap').is(":checked"));
                        $('#hdnSkrillUseOneTap').val(true);
                    }
                    $('#payCardID').val($('input[name=skrillOptions]:checked').data("id"));
                }
            })();
            $(CMS.mobile360.Generic.input);
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
    </ui:MinifiedJavascriptControl>
</asp:content>