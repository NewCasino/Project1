<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="buddytransfer-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnBuddyTransfer">
 <div class="InnerBuddyTransfer">

        <%: Html.ErrorMessage( this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true ) %>
 </div>
</ui:Panel>
</div>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('TransferPage BuddyTransfer');
jQuery('.inner').addClass('ProfileContent TransferContent BuddyTransferContent');
jQuery('.MainProfile').addClass('MainWithdraw MainTransfer MainBuddyTransfer');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');

setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>



