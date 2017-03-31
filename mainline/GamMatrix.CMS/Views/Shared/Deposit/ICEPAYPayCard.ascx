<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

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

    private SelectList GetIssuerList()
    {
        Dictionary<string, string> list = new Dictionary<string, string>();
        list["ABNAMRO"] = this.GetMetadata(".Issuer_ABNAMRO");
        list["ASNBANK"] = this.GetMetadata(".Issuer_ASNBANK");
        list["FRIESLAND"] = this.GetMetadata(".Issuer_FRIESLAND");
        list["ING"] = this.GetMetadata(".Issuer_ING");
        list["RABOBANK"] = this.GetMetadata(".Issuer_RABOBANK");
        list["SNSBANK"] = this.GetMetadata(".Issuer_SNSBANK");
        list["SNSREGIOBANK"] = this.GetMetadata(".Issuer_SNSREGIOBANK");
        list["TRIODOSBANK"] = this.GetMetadata(".Issuer_TRIODOSBANK");
        list["VANLANSCHOT"] = this.GetMetadata(".Issuer_VANLANSCHOT");
        
        object selectedValue = null;
        foreach( string v in list.Keys ){
            selectedValue = v;
            break;
        }
        return new SelectList(list, "Key", "Value", selectedValue);
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            ICEPay
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Selected="true">
            <form id="formICEPAYPayCard" onsubmit="return false">

            <% if( string.Equals( this.Model.UniqueName, "ICEPAY_IDeal", StringComparison.InvariantCultureIgnoreCase) )
               { %>
                <ui:InputField ID="fldIssuer" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Issuer_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.DropDownList("issuer", GetIssuerList(), new { @id = "ddlICEPAYiDealIssuer" })%>                                             
	                </ControlPart>
                </ui:InputField>
             <% } %>

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
        $('#formICEPAYPayCard').initializeForm();

        $('#btnDepositWithICEPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $('#hPrepareTransactionIssuer').val($('#ddlICEPAYiDealIssuer').val());

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= GetExistingPayCard().ID.ToString() %>';
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithICEPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>
