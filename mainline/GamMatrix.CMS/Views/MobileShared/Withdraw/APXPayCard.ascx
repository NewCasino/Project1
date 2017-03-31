<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>


<script type="text/C#" runat="server">
    private List<PayCardInfoRec> PayCards { get; set; }
    
    protected override void OnInit(EventArgs e)
    {
        var payCards = GamMatrixClient.GetPayCards()
                        .Where(p => !p.IsDummy && p.VendorID == VendorID.APX)
                        .OrderByDescending(p => p.Ins).ToList();

        this.PayCards = payCards;
                                        
        base.OnInit(e);
    }

    private string GetPayCardJson(PayCardInfoRec card)
    {
        return string.Format("{{\"ID\":\"{0}\",\"BankName\":\"{1}\",\"BankCode\":\"{2}\",\"BranchAddress\":\"{3}\",\"BranchCode\":\"{4}\",\"Payee\":\"{5}\",\"PayeeAddress\":\"{6}\",\"AccountNumber\":\"{7}\",\"IBAN\":\"{8}\",\"SWIFT\":\"{9}\",\"Currency\":\"{10}\",\"CountryID\":\"{11}\", \"BankAdditionalInfo\":\"{12}\"}}"
            , card.ID
            , card.BankName.SafeJavascriptStringEncode()
            , card.BankCode.SafeJavascriptStringEncode()
            , card.BankAddress.SafeJavascriptStringEncode()
            , card.BankBranchCode.SafeJavascriptStringEncode()
            , card.OwnerName.SafeJavascriptStringEncode()
            , card.BankBeneficiaryAddress.SafeJavascriptStringEncode()
            , card.BankAccountNo.SafeJavascriptStringEncode()
            , card.BankIBAN.SafeJavascriptStringEncode()
            , card.BankSWIFT.SafeJavascriptStringEncode()
            , card.BaseCurrency.SafeJavascriptStringEncode()
            , card.BankCountryID
            , card.BankAdditionalInfo
            );
    }

</script>

<div class="BankWithdrawal">
    <fieldset>
    <legend class="Hidden">
    <%= this.GetMetadata(".BankAccount").SafeHtmlEncode() %>
    </legend>
    <p class="SubHeading WithdrawSubHeading">
    <%= this.GetMetadata(".BankAccount").SafeHtmlEncode() %>
    </p>
        <%: Html.Hidden( "payCardID", string.Empty, new { @id = "hBankPayCardID" }) %>

<% Html.RenderPartial("/Components/GenericTabSelector", new GenericTabSelectorViewModel(new List<GenericTabData> 
{ 
new GenericTabData 
{ 
Name = this.GetMetadata(".Tab_RecentPayCards"), 
Attributes = new Dictionary<string, string>() { {"id", "#tabExistingCard"} } 
},
new GenericTabData 
{ 
Name = this.GetMetadata(".Tabs_RegisterPayCard"), 
Attributes = new Dictionary<string, string>() { {"id", "#tabRegisterCard"} } 
}
})
{
ComponentId = "cardActionSelector"
}); %>

<div class="TabContent" id="tabExistingCard">
        
        <ul class="FormList">
        <li class="FormItem">
                    <ul class="PayCardList">
                        <% foreach (PayCardInfoRec card in this.PayCards)
                           { %>
                        <li>
                            <input type="radio" name="existingPayCardID" class="FormRadio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" data-json="<%= GetPayCardJson(card).SafeHtmlEncode() %>" />
                            <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode() %></label>
                        </li>
                        <% } %>
                    </ul>
        </li>

                <%---------------------------------------------------------------
                    BankName (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldBankName2">
        <label class="FormLabel" for="withdrawBankName2">
                    <%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("bankName2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawBankName2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".BankName_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>


                <%---------------------------------------------------------------
                    BranchAddress (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldBranchAddress2">
        <label class="FormLabel" for="withdrawBranchAddress2">
                    <%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("branchAddress2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawBranchAddress2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".BranchAddress_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>


                <%---------------------------------------------------------------
                    IBAN (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldIBAN2">
        <label class="FormLabel" for="withdrawIBAN2">
                    <%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("IBAN2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawIBAN2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
                            { "readonly", "readonly" },
{ "placeholder", this.GetMetadata(".IBAN_Label") },
                            { "disabled", "disabled" },
                        }) %>
        </li>

                <%---------------------------------------------------------------
                    SWIFT (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldSWIFT2">
        <label class="FormLabel" for="withdrawSWIFT2">
                    <%= this.GetMetadata(".SWIFT_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("SWIFT2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawSWIFT2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
                            { "readonly", "readonly" },
{ "placeholder", this.GetMetadata(".SWIFT_Label") },
                            { "disabled", "disabled" },
                        }) %>
        </li>

                <%---------------------------------------------------------------
                    TC Number ( Readonly )
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldTCNumber2">
        <label class="FormLabel" for="withdrawTCNumber2">
                    <%= this.GetMetadata(".TCNumber_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("tcNumber", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawTCNumber" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
                            { "readonly", "readonly" },
{ "placeholder", this.GetMetadata(".TCNumber_Label") },
                            { "disabled", "disabled" },
                        }) %>
        </li>
        </ul>
</div>
    <div class="TabContent Hidden" id="tabRegisterCard">
            
            <%: Html.Hidden("vendorID", "", new { @id = "hBankPayCardVendorID" })%>
        <ul class="FormList">
            

            <%---------------------------------------------------------------
                BankName
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBankName">
                <label class="FormLabel" for="withdrawBankName">
                    <%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("bankName", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawBankName" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".BankName_Label") },
                        { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".BankName_Empty")) }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>

            <%---------------------------------------------------------------
                BranchAddress
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBranchAddress">
                <label class="FormLabel" for="withdrawBranchAddress">
                    <%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("branchAddress", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawBranchAddress" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".BranchAddress_Label") },
                        { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".BranchAddress_Empty")) }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>

            <%---------------------------------------------------------------
                IBAN
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldIBAN">
                <label class="FormLabel" for="withdrawIBAN">
                    <%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("iban", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawIBAN" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".IBAN_Label") },
                        { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".IBAN_Empty")).Custom("validateIBAN") },
                        { "maxlength", "26" }, 
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isIBANRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showIBAN; }
                function validateIBAN() {
                    var value = this;
                    var validationExpressionOfIBAN = /^(TR)(([a-z]|[0-9]){24,24})$/i;
                    if (value == null ||
                        value.length == 0 ||
                        validationExpressionOfIBAN == null) {
                        return true;
                    }
                
                    var ret = validationExpressionOfIBAN.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                SWIFT
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldSWIFT">
                <label class="FormLabel" for="withdrawSWIFT">
                    <%= this.GetMetadata(".SWIFT_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("swift", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawSWIFT" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".SWIFT_Label") },
                        { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".SWIFT_Empty")).Custom("validateSWIFT") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isSWIFTRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showSWIFT; }
                function validateSWIFT() {
                    var value = this;
                    var validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
                    if (value == null ||
                        value.length == 0 ||
                        validationExpressionOfSWIFT == null) {
                        return true;
                    }
                    var ret = validationExpressionOfSWIFT.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>


            <%---------------------------------------------------------------
                TC Number ( 11 digit )
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldTCNumber">
                <label class="FormLabel" for="withdrawTCNumber">
                    <%= this.GetMetadata(".TCNumber_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("tcNumber", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawTCNumber" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".TCNumber_Label") },
                        { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".CheckDigits_Empty")) },
                        { "maxlength", "11" },
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
        </ul>
</div>

    </fieldset>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function BankPayCard() {
        var cardActionSelector = new GenericTabSelector('#cardActionSelector'),
currentAction = $('#tabExistingCard');

        function selectAction(data) {
            if (currentAction) {
                currentAction.addClass('Hidden');
                $('input, select', currentAction).attr('disabled', true);
            }

            currentAction = $(data.id);

            currentAction.removeClass('Hidden');
            $('input, select', currentAction).each(function (index, element) {
                element = $(element);
                if (!element.data('inactive')) 
                    element.attr('disabled', false);
            });

            if (data.id == '#tabExistingCard')
                $(':radio:first', '#tabExistingCard').click();
            else
                $('#hBankPayCardID').val('');
                
        }

        function removeItem(id) {
            $('[data-id="' + id + '"]', '#cardActionSelector').remove();
            $('#cardActionSelector').removeClass('Cols-2').addClass('Cols-1');
            $(id).remove();
        }

        // <%-- init tabs starts --%>
        var $list = $('div.BankWithdrawal ul.PayCardList li');
        if ($list.length > 0) {
            $(':radio', $list).click(function (e) {
                var json = $(this).data('json');
                $('#hBankPayCardID').val($(this).val());
                $(this).val($('#hBankPayCardID').val())
                activate($('#fldBankName2'), false);
                activate($('#fldBranchAddress2'), false);
                activate($('#fldIBAN2'), false);
                activate($('#fldSWIFT2'), false);
                activate($('#fldTCNumber2'), false);

                if (json.BankName.length > 0) {
                    activate($('#fldBankName2'), true, json.BankName);
                }
                if (json.BranchAddress.length > 0) {
                    activate($('#fldBranchAddress2'), true, json.BranchAddress);
                }
                if (json.IBAN.length > 0) {
                    activate($('#fldIBAN2'), true, json.IBAN);
                }
                if (json.SWIFT.length > 0) {
                    activate($('#fldSWIFT2'), true, json.SWIFT);
                }
                if (json.BankAdditionalInfo.length > 0) {
                    activate($('#fldTCNumber2'), true, json.BankAdditionalInfo);
                }

            });

            function activate(element, state, updateVal) {
                if (state)
                    element.show();
                else
                    element.hide();

                var input = $('.FormInput', element);
                input.attr('disabled', !state).data('inactive', !state);
                if (updateVal !== undefined)
                    input.val(updateVal);
            }

            $(document).ready(function () {
                $(':radio:first', $list.eq(0)).click();
            });

            if ($list.length.length >= 3) 
                removeItem('#tabRegisterCard');
        }
        else 
            removeItem('#tabExistingCard');
        // <%-- init tabs ends --%>

        cardActionSelector.evt.bind('select', selectAction);
        selectAction(cardActionSelector.select(0));
    };

    $(function () {
        new BankPayCard();
    });
</script>
</ui:MinifiedJavascriptControl>