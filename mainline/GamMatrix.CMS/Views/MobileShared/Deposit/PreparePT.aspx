<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PreparePaymentTrustViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="Finance" %>

<script runat="Server">

    private List<SelectListItem> GetMonthList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Month"), Value = "", Selected = true });

        for (int i = 1; i <= 12; i++)
        {
            list.Add(new SelectListItem() { Text = string.Format("{0:00}", i), Value = string.Format("{0:00}", i) });
        }

        return list;
    }

    private List<SelectListItem> GetExpiryYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = 0; i < 20; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }

    private List<SelectListItem> GetValidFromYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = -20; i <= 0; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="DepositPrepareBox" class="UserBox CenterBox DepositBox DepositOptionsList DepositStep3 DepositPrepareBox StyleV2" data-step="3">
        <div class="BoxContent DepositContent" id="DepositContent">
        <% if (!Settings.MobileV2.IsV2DepositProcessEnabled) { %>
    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
        <% } %>
<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPreparePT" class="GeneralForm DepositForm DepositPrepare">
    
<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <fieldset>
            <legend class="Hidden">
            <%= this.GetMetadata(".CreditCard").SafeHtmlEncode() %>
            </legend>
                <%: Html.Hidden( "payCardID", string.Empty, new { @id = "hCreditCardPayCardID" }) %>

<% Html.RenderPartial("/Components/GenericTabSelector", new GenericTabSelectorViewModel(new List<GenericTabData> 
{ 
new GenericTabData 
{ 
Name = this.GetMetadata(".Tab_RecentPayCards"), 
Attributes = new Dictionary<string, string>() { {"id", "#tabExistingCard"} } 
},
new GenericTabData 
{ 
Name = this.GetMetadata(".Tab_RegisterPayCard"), 
Attributes = new Dictionary<string, string>() { {"id", "#tabRegisterCard"} } 
}
})
{
ComponentId = "cardActionSelector"
}); %>

                <%-- Existing Card --%>
            <div class="TabContent" id="tabExistingCard">

<ul class="FormList">

    <%--------------------------
        Existing Card List
      --------------------------%>
    <li class="FormItem">
        <ul class="ExistingPayCards">
            <% foreach (PayCardInfoRec card in Model.PayCards)
                { %>
            <li>
                <input name="PaymentTrustPayCardID" class="FormRadio" type="radio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" />
                <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode() %></label>
            </li>
            <% } %>
        </ul>
    </li>


    <%--------------------------
        Security Key for existing card
      --------------------------%>
    <li class="FormItem">
    <label class="FormLabel" for="depositSecurityKey">
        <%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("securityKeyForExistingPayCard", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositSecurityKey" },
                { "maxlength", "3" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
                { "required", "required" },
{ "placeholder", this.GetMetadata(".CardSecurityCode_Label") },
                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".CardSecurityCode_Empty"))
                            .Custom("PreparePT.validateCardSecurityCode")  }
            }) %>
        <span class="FormStatus">Status</span>
<span class="FormHelp"></span>
<script>
$(function () {
new CMS.views.RestrictedInput('#depositSecurityKey', CMS.views.RestrictedInput.digits);
});
</script>
    </li>

    <li id="maxRegisteredCardsMsg" class="FormItem Hidden">
        <label class=""><%= this.GetMetadata(".MaxRegisteredCardsExceeded_Text") %></label>
    </li>
</ul>


                </div>

                <%-- Register Card --%>
                <div class="TabContent Hidden" id="tabRegisterCard">

<ul class="FormList">

    <%------------------------
        Card Number
    -------------------------%>    
    <li class="FormItem">
    <label class="FormLabel" for="depositCardNumber">
        <%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("identityNumber", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositCardNumber" },
                { "maxlength", "16" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
{ "type", "text" },
                { "required", "required" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CardNumber_Label") },
                { "data-validator", ClientValidators.Create().RequiredIf( "PreparePT.isRegisteringNewCard", this.GetMetadata(".CardNumber_Empty"))
                            .Custom("PreparePT.validateCardNumber")  }
            }) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>

        <script>
        $(function () {
        new CMS.views.RestrictedInput('#depositCardNumber', CMS.views.RestrictedInput.digits);
            });

            function validateCardNumber() {
            if (PreparePT.isRegisteringNewCard()) {
                    var value = this;
                    var ret = /^(\d{9,16})$/.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".CardNumber_Invalid").SafeJavascriptStringEncode() %>';
                }
                return true;
            }
        </script>
    </li>
    
    
    <%------------------------
        Card Holder Name
    -------------------------%>   
    <li class="FormItem">
    <label class="FormLabel" for="depositHolderName">
        <%= this.GetMetadata(".CardHolderName_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("ownerName", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositHolderName" },
                { "maxlength", "30" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
                { "required", "required" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CardHolderName_Label") },
                { "data-validator", ClientValidators.Create().RequiredIf( "PreparePT.isRegisteringNewCard", this.GetMetadata(".CardHolderName_Empty")) }
            }) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>

    <%------------------------
        Valid From
    -------------------------%> 
    <% if (Model.ShowExtraFields) {  %> 
    <li class="FormItem">
    <label class="FormLabel" for="ddlValidFromMonth">
        <%= this.GetMetadata(".ValidFrom_Label").SafeHtmlEncode()%>
        </label>
        <ol class="CompositeInput DateInput Cols-2">
    <li class="Col">
                <%: Html.DropDownList("validFromMonth", GetMonthList(), new
                {
                    @id = "ddlValidFromMonth",
                    @class = "FormInput"
                } 
                )%>
            </li>
            <li class="Col">
                <%: Html.DropDownList("validFromYear", GetValidFromYears(), new
                {
                    @id = "ddlValidFromYear",
                    @class = "FormInput"
                } 
                )%>
            </li>
    </ol>
        <%: Html.Hidden("validFrom","", new Dictionary<string, object>() 
            {
{ "class", "FormInput" },
                { "id", "hCardValidFrom" },
{ "disabled", "disabled" },
{ "autocomplete", "off" },
            } ) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
        <script>
            //<![CDATA[
            $(function () {
                var fun = function () {
                    var month = $('#ddlValidFromMonth').val();
                    var year = $('#ddlValidFromYear').val();
                    var value = '';
                    if (month.length > 0 && year.length > 0)
                        value = year + '-' + month + '-01';
                    $('#hCardValidFrom').val(value);
                };
                $('#ddlValidFromMonth').change(fun);
                $('#ddlValidFromYear').change(fun);
            });
            //]]>
        </script>
    </li>
    <% } // ShowExtraFields %>


    <%------------------------
        Expiry Date
    -------------------------%>   
    <li class="FormItem">
    <label class="FormLabel" for="ddlExpiryMonth">
        <%= this.GetMetadata(".CardExpiryDate_Label").SafeHtmlEncode()%>
        </label>
        <ol class="CompositeInput DateInput Cols-2">
    <li class="Col">
                <%: Html.DropDownList("expiryMonth", GetMonthList(), new
                {
                    @id="ddlExpiryMonth",
                    @class = "FormInput"
                } 
                )%>
            </li>
            <li class="Col">
                <%: Html.DropDownList("expiryYear", GetExpiryYears(), new
                {
                    @id = "ddlExpiryYear",
                    @class = "FormInput"
                } 
                )%>
            </li>
    </ol>
        <%: Html.Hidden("expiryDate","", new Dictionary<string, object>() 
            {
{ "class", "FormInput" },
                { "id", "hCardExpiryDate" },
{ "disabled", "disabled" },
{ "autocomplete", "off" },
{ "data-validator", ClientValidators.Create().RequiredIf("PreparePT.isRegisteringNewCard", this.GetMetadata(".CardExpiryDate_Empty")) } 
            } ) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
        <script>
            $(function () {
                var fun = function () {
                    var month = $('#ddlExpiryMonth').val();
                    var year = $('#ddlExpiryYear').val();
                    var value = '';
                    if (month.length > 0 && year.length > 0)
                        value = year + '-' + month + '-01';
                    $('#hCardExpiryDate').val(value);
                };
                $('#ddlExpiryMonth').change(fun);
                $('#ddlExpiryYear').change(fun);
            });
        </script>
    </li>


    <%------------------------
        Card Issue Number
    -------------------------%>   
    <% if( Model.ShowExtraFields ) {  %>
    <li class="FormItem">
    <label class="FormLabel" for="depositIssueNumber">
        <%= this.GetMetadata(".CardIssueNumber_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("issueNumber", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositIssueNumber" },
                { "maxlength", "16" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CardIssueNumber_Label") },
            }) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
    <% } %>

    <%--------------------------
        Security Key for new card
      --------------------------%>
    <li class="FormItem">
    <label class="FormLabel" for="depositNewSecurityKey">
        <%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("securityKeyForNewPayCard", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositNewSecurityKey" },
                { "maxlength", "3" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
                { "required", "required" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CardSecurityCode_Label") },
                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".CardSecurityCode_Empty"))
                            .Custom("PreparePT.validateCardSecurityCode")  }
            }) %>
        <span class="FormStatus">Status</span>
<span class="FormHelp"></span>
<script>
$(function () {
new CMS.views.RestrictedInput('#depositNewSecurityKey', CMS.views.RestrictedInput.digits);
});
</script>
    </li>

</ul>

                </div>
            </fieldset>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>

</form>
    </div>
</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
<script>
//<![CDATA[
    function PreparePT() {
    //card actions
    var cardActionSelector = new GenericTabSelector('#cardActionSelector'),
currentAction = $('#tabExistingCard');

    function selectAction(data) {
    if (currentAction) {
    currentAction.addClass('Hidden');
    $('input, select', currentAction).attr('disabled', true);
    }

    currentAction = $(data.id);

    currentAction.removeClass('Hidden');
    $('input, select', currentAction).attr('disabled', false);

    if (data.id == '#tabExistingCard') {
        $(':radio:first', '#tabExistingCard').click();
    }
    else {
        $('#hCreditCardPayCardID').val('');
    }
    }

    function removeItem(id) {
    $('[data-id="' + id + '"]', '#cardActionSelector').remove();
    $('#cardActionSelector').removeClass('Cols-2').addClass('Cols-1');
    $(id).remove();
        }

        $(':radio', '#tabExistingCard').click(function (e) {
            $('#hCreditCardPayCardID').val($(this).val());
        });

        var count = $(':radio', '#tabExistingCard').length;
        if (count >= <%= Settings.Payments_Card_CountLimit %>) {
            removeItem('#tabRegisterCard');
            $('#maxRegisteredCardsMsg').removeClass('Hidden');
        }
        else if (count == 0) {
            removeItem('#tabExistingCard');
            $('#maxRegisteredCardsMsg').addClass('Hidden');
        }
        
        function markOptional(inputSelector, state) {
        $.each(inputSelector.closest('.FormItem').find('.FormLabel'), function (i, label) {
        label = $(label);
        if (state) {
        if (!label.find('.FormLabelOptional').length)
        label.append('<span class="FormLabelOptional"> <%= this.GetMetadata(".FieldOptional").SafeJavascriptStringEncode() %></span>');
        } else 
        $('.FormLabelOptional', label).remove();
        });
        }

    cardActionSelector.evt.bind('select', selectAction);
    selectAction(cardActionSelector.select(0));
    markOptional($('#depositIssueNumber, #ddlValidFromMonth'), true);
    };

    PreparePT.validateCardSecurityCode = function () {
    var value = this;
    if (value.length > 0) {
    var ret = /^(\d{3,3})$/.exec(value);
    if (ret == null || ret.length == 0)
    return '<%= this.GetMetadata(".CardSecurityCode_Invalid").SafeJavascriptStringEncode() %>';
    }
    return true;
    }

    PreparePT.isRegisteringNewCard = function () {
    return $('#hCreditCardPayCardID').val() == '';
    }
    PreparePT.isExistingCard = function () {
    return !PreparePT.isRegisteringNewCard();
    }

    $(function () {
    CMS.mobile360.Generic.input();
    new PreparePT();
    });
//]]>
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

