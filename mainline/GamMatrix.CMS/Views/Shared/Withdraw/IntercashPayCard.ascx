<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>


<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="Finance" %>

<script language="C#" runat="server" type="text/C#">
    private int MaxAllowedCards { get { return 4; } }
    private cmUser CurrentUser { get; set; }
    private List<PayCardInfoRec> IntercashPayCards { get; set; }
    protected override void OnInit(EventArgs e)
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        this.CurrentUser = ua.GetByID(Profile.AsCustomProfile().UserID);

        this.IntercashPayCards = GamMatrixClient.GetPayCards(VendorID.Intercash);
        base.OnInit(e);
    }

    private string GetCountryName()
    {
        CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault( c => c.InternalID == this.CurrentUser.CountryID);
        if (country != null)
            return country.DisplayName;

        return string.Empty;
    }

    private SelectList GetCurrencyList()
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .Where( c => this.Model.SupportedCurrencies.Exists(c.ISO4217_Alpha) )
                        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                        .ToList();
        string userCurrency = Profile.AsCustomProfile().UserCurrency;
        if( list.Exists( c => string.Equals( c.Key, userCurrency) ) )
            return new SelectList(list, "Key", "Value", userCurrency);
        else
            return new SelectList(list, "Key", "Value", "EUR");
    }
</script>


<%---------------------------------------------------------------
Intercash
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
                Existing Cards
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
            <form id="formIntercashPayCard" onsubmit="return false">

                <%---------------------------------------------------------------
                        Select a card
                ----------------------------------------------------------------%>
                <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".WithdrawTo").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <ul id="paycards-selector">
                            <% 
                                foreach (PayCardInfoRec payCard in this.IntercashPayCards)
                                {
                                    if (payCard.IsDummy)
                                        continue;
                                    %>
                                    <li>
                                        <input type="radio" name="existingPayCard" value="<%= payCard.ID %>" id="payCard_<%= payCard.ID %>"/>
                                        <label for="payCard_<%= payCard.ID %>" dir="ltr">
                                            <%= payCard.DisplayNumber.SafeHtmlEncode() %>
                                        </label>
                                    </li>
                                    <%
                                }
                             %>            
                        </ul>
                        <%: Html.Hidden("existingPayCardID", "", new 
                        { 
                            @id = "hExistingPayCardID",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".ExistingCard_Empty")) 
                        }) %>
                    </ControlPart>
                </ui:InputField>

             
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithIntercashPayCard" })%>
                </center>
            </form>
        </ui:Panel>

        

        <%---------------------------------------------------------------
                Issue Card
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabIssue" Caption="<%$ Metadata:value(.Tab_IssuePayCard) %>">
            <form id="formIssueIntercashPayCard" method="post" onsubmit="return false">

            <%---------------------------------------------------------------
                    Currency
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldCurrency" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.DropDownList("currency", GetCurrencyList(), new { @id="ddlIssueCardCurrency"  })%>
                </ControlPart>
            </ui:InputField>

            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnIssuePayCard" })%>
            </center>


            <%: Html.WarningMessage( this.GetMetadata(".CheckYourProfile"), true )  %>
           
            <%---------------------------------------------------------------
                    First name
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldFirstname" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("firstname", this.CurrentUser.FirstName, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    Surname
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldSurname" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Surname_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("surname", this.CurrentUser.Surname, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    Email
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("email", this.CurrentUser.Email, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    Address 1
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldAddress1" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Address1_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("address1", this.CurrentUser.Address1, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    Address 2
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldAddress2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Address2_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("address2", this.CurrentUser.Address2, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    City
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldCity" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".City_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("city", this.CurrentUser.City, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    Country
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldCountry" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Country_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("city", GetCountryName(), new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>

            <%---------------------------------------------------------------
                    Postal Code
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldPostalCode" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".PostalCode_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("postalCode", this.CurrentUser.Zip, new { @readonly = "readonly" })%>
                </ControlPart>
            </ui:InputField>


            
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formIntercashPayCard').initializeForm();
        $('#formIssueIntercashPayCard').initializeForm();

        // <%-- paycards-selector --%>
        $('#hExistingPayCardID').val('');
        $('#paycards-selector input[name="existingPayCard"]').click(function () {
            $('#hExistingPayCardID').val($(this).val());
            InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
        });

        // <%-- tabs --%>
        if ( $('#paycards-selector > li').length > 0) {
            $('#tabbedPayCards').showTab('tabRecentCards', true);
            $('#tabbedPayCards').selectTab('tabRecentCards');
        } else {
            $('#tabbedPayCards').selectTab('tabIssue');
            $('#tabbedPayCards').showTab('tabIssue', true);
            $('#tabbedPayCards').showTab('tabRecentCards', false);
        }

    <%  // if the card number exceeds the max allowed cards
        if( this.IntercashPayCards.Count( p => !p.IsDummy ) > MaxAllowedCards )
        { %>
            $('#tabbedPayCards').showTab('tabIssue', false);
    <%  } %>

        $('#btnWithdrawWithIntercashPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() || !$('#formIntercashPayCard').valid())
                return;

            // <%-- Temp Reference --%>
            $('#hRepareTransactionRequestCreditCurrency').val('');

            $('#btnWithdrawWithIntercashPayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm($('#fldExistingPayCard input[name="existingPayCardID"]').val()
            , function () { $('#btnWithdrawWithIntercashPayCard').toggleLoadingSpin(false); });
        });

<% 
    PayCardInfoRec payCard = this.IntercashPayCards.FirstOrDefault(p => p.IsDummy);
    if (payCard != null)
    { %>
        $('#btnIssuePayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() )
                return;

            // <%-- RequestCreditCurrency --%>
            $('#hRepareTransactionRequestCreditCurrency').val($('#ddlIssueCardCurrency').val());

            $(this).toggleLoadingSpin(true);

            $('#btnIssuePayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm( '<%= payCard.ID %>', function () { $('#btnIssuePayCard').toggleLoadingSpin(false); });
        });
 <% }
    else
    { %>
        $('#tabbedPayCards').showTab('tabIssue', false);
 <% } %>
        
    });


</script>

