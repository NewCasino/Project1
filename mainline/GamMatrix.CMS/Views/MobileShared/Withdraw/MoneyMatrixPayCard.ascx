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

<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>
<div class="UiPasWithdrawal">
    <fieldset>
        <legend class="Hidden">
            <%= this.GetMetadata(".Withdraw_Message").SafeHtmlEncode()%>
        </legend>
        <p class="SubHeading WithdrawSubHeading">
            <%= this.GetMetadata(".Withdraw_Message").SafeHtmlEncode()%>
        </p>
        <ul class="FormList">
            <li class="FormItem">
                <ul class="PayCardList" id="paycards-selector">
                    <% foreach (PayCardInfoRec card in this.GetPayCards())
                       {  %>
                    <li>
                        <input type="radio" name="payCardID" class="FormRadio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" />
                        <label for="btnPayCard_<%: card.ID %>" data-cardtype="" data-pan="<%= card.DisplayName %>"><%= card.DisplayName.SafeHtmlEncode() %></label>
                    </li>

                    <% } %>
                </ul>
            </li>
        </ul>
    </fieldset>
</div>
<script type="text/javascript">
    $(function () {
        $('#paycards-selector label').each(function (index, item) {
            var pan = $(item).attr('data-pan');
            var cardTypeValidateResult = $('<input value="' + pan + '"/>').validateCreditCard();
            var cardType = cardTypeValidateResult.card_type ? cardTypeValidateResult.card_type.name : '';

            $(item).attr('data-cardtype', cardType);
        });

        $('ul.PayCardList :radio:first').click();
    });
</script>

<style type="text/css">
    #paycards-selector li label
    {
        padding-left: 50px;
        background: url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -53px;
        background-size: 50px;
    }

        #paycards-selector li label[data-cardtype='visa']
        {
            background-position: -3px -96px;
        }

        #paycards-selector li label[data-cardtype='visa_electron']
        {
            background-position: -3px -138px;
        }

        #paycards-selector li label[data-cardtype='mastercard']
        {
            background-position: -3px -179px;
        }

        #paycards-selector li label[data-cardtype='maestro']
        {
            background-position: -3px -223px;
        }

        #paycards-selector li label[data-cardtype='discover']
        {
            background-position: -3px -265px;
        }

        #paycards-selector li label[data-cardtype='amex']
        {
            background-position: -3px -303px;
        }

        #paycards-selector li label[data-cardtype='jcb']
        {
            background-position: -3px -336px;
        }

        #paycards-selector li label[data-cardtype='diners_club_carte_blanche']
        {
            background-position: -3px -368px;
        }

        #paycards-selector li label[data-cardtype='diners_club_international']
        {
            background-position: -3px -368px;
        }

        #paycards-selector li label[data-cardtype='laser']
        {
            background-position: -3px -402px;
        }
</style>
