<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.LoginFormViewModel>" %>
<%@ Import Namespace="CM.State" %>

<script language="C#" runat="server" type="text/C#">
    private bool IsSecondFactorAuthenticationEnabled
    {
        get {
            return Settings.Session.SecondFactorAuthenticationEnabled;
        }
    }

    private bool IsSecondStepsAuthenticationEnabled
    {
        get 
        {
            return Settings.SecondStepsAuthenticationEnabled;
        }
    }
</script>
<div id="loginContainer" class="LoginContainer <%= this.Model.Hidden ? "Hidden" : "" %>">
    <div class="PageOverlay Hidden"></div>
    <form id="loginForm" method="POST" action="<%= this.Url.RouteUrl("Login", new { @action = "SignIn" }).SafeHtmlEncode() %>" target="loginResponse" data-redirect="<%= this.Model.GetRedirectUrl().SafeHtmlEncode() %>">
        <fieldset>
            <legend class="Hidden">
                <%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
            </legend>

            <%= Html.Hidden("callback") %>

            <% if (Settings.MobileV2.IsLoginV2FormEnabled)
                { //LOGIN V2 FORM %>

            <ul class="FormList LoginFormList LoginForm_V2">
                <li class="FormItem">
                    <input class="FormInput" value="" type="text" id="loginUsername" name="username" placeholder="<%= this.GetMetadata(".UserPlaceholder").SafeHtmlEncode()%>" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode() %></span>
                </li>
                <li class="FormItem">
                    <input class="FormInput" value="" type="password" id="loginPassword" name="password" placeholder="<%= this.GetMetadata(".PasswordPlaceholder").SafeHtmlEncode()%>" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode()%></span>
                    <a class="Link ForgotPassWordLink" href="<%= this.Url.RouteUrl("ForgotPassword") %>"><%= this.GetMetadata(".ForgotPasswordText").SafeHtmlEncode()%></a>
                    <%=this.GetMetadata(".LiveChat").HtmlEncodeSpecialCharactors() %>
                </li>
                <%------------------------------------------
                    Captcha
                 -------------------------------------------%>
                <% Html.RenderPartial("/Components/Captcha", this.ViewData.Merge(new { @InitCaptcha = "false" })); %>
            </ul>
            <% if (IsSecondStepsAuthenticationEnabled) { %>
            <ul class="FormList FormListVerifyPhone" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".PhoneVerfication_Desc").HtmlEncodeSpecialCharactors() %>
                </li>
                <li class="FormItem" style="background:none transparent; padding: 0;">
                    <div class="FormLabelText"><%= this.GetMetadata(".Phone_Wartermark").SafeHtmlEncode()%> <span class="lblPhoneNumber"></span></div>
                    <input class="FormInput" value="" type="text" id="loginPhone" name="loginPhone" placeholder="<%= this.GetMetadata(".PhonePlaceholder") %>" maxlength="200" autocomplete="false" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode()%></span>
                </li>
            </ul>
            <%} else if (IsSecondFactorAuthenticationEnabled) {%>
            <ul class="FormList FormListExtraSecurity" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".ExtraSecurity_description").HtmlEncodeSpecialCharactors() %>
                </li>
            </ul>
            <ul class="FormList FormListLiveSupport" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".LiveSupport_description").HtmlEncodeSpecialCharactors() %>
                </li>
            </ul>
            <ul class="FormList FormListAcceptRisks" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".AcceptRisks_description").HtmlEncodeSpecialCharactors() %>
                </li>
            </ul>
            <ul class="FormList FormListPhoneOrEmail" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <p><%=this.GetMetadata(".Smartphone_description").HtmlEncodeSpecialCharactors() %></p>
                </li>
            </ul>
            <ul class="FormList FormList_TwoFactorAuth">
                <%--<li class="FormItem FormItemQrCode">
                    <p>In order to secure your account, please download the Google Authenticator app fpr youer phone(Andriod, iPhone) and use it to sacn the following QR code:</p>
                    <img src="" />
                    <p>...or type in the secret key below:</p>
                    <p><strong class="TwoFactorAuth_SecretKey"></strong></p>
                    <%= this.GetMetadata(".AuthToken_Smartphone_First_Description").HtmlEncodeSpecialCharactors() %>
                </li>--%>
                <li class="FormItem FormItemDesc">
                    <p><%= this.GetMetadata(".AuthToken_Smartphone_Description").HtmlEncodeSpecialCharactors() %></p>
                </li>
                <li class="FormItem">
                    <label class="FormLabel"><%= this.GetMetadata(".AuthToken_Lable").SafeHtmlEncode()%></label>
                    <input class="FormInput" value="" type="text" id="authToken" name="authToken" placeholder="<%=this.GetMetadata(".AuthToken_Wartermark").SafeHtmlEncode()%>" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode() %></span>
                    <input type="hidden" name="authType" value="" />
                </li>  
                <%--<li class="FormItem">
                    <input type="checkbox" id="cbTrustedDevice" class="FormCheck" name="cbTrustedDevice"/>
                    <input type="hidden" name="trustedDevice" />
                    <label for="cbTrustedDevice" class="FormCheckLabel"><%= this.GetMetadata(".TrustDevice_Label").SafeHtmlEncode() %></label>
                </li>--%>              
            </ul>   
            <% } %>         
            <div class="AccountButtonContainer LoginBTNs LoginBTNs_V2">
                <button class="Button AccountButton LoginBTNLink" type="submit" id="btnLogin">
                    <strong class="ButtonText"><%= this.GetMetadata(".LoginButton").SafeHtmlEncode()%></strong>
                </button>
                <% if (IsSecondStepsAuthenticationEnabled) { %>
                    <button class="Button AccountButton VerifyPhoneBTNLink" type="button" id="VerifyPhoneBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".PhoneVerfication_Button_Text").SafeHtmlEncode()%></strong>
                    </button>
                <%} else if (IsSecondFactorAuthenticationEnabled) {%>
                    <button class="Button AccountButton ExtraSecurityBTNLink" type="button" id="ExtraSecurityBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".ExtraSecurity_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton ExtraSecurityBTNLink" type="button" id="LoginNormalBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".LoginNormal_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton LiveSupportBTNLink" type="button" id="LiveSupportBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".LiveSupport_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton LiveSupportBTNLink" type="button" id="LiveSupportBackBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".LiveSupportBack_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton AcceptRisksBTNLink" type="button" id="AcceptRisksBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".AcceptRisks_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton AcceptRisksBTNLink" type="button" id="RiskBackBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".RiskBack_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                <% } %>
                <a class="Button AccountButton SignUpLink SignUpBtn_V2" href="<%= this.Url.RouteUrl("Register") %>">
                    <strong class="ButtonText"><%= this.GetMetadata(".RegisterButton").SafeHtmlEncode()%></strong>
                </a>
            </div>

            <% }
            else
            { //OLD LOGIN FORM %>

            <ul class="FormList FormListNormal">
                <li class="FormItem">
                    <label class="FormLabel" for="loginUsername"><%= this.GetMetadata(".UserLabel").SafeHtmlEncode()%></label>
                    <input class="FormInput" value="" type="text" id="loginUsername" name="username" placeholder="<%= this.GetMetadata(".UserPlaceholder").SafeHtmlEncode()%>" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode() %></span>
                    <a class="Link SignUpLink" href="<%= this.Url.RouteUrl("Register") %>"><%= this.GetMetadata(".RegisterButton").SafeHtmlEncode()%></a>
                </li>
                <li class="FormItem">
                    <label class="FormLabel" for="loginPassword"><%= this.GetMetadata(".PasswordLabel").SafeHtmlEncode()%></label>
                    <input class="FormInput" value="" type="password" id="loginPassword" name="password" placeholder="<%= this.GetMetadata(".PasswordPlaceholder").SafeHtmlEncode()%>" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode()%></span>
                    <a class="Link ForgotPassWordLink" href="<%= this.Url.RouteUrl("ForgotPassword") %>"><%= this.GetMetadata(".ForgotPasswordText").SafeHtmlEncode()%></a>
                    <%=this.GetMetadata(".LiveChat").HtmlEncodeSpecialCharactors() %>
                </li>
                <%------------------------------------------
                    Captcha
                 -------------------------------------------%>
                <% Html.RenderPartial("/Components/Captcha", this.ViewData.Merge(new { @InitCaptcha = "false" })); %>
            </ul>
            <% if (IsSecondStepsAuthenticationEnabled) { %>
            <ul class="FormList FormListVerifyPhone" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".PhoneVerfication_Desc").HtmlEncodeSpecialCharactors() %>
                </li>
                <li class="FormItem" style="background:none transparent; padding: 0;">
                    <div class="FormLabelText"><%= this.GetMetadata(".Phone_Wartermark").SafeHtmlEncode()%> <span class="lblPhoneNumber"></span></div>
                    <input class="FormInput" value="" type="text" id="loginPhone" name="loginPhone" placeholder="<%= this.GetMetadata(".PhonePlaceholder") %>" maxlength="200" autocomplete="false" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode()%></span>
                </li>
            </ul>
            <%} else if (IsSecondFactorAuthenticationEnabled) {%>
            <ul class="FormList FormListExtraSecurity" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".ExtraSecurity_description").HtmlEncodeSpecialCharactors() %>
                </li>
                <li class="FormItem">
                    <%=this.GetMetadata(".LiveChat").HtmlEncodeSpecialCharactors() %>
                </li>
            </ul>
            <ul class="FormList FormListLiveSupport" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".LiveSupport_description").HtmlEncodeSpecialCharactors() %>
                </li>
            </ul>
            <ul class="FormList FormListAcceptRisks" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <%=this.GetMetadata(".AcceptRisks_description").HtmlEncodeSpecialCharactors() %>
                </li>
                <li class="FormItem">
                    <%=this.GetMetadata(".LiveChat").HtmlEncodeSpecialCharactors() %>
                </li>
            </ul>
            <ul class="FormList FormListPhoneOrEmail" style="display:none;">
                <li class="FormItem FormItemDesc">
                    <p><%=this.GetMetadata(".Smartphone_description").HtmlEncodeSpecialCharactors() %></p>
                </li>
            </ul>
            <ul class="FormList FormList_TwoFactorAuth">
                <%--<li class="FormItem FormItemQrCode">
                    <p><%= this.GetMetadata(".AuthToken_Smartphone_First_Description").HtmlEncodeSpecialCharactors() %></p>
                </li>--%>
                <li class="FormItem FormItemDesc">
                    <p><%= this.GetMetadata(".AuthToken_Smartphone_Description").HtmlEncodeSpecialCharactors() %></p>
                </li>

                <li class="FormItem">
                    <label class="FormLabel"><%= this.GetMetadata(".AuthToken_Lable").SafeHtmlEncode()%></label>
                    <input class="FormInput" value="" type="text" id="authToken" name="authToken" placeholder="<%=this.GetMetadata(".AuthToken_Wartermark").SafeHtmlEncode()%>" />
                    <span class="FormStatus"><%= this.GetMetadata(".FormStatus").SafeHtmlEncode() %></span>
                    <input type="hidden" name="authType" value="" />
                </li>    
                <%--<li class="FormItem">
                    <input type="checkbox" id="cbTrustedDevice" class="FormCheck" name="cbTrustedDevice"/>
                    <input type="hidden" name="trustedDevice" />
                    <label for="cbTrustedDevice" class="FormCheckLabel"><%= this.GetMetadata(".TrustDevice_Label").SafeHtmlEncode() %></label>
                </li> --%>          
            </ul>
            <% } %>
            <div class="AccountButtonContainer">
                <button class="Button AccountButton" type="submit" id="btnLogin">
                    <strong class="ButtonText"><%= this.GetMetadata(".LoginButton").SafeHtmlEncode()%></strong>
                </button>
                <% if (IsSecondStepsAuthenticationEnabled) { %>
                    <button class="Button AccountButton VerifyPhoneBTNLink" type="button" id="VerifyPhoneBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".PhoneVerfication_Button_Text").SafeHtmlEncode()%></strong>
                    </button>
                <%} else if (IsSecondFactorAuthenticationEnabled) {%>
                    <button class="Button AccountButton ExtraSecurityBTNLink" type="button" id="ExtraSecurityBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".ExtraSecurity_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton ExtraSecurityBTNLink" type="button" id="LoginNormalBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".LoginNormal_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton LiveSupportBTNLink" type="button" id="LiveSupportBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".LiveSupport_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton LiveSupportBTNLink" type="button" id="LiveSupportBackBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".LiveSupportBack_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton AcceptRisksBTNLink" type="button" id="AcceptRisksBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".AcceptRisks_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                    <button class="Button AccountButton AcceptRisksBTNLink" type="button" id="RiskBackBTNLink" style="display:none;margin:10px auto;">
                        <strong class="ButtonText"><%= this.GetMetadata(".RiskBack_Btn_Text").SafeHtmlEncode()%></strong>
                    </button>
                <% } %>
            </div>

            <% } %>
        </fieldset>
        <span class="FormHelp FormError" id="loginMessage"><%= this.GetMetadata(".UsernamePassword_Empty").SafeHtmlEncode()%></span>
         <%if (Settings.IovationDeviceTrack_Enabled)
                  { %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>   
    </form>
    <iframe class="Hidden" name="loginResponse"></iframe>
</div>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="false">
    <script type="text/javascript">
        function LoginForm() {
            var container = $("#loginContainer"),
            loginForm = $('#loginForm'),
            msgField = $('#loginMessage'),
            userField = $('#loginUsername'),
            passField = $('#loginPassword'),
            overlay = $('.PageOverlay'),
            captchaField = $('.FormItem_Captcha');
            secondFactorAuthField = $('.FormList_TwoFactorAuth');
            verifyPhoneField = $('.FormListVerifyPhone');

            var hiddenStyle = 'Hidden';

            var statusStyles = { 'true': 'FormOk', 'false': 'FormError' },
            requiredError = msgField.text();
            
            secondFactorAuthField.hide();
            secondFactorAuthField.find('#authToken').val('');

            var loginResult = {
                'NoMatch_RequiresCaptcha': '<%= CustomProfile.LoginResult.NoMatch_RequiresCaptcha.ToString().SafeJavascriptStringEncode() %>',
                'RequiresCaptcha': '<%= CustomProfile.LoginResult.RequiresCaptcha.ToString().SafeJavascriptStringEncode() %>',
                'CaptchaNotMatch': '<%= CustomProfile.LoginResult.CaptchaNotMatch.ToString().SafeJavascriptStringEncode() %>',
                'RequiresSecondFactor': '<%= CustomProfile.LoginResult.RequiresSecondFactor.ToString().SafeJavascriptStringEncode() %>',
                'RequiresSecondFactor_FirstTime': '<%= CustomProfile.LoginResult.RequiresSecondFactor_FirstTime.ToString().SafeJavascriptStringEncode() %>',
                'NotMatchDevice': '<%=CustomProfile.LoginResult.NotMatchDevice.ToString().SafeJavascriptStringEncode() %>',
            };

            <%--$('#cbTrustedDevice').change(function () {
                if ($(this).prop("checked"))
                    $('input[name="trustedDevice"]').val(true);
                else
                    $('input[name="trustedDevice"]').val(false);
            }).change();--%>

            $('.AccountButtonContainer').off('click', '.VerifyPhoneBTNLink').on('click', '.VerifyPhoneBTNLink', function(e) {
                e.preventDefault();
                var phoneNumber = $('#loginPhone').val();
                if (phoneNumber == '') return;
                $('.verifyPhoneBox .errorMessage').html('');
                $.ajax({
                    type: "GET",
                    url: "/Login/ValidatePhoneNumber",
                    async: true,
                    data: {
                        username: userField.val(),
                        phoneNumber : phoneNumber
                    },
                    dataType: "json",
                    success: function (data) {
                        if (data.success == true) {
                            $('#btnLogin').trigger('click');
                        } else {
                            userMessage('<%=this.GetMetadata(".VerifyPhone_ErrorMessage").SafeJavascriptStringEncode() %>');
                        }
                    }
                });
            });

            $('.AccountButtonContainer').off('click', '.ExtraSecurityBTNLink').on('click', '.ExtraSecurityBTNLink', function(e) {
                e.preventDefault();
                if ($(this).prop('id') == 'ExtraSecurityBTNLink') {
                    $('.FormListExtraSecurity, .ExtraSecurityBTNLink, .FormListAcceptRisks, .AcceptRisksBTNLink, a.ga_livechat').slideUp();
                    $('.FormListLiveSupport, .LiveSupportBTNLink').slideDown();
                } else {
                    $('.FormListExtraSecurity, .ExtraSecurityBTNLink, .FormListLiveSupport, .LiveSupportBTNLink').slideUp();
                    $('.FormListAcceptRisks, .AcceptRisksBTNLink, a.ga_livechat').slideDown();
                }
            });

            $('.AccountButtonContainer').off('click', '.LiveSupportBTNLink').on('click', '.LiveSupportBTNLink', function(e) {
                e.preventDefault();
                if ($(this).prop('id') == 'LiveSupportBTNLink') {
                    window.open($('a.ga_livechat').prop('href'), '_blank');
                } else {
                    $('.FormListAcceptRisks, .AcceptRisksBTNLink, .FormListLiveSupport, .LiveSupportBTNLink').slideUp();
                    $('.FormListExtraSecurity, .ExtraSecurityBTNLink, a.ga_livechat').slideDown();
                }
            });

            $('.AccountButtonContainer').off('click', '.AcceptRisksBTNLink').on('click', '.AcceptRisksBTNLink', function(e) {
                e.preventDefault();
                if ($(this).prop('id') == 'AcceptRisksBTNLink') {
                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.NormalLogin.ToString() %>');
                    $('#btnLogin').trigger('click');
                } else {
                    $('.FormListAcceptRisks, .AcceptRisksBTNLink, .FormListLiveSupport, .LiveSupportBTNLink').slideUp();
                    $('.FormListExtraSecurity, .ExtraSecurityBTNLink, a.ga_livechat').slideDown();
                }
            });

            loginForm.submit(function (event) {
                if (userField.val() == '' || passField.val() == '') {
                userMessage(requiredError);
                return false;
                }

                if (!secondFactorAuthField.is(':hidden') && $('#authToken').val() == '') {
                    userMessage('<%= this.GetMetadata(".AuthToken_Empty").SafeJavascriptStringEncode() %>');
                    return false;
                }

                <% if (IsSecondFactorAuthenticationEnabled) {%>
                if ($('input[name=authType]').val() == '')
                { 
                    $.post('<%= this.Url.RouteUrl("Login", new { @action = "GetSecondFactorAuthType" }).SafeJavascriptStringEncode() %>',
                    { username: userField.val(), password: passField.val() },
                    function (json) {
                        if (json.success) {
                            switch(json.type) {
                                case <%=(int)TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator %>:
                                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>');
                                    $('#btnLogin').trigger('click');
                                    break;
                                case <%=(int)TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode %>:
                                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode.ToString() %>');
                                    $('#btnLogin').trigger('click');
                                    break;
                                case <%=(int)TwoFactorAuth.SecondFactorAuthType.NormalLogin %>:
                                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.NormalLogin.ToString() %>');
                                    $('#btnLogin').trigger('click');
                                    break;
                                default:
                                    $('ul.LoginFormList, ul.FormListNormal, #btnLogin').slideUp();
                                    $('.FormListExtraSecurity, .ExtraSecurityBTNLink').slideDown();

                                    break;
                            }
                        }
                        else {
                            alert(json.error);
                        }
                    }, 'json').error(function (e) {
                        alert(e);
                    });
                   

                    return false;
                }
                <% } %>

                overlay.removeClass(hiddenStyle);
            });

            userField.add(passField).click(function () {
                msgField.hide();
            });

            function initCaptcha(hide) {
                try {
                    if (hide) {
                        captchaField.hide();
                        captchaField.find('input').attr("disabled", "disabled");
                    }
                    else {
                        __changeCaptcha();
                        captchaField.find('input').removeAttr("disabled");
                        captchaField.show();
                    }
                } catch (ex) { }
            }

            function initSecondFactorAuth(secondFactorAuthSetupCode)
            {
                //try {
                $('ul.FormListNormal').slideUp();
                secondFactorAuthField.slideDown();
                
                if (secondFactorAuthSetupCode) {
                    /*secondFactorAuthField.find('img').attr('src', secondFactorAuthSetupCode.QrCodeImageUrl);
                    secondFactorAuthField.find('.TwoFactorAuth_SecretKey').text(secondFactorAuthSetupCode.SetupCode);*/
                    secondFactorAuthField.find('.FormItemDesc').hide();
                    secondFactorAuthField.find('.FormItemQrCode').show();
                }
                else {
                    secondFactorAuthField.find('.FormItemDesc').show();
                    secondFactorAuthField.find('.FormItemQrCode').hide();
                }

                //} catch (ex) { }
            }

            function loginResponse(status, message, rawResult, secondFactorAuthSetupCode, phoneNumber) {
                overlay.addClass(hiddenStyle);

                userMessage(message, status);
                if (status) {
                    $("<div id=\"DK_Popup_Container\"></div>").appendTo(top.document.body).load("/Login/LoginSuccessDeal");
                }
                else {
                    if (rawResult == loginResult.NoMatch_RequiresCaptcha
                        || rawResult == loginResult.RequiresCaptcha
                        || rawResult == loginResult.CaptchaNotMatch) {
                        initCaptcha();
                    }
                    else if (rawResult == loginResult.NotMatchDevice) {
                        $('.lblPhoneNumber').text(phoneNumber);
                        $('ul.LoginFormList, ul.FormListNormal, .FormListPhoneOrEmail, .PEBTNLink').slideUp();
                        $('#btnLogin').slideUp();
                        verifyPhoneField.slideDown();
                        $('#VerifyPhoneBTNLink').slideDown();
                    }
                    else if(rawResult == loginResult.RequiresSecondFactor || rawResult == loginResult.RequiresSecondFactor_FirstTime) {
                        //initSecondFactorAuth(secondFactorAuthSetupCode);
                        if(rawResult == loginResult.RequiresSecondFactor_FirstTime)
                        {
                            if ($('input[name=authType]').val() == '<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>') {
                                secondFactorAuthField.find('.FormItemDesc').html('<%=this.GetMetadata(".AuthToken_Smartphone_First_Description").SafeJavascriptStringEncode() %>');
                            } else {
                                secondFactorAuthField.find('.FormItemDesc').html('<%=this.GetMetadata(".AuthToken_First_Description").SafeJavascriptStringEncode() %>');
                            }
                        } else {
                            if ($('input[name=authType]').val() == '<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>') {
                                secondFactorAuthField.find('.FormItemDesc').html('<%=this.GetMetadata(".AuthToken_Smartphone_Description").SafeJavascriptStringEncode() %>');
                            } else {
                                secondFactorAuthField.find('.FormItemDesc').html('<%=this.GetMetadata(".AuthToken_Description").SafeJavascriptStringEncode() %>');
                            }
                        }

                        $('ul.LoginFormList, ul.FormListNormal, .FormListPhoneOrEmail, .PEBTNLink').slideUp();
                        $('#btnLogin').slideDown();
                        secondFactorAuthField.slideDown();
                        userMessage('<%=this.GetMetadata(".AuthToken_Empty").SafeJavascriptStringEncode()%>');
                    }
                }
            }

            function userMessage(message, status) {
                msgField
                .removeClass(statusStyles[(!status).toString()])
                .addClass(statusStyles[(!!status).toString()])
                .text(message)
                .show();

                msgField[0].scrollIntoView();
                overlay.addClass(hiddenStyle);
            }

            function setFocus() {
                userField.focus();
            }

            msgField.hide();
            initCaptcha(true);

            return {
                focus: setFocus,
                callback: loginResponse
            }
        }

    function LoginSuccessPageRediret() {
        setTimeout(function () {
            var url = $('#loginForm').data('redirect').toString();
            if (url.toLowerCase().indexOf('/forgotpassword/') >= 0)
                url = '/';
            self.location = url;
        }, 3000);
    }
$(function () {
    window.loginForm = new LoginForm();
    $('#callback').val('loginForm.callback');
});
    </script>
</ui:MinifiedJavascriptControl>
