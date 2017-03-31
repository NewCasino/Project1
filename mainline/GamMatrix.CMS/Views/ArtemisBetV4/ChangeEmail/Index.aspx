<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%Response.Redirect("/");%>
<div id="changeemail-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnChangeEmail">


<%
    if (Profile.IsAuthenticated)
        Html.RenderPartial("InputView", this.ViewData);
    else
        Html.RenderPartial("Anonymous", this.ViewData);
%>

</ui:Panel>

</div>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('ProfilePage ChangeEmail');
jQuery('.inner').addClass('ProfileContent ChangeEmailContent');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');
setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
</script>
</ui:MinifiedJavascriptControl>


</asp:Content>

