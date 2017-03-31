<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.Common.Components.MoneyMatrixCreditCardPrepareViewModel>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script runat="server">

    private List<PayCardInfoRec> GetPayCards()
    {
        List<PayCardInfoRec> payCards = GamMatrixClient.GetMoneyMatrixPayCards().Where(p => !p.IsDummy).ToList();

        var brandTypes = Model.BrandTypes;
        var acceptableCardBins = Model.AcceptableCardBins;

        if (brandTypes == null && acceptableCardBins == null)
        {
            return new List<PayCardInfoRec>();
        }

        if (brandTypes != null)
        {
            payCards = payCards.Where(p => brandTypes.Any(b => b.Equals(p.BrandType, StringComparison.InvariantCultureIgnoreCase))).ToList();
        }

        if (acceptableCardBins != null)
        {
             payCards = payCards.Where(p => acceptableCardBins.Any(b => p.DisplayName.StartsWith(b))).ToList();
        }

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
                    <%  var checkedAttr = "checked";
                        foreach (PayCardInfoRec card in this.GetPayCards())
                        {
                            var cardType = string.Empty;
                            Model.BrandCardTypeMatching.TryGetValue(card.BrandType, out cardType); %>
                    <li>
                        <input type="radio" name="payCardID" <%= checkedAttr %> class="FormRadio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" />
                        <label for="btnPayCard_<%: card.ID %>" data-cardtype="<%= cardType %>" data-pan="<%= card.DisplayName %>"><%= card.DisplayName.SafeHtmlEncode() %></label>
                    </li>
                     <% checkedAttr = "unchecked";
                     } %>
                </ul>
            </li>
        </ul>
    </fieldset>
</div>

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
