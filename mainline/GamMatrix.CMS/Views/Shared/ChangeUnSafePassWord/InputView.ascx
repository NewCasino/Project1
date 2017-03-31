<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<style>
    .changePassWordContainer{padding-left:20%;}
    #container .saveButton{text-align:center;}
    #btnChangePwd {max-width: 300px;margin: 0 auto !important;}
    #txtUserName,#txtOldPassword,#txtNewPassword,#txtRepeatPassword{width:95%!important;padding:3px;margin:5px;max-width: 100%;}
    #container .inputfield_Table{width:100%;}
    #pnGeneralLiteral .controls{width:75%;max-width: 900px;  min-width: 450px;}
    .changePassWordContainer table, .changePassWordContainer tbody, .changePassWordContainer tr{display: block;}
    .changePassWordContainer td{width:800px;}
    #btnChangePwd{margin: 20px 0;}
    .message.warning {width: 80%;margin: 0 auto;}
</style>
<% using (Html.BeginRouteForm("ChangePwd", new { @action = "SaveSafe" }, FormMethod.Post, new { @id = "pnGeneralLiteral", @style = "width:100%" }))
   { %>

<%------------------------------------------
    UserName
 -------------------------------------------%>

<div class="unsafeError"><%: Html.WarningMessage( this.GetMetadata("/Metadata/ServerResponse.Login_NeedChangePassword").HtmlEncodeSpecialCharactors(),true ) %></div>
<div class="changePassWordContainer">
<ui:InputField ID="InputField1" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata("/Head/_LoginPane_ascx.Username_Wartermark").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("username", string.Empty, new 
{
            @id = "txtUserName",
            @type = "text",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".Username_Empty"))
}
) %>
</ControlPart>
</ui:InputField>
<%------------------------------------------
    Old Password
 -------------------------------------------%>
<ui:InputField ID="fldOldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata("/ChangePwd/_InputView_ascx.OldPassword_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("oldPassword", string.Empty, new 
{
            @maxlength = 20,
            @id = "txtOldPassword",
            @type = "password",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata("/ChangePwd/_InputView_ascx.OldPassword_Empty"))
}
) %>
</ControlPart>
</ui:InputField>

<%------------------------------------------
    New Password
 -------------------------------------------%>
<ui:InputField ID="fldNewPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata("/ChangePwd/_InputView_ascx.NewPassword_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("newPassword", string.Empty, new 
{
            @maxlength = Settings.Registration.PasswordMaxLength,
            @id = "txtNewPassword",
            @type = "password",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata("/ChangePwd/_InputView_ascx.NewPassword_Empty"))
                .MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata("/ChangePwd/_InputView_ascx.NewPassword_Invalid"))
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
                return '<%= this.GetMetadata("/ChangePwd/_InputView_ascx.Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        }
        if(value == $("#txtOldPassword").val())
        {
            return '<%= this.GetMetadata("/ChangePwd/_InputView_ascx.Password_SameWithOldPassword").SafeJavascriptStringEncode() %>';
        }
        var ret = <%=this.GetMetadata("Metadata/Settings.Password_ValidationRegex") %>.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata("/ChangePwd/_InputView_ascx.Password_UnSafe").HtmlEncodeSpecialCharactors() %>';
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
<LabelPart><%= this.GetMetadata("/ChangePwd/_InputView_ascx.RepeatPassword_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("repeatPassword", string.Empty, new 
{
            @maxlength = Settings.Registration.PasswordMaxLength,
            @id = "txtRepeatPassword",
            @type = "password",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata("/ChangePwd/_InputView_ascx.RepeatPassword_Empty"))
                .EqualTo("#txtNewPassword", this.GetMetadata("/ChangePwd/_InputView_ascx.RepeatPassword_NotMatch"))
}
) %>
</ControlPart>
</ui:InputField>
</div>
<div class="button-wrapper saveButton">
    <%: Html.Button(this.GetMetadata("/ChangePwd/_InputView_ascx.Button_Save"), new { @id ="btnChangePwd", @type="submit"}) %>
</div>

<% } %>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#pnGeneralLiteral').initializeForm();

        $('#btnChangePwd').click(function (e) {
            e.preventDefault();

            if (!$('#pnGeneralLiteral').valid())
                return;
                
            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnChangePwd').toggleLoadingSpin(false);
                    $('#pnGeneralLiteral').parent().html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnChangePwd').toggleLoadingSpin(false);
                }
            };
            $('#pnGeneralLiteral').ajaxForm(options);
            $('#pnGeneralLiteral').submit();
        });

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