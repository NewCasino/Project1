<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

 <div class="content-wrapper ActivateAccountContainer">
<%= this.GetMetadata(".Html").HtmlEncodeSpecialCharactors() %>
       <%=this.GetMetadata(".RegisterSupportGirl") %>
            <p class="RegisterSupportText"><%= this.GetMetadata(".RegisterSupportText") %></p>
        </div>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
<script type="text/javascript">
jQuery('body').addClass('register-popup').addClass('PopUpPage').addClass('ActivateAccountPopup');
$('#simplemodal-container', top.document.body).addClass("PopUpContainer register-popup-Container");
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

