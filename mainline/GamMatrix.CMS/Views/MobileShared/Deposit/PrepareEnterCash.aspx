<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareEnterCashViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>

<script language="C#" type="text/C#" runat="server">
    protected int TotalSteps;
    protected int CurrentStep;
    
    protected bool IsStyle2()
    {
        return Settings.MobileV2.IsV2DepositProcessEnabled;
    }

    protected override void OnInit(EventArgs e)
    {
        //Model.ExistingPayCard.BankCode = null;
        base.OnInit(e);

        if (IsStyle2())
        {
            TotalSteps = 3;
            CurrentStep = 1;
        }
        else
        {
            TotalSteps = 4;
            CurrentStep = 2;
        }
    }
</script>

<asp:content id="Content1" contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content id="Content2" contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = TotalSteps, CurrentStep = CurrentStep }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareNeteller">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                EnterCash
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".EnterCash_Account").SafeHtmlEncode() %>
	            </legend>
                <% if (IsStyle2() && string.Equals(Model.PaymentMethod.UniqueName, "EnterCash_OnlineBank", StringComparison.InvariantCultureIgnoreCase))
                   { %>
                        <ul class="BankFields">
                            <li class="FormItem">
                                <label class="FormLabel" for="depositEnterCashBankID"><%= this.GetMetadata(".BankID_Label").SafeHtmlEncode() %></label>
                                <%: Html.DropDownList("enterCashBankID", Model.GetEnterCashBankList(), new Dictionary<string, object>()  
                                                { 
                                                    { "class", "FormInput" },
                                                    { "id", "depositEnterCashBankID" },
                                                    { "dir", "ltr" },
                                                    { "required", "required" },
                                                }) %>

                                <span class="FormStatus">Status</span>
                                <span class="FormHelp"></span>
                            </li>
                        </ul>
                <% } %>
                <% if (string.Equals(Model.PaymentMethod.UniqueName, "EnterCash_WyWallet", StringComparison.InvariantCultureIgnoreCase))
                   { %>
                    <% if (Model.ExpectedMobilePrefix == Model.UserMobilePrefix)
                       { %>
                    <%: Html.Hidden("enterCashBankID", Model.EnterCashBankID) %>
	                <ul class="FormList">
                        <li class="FormItem">
                            <%if (string.IsNullOrWhiteSpace(Model.ExistingPayCard.BankCode))
                              { %>
			                <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".SendVerificationCode_Label").SafeHtmlEncode() %></label>
                            <%: Html.TextBox("mobile", string.Format("{0}-{1}", Model.UserMobilePrefix, Model.UserMobile), new Dictionary<string, object>()  
                                { 
                                    { "class", "FormInput" },
                                    { "id", "depositMobile" },
                                    { "dir", "ltr" },
								    { "type", "text" },
                                    { "maxlength", "16" },
                                    { "autocomplete", "off" },
                                    { "required", "required" },
								    { "placeholder", this.GetMetadata(".VerificationCode_Label") },
                                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".VerificationCode_Empty")) }
                                }.SetReadOnly(true)) %>

			                <span class="FormStatus">Status</span>
			                <span class="FormHelp"></span>
		                </li>
                        <li class="FormItem">
                            <button type="button" class="Button RegLink DepLink NextStepLink" id="btnSendVerificationCode">
				                <span class="ButtonText"><%= this.GetMetadata(".Button_SendVerificationCode").SafeHtmlEncode()%></span>
			                </button>
                            <span id="sendVerificationCodeError" class="FormHelp FormError"></span>
                        </li>
                        <% } %>
                        <li class="FormItem">
			                <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".VerificationCode_Label").SafeHtmlEncode() %></label>
                            <%: Html.TextBox("verificationCode", Model.HasPayCards() ? Model.ExistingPayCard.BankCode : string.Empty, new Dictionary<string, object>()  
                                { 
                                    { "class", "FormInput" },
                                    { "id", "depositVerificationCode" },
                                    { "dir", "ltr" },
								    { "type", "text" },
                                    { "maxlength", "16" },
                                    { "autocomplete", "off" },
                                    { "required", "required" },
								    { "placeholder", this.GetMetadata(".VerificationCode_Label") },
                                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".VerificationCode_Empty")) }
                                }.SetReadOnly(Model.HasPayCards() && !string.IsNullOrWhiteSpace(Model.ExistingPayCard.BankCode))) %>

			                <span class="FormStatus">Status</span>
			                <span class="FormHelp"></span>
		                </li>
	                </ul>
                    <% } %>
                    <% else %>
                    <% { %>
                    <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Message_MobileDonotSupport"))); %>
                    <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadataEx(".Message_MobileDonotSupport2", Model.ExpectedMobilePrefix))); %>
                    <% } %>
                <% } %>
            </fieldset>

            <input type="hidden" name="payCardID" value="<%= Model.HasPayCards() ? Model.ExistingPayCard.ID.ToString() : string.Empty %>" />

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { NextButtonEnabled = Model.ExpectedMobilePrefix == Model.UserMobilePrefix }); %>
		</form>
        <form action="<%= this.Url.RouteUrl("Deposit", new { action = "SendEnterCashVerificationCode" }).SafeHtmlEncode() %>" method="post" id="formSendVerificationCode">
            
            <input type="hidden" value="<%=string.Format("{0}{1}", Model.UserMobilePrefix, Model.UserMobile).SafeHtmlEncode() %>" name="phoneNumber" id="phoneNumber" />
            <input type="hidden" value="<%=Model.StateVars["enterCashBankID"].SafeHtmlEncode() %>" name="enterCashBankID" id="enterCashBankID" />
        </form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    $(CMS.mobile360.Generic.input);

    // String format : 'str1-{0} str2-{1}'.format('str1', 'str2')
    String.prototype.format = function () {
        if (arguments.length == 0)
            return this;

        var str = this;
        for (var i = 0; i < arguments.length; i++) {
            var re = new RegExp('\\{' + (i) + '\\}', 'gm');
            str = str.replace(re, arguments[i]);
        }
        return str;
    }

    var _countDownSecondsForSendEnterCashVerificationCode = 60;
    var sendButton = $('#btnSendVerificationCode');

    function countDownForResend() {
        _countDownSecondsForSendEnterCashVerificationCode = _countDownSecondsForSendEnterCashVerificationCode - 1;
        if (_countDownSecondsForSendEnterCashVerificationCode > 0) {
            sendButton.find('span').text('<%= this.GetMetadata(".VerificationCode_CountDown_Text").SafeJavascriptStringEncode() %>'.format(_countDownSecondsForSendEnterCashVerificationCode));
            window.setTimeout(countDownForResend, 1000);
        }
        else {
            sendButton.find('span').text('<%= this.GetMetadata(".VerificationCode_Resend").SafeJavascriptStringEncode() %>');
            sendButton.removeAttr("disabled");
        }
    }

    var VerificationCode = (function () {//internal classes in closure
        var errorField = $("#sendVerificationCodeError");
        var loading = false;

        sendButton.click(function (e) {
            e.preventDefault();
            if (loading)
                return;

            loading = true;
            sendButton.attr("disabled", "disabled");
            _countDownSecondsForSendEnterCashVerificationCode = 60;
            sendButton.find('span').text('<%= this.GetMetadata(".VerificationCode_Sending").SafeJavascriptStringEncode() %>');

            $.ajax({
                dataType: 'json',
                type: 'POST',
                url: $('#formSendVerificationCode').attr('action'),
                data: {
                    bankID: $('#enterCashBankID').val(),
                    phoneNumber: $('#phoneNumber').val()
                },
                success: sendVerificationCodeResponse,
                error: showErrorfunction,
            });
        });

        function sendVerificationCodeResponse(json) {
            loading = false;
            alert('<%=this.GetMetadata(".VerificationCode_SendSucceed").SafeJavascriptStringEncode()%>');
            countDownForResend();
        }

        function showErrorfunction(XMLHttpRequest, textStatus, errorThrown) {
            loading = false;
            errorField.text(textStatus + errorThrown).show();
            sendButton.find('span').text('<%= this.GetMetadata(".Button_SendVerificationCode").SafeJavascriptStringEncode() %>');
            sendButton.removeAttr("disabled");
        }
    });

    new VerificationCode();

    <%=this.Model.GetEnterCashBankInfoJson() %>

    $(function () {
        var amountSelector = new AmountSelector();
        $('#depositEnterCashBankID').change(function () {
            var bankID = $(this).val();
            var bank = enterCashBankInfos[bankID];
            amountSelector.lock(bank.Currency);
        });

        //setTimeout(function () {
            var defaultBankID = $('#depositEnterCashBankID').val();
            var defaultBank = enterCashBankInfos[defaultBankID];
            amountSelector.lock(defaultBank.Currency);
        //}, 100);
    });
</script>
</ui:MinifiedJavascriptControl>
</asp:content>

