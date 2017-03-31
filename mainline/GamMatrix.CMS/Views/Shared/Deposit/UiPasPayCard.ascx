<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.UiPas)
            .Where(e => !e.IsDummy)
            .OrderByDescending(e => e.Ins).FirstOrDefault();
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>

        <%---------------------------------------------------------------
            UiPas
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards"  IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/UIPAS.Title) %>"  Selected="true">
            <form id="formUiPasPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

                <%------------------------
                    Account ID
                -------------------------%>    
                <ui:InputField ID="fldAccountID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".AccountID_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>

                        <% PayCardInfoRec paycard = GetExistingPayCard(); %>
                        <%: Html.TextBox("identityNumber", ((paycard == null) ? string.Empty : paycard.DisplayNumber), new 
                        { 
                            @maxlength = 16,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().RequiredIf( "isAccountIDRequired", this.GetMetadata(".AccountID_Empty"))
                            .Custom("validateUiPasAccountID") 
                        } 
                        )%>
                        <%: Html.Hidden("uiPasPayCardID", ((paycard == null) ? string.Empty : paycard.ID.ToString())) %>
	                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(function () {
                        if (!isAccountIDRequired()) {
                            $('#fldAccountID input[name="identityNumber"]').attr('readonly', true);
                            if ($('#fldAccountID input[name="identityNumber"]').val().length == 0)
                                $('#fldAccountID').hide();
                        }
                    });
                    function isAccountIDRequired() {
                        return $('#fldAccountID input[name="uiPasPayCardID"]').val().length == 0;
                    }
                    function validateUiPasAccountID() {
                        var value = this;
                        if (!isAccountIDRequired())
                            return true;
                        var ret = /^(.{7,16})$/.exec(value);
                        if (ret == null || ret.length == 0)
                            return '<%= this.GetMetadata(".AccountID_Invalid").SafeJavascriptStringEncode() %>';
                        return true;
                    }
                    //]]>
                </script>

                <%------------------------
                    Password
                -------------------------%>    
                <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("password", "", new 
                        { 
                            @maxlength = 16,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".Password_Empty"))
                            .Custom("validateUiPasPassword") 
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    function validateUiPasPassword() {
                        var value = this;
                        var ret = /^(.{8,16})$/.exec(value);
                        if (ret == null || ret.length == 0)
                            return '<%= this.GetMetadata(".Password_Invalid").SafeJavascriptStringEncode() %>';
                        return true;
                    }
                    //]]>
                </script>


                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithUiPasPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    //<![CDATA[
    $(document).ready(function () {
        $('#formUiPasPayCard').initializeForm();

        $('#btnDepositWithUiPasPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formUiPasPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#fldAccountID input[name="uiPasPayCardID"]').val();
            if (payCardID.length > 0) {
                // <%-- post the prepare form --%>   
                tryToSubmitDepositInputForm(payCardID, function () {
                    $('#btnDepositWithUiPasPayCard').toggleLoadingSpin(false);
                });
                return;
            }

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {

                    if (!json.success) {
                        $('#btnDepositWithUiPasPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    $('#fldAccountID input[name="uiPasPayCardID"]').val(json.payCardID);
                    $('#fldAccountID input[name="identityNumber"]').attr('readonly', true);

                    // <%-- post the prepare form --%>   
                    tryToSubmitDepositInputForm(json.payCardID, function () {
                        $('#btnDepositWithUiPasPayCard').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formUiPasPayCard').ajaxForm(options);
            $('#formUiPasPayCard').submit();
        });

        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveSecurityKey" }).SafeJavascriptStringEncode() %>';
            var data = { sid: sid, securityKey: $('#fldPassword input[name="password"]').val() };
            jQuery.getJSON(url, data, function (json) {
                if (!json.success) {
                    showDepositError(json.error);
                    return;
                }
            });
        });
    });
        //]]>
</script>
