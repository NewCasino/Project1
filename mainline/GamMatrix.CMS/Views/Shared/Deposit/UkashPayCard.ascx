<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Ukash)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("Ukash is not configrured in GmCore correctly, missing dummy pay card.");
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
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Ukash.Title) %>" Selected="true">
            <form id="formUkashPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveUkash", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">

                <%: Html.Hidden( "sid", "") %>

                <% if (Settings.Ukash_AllowPartialDeposit)
                   { %>
                <%: Html.WarningMessage(this.GetMetadata(".Warning_Message"), false, new { @id="ukashMessage"})%>
                <% } %>
                <% else %>
                <% { %>
                <%: Html.WarningMessage(this.GetMetadata(".Warning_Message2"), false, new { @id="ukashMessage"})%>
                <% } %>

                <%------------------------
                    Ukash Number
                -------------------------%>    
                <ui:InputField ID="fldUkashNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".UkashNumber_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("ukashNumber", "", new 
                        { 
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".UkashNumber_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>

                <% if (Settings.Ukash_AllowPartialDeposit) 
                   { %>
                <%------------------------
                    Ukash Value
                -------------------------%>    
                <ui:InputField ID="fldUkashValue" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".UkashValue_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("ukashValue", "", new 
                        { 
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".UkashValue_Empty"))
                            .Custom("validateUkashValue") 
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>
                <script type="text/javascript">
                    //<![CDATA[
                    function validateUkashValue() {
                        var value = this;
                        if (parseFloat(value) > 0.00)
                            return true;
                        return '<%= this.GetMetadata(".UkashValue_Invalid").SafeJavascriptStringEncode() %>';
                    }
                    //]]>
                </script>
                <% } %>
                

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithUkashPayCard", @class="ContinueButton button" })%>
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

        $('#formUkashPayCard').initializeForm();

        <% if (Settings.Ukash_AllowPartialDeposit) 
        { %>
        $('#fldUkashValue input[name="ukashValue"]').change(function () {
            var num = $(this).val();
            num = num.toString().replace(/[^(\.|\d)]/g, '');
            if (num == "" || isNaN(num))
                $(this).val("0.00");
            else
                $(this).val(parseFloat(num).toFixed(2));
        });
        <% } %>

        $('#btnDepositWithUkashPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formUkashPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm('<%= GetDummyPayCard().ID.ToString() %>', function () {
                $('#btnDepositWithUkashPayCard').toggleLoadingSpin(false);
            });
        });


        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            $('#formUkashPayCard input[name="sid"]').val(sid);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithUkashPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithUkashPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formUkashPayCard').ajaxForm(options);
            $('#formUkashPayCard').submit();
        });
    });
    //]]>
</script>
