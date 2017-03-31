<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" runat="server" type="text/C#">
    private List<PayCardInfoRec> PayCards { get; set; }

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
    
    protected override void  OnInit(EventArgs e)
    {
     base.OnInit(e);
        
        this.PayCards = GamMatrixClient.GetPayCards(VendorID.PaymentTrust)
                .Where(p => p.IsBelongsToPaymentMethod(this.Model.UniqueName) && IsCreditCardWithdrawable(p) )
                .ToList();
    }

</script>

<div class="PaymentTrustWithdrawal">
    <fieldset>
    <legend class="Hidden">
    <%= this.GetMetadata(".CreditCard").SafeHtmlEncode() %>
    </legend>
    <p class="SubHeading WithdrawSubHeading">
    <%= this.GetMetadata(".CreditCard").SafeHtmlEncode()%>
    </p>

    <ul class="Tabs Cols-2 Container">
        
    <li class="Col Tab" data-for="tabExistingCard">
    <a class="TabLink TabButton" href="javascript:void(0)">
                <%= this.GetMetadata(".Tab_ExistingPayCards").SafeHtmlEncode()%>
                </a>
    </li>

    </ul>
<div class="TabContent" id="tabExistingCard">
        
        <ul class="FormList">
            <li class="FormItem">
                <%---------------------------------------------------------------
                    Existing paycards
                ----------------------------------------------------------------%>
            <ul class="PayCardList">
                    <% foreach (PayCardInfoRec card in this.PayCards)
                        {  %>
            <li>
                            <input type="radio" name="payCardID" class="FormRadio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" />
                            <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode() %></label>
                        </li>

                    <% } %>
            </ul>

            </li>
        </ul>
            
</div>
    
    </fieldset>
</div>

<script type="text/javascript">
    $(function () {
        $('div.PaymentTrustWithdrawal ul.Tabs li.Tab').click(function (e) {
            $('div.PaymentTrustWithdrawal ul.Tabs li.ActiveTab').removeClass('ActiveTab');
            $(this).addClass('ActiveTab');
            $('div.PaymentTrustWithdrawal div.TabContent').hide();
            var id = $(this).data('for');
            $(document.getElementById(id)).show();

            if ($(this).data('for') != 'tabExistingCard')
                $('#hPaymentTrustPayCardID').val('');
        }).eq(0).click();

        $('ul.PayCardList :radio:first').click();
    });
</script>