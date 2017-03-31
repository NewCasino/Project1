<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" runat="server" type="text/C#">
    private bool IsCreditCardWithdrawable(PayCardInfoRec payCard)
    {
        if (string.IsNullOrWhiteSpace(payCard.IssuerCountryCode))
            return true;

        var countries = CountryManager.GetAllCountries();
        var country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, payCard.IssuerCountryCode, StringComparison.InvariantCultureIgnoreCase));
        if (country == null)
            return true;

        return !country.RestrictCreditCardWithdrawal;
    }
    
    private List<PayCardInfoRec> GetPayCards()
    {
        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(VendorID.MoneyMatrix).Where(x => !x.IsDummy)
            .ToList();
        return payCards;
    }
</script>



<%---------------------------------------------------------------
PaymentTrust
----------------------------------------------------------------%>
<form id="formPaymentTrustPayCard" onsubmit="return false">

        <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata(".WithdrawTo").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>

        <ul id="paycards-selector">
          <% foreach (PayCardInfoRec paycard in GetPayCards())
        { %>
            <li>
                <input type="radio" name="existingPayCard" value="<%= paycard.ID.ToString() %>" id="payCard_<%= paycard.ID.ToString() %>"/>
                <label for="payCard_<%= paycard.ID.ToString() %>" dir="ltr" data-cardtype="" data-pan="<%= paycard.DisplayName %>">
                    <%= paycard.DisplayName.SafeHtmlEncode() %> (<%= paycard.ExpiryDate.ToString("MM/yyyy") %> <%= paycard.OwnerName %>)
                </label>
            </li>
        <% } %>  
        </ul>
        <%: Html.Hidden("existingPayCardID", "", new 
            { 
                @id = "hExistingPayCardID",
                @validator = ClientValidators.Create().Required(this.GetMetadata(".ExistingCard_Empty")) 
            }) %>
        </ControlPart>
    </ui:InputField>


    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnWithdrawBack", @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
        <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithNetellerPayCard" })%>
    </center>
</form>

<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>
<script type="text/javascript">
    $(function () {
        $('#paycards-selector label').each(function(index, item) {
            var pan = $(item).attr('data-pan');
            var cardTypeValidateResult = $('<input value="' + pan + '"/>').validateCreditCard();
            var cardType = cardTypeValidateResult.card_type ? cardTypeValidateResult.card_type.name : '';

            $(item).attr('data-cardtype', cardType);
        });

        $('#formPaymentTrustPayCard').initializeForm();

        // <%-- the radio button click event--%>
        $('#paycards-selector input[name="existingPayCard"]').click(function () {
            $('#hExistingPayCardID').val($(this).val());
            InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
        });

        $('#btnWithdrawWithNetellerPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() || !$('#formPaymentTrustPayCard').valid())
                return;

            $('#btnWithdrawWithNetellerPayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm($('#hExistingPayCardID').val()
            , function () { $('#btnWithdrawWithNetellerPayCard').toggleLoadingSpin(false);  });
        });

        if ($('#paycards-selector :checked').length == 0)
            $('#paycards-selector input:first').trigger('click');
    });
    
</script>
<style type="text/css">
    #paycards-selector li label{padding-left:50px;background:url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -53px;background-size: 50px; }
    #paycards-selector li label[data-cardtype='visa'] { background-position: -3px -96px; }
    #paycards-selector li label[data-cardtype='visa_electron'] { background-position: -3px -138px; }
    #paycards-selector li label[data-cardtype='mastercard'] { background-position: -3px -179px; }
    #paycards-selector li label[data-cardtype='maestro'] { background-position: -3px -223px; }
    #paycards-selector li label[data-cardtype='discover'] { background-position: -3px -265px; }
    #paycards-selector li label[data-cardtype='amex'] { background-position: -3px -303px; }
    #paycards-selector li label[data-cardtype='jcb'] { background-position: -3px -336px; }
    #paycards-selector li label[data-cardtype='diners_club_carte_blanche'] { background-position: -3px -368px; }
    #paycards-selector li label[data-cardtype='diners_club_international'] { background-position: -3px -368px; }
    #paycards-selector li label[data-cardtype='laser'] { background-position: -3px -402px; }
</style>