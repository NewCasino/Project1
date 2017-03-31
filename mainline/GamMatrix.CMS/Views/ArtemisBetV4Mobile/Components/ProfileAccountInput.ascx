<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.ProfileAccountInputViewModel>" %>
<%@ Import Namespace="GmCore"  %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/C#" runat="server">
    public string Password = "";
    protected override void OnPreRender(EventArgs e)
    {
        fldUsername.Visible = Model.InputSettings.IsUsernameVisible;
        scriptUsername.Visible = Model.InputSettings.IsUsernameVisible;

        fldPassword.Visible = Model.InputSettings.IsPasswordVisible;
        //fldRepeatPassword.Visible = Model.InputSettings.IsPasswordVisible;

        fldCurrency.Visible = Model.InputSettings.IsCurrencyVisible;
        scriptCurrency.Visible = Model.InputSettings.IsCurrencyVisible;

        fldSecurityQuestion.Visible = Model.InputSettings.IsSecurityQuestionVisible;
        scriptSecurityQuestion.Visible = Model.InputSettings.IsSecurityQuestionVisible;
        fldSecurityAnswer.Visible = Model.InputSettings.IsSecurityQuestionVisible;
        scriptSecurityAnswer.Visible = Model.InputSettings.IsSecurityQuestionVisible;

        fldLanguage.Visible = Model.InputSettings.IsLanguageVisible;
        scriptLanguage.Visible = Model.InputSettings.IsLanguageVisible;
        if (!string.IsNullOrEmpty(Request.Form["password"]))
        {
            Password = Request.Form["password"].ToString();
        }
        base.OnPreRender(e);
    }
</script>
<input type="password" runat="server" id="user_password" value="" style="display:none;" class="user_name" />
<ul class="FormList">
    <%------------------------------------------
        Username
        -------------------------------------------%>
<li class="FormItem" id="fldUsername" runat="server">
<label class="FormLabel" for="registerUsername"><%= this.GetMetadata(".Username_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("username", Model.InputSettings.Username, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerUsername" },
            { "maxlength", Settings.Registration.UsernameMaxLength },
            { "placeholder", this.GetMetadata(".Username_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Username_Empty")).MinLength(4, this.GetMetadata(".Username_Length")).Custom("validateRegistrationUsername").Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueUsername", @message = this.GetMetadata(".Username_Exist") }))  }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl ID="scriptUsername" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
function validateRegistrationUsername() {
var value = this;
var ret = /^\w+$/.exec(value);
if (ret == null || ret.length == 0)
return '<%= this.GetMetadata(".Username_Illegal").SafeJavascriptStringEncode() %>';
return true;
}

$(function () {
new CMS.views.RestrictedInput('#registerUsername', CMS.views.RestrictedInput.username);
$("#registerPassword").val("<%=Password%>");
});
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Password
        -------------------------------------------%>
<li class="FormItem" id="fldPassword" runat="server">
<label class="FormLabel" for="registerPassword"><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></label>
        <%: Html.Password("password", "", new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerPassword" },
            { "maxlength", Settings.Registration.PasswordMaxLength },
            { "placeholder", this.GetMetadata(".Password_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Password_Empty")).MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata(".Password_Incorrect")).Custom("validatePassword") }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        function validatePassword() {
            var value = this;
            <% if (Settings.Registration.AvoidSameUsernamePassword) 
   { %>
var user = $('[name="username"]').val() || $('[name="email"]').val() || '';
if (value.toLowerCase() == user.toLowerCase())
return '<%= this.GetMetadata(".Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        <% }

if (!string.IsNullOrWhiteSpace(Settings.Password_ValidationRegex)) 
{ %>
        var test = new RegExp(<%= Settings.Password_ValidationRegex %>).exec(value);
        if (test == null || test.length == 0)
        return '<%= this.GetMetadata(".Password_UnSafe").SafeJavascriptStringEncode() %>';
<% } %>
            return true;
        }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Confirm Password
        -------------------------------------------%>
<%--<li class="FormItem" id="fldRepeatPassword" runat="server">
<label class="FormLabel" for="registerPassword2"><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></label>
        <%: Html.Password("password2", "", new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerPassword2" },
            { "maxlength", Settings.Registration.PasswordMaxLength },
            { "placeholder", this.GetMetadata(".RepeatPassword_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".RepeatPassword_Empty")).EqualTo("#registerPassword", this.GetMetadata(".RepeatPassword_NotMatch")) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>--%>

    <%------------------------------------------
        Currency
        -------------------------------------------%>
<li class="FormItem" id="fldCurrency" runat="server">
<label class="FormLabel" for="registerCurrency"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></label>
<%: Html.DropDownList("currency", this.Model.GetCurrencyList(), new Dictionary<string, object>() 
        { 
            { "class", "FormInput" },
            { "id", "registerCurrency" },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Currency_Empty")) }
        })%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<ui:MinifiedJavascriptControl runat="server" ID="scriptCurrency" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
    $(function () {
    if ($('#registerCurrency > option').length <= 1)
    $('#fldCurrency').hide();
    else {
    $(document).bind('COUNTRY_SELECTION_CHANGED', function (el, data) {
    $('#registerCurrency').val(data.c);
    });
    }
    });
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Security Question
        -------------------------------------------%>
<li class="FormItem" id="fldSecurityQuestion" runat="server">
<label class="FormLabel" for="registerQuestion"><%= this.GetMetadata(".SecurityQuestion_Label").SafeHtmlEncode()%></label>
<%: Html.DropDownList("securityQuestion", this.Model.GetSecurityQuestionList(this.GetMetadata(".SecurityQuestion_Select")), new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerQuestion" },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().RequiredIf( "isSecurityQuestionRequired", this.GetMetadata(".SecurityQuestion_Empty")) }
        })%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptSecurityQuestion" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
        function isSecurityQuestionRequired() {
            return false;
        }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Security Answer
        -------------------------------------------%>
<li class="FormItem" id="fldSecurityAnswer" runat="server">
<label class="FormLabel" for="registerAnswer"><%= this.GetMetadata(".SecurityAnswer_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("securityAnswer", Model.InputSettings.SecurityAnswer, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerAnswer" },
            { "maxlength", "50" },
            { "placeholder", this.GetMetadata(".SecurityAnswer_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().RequiredIf( "isSecurityAnswerRequired", this.GetMetadata(".SecurityAnswer_Empty")).MinLength(2, this.GetMetadata(".SecurityAnswer_MinLength")) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptSecurityAnswer" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
        function isSecurityAnswerRequired() {
            return false;
        }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Language
        -------------------------------------------%>
<li class="FormItem" id="fldLanguage" runat="server">
<label class="FormLabel" for="registerLanguage"><%= this.GetMetadata(".Language_Label").SafeHtmlEncode()%></label>
<%: Html.DropDownList("language", this.Model.GetLanguageList(), new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerLanguage" },
            { "required", "required" },
        })%>
<span class="FormStatus">Status</span>
</li>
<ui:MinifiedJavascriptControl runat="server" ID="scriptLanguage" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
    $(function () {
    if ($('#registerLanguage > option').length > 1) 
    new CMS.mobile360.views.LangSelect($('#registerLanguage'));
    else 
    $('#fldLanguage').hide();
    });
    </script>
    </ui:MinifiedJavascriptControl>
</ul>
<script type="text/javascript">
$(function(){
        $('#registerMobilePrefix').val("+90");
        $('#registerCurrency').val("TRY");
});
</script>