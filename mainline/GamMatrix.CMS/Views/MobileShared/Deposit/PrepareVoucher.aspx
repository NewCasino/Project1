<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareVoucherViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareVoucher">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                Voucher
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".Voucher_Account").SafeHtmlEncode() %>
	            </legend>
				
	            <ul class="FormList">
                    <li class="FormItem">
                    </li>
		            <li class="FormItem">
			            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".VoucherCardNumber_Label").SafeHtmlEncode() %></label>
                        <ul class="Container Cols-4">
                            <li class="Container Col">
                                <%: Html.TextBox("part1", "", new Dictionary<string, object>()  
                                { 
                                    { "class", "FormInput" },
                                    { "id", "part1" },
                                    { "next", "part2" },
                                    { "maxlength", "4" },
                                    { "data-validator", ClientValidators.Create()
                                        .Required(this.GetMetadata(".VoucherCardNumber_Empty"))
                                        .Custom("__validateVoucherCardNumber") }
                                }) %>
                            </li>
                            <li class="Container Col">
                                <%: Html.TextBox("part2", "", new Dictionary<string, object>()  
                                { 
                                    { "class", "FormInput" },
                                    { "id", "part2" },
                                    { "next", "part3" },
                                    { "maxlength", "4" },
                                    { "data-validator", ClientValidators.Create()
                                        .Required(this.GetMetadata(".VoucherCardNumber_Empty"))
                                        .Custom("__validateVoucherCardNumber") }
                                }) %>
                            </li>
                            <li class="Container Col">
                                <%: Html.TextBox("part3", "", new Dictionary<string, object>()  
                                { 
                                    { "class", "FormInput" },
                                    { "id", "part3" },
                                    { "next", "part4" },
                                    { "maxlength", "4" },
                                    { "data-validator", ClientValidators.Create()
                                        .Required(this.GetMetadata(".VoucherCardNumber_Empty"))
                                        .Custom("__validateVoucherCardNumber") }
                                }) %>
                            </li>
                            <li class="Container Col">
                                <%: Html.TextBox("part4", "", new Dictionary<string, object>()  
                                { 
                                    { "class", "FormInput" },
                                    { "id", "part4" },
                                    { "next", "depositSecurityKey" },
                                    { "maxlength", "4" },
                                    { "data-validator", ClientValidators.Create()
                                        .Required(this.GetMetadata(".VoucherCardNumber_Empty"))
                                        .Custom("__validateVoucherCardNumber") }
                                }) %>
                            </li>
                        </ul>
                         <%: Html.Hidden("voucherNumber", "", new Dictionary<string, object>()  
                            { 
                                //{ "class", "FormInput" },
                                { "id", "depositVoucherNumber" },
                                //{ "style", "display: none" },
                                //{ "required", "required" },
                                //{ "autocomplete", "off" },
                                //{ "dir", "ltr" },
                                //{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".VoucherCardNumber_Empty")).Custom("__validateVoucherCardNumber") }
                            }) %>
                        <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
		            <li class="FormItem">
			            <label class="FormLabel" for="depositSecurityKey"><%= this.GetMetadata(".ValidationCode_Label").SafeHtmlEncode()%></label>
                        <%: Html.TextBox("securityKey", "", new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositSecurityKey" },
                                { "maxlength", "6" },
                                { "autocomplete", "off" },
                                { "dir", "ltr" },
                                { "required", "required" },
								{ "placeholder", this.GetMetadata(".ValidationCode_Label") },
                                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ValidationCode_Empty")).Custom("__validateVoucherValidationCode") }
                            }) %>
			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
	            </ul>
            </fieldset>

            <input type="hidden" name="payCardID" value="<%= Model.HasPayCards() ? Model.ExistingPayCard.ID.ToString() : string.Empty %>" />

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
</ui:MinifiedJavascriptControl>
<script type="text/javascript">
    $(document).ready(function () {
        // <%-- the keypress event --%>
        $('#formPrepareVoucher input[id^="part"]').keypress(function (e) {
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

        $('#txtVoucherSecurityKey').keypress(function (e) {
            if (e.which >= 48 && e.which <= 57) {
            }
            else if (e.which == 0 || e.which == 8) {
            }
            else
                e.preventDefault();
        });
    });

    // <%-- combine the Voucher number --%>
    $('#formPrepareVoucher input[id^="part"]').change(function () {
        var code = $('#formPrepareVoucher #part1').val()
                + $('#formPrepareVoucher #part2').val()
                + $('#formPrepareVoucher #part3').val()
                + $('#formPrepareVoucher #part4').val();

        $('#depositVoucherNumber').val(code);
        if (code.length >= 16) {
            $('#formPrepareVoucher').validate().element($('#depositVoucherNumber'));
        }
    });

    function __validateVoucherCardNumber() {
        var value = $('#depositVoucherNumber').val();
        
        var ret = /^(\d{16,16})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".VoucherCardNumber_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }

    function __validateVoucherValidationCode() {
        var value = this;
        var ret = /^\d{6,6}$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".ValidationCode_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }

    $(CMS.mobile360.Generic.input);
</script>


</asp:content>

