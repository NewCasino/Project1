<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.ProfilePersonalInputViewModel>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
	protected override void OnPreRender(EventArgs e)
	{
		fldTitle.Visible = Model.InputSettings.IsTitleVisible;
		scriptTitle.Visible = Model.InputSettings.IsTitleVisible;

		fldFirstName.Visible = Model.InputSettings.IsFirstnameVisible;
		scriptFirstname.Visible = Model.InputSettings.IsFirstnameVisible;

		fldSurname.Visible = Model.InputSettings.IsSurnameVisible;
		scriptSurname.Visible = Model.InputSettings.IsSurnameVisible;

		fldEmail.Visible = Model.InputSettings.IsEmailVisible;

		fldDOB.Visible = Model.InputSettings.IsBirthDateVisible;
		scriptDOB.Visible = Model.InputSettings.IsBirthDateVisible;

		fldPersonalID.Visible = Model.InputSettings.IsPersonalIDVisible;
		scriptPersonalID.Visible = Model.InputSettings.IsPersonalIDVisible;
		
		base.OnPreRender(e);
	}
</script>

<ul class="FormList">
	<%------------------------------------------
		Title
		-------------------------------------------%>
	<li class="FormItem" id="fldTitle" runat="server">
		<label class="FormLabel" for="registerTitle"><%= this.GetMetadata(".Title_Label").SafeHtmlEncode()%></label>
		<%: Html.DropDownList("title", this.Model.GetTitleList("/Metadata/UserTitle/", this.GetMetadata(".Title_Choose")), new Dictionary<string, object>() 
		{ 
			{ "class", "FormInput" },
			{ "id", "registerTitle" },
			{ "required", "required" },
			{ "data-validator", ClientValidators.Create().RequiredIf( "isTitleRequired", this.GetMetadata(".Title_Empty")) },
		})%>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<ui:MinifiedJavascriptControl runat="server" ID="scriptTitle" AppendToPageEnd="true" Enabled="true">
	<script type="text/javascript">
		function isTitleRequired() {
			return <%= this.Model.InputSettings.IsTitleRequired.ToString().ToLowerInvariant() %>;
		}
	</script>
	</ui:MinifiedJavascriptControl>

	<%------------------------------------------
		Firstname
		-------------------------------------------%>
	<li class="FormItem" id="fldFirstName" runat="server">
		<label class="FormLabel" for="registerFirstname"><%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode()%></label>
		<%: Html.TextBox( "firstname", Model.InputSettings.FirstName, new Dictionary<string, object>()  
		{ 
			{ "class", "FormInput" },
			{ "id", "registerFirstname" },
			{ "maxlength", "50" },
			{ "placeholder", this.GetMetadata(".Firstname_Choose") },
			{ "required", "required" },
			{ "data-validator", ClientValidators.Create()
											.RequiredIf( "isFirstnameRequired", this.GetMetadata(".Firstname_Empty"))
											.MinLength(2, this.GetMetadata(".FirstName_MinLength").SafeHtmlEncode()) }
		}) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<ui:MinifiedJavascriptControl runat="server" ID="scriptFirstname" AppendToPageEnd="true" Enabled="true">
	<script type="text/javascript">
		function isFirstnameRequired() {
			return <%= this.Model.InputSettings.IsFirstnameRequired.ToString().ToLowerInvariant() %>;
		}

		$(function () {
			new CMS.views.RestrictedInput('#registerFirstname', CMS.views.RestrictedInput.username);
		});
	</script>
	</ui:MinifiedJavascriptControl>

	<%------------------------------------------
		Surname
		-------------------------------------------%>
	<li class="FormItem" id="fldSurname" runat="server">
		<label class="FormLabel" for="registerSurname"><%= this.GetMetadata(".Surname_Label").SafeHtmlEncode()%></label>
		<%: Html.TextBox("surname", Model.InputSettings.Surname, new Dictionary<string, object>() 
		{ 
			{ "class", "FormInput" },
			{ "id", "registerSurname" },
			{ "maxlength", "50" },
			{ "placeholder", this.GetMetadata(".Surname_Choose") },
			{ "required", "required" },
			{ "data-validator", ClientValidators.Create()
												.RequiredIf( "isSurnameRequired", this.GetMetadata(".Surname_Empty"))
												.MinLength(2, this.GetMetadata(".Surname_MinLength").SafeHtmlEncode()) }
		}) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<ui:MinifiedJavascriptControl runat="server" ID="scriptSurname" AppendToPageEnd="true" Enabled="true">
	<script type="text/javascript">
		function isSurnameRequired() {
			return <%= this.Model.InputSettings.IsSurnameRequired.ToString().ToLowerInvariant() %>;
		}

		$(function () {
			new CMS.views.RestrictedInput('#registerSurname', CMS.views.RestrictedInput.username);
		});
	</script>
	</ui:MinifiedJavascriptControl>

	<%------------------------------------------
		Email
		-------------------------------------------%>
	<li class="FormItem" id="fldEmail" runat="server">
		<label class="FormLabel" for="registerEmail"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></label>
		<%: Html.TextBox("email", Model.InputSettings.Email, new Dictionary<string, object>()
		{
			{ "class", "FormInput" },
			{ "id", "registerEmail" },
			{ "maxlength", "50" },
			{ "type", "email" },
			{ "placeholder", this.GetMetadata(".Email_Choose") },
			{ "required", "required" },
			{ "data-validator", ClientValidators.Create()
												.Required(this.GetMetadata(".Email_Empty"))
												.Email(this.GetMetadata(".Email_Incorrect"))
												.Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".Email_Exist") })) }
		}) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>

	<%------------------------------------------
		Date of birth
		-------------------------------------------%>
	<li class="FormItem DOBFormItem" id="fldDOB" runat="server">
		<label class="FormLabel"><%= this.GetMetadata(".DOB_Label").SafeHtmlEncode()%></label>
		<ol class="CompositeInput DateInput Cols-3">
			<li class="Col">
				<%: Html.DropDownList("day", this.Model.DateSelect.GetDayList(this.GetMetadata(".DOB_Day")), new Dictionary<string, object>() 
				{ 
					{ "class", "FormInput" },
					{ "id", "registerDay" },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateRegistrationBirthDate") }
				})%>
			</li>
			<li class="Col">
				<%: Html.DropDownList("month", this.Model.DateSelect.GetMonthList(this.GetMetadata(".DOB_Month")), new Dictionary<string, object>() 
				{ 
					{ "class", "FormInput" },
					{ "id", "registerMonth" },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateRegistrationBirthDate") }
				})%>
			</li>
			<li class="Col">
				<%: Html.DropDownList("year", this.Model.DateSelect.GetYearList(this.GetMetadata(".DOB_Year")), new Dictionary<string, object>() 
				{ 
					{ "class", "FormInput" },
					{ "id", "registerYear" },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateRegistrationBirthDate") }
				})%>
			</li>
		</ol>
		<%= Html.Hidden("birth", string.Empty, new { id = "registerBirth" })%>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<ui:MinifiedJavascriptControl ID="scriptDOB" runat="server" Enabled="true" AppendToPageEnd="true" EnableObfuscation="true">
	<script type="text/javascript">
	function validateRegistrationBirthDate() {
		var day = $('#registerDay').val();
		var month = $('#registerMonth').val();
		var year = $('#registerYear').val();

		if( day.length == 0 || month.length == 0 || year.length == 0 )
			return '<%= this.GetMetadata(".DOB_Empty").SafeJavascriptStringEncode() %>';

		day = parseInt(day, 10);
		month = parseInt(month, 10);
		year = parseInt(year, 10);

		var maxDay = 31;
		switch (month) {
			case 4: maxDay = 30; break;
			case 6: maxDay = 30; break;
			case 9: maxDay = 30; break;
			case 11: maxDay = 30; break;

			case 2:
				{
					if (year % 400 == 0 || year % 4 == 0)
						maxDay = 29;
					else
						maxDay = 28;
					break;
				}
			default:
				break;
		}
		if (day > maxDay)
			return '<%= this.GetMetadata(".DOB_Empty").SafeJavascriptStringEncode() %>';

		var date = new Date();
		date.setFullYear( year, month - 1, day);
		var compare = new Date();
		compare.setFullYear(<%= this.Model.GetLegalAgeDate() %>);

		if (date > compare)
			return '<%= this.GetMetadataEx(".DOB_Under18", Settings.Registration.LegalAge ).SafeJavascriptStringEncode() %>';

		$('#registerBirth').val(year + '-' + (month.toString().length == 1 ? ('0' + month) : month) + '-' + (day.toString().length == 1 ? ('0' + day) : day));
		return true;
	}
	</script>
	</ui:MinifiedJavascriptControl>

	<%------------------------------------------
        Personal ID
        -------------------------------------------%>
	<li class="FormItem Hidden" id="fldPersonalID" runat="server">
		<label class="FormLabel" for="personalID"><%= this.GetMetadata(".PersonalID_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("personalID", "", new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerPersonalID" },
            { "placeholder", this.GetMetadata(".PersonalID_Label") },
            { "required", "required" },
			{ "disabled", "disabled" },
            { "data-validator", ClientValidators.Create()
				.RequiredIf("isPersonalIDRequired", this.GetMetadata(".PersonalID_Empty"))
                .Custom("validatePersonalID")
                .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniquePersonalID", @message = this.GetMetadata(".PersonalID_Exist") }))},
			{ "data-rules", Model.GetPersonalIdRulesJson() }
        }) %>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<ui:MinifiedJavascriptControl runat="server" ID="scriptPersonalID" AppendToPageEnd="true" Enabled="true">
	<script type="text/javascript">
		var __isPersonalIdMandatory = false;
		var __personalIdValidationRegularExpression = false;

		$(function(){
			setStateOfPersonalID(<%=Profile.IpCountryID %>);
		});

		function setStateOfPersonalID(countryID)
		{
			var element = $('#registerPersonalID'),
				container = element.parent(),
				rules =  $('#registerPersonalID').data('rules'),
				rule = rules[countryID];
			
			if(rule) {
				__isPersonalIdMandatory = rule.required;
				__personalIdValidationRegularExpression = rule.validator;
				
				element.prop('disabled', !rule.visible);
				container.toggleClass('Hidden', !rule.visible);
				
				if(rule.length > 0)
					element.attr('maxlength', rule.length)
			}
			else{
				__isPersonalIdMandatory = false;
				element.removeAttr('maxlength');

				element.prop('disabled', true);
				container.addClass('Hidden');
			}
		}

		function isPersonalIDRequired() {
			return __isPersonalIdMandatory;
		}

		function validatePersonalID() {
			if( __personalIdValidationRegularExpression == null || __personalIdValidationRegularExpression.length == 0 )
				return true;

			var value = this;
			var regex = new RegExp(__personalIdValidationRegularExpression, "g");
			var ret = regex.exec(value);
			if (ret == null || ret.length == 0)
				return '<%= this.GetMetadata(".PersonalID_Illegal").SafeJavascriptStringEncode() %>';
			return true;
		}
	</script>
	</ui:MinifiedJavascriptControl>
</ul>