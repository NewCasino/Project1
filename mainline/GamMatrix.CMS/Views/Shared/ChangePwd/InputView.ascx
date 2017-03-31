<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<% using (Html.BeginRouteForm("ChangePwd", new { @action = "Save" }, FormMethod.Post, new { @id = "formChangePwd" }))
   { %>
<%------------------------------------------
    Old Password
 -------------------------------------------%>
<ui:InputField ID="fldOldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".OldPassword_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("oldPassword", string.Empty, new 
		{
            @maxlength = 20,
            @id = "txtOldPassword",
            @type = "password",
            @autocomplete = "off",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".OldPassword_Empty"))
		}
			) %>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    New Password
 -------------------------------------------%>
<ui:InputField ID="fldNewPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".NewPassword_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("newPassword", string.Empty, new 
		{
            @maxlength = Settings.Registration.PasswordMaxLength,
            @id = "txtNewPassword",
            @type = "password",
            @autocomplete = "off",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".NewPassword_Empty"))
                .MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata(".NewPassword_Invalid"))
                .Custom("validatePassword")
		}
			) %>
	</ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptPassword" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function validatePassword() {
        var value = this;
        if(avoidSameUsernamePassword())
        {   
            if(value.toLowerCase()=='<%=Profile.UserName.SafeJavascriptStringEncode() %>'.toLowerCase())
                return '<%= this.GetMetadata(".Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        }
        if(value == $("#txtOldPassword").val())
        {
            return '<%= this.GetMetadata(".Password_SameWithOldPassword").SafeJavascriptStringEncode() %>';
        }
        var ret = <%=this.GetMetadata("Metadata/Settings.Password_ValidationRegex") %>.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".Password_UnSafe").SafeJavascriptStringEncode() %>';
        return true;
    }

    
    function avoidSameUsernamePassword() {
        return <%= Settings.Registration.AvoidSameUsernamePassword.ToString().ToLowerInvariant() %>;
    }
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Repeat Password
 -------------------------------------------%>
<ui:InputField ID="fldRepeatPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("repeatPassword", string.Empty, new 
		{
            @maxlength = Settings.Registration.PasswordMaxLength,
            @id = "txtRepeatPassword",
            @type = "password",
            @autocomplete = "off",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".RepeatPassword_Empty"))
                .EqualTo("#txtNewPassword", this.GetMetadata(".RepeatPassword_NotMatch"))
		}
			) %>
	</ControlPart>
</ui:InputField>

<div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Button_Save"), new { @id ="btnChangePwd", @type="submit"}) %>
</div>

<% } %>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formChangePwd').initializeForm();

        $('#btnChangePwd').click(function (e) {
            e.preventDefault();

            if (!$('#formChangePwd').valid())
                return;
                
            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnChangePwd').toggleLoadingSpin(false);
                    $('#formChangePwd').parent().html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnChangePwd').toggleLoadingSpin(false);
                }
            };
            $('#formChangePwd').ajaxForm(options);
            $('#formChangePwd').submit();
        });
    });
</script>