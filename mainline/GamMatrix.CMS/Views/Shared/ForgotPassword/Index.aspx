<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="forgot-pwd-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>


<ui:Panel runat="server" ID="pnForgotPwd">

<center>
    <%: Html.InformationMessage( this.GetMetadata(".Message") ) %>
</center>
<% using( Html.BeginRouteForm( "ForgotPassword", new { @action = "SendEmail" }, FormMethod.Post, new { @id="formForgotPassword", @target="_self" } ) )
   { %>
<%------------------------------------------
    Forgot Password Email
 -------------------------------------------%>
<ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
	<LabelPart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("email", "", new
            {
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Email_Empty")).Email(this.GetMetadata(".Email_Invalid"))
            })%>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    Captcha
 -------------------------------------------%>
<% Html.RenderPartial("/Components/Captcha", this.ViewData); %>

<center>
    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnSendForgotPasswordEmail", @type = "submit" })%>
</center>
<%=this.GetMetadata(".RegGuide_Html").HtmlEncodeSpecialCharactors()%>
<% } %>
</ui:Panel>


</div>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formForgotPassword').initializeForm();

        $('#btnSendForgotPasswordEmail').click(function (e) {
            if (!$('#formForgotPassword').valid()) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true)
        });
    });
</script>


</asp:Content>

