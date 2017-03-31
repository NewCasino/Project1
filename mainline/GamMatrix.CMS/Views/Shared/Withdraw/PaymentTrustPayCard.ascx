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
        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(VendorID.PaymentTrust)
            .Where(p => p.IsBelongsToPaymentMethod(this.Model.UniqueName) && IsCreditCardWithdrawable(p) )
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
                <label for="payCard_<%= paycard.ID.ToString() %>" dir="ltr">
                    <%= paycard.DisplayName.SafeHtmlEncode() %> (<%= paycard.ExpiryDate.ToString("MM/yyyy") %>)
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

<script type="text/javascript">
    $(function () {
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