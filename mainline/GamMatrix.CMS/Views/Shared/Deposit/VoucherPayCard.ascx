<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(VendorID.Voucher)
            .Where( p => p.IsDummy )
            .FirstOrDefault();

        if (payCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return payCard;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
         <%---------------------------------------------------------------
            Voucher
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabVoucherPayCard" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Voucher.Title) %>" Selected="true">
            <form id="formVoucherPayCard" onsubmit="return false">

                <%------------------------
                    Voucher Card Number
                -------------------------%>    
                <ui:InputField ID="fldVoucherCardNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".VoucherCardNumber_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        
                        <table cellpadding="2" cellspacing="0" border="0" dir="ltr">
                            <tr>
                                <td>
                                <%: Html.TextBox( "part1", "", new 
                                {
                                    @id = "part1",
                                    @next = "part2",
                                    @maxlength = 4,
                                    @style = "width:35px",
                                })  %>
                                </td>
                                <td>
                                <%: Html.TextBox( "part2", "", new 
                                {
                                    @id = "part2",
                                    @next = "part3",
                                    @maxlength = 4,
                                    @style = "width:35px",
                                })  %>
                                </td>
                                <td>
                                <%: Html.TextBox( "part3", "", new 
                                {
                                    @id = "part3",
                                    @next = "part4",
                                    @maxlength = 4,
                                    @style = "width:35px",
                                })  %>
                                </td>
                                <td>
                                <%: Html.TextBox( "part4", "", new 
                                {
                                    @id = "part4",
                                    @next = "txtVoucherSecurityKey",
                                    @maxlength = 4,
                                    @style = "width:35px",
                                })  %>
                                </td>
                            </tr>
                        </table>
                        <%: Html.Hidden("voucherNumber", "", new 
                            {
                                @id = "txtVoucherCardNumber",
                                @validator = ClientValidators.Create()
                                .Required(this.GetMetadata(".VoucherCardNumber_Invalid"))
                                .Custom("validateVoucherCardNumber")
                            } 
                            )%>                      
	                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                //<![CDATA[
                    $(document).ready(function () {
                        // <%-- the keypress event --%>
                        $('#fldVoucherCardNumber input[id^="part"]').keypress(function (e) {
                            if (e.which >= 48 && e.which <= 57) {
                                setTimeout((function (o) {
                                    return function () {
                                        if (o.val().length >= 4) {
                                            $(document.getElementById(o.attr('next'))).focus().select();
                                        }
                                    };
                                })($(this)), 0);
                            }
                            else if (e.which == 0 || e.which == 8) {
                            }
                            else
                                e.preventDefault();
                        });

                    });

                    // <%-- combine the Voucher number --%>
                    $('#fldVoucherCardNumber table input[id^="part"]').change(function () {
                        var code = $('#fldVoucherCardNumber #part1').val()
                                + $('#fldVoucherCardNumber #part2').val()
                                + $('#fldVoucherCardNumber #part3').val()
                                + $('#fldVoucherCardNumber #part4').val();

                        $('#txtVoucherCardNumber').val(code);
                        if( code.length >= 16 )
                            InputFields.fields['fldVoucherCardNumber'].validator.element($('#txtVoucherCardNumber'));
                    });

                    function validateVoucherCardNumber() {
                        var value = this;
                        var ret = /^(\d{16,16})$/.exec(value);
                        if (ret == null || ret.length == 0)
                            return '<%= this.GetMetadata(".VoucherCardNumber_Invalid").SafeJavascriptStringEncode() %>';
                        return true;
                    }
                //]]>
                </script>

                <%------------------------
                    Validation Code
                -------------------------%>    
                <ui:InputField ID="fldValidationCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".ValidationCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        
                        <%: Html.TextBox("securityKey", "", new 
                        {
                            @id = "txtVoucherSecurityKey",
                            @maxlength = "6",
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".ValidationCode_Empty"))
                            .Custom("validateVoucherValidationCode")
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                //<![CDATA[
                    $(document).ready(function () {
                        // <%-- the keypress event --%>
                        $('#txtVoucherSecurityKey').keypress(function (e) {
                            if (e.which >= 48 && e.which <= 57) {
                            }
                            else if (e.which == 0 || e.which == 8) {
                            }
                            else
                                e.preventDefault();
                        });
                    });

                    function validateVoucherValidationCode() {
                        var value = this;
                        var ret = /^\d{6,6}$/.exec(value);
                        if (ret == null || ret.length == 0)
                            return '<%= this.GetMetadata(".ValidationCode_Invalid").SafeJavascriptStringEncode() %>';
                        return true;
                    }
                //]]>
                </script>
                

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithVoucherPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formVoucherPayCard').initializeForm();

        $('#btnDepositWithVoucherPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formVoucherPayCard').valid() )
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= GetExistingPayCard().ID.ToString() %>';
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithVoucherPayCard').toggleLoadingSpin(false);
            });
        });

        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveVoucher" }).SafeJavascriptStringEncode() %>';
            var data = { sid: sid,
                securityKey: $('#fldValidationCode input[name="securityKey"]').val(),
                voucherNumber: $('#fldVoucherCardNumber input[name="voucherNumber"]').val()
            };
            jQuery.getJSON(url, data, function (json) {
                if (!json.success) {
                    showDepositError(json.error);
                    return;
                }
            });
        });
    });
</script>