<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Runtime.Serialization.Formatters.Binary" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    private string depositTypeCode = string.Empty;

    private PayCardInfoRec GetExistingPayCard()
    {
        return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.InPay)
            .Where(p => p.IsDummy && p.ActiveStatus == ActiveStatus.Active)
            .OrderByDescending(e => e.Ins).FirstOrDefault();
    }

    private List<InPayCountry> _InPayCountries = null;
    private List<InPayCountry> InPayCountries
    {
        get
        {
            if (_InPayCountries != null)
                return _InPayCountries;

            try
            {
                _InPayCountries = InPayClient.GetInPayCountryAndBanks();
            }
            catch (GmException ge)
            {
                var message = ge.TryGetFriendlyErrorMsg();
                if (message.IndexOf("SYS_1170", StringComparison.InvariantCultureIgnoreCase) >= 0)
                    _InPayCountries = new List<InPayCountry>();
            }
            catch
            {
                throw;
            }
            return _InPayCountries;
        }
    }

    private SelectList GetInPayBankList()
    {
        var selectedValue = InPayCountries.FirstOrDefault().CountryCode;
        var userCountry = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == Profile.UserCountryID);
        if (userCountry != null)
            selectedValue = userCountry.ISO_3166_Alpha2Code;
        //selectedValue = "BA";

        var selectedCountry = InPayCountries.FirstOrDefault(c => c.CountryCode == selectedValue);
        if (selectedCountry == null)
        {
            selectedCountry = InPayCountries.FirstOrDefault(c => c.CountryCode == "DE");//default to DE, Germany
            if (selectedCountry == null)
                _InPayCountries.Clear();
        }

        var list = selectedCountry.Banks.Select(b => new { Key = b.ID, Value = b.Name }).ToList();
        return new SelectList(list
            , "Key"
            , "Value"
            );
    }

    private string PaymentTitle;
    private string PaymentUniqueName;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        //string paymentTitleMetadataPath = string.Format("/Metadata/PaymentMethod/{0}.Title", this.Model.UniqueName);
        PaymentTitle = this.GetMetadata(".Title");

        if (InPayCountries.Count == 0)
        {
            divError.Visible = true;
            tabbedPayCards.Visible = false;
            return;
        }

        divError.Visible = false;
        tabbedPayCards.Visible = true;

        PaymentUniqueName = this.Model.UniqueName;

        tabRecentCards.Attributes["Caption"] = PaymentTitle;

    }
</script>


<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>
        <%---------------------------------------------------------------
            InPay
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Selected="true">
            <%--<form id="formInPayPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "ProcessInPayTransaction", @vendorID=this.Model.VendorID, @paymentMethodName = this.Model.UniqueName }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">--%>
                <%: Html.Hidden( "sid", "") %>
                <%: Html.Hidden("paymentName", PaymentUniqueName)%>
                <%: Html.Hidden("paymentType", depositTypeCode)%>
                <% var paycard = GetExistingPayCard(); %>
                <%: Html.Hidden("inPayPayCardID", ((paycard == null) ? string.Empty : paycard.ID.ToString())) %>

                <%------------------------------------------
                    Bank ID
                 -------------------------------------------%>
                <ui:InputField ID="fldInPayBankID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".BankID_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.DropDownList("inPayBankID", GetInPayBankList(), new { @class = "ddlInPayBankID", @id = "ddlInPayBankID" })%>
	                </ControlPart>
                </ui:InputField>
                
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnDepositWithInPayPayCard" })%>
                </center>
            <%--</form>--%>
        </ui:Panel>
    </tabs>
</ui:TabbedContent>

<ui:MinifiedJavascriptControl runat="server" ID="scriptDepositWithEnterCashPayCard" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        $(function () {
            //showDepositConfirmation('f514b3a2a38d4b138e3b2089a1ed52ac');

            //$('#formInPayPayCard').initializeForm();

            $('#btnDepositWithInPayPayCard').click(function (e) {
                e.preventDefault();
                if (!isDepositInputFormValid())
                    return false;

                $(this).toggleLoadingSpin(true);

                // <%-- post the prepare form --%>   
                var payCardID = $('#formProcessInPayTransaction input[name="inPayPayCardID"]').val();
                tryToSubmitProcessInPayForm(payCardID, function () {
                    $('#btnDepositWithInPayPayCard').toggleLoadingSpin(false);
                });
            });
        });

    </script>
</ui:MinifiedJavascriptControl>

<div runat="server" id="divError">
    <%: Html.H1(PaymentTitle)%>
    <ui:Panel runat="server" ID="pnError">
        <%: Html.WarningMessage(this.GetMetadata(".CountryNotSupported")) %>

        <center>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnBackFromDepositWithInPayPayCard", @onclick = "backToDepositIndexPage(); return false;" })%>
</center>
        <script type="text/javascript">
            function backToDepositIndexPage() {
                window.location = '<%= this.Url.RouteUrl("Deposit").SafeJavascriptStringEncode() %>';
                return false;
            }
        </script>
    </ui:Panel>
</div>
