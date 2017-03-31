<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<center>
    <br />
    <%: Html.InformationMessage( this.GetMetadata(".Message"), true ) %>
</center>

<% using (Html.BeginRouteForm("ChangeEmail", new { @action = "ChangeEmail" }, FormMethod.Post, new { @id = "formChangeEmail" }))
   { %>
<%------------------------------------------
    New Email Address
 -------------------------------------------%>
<ui:InputField ID="fldNewEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".NewEmail_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("email", string.Empty, new 
		{
            @maxlength = "50",
            @id = "txtNewEmail",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".Email_Empty"))
                .Email(this.GetMetadata(".Email_Incorrect"))
                .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".Email_Exist") }))
		}
		) %>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    Password
 -------------------------------------------%>
<ui:InputField ID="fldUserPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("password", string.Empty, new 
		{
            @maxlength = 30,
            @id = "txtUserPassword",
            @type = "password",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".Password_Empty"))
		}
		) %>
	</ControlPart>
</ui:InputField>


<%: Html.Partial("/Components/Captcha", this.ViewData) %>


<div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Button_ChangeEmail"), new { @id ="btnChangeEmail", @type="submit"}) %>
</div>

<% } %>

<script type="text/javascript">
    $(function () {
        $('#formChangeEmail').initializeForm();

        $('#btnChangeEmail').click(function (e) {
            e.preventDefault();

            if (!$('#formChangeEmail').valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnChangeEmail').toggleLoadingSpin(false);
                    $('#formChangeEmail').parent().html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnChangeEmail').toggleLoadingSpin(false);
                }
            };
            $('#formChangeEmail').ajaxForm(options);
            $('#formChangeEmail').submit();
        });
    });
</script>