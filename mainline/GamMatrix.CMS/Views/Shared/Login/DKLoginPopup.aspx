<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%=this.GetMetadata(".CSS").HtmlEncodeSpecialCharactors() %>
<%= Html.InformationMessage( this.GetMetadata(".Html").HtmlEncodeSpecialCharactors(), true ) %>
<script type="text/javascript">
    $('html').addClass('DKPopupPage');
    function getUrlParam(name) {
        var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)"); 
        var r = window.location.search.substr(1).match(reg); 
        if (r != null) return unescape(r[2]); return null; 
    }
    $(window.parent.document).find(".simplemodal-close").css("display", "block");
    var frameId = getUrlParam('frameId');
    $(window).unload(function () {
        try {
            if (frameId != undefined) {
                if (frameId != ''){
                    window.top.window.frames[frameId][0].contentWindow.LoginSuccessPageRediret();
                }
                else {
                    window.top.LoginSuccessPageRediret();
                }
            }
            else { window.top.location = "/"; }
        }
        catch (e) { window.top.location = "/";}
    });
</script>
</asp:Content>
