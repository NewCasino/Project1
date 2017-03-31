<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


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
<%
        if (Profile.IsAuthenticated) {
            Response.Redirect("/Deposit");
        }
         %>
<div class="main-pane">
<div id="forgot-pwd-wrapper" class="content-wrapper forgotWrapper">
<div class="DialogHeader">
        <span class="DialogIcon">ArtemisBet</span>
        <h3 class="DialogTitle"><%= this.GetMetadata(".LoginDialogTitle") %></h3>
        <p class="DialogInfo"><%= this.GetMetadata(".LoginDialogInfo") %></p>
    </div>

<ui:Panel runat="server" ID="pnForgotPwd">

    <%--: Html.InformationMessage( this.GetMetadata(".Message") ) --%>

<% using( Html.BeginRouteForm( "ForgotPassword", new { @action = "SendEmail" }, FormMethod.Post, new { @id="formForgotPassword", @target="_self" } ) )
   { %>
<%------------------------------------------
    Forgot Password Email
 -------------------------------------------%>
<label for="email" class="inputfield_Label"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></label>
<ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
<LabelPart></LabelPart>
<ControlPart>
        <%: Html.TextBox("email", "", new
            {
                @placeholder = this.GetMetadata(".EmailPlaceholder"),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Email_Empty")).Email(this.GetMetadata(".Email_Invalid"))
            })%>
</ControlPart>
</ui:InputField>

<%------------------------------------------
    Captcha
 -------------------------------------------%>
<% Html.RenderPartial("/Components/Captcha", this.ViewData); %>

<div  class="ForgotpassEmail">
    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnSendForgotPasswordEmail", @type = "submit", @class="Button" })%>
</div>

<% } %>

<div class="login-guide-box">
    <div class="guide-title"><%=this.GetMetadata(".Guide_Login_Title")%></div>

    <div class="guide-link"><%=this.GetMetadata(".Guide_Login_Link")%></div>
   <div class="guide-title"><%=this.GetMetadata(".Guide_Reg_Title")%></div> 
    <div class="guide-button"><%: Html.Button(this.GetMetadata(".Button_SignUp"), new { @id = "btnGoToSignUpPage", @type = "submit" })%></div>
</div>


</ui:Panel>

 <div class="RegisterSupport">
            <%=this.GetMetadata(".RegisterSupportGirl") %>
            <p class="RegisterSupportText"><%= this.GetMetadata(".RegisterSupportText") %></p>
        </div>
    </div>

</div>
</div>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formForgotPassword').initializeForm();
        $('#btnGoToSignUpPage').click(function(e){
            window.location.href="/register";
        });
        $('#btnSendForgotPasswordEmail').click(function (e) {
            if (!$('#formForgotPassword').valid()) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true)
        });
    });
</script>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('forgotpassword-popup').addClass('register-popup').addClass('forgot-page');
$(document).ready(function () {
$('#ARFrameLoader', top.document.body).contents().find('body').removeClass("forgot-page");
});
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

