<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.RegisterV2FormViewModel>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script runat="server">
    private string GetCountryJson()
    {
        StringBuilder json = new StringBuilder();
        json.AppendLine("var countries = {");
        foreach (CountryInfo countryInfo in CountryManager.GetAllCountries())
        {
            json.AppendFormat(System.Globalization.CultureInfo.InvariantCulture, "'{0}':{{PC:'{1}',CC:'{2}'}},"
                , countryInfo.InternalID
                , countryInfo.PhoneCode.SafeJavascriptStringEncode()
                , countryInfo.CurrencyCode.SafeJavascriptStringEncode()
                );
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);
        json.AppendLine("};");
        return json.ToString();
    }
</script>


<form action="<%= this.Url.RouteUrl("Register", new { @action = "Register" }) %>"
    method="post" id="formRegister" class="GeneralForm FormRegister">

<ul class="FormList RegisterList">
	<%------------------------------------------
		Title
		-------------------------------------------%>
	<li class="FormItem TitleFormItem" id="Li0" runat="server">
		<%: Html.DropDownList("Title", Model.GetPersonTitles("Title"), new Dictionary<string, object>() 
        {
            { "class", "FormInput SelectInput SelectTitle" },
            { "id", "registerTitle" },
			{ "data-validator", ClientValidators.Create()
                .RequiredIf( "isTitleRequired", this.GetMetadata(".Title_Empty")) },
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Username
		-------------------------------------------%>
	<li class="FormItem UsernameFormItem" id="Li13" runat="server">
        <%: Html.TextBox("Username","" , new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerUsername" },
            { "maxlength", Settings.Registration.UsernameMaxLength },
            { "placeholder", this.GetMetadata(".Username_Label") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create()
                .Required(this.GetMetadata(".Username_Empty"))
                .MinLength(4, this.GetMetadata(".Username_Length"))
                .Custom("validateRegistrationUsername")
                .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueUsername", @message = this.GetMetadata(".Username_Exist") }))  }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		FirstName
		-------------------------------------------%>
	<li class="FormItem FirstNameFormItem" id="Li1" runat="server">
        <%: Html.TextBox("FirstName","" , new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerFirstName" },
			{ "placeholder", this.GetMetadata(".FirstName_Label") },
			{ "data-validator", ClientValidators.Create()
											.RequiredIf( "isFirstnameRequired", this.GetMetadata(".Firstname_Empty"))
											.MinLength(2, this.GetMetadata(".FirstName_MinLength").SafeHtmlEncode())
                                            .MaxLength(50, this.GetMetadata(".FirstName_MaxLength").SafeHtmlEncode())}
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Surname
		-------------------------------------------%>
	<li class="FormItem SurnameFormItem" id="Li2" runat="server">
        <%: Html.TextBox("Surname","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerSurname" },
			{ "placeholder", this.GetMetadata(".Surname_Label") },
			{ "data-validator", ClientValidators.Create()
												.RequiredIf( "isSurnameRequired", this.GetMetadata(".Surname_Empty"))
												.MinLength(2, this.GetMetadata(".Surname_MinLength").SafeHtmlEncode())
                                                .MaxLength(50, this.GetMetadata(".Surname_MaxLength").SafeHtmlEncode())}
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Email
		-------------------------------------------%>
	<li class="FormItem EmailFormItem" id="Li3" runat="server">
        <%: Html.TextBox("Email","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerEmail" },
			{ "type", "email" },
			{ "placeholder", this.GetMetadata(".Email_Label") },
			{ "data-validator", ClientValidators.Create()
												.Required(this.GetMetadata(".Email_Empty"))
												.Email(this.GetMetadata(".Email_Incorrect"))
												.Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".Email_Exist") })) }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Password
		-------------------------------------------%>
	<li class="FormItem PasswordFormItem" id="Li4" runat="server">
        <%: Html.Password("Password","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerPassword" },
            { "placeholder", this.GetMetadata(".Password_Label") },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Password_Empty")).MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata(".Password_Incorrect")).Custom("validatePassword") }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
        Confirm Password
        -------------------------------------------%>
	<li class="FormItem pass2FormItem" id="fldRepeatPassword" runat="server">
        <%: Html.Password("password2", "", new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerPassword2" },
            { "maxlength", "20" },
            { "placeholder", this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode() },
            { "required", "required" },
            { "data-validator", ClientValidators.Create()
                .Required(this.GetMetadata(".RepeatPassword_Empty"))
                .EqualTo("#registerPassword", this.GetMetadata(".RepeatPassword_NotMatch")) }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------- 
        Birth
        --------------------%>

    <li class="FormItem BirthdayPickerFormItem" id="LiDate" runat="server">
        <div class="BirthdayPicker" id="BirhtdayPicker"></div>
        <script>
            $(function () {
                $("#BirhtdayPicker").birthdaypicker(
                    {
                        "onChange": function () { onChangeValidateBirthDate() },
                        "data-validator" : "<%= ClientValidators.Create().Custom("validateBirthDate") %>"
                    });
            });
        </script>
		<span class="FormStatus">Status</span>
		<span id="#birthDateFormHelpSpan" class="FormHelp"></span>
    </li>

    <%------------------------------------------
		Country
		-------------------------------------------%>
	<li class="FormItem CountryFormItem" id="Li12" runat="server">
        <%: Html.DropDownList("Country", Model.GetCountries("Country"), new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerCountry" },
            { "data-validator", ClientValidators.Create()
                .Required(this.GetMetadata(".Country_Empty")) }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
        <script>
            $(function () {
                $('#registerCountry').on('change', function () {
                    <%= GetCountryJson() %>
                    var country = countries[$(this).val()];
                    var params = { ID: $(this).val(), CountryCode: '', PhoneCode: '', LegalAge: 18 };
                    if (country != null) {
                        params.CurrencyCode = country.CC;
                        params.PhoneCode = country.PC;
                        if (params.ID == 74)
                            params.LegalAge = 21;

                        $('#registerCurrency').val(params.CurrencyCode);
                        if ($('#registerCurrency').val() == null) $('#registerCurrency').val("");
                        $('#registerMobilePrefix').val(params.PhoneCode);
                    }
                });
                
                $.get('GetIPLocation', function (json) {
                    if (!json.success || !json.data.found) return;
                    if (json.data.isCountryRegistrationBlocked) {
                        return;
                    }
                    $('#registerCountry').val(json.data.countryID).trigger('change');
                });
            });
        </script>
	</li>

    <%------------------------------------------
		City
		-------------------------------------------%>
	<li class="FormItem CityFormItem" id="Li5" runat="server">
        <%: Html.TextBox("City","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerCity" },
            { "placeholder", this.GetMetadata(".City_Label") },
            { "data-validator", ClientValidators.Create()
											.RequiredIf( "isCityRequired", this.GetMetadata(".City_Empty"))
											.MinLength(2, this.GetMetadata(".City_MinLength").SafeHtmlEncode())
                                            .MaxLength(50, this.GetMetadata(".City_MaxLength").SafeHtmlEncode())}
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Address
		-------------------------------------------%>
	<li class="FormItem Address1FormItem" id="Li6" runat="server">
        <%: Html.TextBox("Address1","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerAddress" },
            { "placeholder", this.GetMetadata(".Address_Label") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create()
											.RequiredIf( "isAddress1Required", this.GetMetadata(".Address1_Empty"))
											.MinLength(2, this.GetMetadata(".Address_MinLength").SafeHtmlEncode())
                                            .MaxLength(100, this.GetMetadata(".Address_MaxLength").SafeHtmlEncode())}
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		PostalCode
		-------------------------------------------%>
	<li class="FormItem PostalCodeFormItem" id="Li7" runat="server">
        <%: Html.TextBox("PostalCode","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerPostalCode" },
            { "placeholder", this.GetMetadata(".PostalCode_Label") },
            { "data-validator", ClientValidators.Create()
											.RequiredIf( "isPostalCodeRequired", this.GetMetadata(".PostalCode_Empty")) }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Currency
		-------------------------------------------%>
	<li class="FormItem CurrencyFormItem" id="Li8" runat="server">
        <%: Html.DropDownList("Currency", Model.GetCurrencies("Currency"), new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerCurrency" },
            { "data-validator", ClientValidators.Create()
                .Required(this.GetMetadata(".Currency_Empty")) }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Phone
		-------------------------------------------%>
	<li class="FormItem MobileNumberBox" id="Li9" runat="server">
        <ul class="Container MobileNumberList">
            <li class="FormItem InnerFormItem MobilePrefixFormItem">
                <%: Html.DropDownList("MobilePrefix", Model.MobilePrefixes("Mobile Prefix"), new Dictionary<string, object>() 
                {
                    { "class", "FormInput" },
                    { "id", "registerMobilePrefix" },
                    { "data-validator", ClientValidators.Create()
														.RequiredIf( "isMobileRequired",this.GetMetadata(".PhonePrefix_Empty")) }
                }) %>
            </li>
            <li class="FormItem InnerFormItem MobileContainer MobileNbFormItem">
                <%: Html.TextBox("Mobile","", new Dictionary<string, object>() 
                {
                    { "class", "FormInput" },
                    { "id", "registerPhone" },
                    { "placeholder", this.GetMetadata(".Phone_Label") },
                    { "data-validator", ClientValidators.Create()
														.RequiredIf( "isMobileRequired", this.GetMetadata(".Mobile_Empty"))
														.Digits(this.GetMetadata(".Mobile_Incorrect"))
														.Custom("validateRegistrationMobile")
														.Rangelength(7, 30, this.GetMetadata(".Mobile_Incorrect").SafeHtmlEncode()) }
                }) %>
            </li>
        </ul>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

        <%------------------------------------------
		Security Question
		-------------------------------------------%>
	<li class="FormItem SecurityQuestionFormItem" id="Li15" runat="server">
        <%: Html.DropDownList("SecurityQuestion",Model.GetSecurityQuestionList("SecurityQuestion"), new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerSecurityQuestion" },
            { "placeholder", this.GetMetadata("_ProfileAccountInput_ascx.SecurityQuestion_Label") },
            { "data-validator", ClientValidators.Create().RequiredIf( "isSecurityQuestionRequired", this.GetMetadata("_ProfileAccountInput_ascx.SecurityQuestion_Empty"))}
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

        <%------------------------------------------
		Security Answer
		-------------------------------------------%>
	<li class="FormItem SecurityAnswerFormItem" id="Li16" runat="server">
        <%: Html.TextBox("SecurityAnswer","", new Dictionary<string, object>() 
        {
            { "class", "FormInput" },
            { "id", "registerAnswer" },
            { "placeholder", this.GetMetadata("_ProfileAccountInput_ascx.SecurityAnswer_Choose") },
            { "data-validator", ClientValidators.Create().RequiredIf( "isSecurityAnswerRequired", this.GetMetadata("_ProfileAccountInput_ascx.SecurityQuestion_Empty")).MinLength(2, this.GetMetadata(".SecurityAnswer_MinLength"))}
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		AllowNewsEmail and SmsOffer
		-------------------------------------------%>
	<li class="FormItem AllowNewsEmailFormItem" id="Li10" runat="server">
        <%: Html.CheckBox("AllowNewsEmail", false, new Dictionary<string, object>() 
        {
            { "id", "registerSendEmails" },
            { "class", "FormCheck" },
        }) %>
        <label class="FormLabel" for="registerSendEmails"><%= this.GetMetadata(".AllowNewsEmail_Label").SafeHtmlEncode()%></label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		AllowSmsOffer
		-------------------------------------------%>
	<li class="FormItem Hidden AllowSmsOfferFormItem" id="Li11" runat="server">
         <%: Html.CheckBox("AllowSmsOffer", false, new Dictionary<string, object>() 
         {
            { "id", "registerAllowSmsOffer" },
            { "class", "FormCheck" },
         }) %>
        <label class="FormLabel" for="registerAllowSmsOffer"><%= this.GetMetadata(".AllowSmsOffer_Label").SafeHtmlEncode()%></label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

    <%------------------------------------------
		Confirm over 18
		-------------------------------------------%>
	<li class="FormItem ConfirmOver18FormItem" id="Li14" runat="server">
         <%: Html.CheckBox("ConfirmOver18TermsConditions", false, new Dictionary<string, object>() 
         {
            { "id", "registerConfirmOver18TermsConditions" },
            { "class", "FormCheck" },
            { "data-validator", ClientValidators.Create()
                                    .Custom("confirmOver18TermsConditions") }
         }) %>
        <label class="FormLabel" for="registerConfirmOver18TermsConditions"><%= this.GetMetadata(".ConfirmOver18_TermsConditions_Label").SafeHtmlEncode()%></label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

</ul>

<button type="submit" class="Button SubmitRegister">
    <span class="ButtonIcon SubmitIcon icon-checkmark-2"> </span>
	<span class="ButtonText">Submit</span>
</button>

</form>

<% Html.RenderPartial("/Components/BirthPickerJS"); %>
<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
    
    function submitRegisterForm() {
        $('#formRegister').trigger("submit");
    }

    function validateBirthDate() {
        var strSelectedDate = $('#birthdate').val();
        if (isNaN(Date.parse(strSelectedDate))) {
            return "Incorrect birth date";
        }

        var selectedDate = new Date(strSelectedDate);
        var todayYear = new Date().getFullYear();
        if ((todayYear - selectedDate.getFullYear()) < 18)
        {
            return "Must be over 18";
        }

        return true;
    }

    function onChangeValidateBirthDate(hiddenDate) {
        var result = validateBirthDate();
        var birthdayPicker = $('.BirthdayPicker');
        if (result !== false) {
            $('#birthDateFormHelpSpan').html('<label for="birthdate" generated="true" class="error">' + result + '</label>');
            birthdayPicker.parent().addClass('Error');
        } else {
            $('#birthDateFormHelpSpan').html('');
            birthdayPicker.parent().removeClass('Error');
        }
    }

    var sendEmailsCb = $('#registerSendEmails');
    sendEmailsCb.on('click', function () {
        $('#registerAllowSmsOffer').val(sendEmailsCb.val());
    });

    function isTitleRequired() {
		return <%= Settings.Registration.IsTitleRequired.ToString().ToLowerInvariant() %>;
    }

    function validateRegistrationUsername() {
        return true;
    }

    function isFirstnameRequired() {
        return <%= Settings.Registration.IsFirstnameRequired.ToString().ToLowerInvariant() %>;
    }

    function isSurnameRequired() {
        return <%= Settings.Registration.IsSurnameRequired.ToString().ToLowerInvariant() %>;
    }

    function isCityRequired() {
        return <%= Settings.Registration.IsCityRequired.ToString().ToLowerInvariant() %>;
    }

    function isAddress1Required() {
        return <%= Settings.Registration.IsAddress1Required.ToString().ToLowerInvariant() %>;
    }

    function isPostalCodeRequired() {
        return <%= Settings.Registration.IsPostalCodeRequired.ToString().ToLowerInvariant() %>;
    }

    function isMobileRequired() {
        return <%= Settings.Registration.IsMobileRequired.ToString().ToLowerInvariant() %>;
    }

    function isSecurityQuestionRequired() {
        return <%= Settings.Registration.IsSecurityQuestionRequired.ToString().ToLowerInvariant() %>;
    }

    function isSecurityAnswerRequired() {
        return <%= Settings.Registration.IsSecurityQuestionRequired.ToString().ToLowerInvariant() %>;
    }

    function confirmOver18TermsConditions() {
        if ($('#registerConfirmOver18TermsConditions').is(':checked') == true)
            return true;

        return "<%= this.GetMetadata(".ConfirmOver18_TermsConditions_NotChecked") %>";
    }

    function validateRegistrationMobile() {
        return true;
    }

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
