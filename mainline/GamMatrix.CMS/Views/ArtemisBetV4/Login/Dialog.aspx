<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<script language="C#" runat="server" type="text/C#">
    private string RefUrl {
        get {
            if (!string.IsNullOrEmpty(Request.QueryString["refUrl"]))
                return Request.QueryString["refUrl"];
            else if (!string.IsNullOrEmpty(Request.QueryString["url"]))
                return Request.QueryString["url"];
            return string.Empty;
        }
    }

    private string Target {
        get {
            if (!string.IsNullOrEmpty(Request.QueryString["target"]))
                return Request.QueryString["target"];
            return "top";
        }
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">

<div class="DialogHeader">
    <span class="DialogIcon">ArtemisBet</span>
    <h3 class="DialogTitle"><%= this.GetMetadata(".LoginDialogTitle") %></h3>
    <p class="DialogInfo"><%= this.GetMetadata(".LoginDialogInfo") %></p>
</div>
<div class="LoginDialogContainer">
    <% if (!Profile.IsAuthenticated) { %><form class="LoginDialog" action="#" onsubmit="return false;" autocomplete="false"><fieldset><% } else { %><div class="LoginDialog"><% } %>
        <%: Html.Partial("/Head/LoginPane", this.ViewData.Merge(new { RefreshTarget = Target, refUrl = RefUrl }))%>
        <%: Html.Partial("/Head/ForgotPassword", this.ViewData.Merge())%>
        <%: Html.Partial("/Head/SignUp", this.ViewData.Merge())%>
    <% if (!Profile.IsAuthenticated) { %></fieldset></form><% } else { %></div><% } %>
</div>

<ui:MinifiedJavascriptControl runat="server">
    <script type="text/javascript">
        function ShowGameFromPopup() {
            try{ parent.ShowGameFromPopup(); }catch(ex){}
        }
        $(function () {
            $('#simplemodal-container .CasinoHallDialog', top.document.body).parent().parent().addClass("PopUpContainer Login-popup-Container");
            $('#simplemodal-container .CasinoHallDialog', top.document.body).contents().find('body').addClass("PopUpPage Login-popup");
            $(document).bind('LOGIN_SUCESSED', function (e) {
                try {
                    if (window.parent != window.self)
                        parent.window.$(parent.document).trigger('LOGIN_SUCESSED');
                    ShowGameFromPopup();
                } catch (ex) { }
            });
    
            function getDocument(f) {
                try {
                    return f && typeof (f) == 'object' && f.contentDocument || f.contentWindow && f.contentWindow.document || f.document;
                } catch (e) {
                    return null;
                }
            };
            function getCurrentIframe() {
                try {
                    var iframes = parent.document.getElementsByTagName("iframe");
    
                    for (var i = 0; i < iframes.length; i++) {
                        var $iframe = $(iframes[i]);
                        var doc = getDocument(iframes[i]);
                        if (doc == null) continue;
    
                        if (doc.location == document.location) {
                            return $iframe;
                        }
                    }
                } catch (ex) { }
                return null;
            }
    
            $('a.simplemodal-close', parent.document.body).click(function (e) {
                var $iframe = getCurrentIframe();
                if ($iframe != null)
                    $iframe.hide().attr('src', 'about:blank');
            });
        });
    </script>
</ui:MinifiedJavascriptControl>

</asp:content>