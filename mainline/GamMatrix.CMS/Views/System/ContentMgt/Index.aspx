<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<script language="C#" type="text/C#" runat="server">
    private string GetIframeUrl()
    {
        if (Request.Browser.Type.IndexOf("Chrome", StringComparison.InvariantCultureIgnoreCase) >= 0
            || Request.Browser.Type.IndexOf("Firefox", StringComparison.InvariantCultureIgnoreCase) >= 0)
        {
            return "https://wiki:E:S_7^s%~8N9=*d@wiki.gammatrix.com";
        }
        else
        {
            return "https://wiki.gammatrix.com:2012/";
        }
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.blockUI.js") %>"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/ContentMgt/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<script language="javascript" type="text/javascript">
//<![CDATA[
    self.onNavTreeClicked = function (url) {
        $('#ifmMain').attr('src', url);
        var loc = top.location.toString();
        var index = loc.indexOf('#');
        if (index > 0)
            loc = loc.substr(0, index);
        loc = loc + '#' + url;
        top.location = loc;
    };
//]]>
</script>

<div id="overlapped-layer"></div>

<table id="main-table" cellpadding="0" cellspacing="0" border="0">
    <tr>
        <td class="tree">
            <iframe src="<%= Url.Action("TreeView").SafeHtmlEncode() %>" id="ifmTree" frameborder="0" scrolling="auto" width="100%" height="100%"></iframe>
        </td>
        <td class="splitter">
        </td>
        <td>
            <iframe frameborder="0" allowTransparency="true" width="100%" scrolling="auto" id="ifmMain" src="<%= GetIframeUrl().SafeHtmlEncode() %>" ></iframe>
        </td>
    </tr>
</table>


<ui:ExternalJavascriptControl runat="server">
<script language="javascript" type="text/javascript">
function ContentMgt() {
    self.ContentMgt = this;

    this.autoFit = function () {
        var $height = $(document.body).height() - $('#main-table').offset().top;
        $('#ifmTree').height($height);
        $('#ifmMain').height($height);
        $('#main-table').height($height);
    };

    this.onSplitterMouseDown = function () {
        $('#overlapped-layer').show();
    };

    this.onMouseMove = function (evt) {
        $('#main-table td.tree').width(evt.pageX);
    };

    this.onMoveStop = function () {
        $('#overlapped-layer').hide();
    };

    this.init = function () {
        this.autoFit();
        $(window).bind('resize', this, function (e) { e.data.autoFit(); });

        $('#main-table td.splitter').bind('mousedown', this, function (e) { e.data.onSplitterMouseDown(); });
        $('#overlapped-layer').hide().bind('mousemove', this, function (e) { e.data.onMouseMove(e); }).bind('mouseup', this, function (e) { e.data.onMoveStop(); });

        var url = self.location.toString();
        var index = url.indexOf('#');
        if (index > 0) {
            url = url.substr(index + 1);
            if (url.length > 0 && url != '/ContentMgt')
                $('#ifmMain').attr('src', url);
        }
    };   

    this.init();
}
$(document).ready(function () { new ContentMgt(); });


</script>
</ui:ExternalJavascriptControl>

</asp:Content>



