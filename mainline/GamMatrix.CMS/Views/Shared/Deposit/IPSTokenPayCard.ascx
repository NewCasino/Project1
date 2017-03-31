<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPSToken)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("IPS is not configrured in GmCore correctly, missing dummy pay card.");
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
            UKash
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/IPSToken.Title) %>" Selected="true">
            <form id="formIPSPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveIPSToken", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">

                <%: Html.Hidden( "sid", "") %>

                <%: Html.WarningMessage(this.GetMetadata(".Warning_Message"))  %>

                <%------------------------
                    Token
                -------------------------%>    
                <ui:InputField ID="fldUkashNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Token_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("token", "", new 
                        { 
                            @id = "txtIPSToken",
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".Token_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>

                <%------------------------
                    Check Digits
                -------------------------%>    
                <ui:InputField ID="fldIPSCheckDigit" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CheckDigit_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("checkDigit", "", new 
                        {
                            @maxlength = 10,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".CheckDigit_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>

                

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithIPSPayCard", @class="ContinueButton button" })%>
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

        $('#formIPSPayCard').initializeForm();

        $('#formIPSPayCard input').allowNumberOnly();

        $('#btnDepositWithIPSPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formIPSPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm('<%= GetDummyPayCard().ID.ToString() %>', function () {
                $('#btnDepositWithIPSPayCard').toggleLoadingSpin(false);
            });
        });


        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            $('#formIPSPayCard input[name="sid"]').val(sid);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithIPSPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithIPSPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formIPSPayCard').ajaxForm(options);
            $('#formIPSPayCard').submit();
        });
    });
//]]>
</script>
