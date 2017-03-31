<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.State" %>

<script type="text/javascript">
    <% if (Profile.IsAuthenticated && Settings.DKLicense.IsDKLoginPopup) { %>
        $('iframe.DK_LoginPopup').remove();
        $('<iframe style="border:0px;width:500px;height:300px;display:none" frameborder="0" scrolling="no" allowTransparency="true" class="DK_LoginPopup"></iframe>').appendTo(top.document.body);
        var $iframe = $('iframe.DK_LoginPopup', top.document.body).eq(0);
        $iframe.attr('src', "/Login/DKLoginPopup?_=<%= DateTime.Now.Ticks %>&frameId=" + frameId);
        $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
    <% } %>
    <% else { %>
        LoginSuccessPageRediret();
    <% } %>
</script>