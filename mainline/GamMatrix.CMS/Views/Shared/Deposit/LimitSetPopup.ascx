<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script language="C#" type="text/C#" runat="server">
    private string GetLimitUrl()
    {
        return Url.RouteUrlEx("Limit", new { @ref=Request.RawUrl.SafeHtmlEncode()});
    }
</script>

<div id="uklimitpopup">
<%= Html.InformationMessage( string.Format(this.GetMetadata(".Message"), GetLimitUrl()).HtmlEncodeSpecialCharactors(), true ) %>
</div>
<script type="text/javascript">
    var ukPopupInterval;

    function showPopup() {
        if (PopupCounter.tc)
            return;

        window.clearInterval(ukPopupInterval);

        var $body = $(top.document.body);

        if ($body.find("#uklimitpopup").length == 0) {
            $("#uklimitpopup").appendTo(top.document.body);
        }

        $body.find("#uklimitpopup").modalex(650, 200, true, top.document.body);
        $body.find("#simplemodal-container .simplemodal-close").css("display", "block");
    }

    $(function () {
        ukPopupInterval = window.setInterval('showPopup()', 2000);
     });
</script>