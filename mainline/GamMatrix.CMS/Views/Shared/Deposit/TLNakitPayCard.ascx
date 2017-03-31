<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.TLNakit)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("TLNakit is not configrured in GmCore correctly, missing dummy pay card.");
        return payCard;
    }
</script>


<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <%---------------------------------------------------------------
            UKash
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/TLNakit.Title) %>" Selected="true">
            <form id="formTLNakitPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveTLNakit", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">

                <%: Html.Hidden( "sid", "") %>

                <%------------------------
                    TLNakit Card Number
                -------------------------%>    
                <ui:InputField ID="fldTLNakitNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("cardNumber", "", new 
                        { 
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".CardNumber_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithTLNakitPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#fldCurrencyAmount #ddlCurrency > option[value!="TRY"]').remove();
        $('#fldCurrencyAmount #ddlCurrency').val('TRY').trigger('change');

        $('#formTLNakitPayCard').initializeForm();


        $('#btnDepositWithTLNakitPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formTLNakitPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm('<%= GetDummyPayCard().ID.ToString() %>', function () {
                $('#btnDepositWithTLNakitPayCard').toggleLoadingSpin(false);
            });
        });


        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            $('#formTLNakitPayCard input[name="sid"]').val(sid);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithTLNakitPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithTLNakitPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formTLNakitPayCard').ajaxForm(options);
            $('#formTLNakitPayCard').submit();
        });
    });
//]]>
</script>
</ui:MinifiedJavascriptControl>