<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.State" %>

<%=this.GetMetadata(".CSS").HtmlEncodeSpecialCharactors() %>
<div id="overlay_DK" style="display:none"></div>
<div class="popup_DK_Content" style="display:none">

<a class="CloseDKPopup" href="#" title="Close this dialog">
                <span class="icon"></span></a>
<%= Html.InformationMessage( this.GetMetadata(".Html").HtmlEncodeSpecialCharactors(), true ) %>
</div>
<script type="text/javascript">
    var docHeight = $(document).height();
    $('#overlay_DK').attr("style", "opacity: 0.8;position:absolute;top:0;left:0;background-color:black;width:100%;z-index:5000;height:" + docHeight + "px;");

    $(".CloseDKPopup").click(function () {
        $(".popup_DK_Content,#overlay_DK").fadeOut();
        $("#DK_Popup_Container").css("display", "none");
        PageRediret();
    });
    $(document).ready(function () {
        var docWith = $(document).width();
        var closButtonRight = docWith * 0.05 - 12.5;
        $(".CloseDKPopup").css({ right: closButtonRight });
        $("#DK_Popup_Container").parent().css({ 'margin': '0', 'width': '100%' });
        $(".popup_DK_Content,#overlay_DK").fadeIn();
    });
</script>