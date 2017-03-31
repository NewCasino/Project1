<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="CM.Sites" %>

<script language="C#" runat="server" type="text/C#">
    private string _RefreshTarget = "self";
    protected string RefreshTarget
    {
        get { return _RefreshTarget; }
        set { _RefreshTarget = value; }
    }

    private string RefUrl
    {
        get
        {
            if (!string.IsNullOrEmpty(Request.QueryString["refUrl"]))
                return Request.QueryString["refUrl"];
            else if (!string.IsNullOrEmpty(Request.QueryString["url"]))
                return Request.QueryString["url"];
            return string.Empty;
        }
    }

    private string GetLoginUrl()
    {
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

    private string GetCurrentBaseUrl()
    {
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

    private string GetRedirectUrl()
    {
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

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (this.ViewData["RefreshTarget"] != null && !string.IsNullOrEmpty(this.ViewData["RefreshTarget"].ToString()))
        {
            RefreshTarget = this.ViewData["RefreshTarget"].ToString();
        }
    }

    protected string CtrlUsernameName
    {
        get
        {
            if (this.ViewData["ReferrerID"] == null)
                return "username";

            return this.ViewData["ReferrerID"].ToString() + "_username";
        }
    }

    protected string CtrlPasswordName
    {
        get
        {
            if (this.ViewData["ReferrerID"] == null)
                return "password";

            return this.ViewData["ReferrerID"].ToString() + "_password";
        }
    }

    protected string CtrlCaptchaName
    {
        get
        {
            if (this.ViewData["ReferrerID"] == null)
                return "captcha";

            return this.ViewData["ReferrerID"].ToString() + "_captcha";
        }
    }

    protected bool RequiresCaptcha
    {
        get
        {
            bool _rc = false;
            if (!string.IsNullOrWhiteSpace(Request.QueryString["requirescaptcha"]))
            {
                bool.TryParse(Request.QueryString["requirescaptcha"], out _rc);
            }
            return _rc;
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
<div id="login-pane">
    <% if (!Profile.IsAuthenticated)
       {
    %>
    <div class="username_wrap">
        <%: Html.TextboxEx(this.CtrlUsernameName, "", this.GetMetadata(".Username_Wartermark"))%>
    </div>
    <div class="password_wrap">
        <%: Html.TextboxEx(this.CtrlPasswordName, "", this.GetMetadata(".Password_Wartermark"), new { type = "password" })%>
    </div>
    <%if (RequiresCaptcha) { %>
    <div class="captcha_wrap" id="captcha_wrap">
        <%: Html.TextboxEx(this.CtrlCaptchaName, "", this.GetMetadata(".Captcha_Wartermark"), new { placeholder = this.GetMetadata(".Captcha_Wartermark") })%>
        <img class="captcha_img" style="width:80%" onclick="__changeLoginCaptcha()" src="/Views/Shared/Components/_captcha.ashx" />        
    </div>
    <script language="javascript" type="text/javascript">
        function __changeLoginCaptcha() {
            var $img = $('.captcha_wrap img.captcha_img');
            $img.attr('src', '/Views/Shared/Components/_captcha.ashx?_t=' + (new Date()).toString());
        }
    </script>
    <%} %>
     <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
    <div class="login_btn">
        <%: Html.Button( this.GetMetadata(".Login_Btn_Text"), new { @type = "submit" }) %>
    </div>
    <div style="clear: both"></div>

    <script type="text/javascript">
    //<![CDATA[
    $(function () {
        var _lastAttempTime = 0;
        $('#login-pane div.login_btn button').click(function (e) {
            e.preventDefault();
            var username = $('#login-pane input[name="<%=this.CtrlUsernameName%>"]').val();
            var password = $('#login-pane input[name="<%=this.CtrlPasswordName%>"]').val();
            var captcha = '';
            if (username == '' || password == '') {
                alert('<%= this.GetMetadata(".UsernamePassword_Empty").SafeJavascriptStringEncode() %>');
                return;
            }
            <%if (RequiresCaptcha) { %>
            captcha = $('#login-pane input[name="<%=this.CtrlCaptchaName%>"]').val();
            if (captcha == '' ) {
                alert('<%= this.GetMetadata(".Captcha_Empty").SafeJavascriptStringEncode() %>');
                return;
            }
            <% } %>

            var now = (new Date()).getTime();
            if( now - _lastAttempTime < 3000 ){
                return;
            }
            _lastAttempTime = now;

            $(this).toggleLoadingSpin(true);

            $('iframe.ifmLoginCallback').remove();
            $('form.LoginSubmissionForm').remove();
            $('<iframe style="display:none" id="ifmLoginCallback" name="ifmLoginCallback" class="ifmLoginCallback"></iframe>').appendTo(document.body);
            var $form = $('<form style="display:none" class="LoginSubmissionForm" target="ifmLoginCallback" method="POST"></form>').appendTo(document.body);
            $form.attr('action', '<%= GetLoginUrl().SafeJavascriptStringEncode() %>');
            $('<input type="hidden" name="username" />').appendTo($form).val(username);
            $('<input type="hidden" name="password" />').appendTo($form).val(password);
            $('<input type="hidden" name="captcha" />').appendTo($form).val(captcha);
            $('<input type="hidden" name="baseURL" />').appendTo($form).val('<%= GetCurrentBaseUrl().SafeJavascriptStringEncode() %>');
            $('<input type="hidden" name="referrerID" />').appendTo($form).val('<%= this.ViewData["ReferrerID"]%>');
            <% if (Settings.IovationDeviceTrack_Enabled)
        { %>
            $('<input type="hidden" name="iovationBlackBox" />').appendTo($form).val(io_blackbox_value);
            $('<input type="hidden" name="iovationBlackBox_info" />').appendTo($form).val(io_blackboxInfoFun());
            <%}%>
            $form[0].submit();
        });

        $('#login-pane input[name="password"]').keypress(function (e) {
            if (e.keyCode == 13) {
                $('#login-pane div.login_btn button').trigger('click');
            }
        });

        
    });

    var redirectPage = "";
    var dest = "";
    function LoginSuccessPageRediret(){
        dest.location = redirectPage;
    }
    var frameId = window.frameElement && window.frameElement.id || '';
    function OnLoginResponse(json) {        
        
        if (!json.success) {
            ToggleLoginLoadingSpin(false);
            alert(json.error);
            return;
        }
        switch (json.result.toLowerCase()) {
            case 'success': 
                try{
                    dest = window.<%=RefreshTarget %> || window.self;
                    var redirectUrl = '<%= GetRedirectUrl() %>';
                    var refUrl = '<%=RefUrl %>';
                    var destUrl = dest.location.toString().replace(/(\#.*)$/, '');

                    if (redirectUrl.toLowerCase().indexOf('/forgotpassword/') >= 0)
                        redirectUrl = '/';
                    if (refUrl.toLowerCase().indexOf('/forgotpassword/') >= 0)
                        refUrl = '/';
                    if (destUrl.toLowerCase().indexOf('/forgotpassword/') >= 0)
                        destUrl = '/';
                    if(refUrl.length>0)
                        redirectPage = refUrl;
                    else if(dest == window.self)
                        redirectPage = redirectUrl;
                    else
                        redirectPage = destUrl;

                    $("<div id=\"DK_Popup_Container\"></div>").appendTo(top.document.body).load("/Login/LoginSuccessDeal");
                }
                catch(ex){
                    try { 
                        var destUrl = dest.location.toString().replace(/(\#.*)$/, '');                   
    
                        if (destUrl.toLowerCase().indexOf('/forgotpassword/') >= 0)
                            destUrl = '/';
        
                        dest.location = destUrl;
                    }catch(ex) {
                        dest.location = '/';
                    }
                }                    
                return;
            case "captchanotmatch":
                $('.captcha_wrap img.captcha_img').trigger('click');
                ToggleLoginLoadingSpin(false);
                alert(json.error);
                return;
            case "notmatchdevice":
                $('.lblPhoneNumber').text(json.phoneNumber);
                $('#login-pane').hide();
                $('.verifyPhoneBox').show();
                ToggleLoginLoadingSpin(false);
                return;
            default:
                ToggleLoginLoadingSpin(false);
                alert(json.error);
                return;
        }
    }
    try{ 
        self.OnLoginResponse = OnLoginResponse;
    }
    catch(e){
    }

    function OnRequiresCaptcha(error)
    {               
        if($('#captcha_wrap').length > 0)
        {
            $('.captcha_wrap img.captcha_img').trigger('click');
            ToggleLoginLoadingSpin(false);

            if( error!= undefined)
            {
                alert(error);
            }
            return;
        }

        if( error!= undefined)
        {
            alert(error);
        }

        ToggleLoginLoadingSpin(false);

        $('iframe.LoginDialog').remove();
        $('<iframe style="border:0px;width:400px;height:350px;display:none" frameborder="0" scrolling="no" src="/Login/Dialog?requirescaptcha=true&_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="LoginDialog"></iframe>').appendTo(top.document.body);
        var $iframe = $('iframe.LoginDialog', top.document.body).eq(0);
        $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
    }
    try{ 
        self.OnRequiresCaptcha = OnRequiresCaptcha;
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
<%
   }%>
</div>
<% if (IsSecondStepsAuthenticationEnabled) { %>
<%=this.GetMetadata(".VerifyPhone_CSS").HtmlEncodeSpecialCharactors() %>
<div class="verifyPhoneBox PopupLogin" style="display:none;">
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
<script type="text/javascript">
    $(function() {
        $('.verifyPhoneBox').off('click', '#btnMobileVerfication').on('click', '#btnMobileVerfication', function(e) {
            e.preventDefault();
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