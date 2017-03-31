<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="CM.Sites" %>

<script language="C#" runat="server" type="text/C#">
    private string _RefreshTarget = "self";
    protected string RefreshTarget {
        get { return _RefreshTarget; }
        set { _RefreshTarget = value; }
    }

    private string RefUrl {
        get {
            if (!string.IsNullOrEmpty(Request.QueryString["refUrl"]))
                return Request.QueryString["refUrl"];
            else if (!string.IsNullOrEmpty(Request.QueryString["url"]))
                return Request.QueryString["url"];
            return string.Empty;
        }
    }
    
    private string GetLoginUrl() {
        if (SiteManager.Current.HttpsPort > 0)
        {
            return string.Format("https://{0}:{1}{2}"
                , Request.Url.Host
                , SiteManager.Current.HttpsPort
                , this.Url.RouteUrl("Login", new { @action = "SignIn" })
                );
        }

        return string.Format("http://{0}:{1}{2}"
                , Request.Url.Host
                , SiteManager.Current.HttpPort
                , this.Url.RouteUrl("Login", new { @action = "SignIn" })
                , DateTime.Now.Ticks
                );
    }
    
    private string GetCurrentBaseUrl() {
        string postfix = string.Empty;
        if (Request.IsHttps() && SiteManager.Current.HttpsPort != 443 && SiteManager.Current.HttpsPort > 0)
            postfix = string.Format(":{0}", SiteManager.Current.HttpsPort);

        if (!Request.IsHttps() && SiteManager.Current.HttpPort != 80 && SiteManager.Current.HttpPort > 0)
            postfix = string.Format(":{0}", SiteManager.Current.HttpPort);
        
        return string.Format("{0}://{1}{2}"
            , Request.IsHttps() ? "https" : "http"
            , Request.Url.Host
            , postfix
            );
    }

    private string GetRedirectUrl() {
        StringBuilder url = new StringBuilder();
        if (SiteManager.Current.HttpsPort > 0)
        {
            url.AppendFormat("https://{0}", Request.Url.Host);
            if (SiteManager.Current.HttpsPort != 443)
                url.AppendFormat(":{0}", SiteManager.Current.HttpsPort);
            url.Append("/");
        }
        else
        {
            url.AppendFormat("http://{0}", Request.Url.Host);
            if (SiteManager.Current.HttpPort != 80)
                url.AppendFormat(":{0}", SiteManager.Current.HttpPort);
            url.Append("/");
        }

        url.Append(Request.Url.PathAndQuery.TrimStart('/'));
        return url.ToString().Replace("_sid=", "_=");
    }

    protected override void OnInit(EventArgs e) {
        base.OnInit(e);
        if (this.ViewData["RefreshTarget"] != null && !string.IsNullOrEmpty(this.ViewData["RefreshTarget"].ToString())) {
            RefreshTarget = this.ViewData["RefreshTarget"].ToString();
        }
    }

    protected string CtrlUsernameName {
        get {
            if (this.ViewData["ReferrerID"] == null)
                return "username";

            return this.ViewData["ReferrerID"].ToString() + "_username";
        }
    }

    protected string CtrlPasswordName {
        get {
            if (this.ViewData["ReferrerID"] == null)
                return "password";

            return this.ViewData["ReferrerID"].ToString() + "_password";
        }
    }

    protected string  CtrlAuthTokenName
    {
        get
        {
            if (this.ViewData["ReferrerID"] == null)
                return "authtoken";

            return this.ViewData["ReferrerID"].ToString() + "_authtoken";
        }
    }

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
<style type="text/css">
    .StepPanel {margin:20px;text-align:left;line-height:28px;}
    .StepPanel .button{width:100%;margin:10px auto;}
    .StepPanel .description{text-align: center;}
</style>
<% if (!Profile.IsAuthenticated) { %>

<ul id="login-pane" class="PopupLogin">
    <li class="PopupLoginItem PopupLoginUsername">
        <label class="FormLabel" for="username">
            <span class="FormLabelText"><%= this.GetMetadata(".Username_Wartermark").SafeHtmlEncode()%></span>
            <input class="FormInput" value="" type="text" id="loginUsername" name="<%=this.CtrlUsernameName%>" placeholder="<%= this.GetMetadata(".UsernamePlaceholder") %>" maxlength="200" autocomplete="false" />
        </label>
    </li>
    <li class="PopupLoginItem PopupLoginPassword">
        <label class="FormLabel" for="loginPassword">
            <span class="FormLabelText"><%= this.GetMetadata(".Password_Wartermark").SafeHtmlEncode()%></span>
            <input class="FormInput" value="" type="password" id="loginPassword" name="<%=this.CtrlPasswordName%>" placeholder="<%= this.GetMetadata(".PasswordPlaceholder") %>" maxlength="200" autocomplete="false" />
        </label>
    </li>
    <li class="PopupLoginItem PopupLoginCTA login_btn">
        <button class="Button LoginCTA button" onclick="this.blur();" type="submit" title="<%= this.GetMetadata(".CTATitle").SafeHtmlEncode()%>">
            <span class="ButtonText"><%= this.GetMetadata(".Login_Btn_Text").SafeHtmlEncode()%></span>
        </button>
    </li>
</ul>
<% if (IsSecondStepsAuthenticationEnabled) { %>
<%=this.GetMetadata(".VerifyPhone_CSS").HtmlEncodeSpecialCharactors() %>
<div class="verifyPhoneBox" style="display:none;">
    <div class="StepPanel">
    <div class="description"><%=this.GetMetadata(".PhoneVerfication_Desc").HtmlEncodeSpecialCharactors() %></div>
    <label class="FormLabel" for="loginPhone">
        <div class="FormLabelText"><%= this.GetMetadata(".Phone_Wartermark").SafeHtmlEncode()%> <span class="lblPhoneNumber"></span></div>
        <input class="FormInput" value="" type="text" id="loginPhone" name="loginPhone" placeholder="<%= this.GetMetadata(".PhonePlaceholder") %>" maxlength="200" autocomplete="false" />
    </label>
    <div class="errorMessage"></div>
    <div class="PopupLoginItem PopupLoginCTA">
        <%: Html.Button( this.GetMetadata(".PhoneVerfication_Button_Text"), new { @id="btnMobileVerfication", @type = "button" }) %>
    </div>
    </div>
</div>
<script type="text/javascript">
    $(function() {
        $('.verifyPhoneBox').off('click', '#btnMobileVerfication').on('click', '#btnMobileVerfication', function(e) {
            e.preventDefault();
            $.cookie("_hvp",null);
            $('.verifyPhoneBox .errorMessage').html('');
            var phoneNumber = $('#loginPhone').val();
            if (phoneNumber == '') return;
            $.ajax({
                type: "GET",
                url: "/Login/ValidatePhoneNumber",
                async: true,
                data: {
                    username: $('#login-pane input[name="<%=this.CtrlUsernameName%>"]').val(),
                    phoneNumber : phoneNumber
                },
                dataType: "json",
                success: function (data) {
                    if (data.success == true) {
                        $('#login-pane .login_btn button').trigger('click');
                    } else {
                        $('.verifyPhoneBox .errorMessage').html('<%=this.GetMetadata(".VerifyPhone_ErrorMessage").SafeJavascriptStringEncode() %>');
                    }
                }
            });
        });
    })
</script>
<% } %>

<%if (IsSecondFactorAuthenticationEnabled) { %>
    <div class="extraSecurity" style="display:none;">
        <div class="StepPanel">
            <div class="description">
                <%=this.GetMetadata(".ExtraSecurity_description").HtmlEncodeSpecialCharactors() %>
            </div>
            <%: Html.Button( this.GetMetadata(".ExtraSecurity_Btn_Text"), new { @id="btnExtraSecurity", @type = "button" }) %>
            <%: Html.Button( this.GetMetadata(".LoginNormal_Btn_Text"), new { @id="btnLoginNormal", @type = "button" }) %>
        </div>
    </div>
    <div class="acceptRisks" style="display:none;">
        <div class="StepPanel">
            <div class="description">
                <%=this.GetMetadata(".AcceptRisks_description").HtmlEncodeSpecialCharactors() %>
            </div>
            <%: Html.Button( this.GetMetadata(".AcceptRisks_Btn_Text"), new { @id="btnAcceptRisks", @type = "button" }) %>
            <%: Html.Button( this.GetMetadata(".RiskBack_Btn_Text"), new { @id="btnRiskBack", @type = "button" }) %>
        </div>
    </div>
    <div class="liveSupportPopup" style="display:none;">
        <div class="StepPanel">
            <div class="description">
                <%=this.GetMetadata(".LiveSupport_description").HtmlEncodeSpecialCharactors() %>
            </div>
            <%: Html.Button( this.GetMetadata(".LiveSupport_Btn_Text"), new { @id="btnLiveSupport", @type = "button" }) %>
            <%: Html.Button( this.GetMetadata(".LiveSupportBack_Btn_Text"), new { @id="btnLiveSupportBack", @type = "button" }) %>
        </div>
    </div>
    <%--<div class="fldHasSmartphone" style="display:none;">
        <div class="StepPanel">
        <div class="description">
            <%=this.GetMetadata(".Smartphone_description").HtmlEncodeSpecialCharactors() %>
        </div>
        <%: Html.Button( this.GetMetadata(".SmartPhone_Btn_Text"), new { @id="btnSmartPhone", @type = "button" }) %>
        <%: Html.Button( this.GetMetadata(".Email_Btn_Text"), new { @id="btnEmail", @type = "button" }) %>
        </div>
    </div>--%>
    <div class="authToken" id="authToken" style="display:none;">
        <div class="StepPanel">
        <div class="description">
            <%=this.GetMetadata(".AuthToken_description").HtmlEncodeSpecialCharactors() %>
        </div>
        
        <div class="authTokenLable"><%=this.GetMetadata(".AuthToken_Lable").SafeHtmlEncode() %></div>
        <div class="authTokenBox" style="width:90%; margin:10px auto; text-align:left;">
            <input class="FormInput" value="" type="text" id="txtAuthToken" name="<%=this.CtrlAuthTokenName%>" placeholder="<%= this.GetMetadata(".AuthToken_Wartermark") %>" maxlength="200" autocomplete="false" style="background: #fff none repeat scroll 0 0; border: 2px solid #c5cacb; box-sizing: border-box; color: #969696; display: block; padding: 1em; width: 100%;" />
            <input type="hidden" name="authType" value="" />
            <%--<div class="fldTrustDevice">
                <%: Html.CheckBox("isTrustDevice", false, new { @id = "btnTrustDevice" })%>
                <label for="btnTrustDevice"><%= this.GetMetadata(".TrustDevice_Label").SafeHtmlEncode() %> </label>  
            </div>--%>
            
            <%: Html.Button( this.GetMetadata(".AuthToken_Btn_Text"), new { @id="btnLogin", @type = "button" }) %>
        </div>
        </div>
    </div>
    <div id="qrcode" style="display: none; ">
    <style type="text/css">
        .qrcode-op-bar {
            height: 8px; width:100%;
        }
            .qrcode-op-bar a {
                background-color: #de1b18; height: 8px; width:100%; display: block;
            }
                .qrcode-op-bar a:hover {
                    background-color: #edec02;
                }

    </style>
    <img />
    <p></p>
    
    </div>
    <%=this.GetMetadata(".LiveChat").HtmlEncodeSpecialCharactors() %>
<%} %>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
<script type="text/javascript">
    //<![CDATA[
    $(function () {
        var _lastAttempTime = 0;

        <%--$('.fldHasSmartphone').off('click', '.button').on('click', '.button', function(e) {
            e.preventDefault();
            if ($(this).prop('id') == 'btnSmartPhone') {
                $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>');
            } else {
                $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode.ToString() %>');
            }

            $('#login-pane .login_btn button').trigger('click');

        });--%>

        $('.extraSecurity').off('click', '.button').on('click', '.button', function(e) {
            e.preventDefault();
            if ($(this).prop('id') == 'btnExtraSecurity') {
                $('.extraSecurity, a.ga_livechat').hide();
                $('.liveSupportPopup').show();
                $('.LoginDialogContainer').height($('.LoginDialog').height());
            } else {
                $('.extraSecurity').hide();
                $('.acceptRisks, a.ga_livechat').show();
                $('.LoginDialogContainer').height($('.LoginDialog').height());
            }
        });

        $('.liveSupportPopup').off('click', '.button').on('click', '.button', function(e) {
            e.preventDefault();
            if ($(this).prop('id') == 'btnLiveSupport') {
                $('.LPMimage', top.document.body).click();
            } else {
                $('.liveSupportPopup').hide();
                $('.extraSecurity, a.ga_livechat').show();
                $('.LoginDialogContainer').height($('.LoginDialog').height());
            }
        });

        $('.acceptRisks').off('click', '.button').on('click', '.button', function(e) {
            e.preventDefault();
            if ($(this).prop('id') == 'btnAcceptRisks') {
                $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.NormalLogin.ToString() %>');
                $('#login-pane .login_btn button').trigger('click');
            } else {
                $('.acceptRisks').hide();
                $('.extraSecurity, a.ga_livechat').show();
                $('.LoginDialogContainer').height($('.LoginDialog').height());
            }
        });

        $('#login-pane .login_btn button, #btnLogin').click(function (e) {
            e.preventDefault();

            var username = $('#login-pane input[name="<%=this.CtrlUsernameName%>"]').val();
            var password = $('#login-pane input[name="<%=this.CtrlPasswordName%>"]').val();

            if (username == '' || password == '') {
                alert('<%= this.GetMetadata(".UsernamePassword_Empty").SafeJavascriptStringEncode() %>');
                return;
            }
            <%if (IsSecondFactorAuthenticationEnabled) { %>
            if ($('input[name=authType]').val() == '')
            { 
                $.post('<%= this.Url.RouteUrl("Login", new { @action = "GetSecondFactorAuthType" }).SafeJavascriptStringEncode() %>',
                    { username: username, password: password },
                    function (json) {
                        if (json.success) {
                            switch(json.type) {
                                case <%=(int)TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator %>:
                                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>');
                                    $('#login-pane .login_btn button').trigger('click');
                                    break;
                                case <%=(int)TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode %>:
                                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode.ToString() %>');
                                    $('#login-pane .login_btn button').trigger('click');
                                    break;
                                case <%=(int)TwoFactorAuth.SecondFactorAuthType.NormalLogin %>:
                                    $('input[name=authType]').val('<%=TwoFactorAuth.SecondFactorAuthType.NormalLogin.ToString() %>');
                                    $('#login-pane .login_btn button').trigger('click');
                                    break;
                                default:
                                    $('#login-pane, a.forgot_password, a.join_now').hide();
                                    $('.extraSecurity').show();

                                    //var height = 500;
                                    $('.LoginDialogContainer').height($('.LoginDialog').height());
                                    //$('#ARFrameLoader', top.document.body).height(height + 70);
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

            var authToken = $('#txtAuthToken').val();

            if ($(this).prop('id') == 'btnLogin' && authToken == '') {
                alert('<%= this.GetMetadata(".AuthToken_Empty").SafeJavascriptStringEncode() %>');
                return;
            }

            var now = (new Date()).getTime();
            if( now - _lastAttempTime < 3000 ){
                return;
            }
            _lastAttempTime = now;

            $(this).toggleLoadingSpin(true);

            $('iframe.ifmLoginCallback').remove();
            $('form.LoginSubmissionForm').remove();
            $('<iframe style="display:none" id="ifmLoginCallback" name="ifmLoginCallback" class="ifmLoginCallback"></iframe>').appendTo(document.body);
            var $form = $('<form style="display:none" class="LoginSubmissionForm" cookieless="UseCookies" target="ifmLoginCallback" method="POST"></form>').appendTo(document.body);
            $form.attr('action', '<%= GetLoginUrl().SafeJavascriptStringEncode().Replace("https", "http").Replace(":443", "") %>');
            $('<input type="hidden" name="username" />').appendTo($form).val(username);
            $('<input type="hidden" name="password" />').appendTo($form).val(password);
            <%if (IsSecondFactorAuthenticationEnabled) { %>
            $('<input type="hidden" name="authToken" />').appendTo($form).val(authToken);
            $('<input type="hidden" name="authType" />').appendTo($form).val($('input[name=authType]').val());  
            $('<input tpe="hidden" name="trustedDevice" />').appendTo($form).val($('#btnTrustDevice').prop('checked'));
            <% } %>
            $('<input type="hidden" name="baseURL" />').appendTo($form).val('<%= GetCurrentBaseUrl().SafeJavascriptStringEncode() %>');
            $('<input type="hidden" name="referrerID" />').appendTo($form).val('<%= this.ViewData["ReferrerID"]%>');
            $form[0].submit();
        });

        $('#login-pane input[name="<%=this.CtrlPasswordName%>"]').keypress(function (e) {
            if (e.keyCode == 13) {
                $('#login-pane div.login_btn button').trigger('click');
            }
        });

        $(this).toggleLoadingSpin(false);
    });

    var redirectPage = "";
    var dest = "";
    function LoginSuccessPageRediret(){
        dest.location = redirectPage;
    }
    var frameId = window.frameElement && window.frameElement.id || '';
    function OnLoginResponse(json) {        
        
        if (!json.success) {
            $('#login-pane div.login_btn button, #btnLogin').toggleLoadingSpin(false);
            try{
                if (window.parent)
                    window.parent.$('#login-pane div.login_btn button, #btnLogin').toggleLoadingSpin(false);
            }
            catch(ex){}
            alert(json.error);
            return;
        }
        switch (json.result.toLowerCase()) {
            case 'success': 
                dest = window.<%=RefreshTarget %> || window.self;
                var redirectUrl = '<%= GetRedirectUrl() %>';
                var refUrl = '<%=RefUrl %>';
                try{
                    if(refUrl.length>0){
                        if (refUrl.toLowerCase().indexOf('/casino/game/info/') >= 0){
                            var str1 = refUrl.toLowerCase().indexOf('game/info/');
                            var str2 = refUrl.substring(str1 + 10);
                            var exp = new Date(); 
                            exp.setTime(exp.getTime() + 25*60*60*1000);
                            document.cookie = "CasinoGameV="+ escape (str2) + ";path=/;expires=" + exp.toGMTString();
                            redirectPage = refUrl.substring(0,str1);
                        }
                        else
                            redirectPage = refUrl;
                    }
                    else if(dest == window.self)
                        redirectPage = redirectUrl;
                    else
                        redirectPage = dest.location.toString().replace(/(\#.*)$/, '');

                    $("<div id=\"DK_Popup_Container\"></div>").appendTo(top.document.body).load("/Login/LoginSuccessDeal");
                }
                catch(ex){
                    try {                    
                        dest.location = dest.location.toString().replace(/(\#.*)$/, '');
                    }catch(ex) {
                        dest.location = '/';
                    }
                }    
                return;
            case "notmatchdevice":
                $('.lblPhoneNumber').text(json.phoneNumber);
                $('#login-pane').hide();
                $('.verifyPhoneBox').show();
                $('#login-pane div.login_btn button, #btnLogin').toggleLoadingSpin(false);
                //alert('not match device');
                return;
            default:
                $('#login-pane div.login_btn button, #btnLogin').toggleLoadingSpin(false);
                alert(json.error);
                return;
        }
    }
    try{ 
        self.OnLoginResponse = OnLoginResponse;
    }
    catch(e){
    }

    function OnRequiresSecondFactor(result, secondFactorAuthSetupCode)
    {
        ToggleLoginLoadingSpin(false);

        //var height = 0, height2 = 0;
        if(result == 'RequiresSecondFactor_FirstTime')
        {
            /*$('#qrcode img').attr('src', secondFactorAuthSetupCode.QrCodeImageUrl);
            $('#qrcode p').text(secondFactorAuthSetupCode.SetupCode);
            $('#qrcode').css({'position': 'absolute', 'top':5, 'left':50, 'display':'block', 'z-index': '100'});                                 

            $(top.document.body).find('#qrcode').remove();
            $('#qrcode').clone().appendTo($(top.document.body));*/
            
            if ($('input[name=authType]').val() == '<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>') {
                $('.authToken .description').html('<%=this.GetMetadata(".AuthToken_Smartphone_First_Description").SafeJavascriptStringEncode() %>');
                //height2 = height = 815;
            } else {
                $('.authToken .description').html('<%=this.GetMetadata(".AuthToken_First_Description").SafeJavascriptStringEncode() %>');
                //height = 550;
                //height2 = height + 70;
            }
        } else {
            if ($('input[name=authType]').val() == '<%=TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator.ToString() %>') {
                $('.authToken .description').html('<%=this.GetMetadata(".AuthToken_Smartphone_Description").SafeJavascriptStringEncode() %>');
                //height = 720;
                //height2 = height + 70;
            } else {
                $('.authToken .description').html('<%=this.GetMetadata(".AuthToken_Description").SafeJavascriptStringEncode() %>');
                //height = 400;
                //height2 = height + 70;
            }
        }
        
        //$('.LoginDialogContainer').height(height);
        //$('#ARFrameLoader', top.document.body).height(height2);
        $('#login-pane, .fldHasSmartphone').hide();
        $('#authToken').show();console.log($('.LoginDialog').height());
        $('.LoginDialogContainer').height('auto');
    }
    try{ 
        self.OnRequiresSecondFactor = OnRequiresSecondFactor;
    }
    catch(e){
    }

    function ToggleLoginLoadingSpin(_loading){
        try{
            $('#login-pane div.login_btn button').toggleLoadingSpin(_loading);
            if (window.parent)
                window.parent.$('#login-pane div.login_btn button').toggleLoadingSpin(_loading);
        }
        catch(ex){}
    }
    //]]>
</script>
</ui:MinifiedJavascriptControl>

<% }%>