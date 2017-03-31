<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="OAuth" %>
<script language="C#" runat="server" type="text/C#">
    protected ReferrerData ReferrerData
    {
        get
        {
            if (this.ViewData["ReferrerData"] == null)
                return null;

            return this.ViewData["ReferrerData"] as ReferrerData;
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        if (AuthParty_Setting.Enable_Facebook
            || AuthParty_Setting.Enable_Google
            || AuthParty_Setting.Enable_MailRu
            || AuthParty_Setting.Enable_Twitter
            || AuthParty_Setting.Enable_VKontakte
            || AuthParty_Setting.Enable_Yandex)
            this.Visible = true;
        else
            this.Visible = false;
        base.OnPreRender(e);
    }
</script>

<div class="quick-signup-panel">
    <%var referrerData = ReferrerData; %>
    <%if (referrerData == null) %>
    <%{ %>

    <div class="quick_signup_wapper">
        <%: Html.H2( this.GetMetadata(".Quick_Signup") ) %>
        <ul>
            <% if (AuthParty_Setting.Enable_Facebook) %>
            <% { %>
            <li class="externalItem_middle"><a code="Facebook" class="item_Facebook" title="Facebook"></a></li>
            <% } %>

            <% if (AuthParty_Setting.Enable_Google) %>
            <% { %>
            <li class="externalItem_middle"><a code="Google" class="item_Google" title="Google"></a></li>
            <% } %>

            <% if (AuthParty_Setting.Enable_MailRu) %>
            <% { %>
            <li class="externalItem_middle"><a code="MailRu" class="item_MailRu" title="Mail.ru"></a></li>
            <% } %>

            <% if (AuthParty_Setting.Enable_Twitter) %>
            <% { %>
            <li class="externalItem_middle"><a code="Twitter" class="item_Twitter" title="Twitter"></a></li>
            <% } %>

            <% if (AuthParty_Setting.Enable_VKontakte) %>
            <% { %>
            <li class="externalItem_middle"><a code="VKontakte" class="item_VKontakte" title="VK"></a></li>
            <% } %>

            <% if (AuthParty_Setting.Enable_Yandex) %>
            <% { %>
            <li class="externalItem_middle"><a code="Yandex" class="item_Yandex" title="Yandex"></a></li>
            <% } %>
        </ul>
        <div class="clear"></div>
    </div>

    <%} %>
    <%else %>
    <%{ %>
    <%:Html.Hidden("referrerID", referrerData.ID) %>
    <div class="connectted-wapper">
        <div class="externalInfo">
            <%
          var info = referrerData.ExternalUserInfo;
          var name = info.Firstname + " " + info.Lastname;
          name = name.Trim();
          if (string.IsNullOrWhiteSpace(name))
              name = this.GetMetadata(".Default_Name");
            %>
            <%:MvcHtmlString.Create(string.Format(this.GetMetadata(".Welcome"), name, referrerData.AuthParty.ToString())) %>
            <%--<div id="login-pane">
                <div class="username_wrap">
                    <%: Html.TextboxEx("username", "", this.GetMetadata(".Username_Wartermark"), new {placeholder = this.GetMetadata(".Username_Wartermark")})%>
                </div>
                <div class="password_wrap">
                    <%: Html.TextboxEx("password", "", this.GetMetadata(".Password_Wartermark"), new { type = "password", placeholder = this.GetMetadata(".Password_Wartermark") })%>
                </div>
                <div class="login_btn">
                    <%: Html.Button( this.GetMetadata(".Login_Btn_Text"), new { @type = "submit" }) %>
                </div>
                <div style="clear: both"></div>
            </div>--%>
        </div>
        <%if (referrerData.GetAssociateStatus() == AssociateStatus.EmailAlreadyRegistered)
          {%>
        <div class="externalEmailRegistered">
            <%:MvcHtmlString.Create(string.Format(this.GetMetadata(".Email_Already_Registered")
                                                  , info.Email
                                                  , SiteManager.Current.DisplayName
                                                  , referrerData.AuthParty.ToString().ToLowerInvariant())) %>
            <%: Html.Partial("/Head/LoginPane", this.ViewData.Merge(new { RefreshTarget = "top", ReferrerID = referrerData.ID }))%>
        </div>
        <%} %>
        <div class="clear"></div>
    </div>

    <%} %>
</div>
<hr />
<ui:MinifiedJavascriptControl runat="server" ID="scriptQuickSignup" AppendToPageEnd="false" Enabled="true">
    <script type="text/javascript">
        var g_wnd;

        function openWnd(url) {
            var width = 800;
            var height = 600;

            var a = typeof window.screenX != 'undefined' ? window.screenX : window.screenLeft;
            var i = typeof window.screenY != 'undefined' ? window.screenY : window.screenTop;
            var g = typeof window.outerWidth != 'undefined' ? window.outerWidth : document.documentElement.clientWidth;
            var f = typeof window.outerHeight != 'undefined' ? window.outerHeight : (document.documentElement.clientHeight - 22);
            var h = (a < 0) ? window.screen.width + a : a;
            var left = parseInt(h + ((g - width) / 2), 10);
            var top = parseInt(i + ((f - height) / 2.5), 10);

            var params = [
                'height=' + height,
                'width=' + width,
                'left=' + left,
                'top=' + top,
                'fullscreen=no',
                'scrollbars=no',
                'status=yes',
                'resizable=yes',
                'menubar=no',
                'toolbar=no',
                'addressbar=no',
                'location=no'
            ].join(',');

            var wnd = window.open(url, "thridpartyauth", params);
            if (wnd == null) {
                alert('Error, can not open the window!');
                return null;
            }
            return wnd;
        }

        function callback(referrerID) {
            if (g_wnd != null)
                g_wnd.close();

            <% if (this.ViewData["Type"] == "QuickRegister")%>
            <%{%>
            self.location = "/QuickRegister?referrerID=" + referrerID;
            <%}%>
            <%else%>
            <%{%>
            self.location = "/Register?referrerID=" + referrerID;
            <%}%>
        }

        $(function () {
            $('.externalItem_middle a').click(function () {
                g_wnd = openWnd('/ExternalLogin/OAuth?authParty=' + $(this).attr('code'));
            });

            $('.externalInfo a').click(function () {
                <% if (this.ViewData["Type"] == "QuickRegister")%>
                <%{%>
                self.location = "/QuickRegister";
                <%}%>
                <%else%>
                <%{%>
                self.location = "/Register";
                <%}%>
            });
        });
    </script>
</ui:MinifiedJavascriptControl>
