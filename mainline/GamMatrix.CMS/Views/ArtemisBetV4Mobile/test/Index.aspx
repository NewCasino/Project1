<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<script type="text/javascript" src="//cdn.everymatrix.com/_js/jquery-1.11.2.min.js"></script>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<a class="lebtn"><div id="LP_DIV_1474557484003" style="display:none;"></div></a>
<div id="ex1" class="LiveChatFixed" style="cursor: pointer;">
<span>Need help?</span>
<em>Contact our</em>
<strong>LIVE SUPPORT</strong>
<em>online 24/7</em>
</div>
<script type="text/javascript">
$("#ex1").click(function(e){
    $(".lebtn div").trigger("click");
});
$(function() {
    $("[src='//cdn.everymatrix.com/_js/combined.js']").remove();
});
</script>
<%= this.GetMetadata(".LiveChat") %>
</asp:Content>