<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="ErrorCol PromotionWrap">
    <h1 class="PageTitle MobilePageHeader"><%: this.GetMetadata(".Content_Title") %> </h1>

    <div class="HalfCol"><%=this.GetMetadata(".Content_Text").HtmlEncodeSpecialCharactors()%>
    </div>
<div class="HalfCol">
<%=this.GetMetadata(".Content_Navigation").HtmlEncodeSpecialCharactors()%>
</div>
<div class="ButtonCol">
<a class="button PageNotFoundButton" href="/">
<strong>ArtemisBet Homepage</strong></a>
</div>
<script type="text/javascript">
var GOOG_FIXURL_LANG = '<%=System.Threading.Thread.CurrentThread.CurrentUICulture.Name %>';
var GOOG_FIXURL_SITE = 'window.location || window.location.href';
</script><script type="text/javascript" src="http://linkhelp.clients.google.com/tbproxy/lh/wm/fixurl.js"></script>
</div>



</div>
</asp:Content>

