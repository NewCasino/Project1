<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.ProfileAccountInputViewModel>" %>
<%@ Import Namespace="GmCore"  %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/C#" runat="server">
    private string Passport
    {
        get 
        {
            long passportId = -1L;
            if (!string.IsNullOrEmpty(Model.InputSettings.PassportID))
            {
                long.TryParse(Model.InputSettings.PassportID, out passportId);
            }
            if (Profile.IsAuthenticated && passportId > 0) 
            {
                var resp = GamMatrixClient.GetUserImageRequest(Profile.UserID, passportId);
                if (resp != null && resp.Image != null)
                {
                    return string.Format("data:{0};base64,{1}", resp.Image.ImageContentType, Convert.ToBase64String(resp.Image.ImageFile));
                }
                else
                {
                    return string.Empty;
                }
            } 
            else 
            {
                return string.Empty;
            }
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
		fldUsername.Visible = Model.InputSettings.IsUsernameVisible;
		scriptUsername.Visible = Model.InputSettings.IsUsernameVisible;

		fldPassword.Visible = Model.InputSettings.IsPasswordVisible;
		fldRepeatPassword.Visible = Model.InputSettings.IsPasswordVisible;

		fldCurrency.Visible = Model.InputSettings.IsCurrencyVisible;
		scriptCurrency.Visible = Model.InputSettings.IsCurrencyVisible;

		fldSecurityQuestion.Visible = Model.InputSettings.IsSecurityQuestionVisible;
		scriptSecurityQuestion.Visible = Model.InputSettings.IsSecurityQuestionVisible;
		fldSecurityAnswer.Visible = Model.InputSettings.IsSecurityQuestionVisible;
		scriptSecurityAnswer.Visible = Model.InputSettings.IsSecurityQuestionVisible;

		fldLanguage.Visible = Model.InputSettings.IsLanguageVisible;
		scriptLanguage.Visible = Model.InputSettings.IsLanguageVisible;

        fldPassport.Visible = Model.InputSettings.IsPassportVisible;
        scriptPassport.Visible = Model.InputSettings.IsPassportVisible;
		
        base.OnPreRender(e);
    }
</script>
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
            { "autocomplete", "off" },
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
	<li class="FormItem" id="fldRepeatPassword" runat="server">
		<label class="FormLabel" for="registerPassword2"><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></label>
        <%: Html.Password("password2", "", new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerPassword2" },
            { "autocomplete", "off" },
            { "maxlength", Settings.Registration.PasswordMaxLength },
            { "placeholder", this.GetMetadata(".RepeatPassword_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".RepeatPassword_Empty")).EqualTo("#registerPassword", this.GetMetadata(".RepeatPassword_NotMatch")) }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

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
            return <%= this.Model.InputSettings.IsSecurityQuestionRequired.ToString().ToLowerInvariant() %>;
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
            return <%= this.Model.InputSettings.IsSecurityQuestionRequired.ToString().ToLowerInvariant() %>;
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
    <%------------------------------------------
    Passport
 -------------------------------------------%>
 <li class="FormItem" id="fldPassport" runat="server">
    <label class="FormLabel" for="registerPassport"><%= this.GetMetadata(".Passport_Label").SafeHtmlEncode() %></label>
    <%: Html.Hidden("passport", this.Passport, new Dictionary<string, object>()  
    { 
        { "class", "FormInput" },
        { "id", "registerPassport" },
        { "required", "required" },
        { "data-validator", ClientValidators.Create().RequiredIf("isPassportRequired", this.GetMetadata(".Passport_Empty")) }
    }) %>
    <div class="PassportBox">
        
       
        <div class="PassportImage">
            <span class="PassportImage_Loading"></span>
            <% if (!Profile.IsAuthenticated || (Profile.IsAuthenticated && string.IsNullOrEmpty(this.Passport))) { %>
            <a class="RemovePassport_Button"<%= !string.IsNullOrEmpty(this.Passport) ? string.Empty : " style='display:none;'" %>></a>
            <% } %>
            <%= !string.IsNullOrEmpty(this.Passport) ? string.Format("<img src='{0}' />", this.Passport) : string.Empty %>
        </div>
        <div class="PassportImage_Button">
            <input type="file" name="uploadPassport" class="hidden" accept=".bmp,.jpg,.jpeg,.gif,.png,.tiff" style="display:none;" />
            <% if (!Profile.IsAuthenticated || (Profile.IsAuthenticated && string.IsNullOrEmpty(this.Passport))) { %>
            <a id="uploadPassport"><%=this.GetMetadata(".UploadPassport_Button").SafeHtmlEncode() %></a>
            <% } %>
        </div>
    </div>

    <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
 </li>
<ui:MinifiedJavascriptControl runat="server" ID="scriptPassport" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
        function isPassportRequired() {
            return <%= this.Model.InputSettings.IsPassportRequired.ToString().ToLowerInvariant() %>;
        }
        $('input[name="uploadPassport"]').on('change', function() {
            var fr = new FileReader();
            fr.readAsDataURL(this.files[0]);
            var img = new Image();
            fr.onload = function() {
                img.src = this.result;
                img.onload = function() {
                    //$(".img").html(img);
                    $(".PassportImage img").remove();
                    $(".PassportImage").append(img);
                    $("#registerPassport").val($(".PassportImage img").prop("src"));
                    $('.RemovePassport_Button').show();
                    $('#registerPassport').valid();
                };
            };
        });
        $(".RemovePassport_Button").click(function() {
            $(".PassportImage img").remove();
            $("#registerPassport").val("");
            $('.RemovePassport_Button').hide();
        })
        $("#uploadPassport").on("click", function() {
            $("input[name='uploadPassport']").click();
        });
    </script>
</ui:MinifiedJavascriptControl>
</ul>
