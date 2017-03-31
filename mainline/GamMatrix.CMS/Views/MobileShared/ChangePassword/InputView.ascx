<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.Web.UI" %>

<form action="<%= this.Url.RouteUrl("ChangePassword", new { @action = "Save" }).SafeHtmlEncode()%>"
    method="post" enctype="application/x-www-form-urlencoded" id="formChangePassword" target="_self">
    
    <fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
		</legend>

        <ul class="FormList">
        <%------------------------------------------
            Old Password
         -------------------------------------------%>
        <li class="FormItem">
        <label class="FormLabel" for="changePasswordOldPassword"><%= this.GetMetadata(".OldPassword_Label").SafeHtmlEncode()%></label>  
        <%: Html.TextBox("oldPassword", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "changePasswordOldPassword" },
                    { "maxlength", "20" },
                    { "type", "password" },
                    { "autocomplete", "off" },
                    { "placeholder", this.GetMetadata(".OldPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".OldPassword_Empty"))}                    
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>      
        </li>

        <%------------------------------------------
            New Password
         -------------------------------------------%>
         <li class="FormItem">
        <label class="FormLabel" for="changePasswordNewPassword"><%= this.GetMetadata(".NewPassword_Label").SafeHtmlEncode()%></label>  
        <%: Html.TextBox("newPassword", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "changePasswordNewPassword" },
                    { "maxlength", Settings.Registration.PasswordMaxLength },
                    { "type", "password" },
                    { "autocomplete", "off" },
                    { "placeholder", this.GetMetadata(".NewPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".NewPassword_Empty")).MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata(".NewPassword_Incorrect")).Custom("validatePassword") }
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>      
        </li>
        
		<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl2" runat="server" Enabled="true">
        <script type="text/javascript">
            function validatePassword() {
                var value = this;
				<% if (Settings.Registration.AvoidSameUsernamePassword) 
				   { %>
            		var user = '<%=Profile.UserName.SafeJavascriptStringEncode() %>';
            		if (value.toLowerCase() == user.toLowerCase())
            			return '<%= this.GetMetadata(".Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        		<% }
			
				if (!string.IsNullOrWhiteSpace(Settings.Password_ValidationRegex)) 
				{ %>
            		var test = new RegExp(<%= Settings.Password_ValidationRegex %>).exec(value);
            		if (test == null || test.length == 0)
            			return '<%= this.GetMetadata(".Password_UnSafe").SafeHtmlEncode() %>';
				<% } %>
                return true;
            }
        </script>
		</ui:MinifiedJavascriptControl>
        
        <%------------------------------------------
            Repeat Password
         -------------------------------------------%>
         <li class="FormItem">
        <label class="FormLabel" for="changePasswordRepeatPassword"><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></label>  
        <%: Html.TextBox("repeatPassword", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "changePasswordRepeatPassword" },
                    { "maxlength", Settings.Registration.PasswordMaxLength },
                    { "type", "password" },
                    { "autocomplete", "off" },
                    { "placeholder", this.GetMetadata(".RepeatPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".RepeatPassword_Empty")).EqualTo("#changePasswordNewPassword", this.GetMetadata(".RepeatPassword_NotMatch")) }
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>      
        </li>
        </ul>

        <div class="AccountButtonContainer">
		<button id="btnChangePassword" class="Button AccountButton" type="submit">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_Save").SafeHtmlEncode()%></strong>
		</button>
	</div>
</fieldset>

<span id="changePasswordError" class="FormHelp FormError"></span>
</form>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="false"
    AppendToPageEnd="true">
<script type="text/javascript">
    function ChangePasswordInputView() {
        var formChangePassword = $("#formChangePassword");

        var errorField = $("#changePasswordError"),
                oldPasswordField = $("#changePasswordOldPassword"),
                newPasswordField = $("#changePasswordNewPassword");

        formChangePassword.submit(function (event) {
            if (formChangePassword.valid()) {
                $.ajax({
                    type: 'POST',
                    url: $(this).attr('action'),
                    data: {
                        oldPassword: oldPasswordField.val(),
                        newPassword: newPasswordField.val()
                    },
                    success: changePasswordResponse,
                    error: showErrorfunction,
                    dataType: 'html'
                });
            }

            return false;
        });

        function changePasswordResponse(html) {
            formChangePassword.parent().html(html);
        }

        function showErrorfunction(XMLHttpRequest, textStatus, errorThrown) {
            errorField.text(textStatus + errorThrown).show();
        }
        
    }

    $(function () {
        new ChangePasswordInputView();
    });
</script>
</ui:MinifiedJavascriptControl>