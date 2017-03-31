<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
 <div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ForgotPass/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ForgotPass/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div class="main-pane">
<div id="forgot-pwd-wrapper" class="content-wrapper forgotStep2 forgotWrapper">


    <div class="DialogHeader">
       <span class="DialogIcon">ArtemisBet</span>
       <h3 class="DialogTitle"><%= this.GetMetadata(".HEAD_TEXT") %></h3>
       <p class="DialogInfo"><%= this.GetMetadata(".LoginDialogInfo") %></p>
    </div>
    <p class="message"> <%: this.GetMetadata(".Success_Message") %> </p>
    <p class="message"><%: this.GetMetadata(".Info_Message")  %> </p>
    <div class="RegisterSupport">
       <%=this.GetMetadata(".RegisterSupportGirl") %>
       <p class="RegisterSupportText"><%= this.GetMetadata(".RegisterSupportText") %></p>
    </div>
</div>
</div>
<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('forgotpassword-popup').addClass('register-popup').addClass('ForgotPwdEmailSent');
$(document).ready(function () {
$('#ARFrameLoader', top.document.body).contents().find('body').removeClass("forgot-page");
});
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

