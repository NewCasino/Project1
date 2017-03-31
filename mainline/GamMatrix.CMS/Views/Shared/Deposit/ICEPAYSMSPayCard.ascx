<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.ICEPAY)
        .OrderByDescending(e => e.LastSuccessDepositDate)
        .FirstOrDefault();
        if (payCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return payCard;
    }

    protected override void  OnPreRender(EventArgs e)
    {
        tabRecentCards.Attributes["Caption"] = this.Model.GetTitleHtml();
 	     base.OnPreRender(e);
    }

    private SelectList GetCountryList()
    {
        List<string> supportedCountries = new List<string>()
            {
                "NL", "AU", "AT", "BE", "CZ", "DK", "EE", "FI", "FR", "DE", "LU", "NO", "PL", "GB", "SE", "ZA"
            };
        List<CountryInfo> countries = CountryManager.GetAllCountries()
            .Where(c => supportedCountries.Exists(code => code == c.ISO_3166_Alpha2Code))
            .ToList();
        
        return new SelectList(countries
            , dataTextField: "DisplayName"
            , dataValueField: "InternalID"
            , selectedValue: Profile.UserCountryID
            );
    }

    private sealed class ICEPAYSMSAmounts
    {
        public long InternalID { get; set; }
        public string Currency { get; set; }
        public List<decimal> Values { get; set; }
    }

    private List<ICEPAYSMSAmounts> GetAmountMatrix()
    {
        List<ICEPAYSMSAmounts> list = new List<ICEPAYSMSAmounts>();
        
        // Netherlands
        ICEPAYSMSAmounts amounts = new ICEPAYSMSAmounts()
            {
                InternalID = 155,
                Currency = "EUR",
                Values = new List<decimal>() { 0.25M, 0.35M, 0.40M, 0.55M, 0.60M, 0.70M, 0.80M, 0.90M,1.10M,1.40M,1.50M,1.80M,2.10M,2.20M,2.60M,2.70M,2.80M,3.00M,3.60M,4.10M,4.40M,4.50M,5.20M,5.60M,6.00M}
            };
        list.Add(amounts);

        // Australia
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 20,
            Currency = "AUD",
            Values = new List<decimal>() { 4.00M, 6.60M }
        };
        list.Add(amounts);

        // Austria
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 21,
            Currency = "EUR",
            Values = new List<decimal>() { 2.00M }
        };
        list.Add(amounts);

        // Belgium
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 28,
            Currency = "EUR",
            Values = new List<decimal>() { 2.00M, 4.00M }
        };
        list.Add(amounts);

        // Czech Republic
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 63,
            Currency = "CZK",
            Values = new List<decimal>() { 40.00M }
        };
        list.Add(amounts);

        // Denmark
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 64,
            Currency = "DKK",
            Values = new List<decimal>() { 1.00M, 5.00M, 10.00M, 15.00M, 20.00M, 25.00M, 30.00M, 50.00M }
        };
        list.Add(amounts);

        // Estonia
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 74,
            Currency = "EEK",
            Values = new List<decimal>() { 50.00M }
        };
        list.Add(amounts);

        // Finland
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 79,
            Currency = "EUR",
            Values = new List<decimal>() { 1.00M, 1.25M, 1.50M, 1.75M, 2.00M, 3.00M, 4.00M, 5.00M }
        };
        list.Add(amounts);

        // France
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 80,
            Currency = "EUR",
            Values = new List<decimal>() { 1.50M }
        };
        list.Add(amounts);

        // Germany
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 88,
            Currency = "EUR",
            Values = new List<decimal>() { 0.99M, 1.49M, 1.99M, 2.49M, 2.99M, 3.99M, 4.99M }
        };
        list.Add(amounts);

        // Luxembourg
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 129,
            Currency = "EUR",
            Values = new List<decimal>() { 1.29M }
        };
        list.Add(amounts);

        // Norway
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 166,
            Currency = "NOK",
            Values = new List<decimal>() { 5.00M, 10.00M, 15.00M, 20.00M, 30.00M, 40.00M, 50.00M, 60.00M }
        };
        list.Add(amounts);

        // Poland
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 177,
            Currency = "PLN",
            Values = new List<decimal>() { 6.10M }
        };
        list.Add(amounts);

        // South Africa
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 200,
            Currency = "ZAR",
            Values = new List<decimal>() { 2.50M, 3.00M, 5.00M }
        };
        list.Add(amounts);

        // Sweden
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 211,
            Currency = "SEK",
            Values = new List<decimal>() { 5.00M, 10.00M, 15.00M, 20.00M, 25.00M, 30.00M, 40.00M, 50.00M, 60.00M, 70.00M, 80.00M, 90.00M, 100.00M, 110.00M, 120.00M, 140.00M, 160.00M, 180.00M, 200.00M }
        };
        list.Add(amounts);

        // United Kingdom
        amounts = new ICEPAYSMSAmounts()
        {
            InternalID = 230,
            Currency = "GBP",
            Values = new List<decimal>() { 1.50M, 3.00M, 5.00M, 10.00M }
        };
        list.Add(amounts);

        return list;
    }
    
</script>

<style type="text/css">
.icepay-sms-amount-ul li { float:left; width:100px; display:block; }
</style>



<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            ICEPay
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Selected="true">
            <form id="formICEPAYPayCard" onsubmit="return false">
                
                <%------------------------
                    Country
                -------------------------%>    
                <ui:InputField ID="fldICEPAYSMSCountry" runat="server" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Country_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: this.Html.DropDownList("icepaySMSCountry", GetCountryList(), new { @id = "ddlICEPAYSMSCountry" })%>
	                </ControlPart>
                </ui:InputField>

                <%------------------------
                    Amount
                -------------------------%>    
                <ui:InputField ID="fldICEPAYSMSAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: this.Html.TextBox("icepaySMSAmount" , string.Empty ,
                        new 
                        { 
                            @id = "txtICEPAYSMSAmount", 
                            @style = "width:0px; height:0px; border:0px; background:transparent; overflow:hidden",
                            @validator = ClientValidators.Create().Required( this.GetMetadata(".Amount_Empty") ).Custom("validateICEPAYSMSAmount")
                        })%>
                        <ul class="icepay-sms-amount-ul">

                        <%
                            {
                                List<ICEPAYSMSAmounts> list = GetAmountMatrix();
                                foreach (ICEPAYSMSAmounts amounts in list)
                                {
                                    foreach (decimal amount in amounts.Values)
                                    {
                                        string countrolID = string.Format("btnAmount_{0}_{1}", amounts.InternalID, amount * 100.0M);
                                        %>
                                        
                                        <li data-InternalID="<%= amounts.InternalID %>" >
                                            <input autocomplete="off" type="radio" id="<%= countrolID.SafeHtmlEncode() %>" name="ICEPAYSMS_amount"
                                                data-Currency="<%= amounts.Currency.SafeHtmlEncode() %>" 
                                                data-Amount="<%= amount.ToString("N2", CultureInfo.InvariantCulture)  %>" />
                                            <label for="<%= countrolID.SafeHtmlEncode() %>"><%= MoneyHelper.FormatWithCurrencySymbol( amounts.Currency, amount).SafeHtmlEncode()  %></label>
                                        </li>
                                        <%
                                    }
                                }
                            } 
                         %>
                            
                        </ul>
                        
	                </ControlPart>
                </ui:InputField>
                <script type="text/javascript">
                    function validateICEPAYSMSAmount() {
                        var value = this;

                        return true;
                    }
                </script>
                
                <br />
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithICEPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#fldCurrencyAmount').hide();
        $('#fldICEPAYSMSAmount :radio').attr('selected', false);
        $('#formICEPAYPayCard').initializeForm();

        function syncSelectedSMSAmount() {
            var $input = $('#fldICEPAYSMSAmount input[type="radio"]:visible:checked');
            if ($input.length == 0) {
                $('#txtICEPAYSMSAmount').val('');
            } else {
                var currency = $input.data("Currency") || $input.attr("data-Currency");
                var amount = $input.data("Amount") || $input.attr("data-Amount");
                $('#fldCurrencyAmount #ddlCurrency').val(currency).trigger('change');
                $('#fldCurrencyAmount :hidden[name="currency"]').val(currency);
                $('#fldCurrencyAmount #txtAmount').val(amount);
                $('#txtICEPAYSMSAmount').val(amount);
            }
        }

        $('#btnDepositWithICEPayCard').click(function (e) {
            e.preventDefault();

            syncSelectedSMSAmount();

            if (!$('#formICEPAYPayCard').valid() || !isDepositInputFormValid())
                return false;

            $('#hPrepareTransactionIssuer').val($('#ddlICEPAYiDealIssuer').val());

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= GetExistingPayCard().ID.ToString() %>';
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithICEPayCard').toggleLoadingSpin(false);
            });
        });

        $('#ddlICEPAYSMSCountry').change(function () {
            $('#fldICEPAYSMSAmount ul li').hide();
            $('#fldICEPAYSMSAmount ul li[data-InternalID="' + $(this).val() + '"]').show();
        }).trigger('change');

        $('#fldICEPAYSMSAmount :radio').click(function () {
            setTimeout(syncSelectedSMSAmount, 0);
        });
    });
//]]>
</script>