<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="OAuth" %>
<script runat="server">
    private bool showLoginPanel
    {
        get
        {
            bool bolRtl = true;
            if (ViewData.ContainsKey("loginPanel") && ViewData["LoginPanel"] != null)
                bool.TryParse(ViewData["LoginPanel"].ToString(), out bolRtl);
            if (!bolRtl)
                return false;

            if (!AuthParty_Setting.Enable_Login)
                return false;

            if (AuthParty_Setting.Enable_Facebook
            || AuthParty_Setting.Enable_Google
            || AuthParty_Setting.Enable_MailRu
            || AuthParty_Setting.Enable_Twitter
            || AuthParty_Setting.Enable_VKontakte
            || AuthParty_Setting.Enable_Yandex)
                return true;
            else
                return false;
        }
    }
    private bool showAssociate
    {
        get
        {
            bool bolRtl = true;
            if (ViewData.ContainsKey("associate") && ViewData["Associate"] != null)
                bool.TryParse(ViewData["Associate"].ToString(), out bolRtl);

            if (!bolRtl)
                return false;

            if (AuthParty_Setting.Enable_Facebook
            || AuthParty_Setting.Enable_Google
            || AuthParty_Setting.Enable_MailRu
            || AuthParty_Setting.Enable_Twitter
            || AuthParty_Setting.Enable_VKontakte
            || AuthParty_Setting.Enable_Yandex)
                return true;
            else
                return false;
        }
    }
    private string getClass(ExternalAuthParty authParty, bool associate)
    {
        Dictionary<ExternalAuthParty, bool> dicAuthPary = ExternalAuthManager.GetAuthPartyStatus(Profile.DomainID, Profile.UserName);

        if (dicAuthPary.ContainsKey(authParty))
        {
            if (associate)
                return "button unenable";
            else
                return string.Empty;
        }
        else
        {
            if (associate)
                return string.Empty;
            else
                return "button unenable";
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        if (!showLoginPanel && !showAssociate)
            this.Visible = false;
        else
            this.Visible = true;

        base.OnPreRender(e);
    }
</script>
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
        top.location = "/Register?referrerID=" + referrerID;
    }

    $(function () {
        $('.externalItem a').click(function () {
            g_wnd = openWnd('/ExternalLogin/OAuth?authParty=' + $(this).attr('code'));
        });
    });
</script>
<div class="external_wrap">
    <% if (!Profile.IsAuthenticated && showLoginPanel)
       { %>
    <span><%= this.GetMetadata(".LoginWith") %></span>
    <div class="external_loginpanel">
        <ul>
            <% if (AuthParty_Setting.Enable_Facebook)
               { %>
            <li class="externalItem"><a code="<%= ExternalAuthParty.Facebook %>" class="item_Facebook" title="Facebook">Facebook</a></li>
            <%} %>
            <% if (AuthParty_Setting.Enable_Google)
               { %>
            <li class="externalItem"><a code="<%= ExternalAuthParty.Google %>" class="item_Google" title="Google">Google</a></li>
            <%} %>
            <% if (AuthParty_Setting.Enable_MailRu)
               { %>
            <li class="externalItem"><a code="<%= ExternalAuthParty.MailRu %>" class="item_MailRu" title="Mail.ru">MailRu</a></li>
            <%} %>
            <% if (AuthParty_Setting.Enable_Twitter)
               { %>
            <li class="externalItem"><a code="<%= ExternalAuthParty.Twitter %>" class="item_Twitter" title="Twitter">Twitter</a></li>
            <%} %>
            <% if (AuthParty_Setting.Enable_VKontakte)
               { %>
            <li class="externalItem"><a code="<%= ExternalAuthParty.VKontakte %>" class="item_VKontakte" title="VK">VKontakte</a></li>
            <%} %>
            <% if (AuthParty_Setting.Enable_Yandex)
               { %>
            <li class="externalItem"><a code="<%= ExternalAuthParty.Yandex %>" class="item_Yandex" title="Yandex">Yandex</a></li>
            <%} %>
        </ul>
    </div>
    <span><%= this.GetMetadata(".LoginWithOR") %></span>
    <%} %>
    <% if (Profile.IsAuthenticated && showAssociate)
       { %>
    <div class="external_associate">
        <ul>
            <% if (AuthParty_Setting.Enable_Facebook)
               { %>
            <li class="externalItem"><a class="item_Facebook"></a>
                <%:Html.Button(this.GetMetadata(".Associate"), new { id="btn_Facebook_associate",code=ExternalAuthParty.Facebook ,action=ExternalAuthAction.Associate, @class=getClass(ExternalAuthParty.Facebook,true) })%>
                <%:Html.Button(this.GetMetadata(".Unassociate"), new { id="btn_Facebook_Unssociate",code=ExternalAuthParty.Facebook ,action=ExternalAuthAction.Unassociate, @class=getClass(ExternalAuthParty.Facebook,false)  })%>
            </li>
            <%} %>
            <% if (AuthParty_Setting.Enable_Google)
               { %>
            <li class="externalItem"><a class="item_Google"></a>
                <%:Html.Button(this.GetMetadata(".Associate"), new { id="btn_Google_associate",code=ExternalAuthParty.Google ,action=ExternalAuthAction.Associate, @class=getClass(ExternalAuthParty.Google,true)  })%>
                <%:Html.Button(this.GetMetadata(".Unassociate"), new { id="btn_Google_Unssociate",code=ExternalAuthParty.Google ,action=ExternalAuthAction.Unassociate, @class=getClass(ExternalAuthParty.Google,false)  })%>
            </li>
            <%} %>
            <% if (AuthParty_Setting.Enable_Twitter)
               { %>
            <li class="externalItem"><a class="item_Twitter"></a>
                <%:Html.Button(this.GetMetadata(".Associate"), new { id="btn_Twitter_associate",code=ExternalAuthParty.Twitter ,action=ExternalAuthAction.Associate, @class=getClass(ExternalAuthParty.Twitter,true)  })%>
                <%:Html.Button(this.GetMetadata(".Unassociate"), new { id="btn_Twitter_Unssociate",code=ExternalAuthParty.Twitter ,action=ExternalAuthAction.Unassociate, @class=getClass(ExternalAuthParty.Twitter,false)  })%>
            </li>
            <%} %>
            <% if (AuthParty_Setting.Enable_VKontakte)
               { %>
            <li class="externalItem"><a class="item_VKontakte"></a>
                <%:Html.Button(this.GetMetadata(".Associate"), new { id="btn_VKontakte_associate",code=ExternalAuthParty.VKontakte ,action=ExternalAuthAction.Associate, @class=getClass(ExternalAuthParty.VKontakte,true)  })%>
                <%:Html.Button(this.GetMetadata(".Unassociate"), new { id="btn_VKontakte_Unssociate",code=ExternalAuthParty.VKontakte ,action=ExternalAuthAction.Unassociate, @class=getClass(ExternalAuthParty.VKontakte,false)  })%>
            </li>
            <%} %>
            <% if (AuthParty_Setting.Enable_Yandex)
               { %>
            <li class="externalItem"><a class="item_Yandex"></a>
                <%:Html.Button(this.GetMetadata(".Associate"), new { id="btn_Yandex_associate",code=ExternalAuthParty.Yandex ,action=ExternalAuthAction.Associate , @class=getClass(ExternalAuthParty.Yandex,true) })%>
                <%:Html.Button(this.GetMetadata(".Unassociate"), new { id="btn_Yandex_Unssociate",code=ExternalAuthParty.Yandex ,action=ExternalAuthAction.Unassociate, @class=getClass(ExternalAuthParty.Yandex,false)  })%>
            </li>
            <%} %>
            <% if (AuthParty_Setting.Enable_MailRu)
               { %>
            <li class="externalItem"><a class="item_MailRu"></a>
                <%:Html.Button(this.GetMetadata(".Associate"), new { id="btn_MailRu_associate",code=ExternalAuthParty.MailRu ,action=ExternalAuthAction.Associate, @class=getClass(ExternalAuthParty.MailRu,true)  })%>
                <%:Html.Button(this.GetMetadata(".Unassociate"), new { id="btn_MailRu_Unssociate",code=ExternalAuthParty.MailRu ,action=ExternalAuthAction.Unassociate, @class=getClass(ExternalAuthParty.MailRu,false)  })%>
            </li>
            <%} %>
        </ul>
    </div>
    <%} %>
</div>
