<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="forgot-pwd-wrapper" class="content-wrapper">
<div class="DialogHeader">
        <span class="DialogIcon">ArtemisBet</span>
        <h3 class="DialogTitle"><%= this.GetMetadata(".HEAD_TEXT") %></h3>
        <p class="DialogInfo"><%= this.GetMetadata(".LoginDialogInfo") %></p>
    </div>



        <%: Html.ErrorMessage(
            (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
                    this.Request["ErrorMessage"].DefaultIfNullOrEmpty( this.GetMetadata(".Message") ) 
                           )
            ) %>
<div class="RegisterSupport">
            <%=this.GetMetadata(".RegisterSupportGirl") %>
            <p class="RegisterSupportText"><%= this.GetMetadata(".RegisterSupportText") %></p>
        </div>
    </div>
</div>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('ForgotPwdError');
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

