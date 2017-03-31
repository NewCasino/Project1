<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="CM.Sites" %>

<script language="C#" runat="server" type="text/C#">
    private string _RefreshTarget = "self";
    protected string RefreshTarget {
        get { return _RefreshTarget; }
        set { _RefreshTarget = value; }
    }

    private string RefUrl
    {
        get {
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
</script>

<% if (!Profile.IsAuthenticated)
   {
%>
<div id="login-pane">
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
    <div class="login_btn">
        <%: Html.Button( this.GetMetadata(".Login_Btn_Text"), new { @type = "submit" }) %>
    </div>
    <div style="clear:both"></div>
</div>


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
            $('#login-pane div.login_btn button').toggleLoadingSpin(false);
            try{
                if (window.parent)
                    window.parent.$('#login-pane div.login_btn button').toggleLoadingSpin(false);
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
            case "captchanotmatch":
                $('.captcha_wrap img.captcha_img').trigger('click');
                ToggleLoginLoadingSpin(false);
                alert(json.error);
                return;
            default:
                $('#login-pane div.login_btn button').toggleLoadingSpin(false);
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

<% }%>