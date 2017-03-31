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
</script>

<% if (!Profile.IsAuthenticated)
   {
%>
<div id="login-pane">
    <div class="username_wrap">
        <%: Html.TextboxEx(this.CtrlUsernameName, "", this.GetMetadata(".Username_Wartermark"), new {placeholder = this.GetMetadata(".Username_Wartermark")})%>
    </div>
    <div class="password_wrap">
        <%: Html.TextboxEx(this.CtrlPasswordName, "", this.GetMetadata(".Password_Wartermark"), new { type = "password", placeholder = this.GetMetadata(".Password_Wartermark") })%>
    </div>
    <div class="login_btn">
        <%: Html.Button( this.GetMetadata(".Login_Btn_Text"), new { @type = "submit" }) %>
    </div>
    <div style="clear:both"></div>
</div>

<iframe style="display:none" id="ifmLoginCallback" name="ifmLoginCallback"></iframe>

<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#login-pane div.login_btn button').click(function (e) {
            e.preventDefault();
            var username = $('#login-pane input[name="<%=this.CtrlUsernameName%>"]').val();
            var password = $('#login-pane input[name="<%=this.CtrlPasswordName%>"]').val();
            if (username == '' || password == '') {
                alert('<%= this.GetMetadata(".UsernamePassword_Empty").SafeJavascriptStringEncode() %>');
                return;
            }
            $(this).toggleLoadingSpin(true);

            var $form = $('<form style="display:none" target="ifmLoginCallback" method="POST"></form>').appendTo(document.body);
            $form.attr('action', '<%= GetLoginUrl().SafeJavascriptStringEncode() %>');
            $('<input type="hidden" name="username" />').appendTo($form).val(username);
            $('<input type="hidden" name="password" />').appendTo($form).val(password);
            $('<input type="hidden" name="baseURL" />').appendTo($form).val('<%= GetCurrentBaseUrl().SafeJavascriptStringEncode() %>');
            $('<input type="hidden" name="referrerID" />').appendTo($form).val('<%= this.ViewData["ReferrerID"]%>');
            $form.submit();
        });

        $('#login-pane input[name="password"]').keypress(function (e) {
            if (e.keyCode == 13) {
                $('#login-pane div.login_btn button').trigger('click');
            }
        });

        
    });

    function OnLoginResponse(json) {        
        $('#login-pane div.login_btn button').toggleLoadingSpin(false);
        if (window.parent)
            window.parent.$('#login-pane div.login_btn button').toggleLoadingSpin(false);
        if (!json.success) {
            alert(json.error);
            return;
        }
        switch (json.result.toLowerCase()) {
            case 'success':
                try{
                    var dest = window.<%=RefreshTarget %> || window.self;
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
                        dest.location = refUrl;
                    else if(dest == window.self)
                        dest.location = redirectUrl;
                    else
                        dest.location = destUrl;
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
            default:
                alert(json.error);
                return;
        }
    }
    self.OnLoginResponse = OnLoginResponse;
//]]>
</script>

<% }%>