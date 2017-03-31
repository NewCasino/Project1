<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }

    protected override void OnLoad(EventArgs e)
    {
        PayCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Neteller)
            .OrderByDescending(p => p.Ins).FirstOrDefault();
        base.OnLoad(e);
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Neteller
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards"  IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Neteller.Title) %>"  Selected="true">
            <form id="formNetellerPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

                <%------------------------
                    Account ID
                -------------------------%>    
                <ui:InputField ID="fldAccountID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".AccountID_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <% if(PayCard == null) {%>
                        <span class="quickregister-wraper"><%=this.GetMetadata(".QuickRegister_Label").HtmlEncodeSpecialCharactors() %></span>
                        <%} %>
                        <%: Html.TextBox("identityNumber", ((PayCard == null) ? string.Empty : PayCard.DisplayNumber), new 
                        { 
                            @maxlength = 100,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().RequiredIf( "isAccountIDRequired", this.GetMetadata(".AccountID_Empty"))
                            .Custom("validateNetellerAccountID") 
                        } 
                        )%>
                        <%: Html.Hidden("netellerPayCardID", ((PayCard == null) ? string.Empty : PayCard.ID.ToString())) %>
                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(function () {
                        if (!isAccountIDRequired()) {
                            $('#fldAccountID input[name="identityNumber"]').attr('readonly', true);
                            if( $('#fldAccountID input[name="identityNumber"]').val().length == 0 )
                                $('#fldAccountID').hide();
                        }
                    });
                    function isAccountIDRequired() {
                        return $('#fldAccountID input[name="netellerPayCardID"]').val().length == 0;
                    }
                    function validateNetellerAccountID() {
                        var value = this;
                        if (!isAccountIDRequired())
                            return true;
                        var account_ret = /^(.{12,12})$/.test(value);
                        var email_ret = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value);
                        if (!account_ret && !email_ret) {
                            return '<%= this.GetMetadata(".AccountID_Invalid").SafeJavascriptStringEncode() %>';
                        }  
                        return true;
                    }
                    //]]>
                </script>

                <%------------------------
                    Security Key
                -------------------------%>    
                <ui:InputField ID="fldSecurityKey" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".SecurityKey_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("securityKey", "", new 
                        { 
                            @maxlength = 6,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".SecurityKey_Empty"))
                            .Custom("validateNelellerSecurityKey") 
                        } 
                        )%>
                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    function validateNelellerSecurityKey() {
                        var value = this;
                        var ret = /^(.{6,6})$/.exec(value);
                        if (ret == null || ret.length == 0)
                            return '<%= this.GetMetadata(".SecurityKey_Invalid").SafeJavascriptStringEncode() %>';
                        return true;
                    }
                    //]]>
                </script>


                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithNetellerPayCard",@class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
//<![CDATA[
$(document).ready(function () {
    $('#formNetellerPayCard').initializeForm();

    $('#btnDepositWithNetellerPayCard').click(function (e) {
        e.preventDefault();
        if (!isDepositInputFormValid() || !$('#formNetellerPayCard').valid())
            return false;

        $(this).toggleLoadingSpin(true);

        var payCardID = $('#fldAccountID input[name="netellerPayCardID"]').val();
        if (payCardID.length > 0) {
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithNetellerPayCard').toggleLoadingSpin(false);
            });
            return;
        }

        var options = {
            dataType: "json",
            type: 'POST',
            success: function (json) {
                
                if (!json.success) {
                    $('#btnDepositWithNetellerPayCard').toggleLoadingSpin(false);
                    showDepositError(json.error);
                    return;
                }
                // <%-- the card is successfully registered, now prepare the transaction --%>
                $('#fldAccountID input[name="netellerPayCardID"]').val(json.payCardID);
                $('#fldAccountID input[name="identityNumber"]').attr('readonly', true);

                // <%-- post the prepare form --%>   
                tryToSubmitDepositInputForm(json.payCardID, function () {
                    $('#btnDepositWithNetellerPayCard').toggleLoadingSpin(false);
                });
            },
            error: function (xhr, textStatus, errorThrown) {
                $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                showDepositError(errorThrown);
            }
        };
        $('#formNetellerPayCard').ajaxForm(options);
        $('#formNetellerPayCard').submit();
    });

    // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
    $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
        var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveSecurityKey" }).SafeJavascriptStringEncode() %>';
        var data = { sid: sid, securityKey: $('#fldSecurityKey input[name="securityKey"]').val() };
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
