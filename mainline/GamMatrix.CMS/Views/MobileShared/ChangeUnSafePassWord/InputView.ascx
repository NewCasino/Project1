<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<form action="<%= this.Url.RouteUrl("_ChangeUnSafePassWord", new { @action = "SaveSafe" }).SafeHtmlEncode()%>"
    method="post" enctype="application/x-www-form-urlencoded" id="formChangePassword" target="_self">
    
<div class="unsafeError"><% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Warning, this.GetMetadata("/Metadata/ServerResponse.Login_NeedChangePassword")) { IsHtml = true }); %></div>
    <fieldset>
<legend class="hidden">
<%= this.GetMetadata("/ChangePassword/_InputView_ascx.Legend").SafeHtmlEncode() %>
</legend>

        <ul class="FormList">
        <li class="FormItem">
            <label class="FormLabel" for="changePasswordOldPassword"><%= this.GetMetadata("/Components/_LoginForm_ascx.UserLabel").SafeHtmlEncode() %></label>
            <%: Html.TextBox("username", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "txtUserName" },
                    { "placeholder", this.GetMetadata("/Components/_LoginForm_ascx.UserPlaceholder") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Username_Empty"))}                    
                }) %>
                <span class="FormStatus">Status</span>
<span class="FormHelp"></span>      
        </li>
        <%------------------------------------------
            Old Password
         -------------------------------------------%>
        <li class="FormItem">
        <label class="FormLabel" for="changePasswordOldPassword"><%= this.GetMetadata("/ChangePassword/_InputView_ascx.OldPassword_Label").SafeHtmlEncode()%></label>  
        <%: Html.TextBox("oldPassword", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "changePasswordOldPassword" },
                    { "maxlength", "20" },
                    { "type", "password" },
                    { "placeholder", this.GetMetadata("/ChangePassword/_InputView_ascx.OldPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata("/ChangePassword/_InputView_ascx.OldPassword_Empty"))}                    
                }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>      
        </li>

        <%------------------------------------------
            New Password
         -------------------------------------------%>
         <li class="FormItem">
        <label class="FormLabel" for="changePasswordNewPassword"><%= this.GetMetadata("/ChangePassword/_InputView_ascx.NewPassword_Label").SafeHtmlEncode()%></label>  
        <%: Html.TextBox("newPassword", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "changePasswordNewPassword" },
                    { "maxlength", Settings.Registration.PasswordMaxLength },
                    { "type", "password" },
                    { "placeholder", this.GetMetadata("/ChangePassword/_InputView_ascx.NewPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata("/ChangePassword/_InputView_ascx.NewPassword_Empty")).MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata("/ChangePassword/_InputView_ascx.NewPassword_Incorrect")).Custom("validatePassword") }
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
                    return '<%= this.GetMetadata("/ChangePassword/_InputView_ascx.Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        <% }

if (!string.IsNullOrWhiteSpace(Settings.Password_ValidationRegex)) 
{ %>
                var test = new RegExp(<%= Settings.Password_ValidationRegex %>).exec(value);
                if (test == null || test.length == 0)
                    return '<%= this.GetMetadata("/ChangePassword/_InputView_ascx.Password_UnSafe").HtmlEncodeSpecialCharactors() %>';
<% } %>
                return true;
            }
        </script>
</ui:MinifiedJavascriptControl>
        
        <%------------------------------------------
            Repeat Password
         -------------------------------------------%>
         <li class="FormItem">
        <label class="FormLabel" for="changePasswordRepeatPassword"><%= this.GetMetadata("/ChangePassword/_InputView_ascx.RepeatPassword_Label").SafeHtmlEncode()%></label>  
        <%: Html.TextBox("repeatPassword", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "changePasswordRepeatPassword" },
                    { "maxlength", Settings.Registration.PasswordMaxLength },
                    { "type", "password" },
                    { "placeholder", this.GetMetadata("/ChangePassword/_InputView_ascx.RepeatPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata("/ChangePassword/_InputView_ascx.RepeatPassword_Empty")).EqualTo("#changePasswordNewPassword", this.GetMetadata("/ChangePassword/_InputView_ascx.RepeatPassword_NotMatch")) }
                }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>      
        </li>
        </ul>

        <div class="AccountButtonContainer">
<button id="btnChangePassword" class="Button AccountButton" type="submit">
<strong class="ButtonText"><%= this.GetMetadata("/ChangePassword/_InputView_ascx.Button_Save").SafeHtmlEncode()%></strong>
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
        usernameN = $("#txtUserName");
        formChangePassword.submit(function (event) {
            if (formChangePassword.valid()) {
                $.ajax({
                    type: 'POST',
                    url: $(this).attr('action'),
                    data: {
                        username: usernameN.val(),
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
        (function ($) {
            $.getUrlParam = function (name) {
                var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)");
                var r = window.location.search.substr(1).match(reg);
                if (r != null) return unescape(r[2]); return null;
            }
        })(jQuery);
        var xx = $.getUrlParam('UN');
        $("#txtUserName").val(xx);
    });
</script>
</ui:MinifiedJavascriptControl>