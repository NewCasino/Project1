<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.BoCash)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("BoCash is not configrured in GmCore correctly, missing dummy pay card.");
        return payCard;
    }

    private string GetSelector()
    {
        StringBuilder script = new StringBuilder();
        foreach( string currency in this.Model.SupportedCurrencies.GetAll() )
        {
            if( this.Model.SupportedCurrencies.Exists(currency) )
                script.AppendFormat("*[value=\"{0}\"],", currency);
        }
        if (script.Length > 0)
            script.Remove(script.Length - 1, 1);
        return script.ToString();
    }
</script>


<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <%---------------------------------------------------------------
            Bocash
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/BoCash.Title) %>" Selected="true">
            <form id="formBoCashPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveBocash", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">

                <%: Html.Hidden( "sid", "") %>

                <%: Html.WarningMessage(this.GetMetadata(".Warning_Message"), false, new { @id="bocashMessage"})%>

                <%------------------------
                    Bocash Number
                -------------------------%>    
                <ui:InputField ID="fldUkashNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".BocashCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("bocashCode", "", new 
                        { 
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".BocashCode_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>


                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithBocashPayCard" })%>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#fldCurrencyAmount #ddlCurrency > option').not('<%= GetSelector().SafeJavascriptStringEncode() %>').remove();
        $('#fldCurrencyAmount #ddlCurrency').val('EUR').trigger('change');

        $('#formBoCashPayCard').initializeForm();

    

        $('#btnDepositWithBocashPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formBoCashPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm('<%= GetDummyPayCard().ID.ToString() %>', function () {
                $('#btnDepositWithBocashPayCard').toggleLoadingSpin(false);
            });
        });


        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            $('#formBoCashPayCard input[name="sid"]').val(sid);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithBocashPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithBocashPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formBoCashPayCard').ajaxForm(options);
            $('#formBoCashPayCard').submit();
        });
    });
//]]>
</script>
