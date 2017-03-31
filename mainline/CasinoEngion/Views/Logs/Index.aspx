<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" Inherits="System.Web.Mvc.ViewPage<dynamic>" %>

<script type="text/C#" language="C#" runat="Server">
    private string GetGameMonitorUrl()
    {
        if( Request.Cookies["gmcoresid"] == null )
            return string.Empty;

        return string.Format("{0}/?session_id={1}"
            , ConfigurationManager.AppSettings["GmLogging.ApiHost"]
            , Request.Cookies["gmcoresid"].Value
            );
    }
</script>

<asp:Content ContentPlaceHolderID="phMain" runat="server">
<style type="text/css">
    html, body { width:100%; height:100%; }
    body { overflow:hidden; }
    #wrapper { margin:0px !important;   width: 100% !important;}
    #ifmGameMonitor { width:100%; }
</style>
<iframe id="ifmGameMonitor" src="<%= GetGameMonitorUrl().SafeHtmlEncode() %>" frameborder="0" scrolling="auto"></iframe>

<script type="text/javascript">
    $(function () {
        var resizeHandler = function () {
            $('#ifmGameMonitor').height( $(document.body).height() - $('#header').height() );
        };
        resizeHandler();
        $(window).bind( 'resize', resizeHandler);
    });
</script>

</asp:Content>
