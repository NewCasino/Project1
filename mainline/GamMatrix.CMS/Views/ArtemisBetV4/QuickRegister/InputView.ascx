<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore"  %>
<%@ Import Namespace="OAuth" %>

<script type="text/C#" runat="server">
    private string _LinkTargetAfterSuccessed = null;
    private string LinkTargetAfterSuccessed {
        get
        {
            if (_LinkTargetAfterSuccessed == null)
            {
                if (this.ViewData["LinkTargetAfterSuccessed"] != null)
                    return this.ViewData["LinkTargetAfterSuccessed"] as string;
                if (string.IsNullOrWhiteSpace(_LinkTargetAfterSuccessed))
                    _LinkTargetAfterSuccessed = "";
            }
            return _LinkTargetAfterSuccessed;
        }
    }

    internal class TitleComparer : IEqualityComparer<KeyValuePair<string, string>>
    {
        public bool Equals(KeyValuePair<string, string> x, KeyValuePair<string, string> y)
        {
            return string.Compare(x.Value, y.Value, true) == 0;
        }

        public int GetHashCode(KeyValuePair<string, string> obj)
        {
            return obj.Value.GetHashCode();
        }
    }

    private SelectList GetSecurityQuestionList()
    {
        string[] paths = Metadata.GetChildrenPaths("/Metadata/SecurityQuestion");

        var list = paths.Select(p => new { Key = this.GetMetadata(p, ".Text"), Value = this.GetMetadata(p, ".Text") }).ToList();
        list.Insert(0, new { Key = "", Value = this.GetMetadata(".SecurityQuestion_Select") });

        return new SelectList(list, "Key", "Value");
    }
    
    private SelectList GetTitleList()
    {
        Dictionary<string, string> titleList = new Dictionary<string, string>();
        titleList.Add("", this.GetMetadata(".Title_Choose"));
        titleList.Add("Mr.", this.GetMetadata("/Metadata/Title.Mr"));
        titleList.Add("Mrs.", this.GetMetadata("/Metadata/Title.Mrs"));
        titleList.Add("Miss", this.GetMetadata("/Metadata/Title.Miss"));
        titleList.Add("Ms.", this.GetMetadata("/Metadata/Title.Ms"));
        var list = titleList.AsEnumerable().Where(t => !string.IsNullOrWhiteSpace(t.Value)).Distinct(new TitleComparer());

        return new SelectList(list, "Key", "Value", null);
    }

    private SelectList GetDayList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata(".DOB_Day"));
        for (int i = 1; i <= 31; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        string selectedValue = string.Empty;
        if (this.GetBirthday().HasValue)
        {
            selectedValue = string.Format("{0:00}", this.GetBirthday().Value.Day);
        }

        return new SelectList(dayList, "Key", "Value", null);
    }

    private SelectList GetMonthList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata(".DOB_Month"));
        for (int i = 1; i <= 12; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        string selectedValue = string.Empty;
        if (this.GetBirthday().HasValue)
        {
            selectedValue = string.Format("{0:00}", this.GetBirthday().Value.Month);
        }

        return new SelectList(dayList, "Key", "Value", null);
    }

    private SelectList GetYearList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata(".DOB_Year"));
        for (int i = DateTime.Now.Year - 18; i > 1900; i--)
        {
            dayList.Add(i.ToString(), i.ToString());
        }

        string selectedValue = string.Empty;
        if (this.GetBirthday().HasValue)
        {
            selectedValue = this.GetBirthday().Value.Year.ToString();
        }

        return new SelectList(dayList, "Key", "Value", null);
    }

    private SelectList GetRegionList()
    {
        int countryID = 0;
        var regions = CountryManager.GetCountryRegions(countryID)
                    .Select(r => new { @Text = r.GetDisplayName(), @Value = r.ID })
                    .OrderBy(r => r.Text)
                    .ToArray();
        return new SelectList(regions, "Value", "Text", null);
    }

    private SelectList GetCountryList()
    {
        var list = CountryManager.GetAllCountries()
                    .Where(c => (c.UserSelectable || this.Model != null) && c.InternalID > 0)
                    .Select(c => new { Key = c.InternalID.ToString(), Value = c.DisplayName })
                    .OrderBy(c => c.Value)
                    .ToList();
        list.Insert(0, new { Key = "", Value = this.GetMetadata(".Country_Select") });

        return new SelectList(list
            , "Key"
            , "Value"
            , null
            );
    }
    private string GetMobile()
    {
        return string.Empty;
    }

    private SelectList GetPhonePrefixList()
    {
        var list = CountryManager.GetAllPhonePrefix().Select(p => new { Key = p, Value = p }).ToList();
        list.Insert(0, new { Key = string.Empty, Value = this.GetMetadata(".PhonePrefix_Select") });

        return new SelectList(list, "Key", "Value", null);
    }

    private string GetCountryJson()
    {
        StringBuilder json = new StringBuilder();
        json.AppendLine("var countries = {");
        foreach (CountryInfo countryInfo in CountryManager.GetAllCountries())
        {
            json.AppendFormat(CultureInfo.InvariantCulture, "'{0}':{{PC:'{1}',CC:'{2}'}},"
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

    private SelectList GetCurrencyList()
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .FilterForCurrentDomain()
                        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                        .ToList();
        return new SelectList(list
            , "Key"
            , "Value"
            , list.Count > 0 ? list[0].Key : null
            );
    }

    private SelectList GetLanguageList()
    {
        SelectList list = new SelectList(SiteManager.Current.GetSupporttedLanguages().Select(l => new { Key = l.LanguageCode, Value = l.DisplayName }).ToList()
                    , "Key"
                    , "Value"
                    , null
                    );
        return list;
    }
    private bool IsRepeatEmailVisible { get { return Settings.QuickRegistration.IsRepeatEmailVisible; } }
    private bool IsUsernameVisible { get { return Settings.QuickRegistration.IsUserNameVisible; } }
    private bool IsPersonalIDVisible { get { return Settings.QuickRegistration.IsPersonalIDVisible; } }
    private bool IsTermsConditionsVisible { get { return Settings.QuickRegistration.IsTermsConditionsVisible; } }
    private bool IsTitleVisible { get { return Settings.QuickRegistration.IsTitleVisible; } }
    private bool IsTitleRequired { get { return Settings.Registration.IsTitleRequired; } }
    private bool IsFirstnameVisible { get { return Settings.QuickRegistration.IsFirstnameVisible; } }
    private bool IsFirstnameRequired { get { return Settings.Registration.IsFirstnameRequired; } }
    private bool IsSurnameVisible { get { return Settings.QuickRegistration.IsSurnameVisible; } }
    private bool IsSurnameRequired { get { return Settings.Registration.IsSurnameRequired; } }
    private bool IsBirthDateVisible { get { return Settings.QuickRegistration.IsBirthDateVisible; } }
    private bool IsBirthDateRequired { get { return Settings.Registration.IsBirthDateRequired; } }
    private bool IsCountryVisible { get { return Settings.QuickRegistration.IsCountryVisible; } }
    private bool IsRegionVisible { get { return Settings.QuickRegistration.IsRegionVisible; } }
    private bool IsAddress1Visible { get { return Settings.QuickRegistration.IsAddress1Visible; } }
    private bool IsAddress1Required { get { return Settings.Registration.IsAddress1Required; } }
    private bool IsCityVisible { get { return Settings.QuickRegistration.IsCityVisible; } }
    private bool IsCityRequired { get { return Settings.Registration.IsCityRequired; } }
    private bool IsPostalCodeVisible { get { return Settings.QuickRegistration.IsPostalCodeVisible; } }
    private bool IsPostalCodeRequired { get { return Settings.Registration.IsPostalCodeRequired; } }
    private bool IsMobileVisible { get { return Settings.QuickRegistration.IsMobileVisible; } }
    private bool IsMobileRequired { get { return Settings.Registration.IsMobileRequired; } }

    private bool IsSecurityQuestionVisible { get { return Settings.QuickRegistration.IsSecurityQuestionVisible; } }
    private bool IsSecurityQuestionRequired { get { return Settings.Registration.IsSecurityQuestionRequired; } }

    private bool IsSecurityAnswerVisible { get { return Settings.QuickRegistration.IsSecurityAnswerVisible; } }
    private bool IsSecurityAnswerRequired { get { return Settings.Registration.IsSecurityAnswerRequired; } }
    
    private bool IsLanguageVisible { get { return Settings.QuickRegistration.IsLanguageVisible; } }
    
    protected override void OnPreRender(EventArgs e)
    {
        fldRepeatEmail.Visible = this.IsRepeatEmailVisible;
        
        fldUsername.Visible = this.IsUsernameVisible;
        fldTermsConditions.Visible = this.IsTermsConditionsVisible;        
        fldPersonalID.Visible = this.IsPersonalIDVisible;
        scriptPersonalID.Visible = this.IsPersonalIDVisible;

        fldTitle.Visible = this.IsTitleVisible;
        scriptTitle.Visible = this.IsTitleVisible;
        fldTitle.ShowDefaultIndicator = this.IsTitleRequired;

        fldFirstName.Visible = this.IsFirstnameVisible;
        scriptFirstname.Visible = this.IsFirstnameVisible;
        fldFirstName.ShowDefaultIndicator = this.IsFirstnameRequired;

        fldSurname.Visible = this.IsSurnameVisible;
        scriptSurname.Visible = this.IsSurnameVisible;
        fldSurname.ShowDefaultIndicator = this.IsSurnameRequired;

        fldDOB.Visible = this.IsBirthDateVisible;
        scriptDOB.Visible = this.IsBirthDateVisible;
        fldDOB.ShowDefaultIndicator = this.IsBirthDateRequired;

        fldCountry.Visible = this.IsCountryVisible;
        scriptCountry.Visible = this.IsCountryVisible;
        scriptReqCountry.Visible = this.IsCountryVisible && !string.IsNullOrEmpty(Request["country"]);
        
        fldRegion.Visible = this.IsRegionVisible;
        scriptRegion.Visible = this.IsRegionVisible;

        fldAddress1.Visible = this.IsAddress1Visible;
        fldAddress1.ShowDefaultIndicator = this.IsAddress1Required;
        scriptAddress1.Visible = this.IsAddress1Visible;

        fldCity.Visible = this.IsCityVisible;
        scriptCity.Visible = this.IsCityVisible;
        fldCity.ShowDefaultIndicator = this.IsCityRequired;

        fldPostalCode.Visible = this.IsPostalCodeVisible;
        scriptPostalCode.Visible = this.IsPostalCodeVisible;
        fldPostalCode.ShowDefaultIndicator = this.IsPostalCodeRequired;

        fldMobile.Visible = this.IsMobileVisible;
        scriptMobile.Visible = this.IsMobileVisible;
        fldMobile.ShowDefaultIndicator = this.IsMobileRequired;
        scriptReqMobile.Visible = !string.IsNullOrEmpty(Request["mobilePrefix"]);

        fldPostalCode.ShowDefaultIndicator = Settings.Registration.IsPostalCodeRequired;

        fldSecurityQuestion.Visible = this.IsSecurityQuestionVisible && this.IsSecurityAnswerVisible;
        scriptSecurityQuestion.Visible = this.IsSecurityQuestionVisible && this.IsSecurityAnswerVisible;
        
        fldSecurityAnswer.Visible = this.IsSecurityAnswerVisible && this.IsSecurityQuestionVisible;
        scriptSecurityAnswer.Visible = this.IsSecurityAnswerVisible && this.IsSecurityQuestionVisible;

        fldLanguage.Visible = this.IsLanguageVisible;
        scriptLanguage.Visible = this.IsLanguageVisible;
        
        base.OnPreRender(e);
    }

    private string GetPersonalIdJson()
    {
        StringBuilder json = new StringBuilder();
        json.Append("{");

        List<CountryInfo> countries = CountryManager.GetAllCountries().Where(c => c.IsPersonalIdVisible).ToList();
        foreach (CountryInfo country in countries)
        {
            json.AppendFormat(CultureInfo.InvariantCulture
                , "'{0}':{{IsPersonalIdVisible:{1}, IsPersonalIdMandatory:{2}, PersonalIdValidationRegularExpression:\"{3}\", PersonalIdMaxLength:{4}}},"
                , country.InternalID
                , country.IsPersonalIdVisible.ToString().ToLowerInvariant()
                , country.IsPersonalIdMandatory.ToString().ToLowerInvariant()
                , country.PersonalIdValidationRegularExpression.SafeJavascriptStringEncode()
                , country.PersonalIdMaxLength.ToString("D0")
                );
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);

        json.Append("}");
        return json.ToString();
    }
    
    private string GetEmailValidationRegex()
    {
        StringBuilder regex = new StringBuilder();
        regex.Append("/(");
        foreach (string item in Settings.Registration.DisallowedEmailDomain)
        {
            regex.Append("(");
            foreach (char c in item)
            {
                regex.AppendFormat("\\x{0:x}", (int)c);
            }
            regex.Append(")|");
        }
        if (regex[regex.Length - 1] == '|')
            regex.Remove(regex.Length - 1, 1);
        else
            regex.Append(@"\x40\x40\x40\x40"); // no restriction, then return an impossible regex
        regex.Append(")$/gi");
        return regex.ToString();
    }

    protected ReferrerData ReferrerData
    {
        get
        {
            if (this.ViewData["ReferrerData"] == null)
                return null;

            return this.ViewData["ReferrerData"] as ReferrerData;
        }
    }

    protected ExternalUserInfo ExternalUserInfo
    {
        get
        {
            if (ReferrerData == null)
                return null;

            //if (ReferrerData.GetAssociateStatus() == AssociateStatus.NotAssociated)
            //    return ReferrerData.ExternalUserInfo;

            //return null;

            return ReferrerData.ExternalUserInfo;
        }
    }

    protected string GetEmail()
    {
        if (this.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ExternalUserInfo.Email))
                return this.ExternalUserInfo.Email.Trim();
        }
        else
        {
            return Request["email"];
        }
        return string.Empty;
    }

    private string GetFirstname()
    {
        if (this.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ExternalUserInfo.Firstname))
                return this.ExternalUserInfo.Firstname.Trim();
        }
        else
        {
            return Request["firstname"];
        }
        return string.Empty;
    }

    private string GetSurname()
    {
        if (this.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ExternalUserInfo.Lastname))
                return this.ExternalUserInfo.Lastname.Trim();
        }
        else
        {
            return Request["surname"];
        }
        return string.Empty;
    }

    private string GetBirth()
    {
        if (this.ExternalUserInfo != null
            && this.ExternalUserInfo.Birth.HasValue)
        {
            return string.Format("{0}-{1:00}-{2:00}"
                , this.ExternalUserInfo.Birth.Value.Year
                , this.ExternalUserInfo.Birth.Value.Month
                , this.ExternalUserInfo.Birth.Value.Day
                );
        }
        return string.Empty;
    }

    private DateTime? GetBirthday()
    {
        if (this.ExternalUserInfo != null
            && this.ExternalUserInfo.Birth.HasValue)
        {
            return this.ExternalUserInfo.Birth.Value;
        }
        return null;
    }

    private string GetUsername()
    {
        if (this.ReferrerData != null && this.ReferrerData.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ReferrerData.ExternalUserInfo.Username))
                return this.ReferrerData.ExternalUserInfo.Username.Trim();
        }
        return Request["username"].DefaultIfNullOrEmpty(string.Empty);
    }
</script>

<div class="register-input-view">
<% using (Html.BeginRouteForm("QuickRegister", new { @action = "Register" }, FormMethod.Post, new { @id = "formQuickRegister" }))
   { %>
    
    <%Html.RenderPartial("/ExternalLogin/QuickSignup", this.ViewData.Merge(new { Type = "QuickRegister" }));%>

   <div class="input-fields">
   <%------------------------------------------
    Username
    -------------------------------------------%>
    <label for="txtUsername" class="inputfield_Label"><%= this.GetMetadata(".Username_Label").SafeHtmlEncode() %></label>
    <ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <ControlPart>
            <%: Html.TextBox("username", null, new {
                        @maxlength = Settings.Registration.UsernameMaxLength,
                        @id = "txtUsername",
                        @placeholder = this.GetMetadata(".UsernamePlaceholder"),
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".Username_Empty"))
                            .MinLength(4, this.GetMetadata(".Username_Length"))
                            .Custom("validateUsername")
                            .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueUsername", @message = this.GetMetadata(".Username_Exist") }))            
            } ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptUsername" AppendToPageEnd="true" Enabled="false">
        <script type="text/javascript">
            $(function () {
                $('#txtUsername').keypress(function (e) {
                    if (e.which > 0) {
                        var STR = '\x20\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
                        var c = String.fromCharCode(e.which);
                        if (STR.indexOf(c) >= 0) {
                            e.preventDefault();
                        }
                    }
                });
    
                $('#txtUsername').change(function (e) {
                    var val = $(this).val();
                    var REGEX = /[\s|\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
                    if (val.length > 0) {
                        val = val.replace(REGEX, '');
                        $(this).val(val);
                    }
                });
            });
    
            function validateUsername() {
                var value = this;
                var ret = /^\w+$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".Username_Illegal").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
    Email
    -------------------------------------------%>
    <script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/regstart" async defer></script> 
    <label for="txtEmail" class="inputfield_Label"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode() %></label>
    <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <ControlPart>
            <%: Html.TextBox("email", GetEmail(), new {
                        @maxlength = "50",
                        @id = "txtEmail",
                        @placeholder = this.GetMetadata(".EmailPlaceholder"),
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".Email_Empty"))
                            .Email(this.GetMetadata(".Email_Incorrect"))
                            .Custom("validateEmailDomain")                
                            .Server(this.Url.RouteUrl("QuickRegister", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".Email_Exist") }))
            } )%>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptEmail" AppendToPageEnd="true" Enabled="false">
        <script type="text/javascript">
            function validateEmailDomain() {        
                var value = this;
        
                var regex = <%= GetEmailValidationRegex() %>;
                var ret = regex.exec(value);
                if( ret != null && ret.length > 0 )
                    return '<%= this.GetMetadata(".Email_UnallowedDomain").SafeJavascriptStringEncode() %>';
        
                return true;
            }
            $(function () {
                try{
                    if($(top.document).find("#txtEmail").val().length﻿ > 0){
                        $("#txtEmail").val($(top.document).find("#txtEmail").val());
                    }
                }
                catch (e) {}
            });
            <% if (!string.IsNullOrWhiteSpace(this.GetEmail())) {%>
                $(function () {
                    $('#txtEmail').blur();
                    $('#txtRepeatEmail').blur();
                });
            <%}%>
        </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
    Retype Email
     -------------------------------------------%>

    <ui:InputField ID="fldRepeatEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".RepeatEmail_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
    <%: Html.TextBox("repeatEmail", GetEmail(), new
            {
                @maxlength = "50",
                @id = "txtRepeatEmail",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".RepeatEmail_Empty"))
                    .EqualTo("#txtEmail", this.GetMetadata(".RepeatEmail_NotMatch"))
            }
            )%>
    </ControlPart>
    </ui:InputField>
    <%------------------------------------------
    Password
    -------------------------------------------%>
    <label for="txtPassword" class="inputfield_Label"><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></label>
    <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <ControlPart>
    <%: Html.TextBox("password",null, new 
    {
                @maxlength = 20,
                @id = "txtPassword",
                @type = "password",
                @placeholder = this.GetMetadata(".PasswordPlaceholder"),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Password_Empty"))
                    .MinLength(8, this.GetMetadata(".Password_Incorrect"))
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
                var _temp = true;
                var $txtUsername = $("#txtUsername");
                if($txtUsername.length>0 && value.toLowerCase()==$txtUsername.val().toLowerCase())
                    _temp = false;
                else
                {
                    var $txtEmail = $("#txtEmail");
                    if($txtEmail.length>0 && value.toLowerCase()==$txtEmail.val().toLowerCase())
                    _temp = false;
                }
                if(!_temp)
                    return '<%= this.GetMetadata(".Password_SameWithUsername").SafeJavascriptStringEncode() %>';
            }
            //var ret = /(?=.*\d.+)(?=.*[a-z]+)(?=.*[A-Z]+)(?=.*[-_=+\\|`~!@#$%^&*()\[\]{};:'",./<>?]+).{8,}/.exec(value);
            var ret = <%=this.GetMetadata("Metadata/Settings.Password_ValidationRegex") %>.exec(value);
            if (ret == null || ret.length == 0)
                return '<%= this.GetMetadata(".Password_UnSafe").SafeJavascriptStringEncode() %>';
            return true;
        }

        function avoidSameUsernamePassword() {
            return <%= Settings.Registration.AvoidSameUsernamePassword.ToString().ToLowerInvariant() %>;
        }
        $(function () {
            try{
                if($(top.document).find("#txtPassword").val().length﻿ > 0){
                    $("#txtPassword").val($(top.document).find("#txtPassword").val());
                }
            }
            catch (e) {}
        });
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Repeat Password
     -------------------------------------------%>
    <%--<ui:InputField ID="fldRepeatPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
    <%: Html.TextBox("repeatPassword", null, new 
    {
                @maxlength = 20,
                @id = "txtRepeatPassword",
                @type = "password",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".RepeatPassword_Empty"))
                    .EqualTo( "#txtPassword", this.GetMetadata(".RepeatPassword_NotMatch"))
    }
    ) %>
    </ControlPart>
    </ui:InputField>--%>
    
    <%------------------------------------------
        Personal ID
     -------------------------------------------%>
    <ui:InputField ID="fldPersonalID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".PersonalID_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
            <%: Html.TextBox("personalID", null, new 
        {
            @id = "txtPersonalID", @validator = ClientValidators.Create()
                        .RequiredIf("isPersonalIDRequired", this.GetMetadata(".PersonalID_Empty"))
                        .Custom("validatePersonalID")
                        .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniquePersonalID", @message = this.GetMetadata(".PersonalID_Exist") }))            
        }
    ) %>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptPersonalID" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    var __isPersonalIdMandatory = false;
    var __personalIdValidationRegularExpression = null;

    $(function(){
        $('#fldPersonalID').hide();
        $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
            setStateOfPersonalID(data.ID);
            if(!data.IsAutomatic)
            $('#txtPersonalID').val('');
        });

        <%if(Profile.IpCountryID>0){%>
        setStateOfPersonalID(<%=Profile.IpCountryID %>);
        <%} %>
    });

    function setStateOfPersonalID(countryID)
    {
        var rules = <%= GetPersonalIdJson() %>;
        var rule = rules[countryID];

        if( rule != null ) {
            __isPersonalIdMandatory = rule.IsPersonalIdMandatory;
            __personalIdValidationRegularExpression = rule.PersonalIdValidationRegularExpression;
            $('#fldPersonalID').show();
            if( rule.PersonalIdMaxLength > 0 ){
                $('#txtPersonalID').attr('maxlength', rule.PersonalIdMaxLength);
            }
        }
        else{
            __isPersonalIdMandatory = false;
            $('#txtPersonalID').removeAttr('maxlength');
            $('#fldPersonalID').hide();
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

    <%------------------------------------------
        Firstname
     -------------------------------------------%>
    <ui:InputField ID="fldFirstName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
    <%: Html.TextBox("firstname", GetFirstname(), new 
        {
                    @maxlength = "50",
            @id = "txtFirstname", @validator = ClientValidators.Create()
                        .RequiredIf( "isFirstnameRequired", this.GetMetadata(".Firstname_Empty"))
                        .Custom("validateFirstname")
        }
    ) %>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptFirstname" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    function isFirstnameRequired() {
        return <%= this.IsFirstnameRequired.ToString().ToLowerInvariant() %>;
    }

    function validateFirstname() {
        var value = this;
        var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
        if( value.length > 0 ){
            var ret = REGEX.exec(value);
            if( ret != null && ret.length > 0 )
                return '<%= this.GetMetadata(".Firstname_Illegal").SafeJavascriptStringEncode() %>';
        
            REGEX = /[^x00-xff]/g;
            value = value.replace(REGEX,"xx");
            if(value.length < 2)
                return '<%= this.GetMetadata(".FirstName_MinLength").SafeJavascriptStringEncode() %>';
        }
        return true;
    }

    $(function () {
    <%if (!string.IsNullOrWhiteSpace(this.GetFirstname()))
      {%>
        $('#txtFirstname').blur();
    <%}%>

        $('#txtFirstname').keypress(function (e) {
            if (e.which > 0) {
                var STR = '\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
                var c = String.fromCharCode(e.which);
                if (STR.indexOf(c) >= 0) {
                    e.preventDefault();
                }
            }
        });

        $('#txtFirstname').change(function (e) {
            var val = $(this).val();
            var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
            if (val.length > 0) {
                val = val.replace(REGEX, '');
                if (val.length > 0)
                    val = val.charAt(0).toUpperCase() + val.substr(1);
                $(this).val(val);
            }
        });
    });  
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Surname
     -------------------------------------------%>
    <ui:InputField ID="fldSurname" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Surname_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
    <%: Html.TextBox("surname", GetSurname(), new 
    {
                @maxlength = "50",
        @id = "txtSurname", @validator = ClientValidators.Create()
                    .RequiredIf( "isSurnameRequired", this.GetMetadata(".Surname_Empty"))
                    .Custom("validateSurname")
    }
    ) %>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptSurname" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    function isSurnameRequired() {
        return <%= this.IsSurnameRequired.ToString().ToLowerInvariant() %>;
    }

    function validateSurname() {
        var value = this;
        var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
        if( value.length > 0 ){
            var ret = REGEX.exec(value);
            if( ret != null && ret.length > 0 )
                return '<%= this.GetMetadata(".Surname_Illegal").SafeJavascriptStringEncode() %>';
        
            REGEX = /[^x00-xff]/g;
            value = value.replace(REGEX,"xx");
            if(value.length < 2)
                return '<%= this.GetMetadata(".Surname_MinLength").SafeJavascriptStringEncode() %>';
        }
        return true;
    }

    $(function () {
    <%if (!string.IsNullOrWhiteSpace(this.GetSurname()))
      {%>
        $('#txtSurname').blur();
    <%}%>

        $('#txtSurname').keypress(function (e) {
            if (e.which > 0) {
                var STR = '\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
                var c = String.fromCharCode(e.which);
                if (STR.indexOf(c) >= 0) {
                    e.preventDefault();
                }
            }
        });

        $('#txtSurname').change(function (e) {
            var val = $(this).val();
            var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
            if (val.length > 0) {
                val = val.replace(REGEX, '');
                if (val.length > 0)
                    val = val.charAt(0).toUpperCase() + val.substr(1);
                $(this).val(val);
            }
        });
    });  
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Country_Select 
     -------------------------------------------%>
    <ui:InputField ID="fldCountry" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Country_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.DropDownList("country", GetCountryList(), new
                {
                    @id = "ddlCountry",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".Country_Empty"))
                })%>
            <input readonly="readonly" disabled="disabled" style=" display:none; " type="text" value="" id="txtCountry" class="textbox valid" autocomplete="off" />
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptCountry" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    $(function () {
        $('#ddlCountry').change( function(){
            <%= GetCountryJson() %>
        var country = countries[$(this).val()];
            var params = { ID: $(this).val(), CountryCode:'', PhoneCode:'', LegalAge:18 };
            if( country != null ){
                params.CurrencyCode = country.CC;
                params.PhoneCode = country.PC;
                if(params.ID==74)
                    params.LegalAge =21;
            }
            $(document).trigger('COUNTRY_SELECTION_CHANGED', params);
        });

        setTimeout( function(){ $('#ddlCountry').trigger('change'); }, 1000);
        $.getJSON( '/Profile/GetIPLocation', function(json){
            if( !json.success || !json.data.found ) return;
            if(json.data.countryID > 0)
                $('#ddlCountry').val( json.data.countryID ).trigger('change');
            if( json.data.isCountryRegistrationBlocked ){
                setTimeout( function(){
                    alert('<%= this.GetMetadata("/Register/_CountryBlockedView_ascx.Blocked_Message").SafeJavascriptStringEncode() %>');
                }, 0);            
            }
        }); 
    }); 
    </script>
    </ui:MinifiedJavascriptControl>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptReqCountry" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        $(function () {
            $('#ddlCountry').val('<%= Request["country"]!=null ? Request["country"].ToString() : "" %>').trigger('change');
        }); 
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Region / State (The RegionID is not updatable now by GmCore API )
     -------------------------------------------%>
    <ui:InputField ID="fldRegion" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
        <LabelPart><%= this.GetMetadata(".Region_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
            <%: Html.DropDownList("regionID", GetRegionList(), new
                {
                    @id = "ddlRegion",
                    @validator = ClientValidators.Create()
                        .RequiredIf("validateRegion", this.GetMetadata(".Region_Empty"))
                })%>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptRegion" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    $(function () {
        $('#fldRegion').hide();
        $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
            $('#ddlRegion').data('countryID', data.ID);
            $('#ddlRegion').empty();
            if (data.ID > 0) {
                var url = '<%= this.Url.RouteUrl( "Register", new { @action = "GetRegionsByCountry" }).SafeJavascriptStringEncode()  %>';
                jQuery.getJSON(url
                    , { countryID: data.ID }
                    , function (json) {
                        if (!json.success) {
                            //alert(json.error);
                            return;
                        }

                        if (json.countryID == $('#ddlRegion').data('countryID') ) {
                            $('#ddlRegion').empty();
                            if (json.regions.length > 0) {
                                $('<option value=""></option>').appendTo($('#ddlRegion')).text('<%= this.GetMetadata(".Region_Select").SafeJavascriptStringEncode() %>').attr('value', '');
                                for (var i = 0; i < json.regions.length; i++) {
                                    var $option = $('<option></option>').appendTo('#ddlRegion');
                                    $option.text(json.regions[i].DisplayName).attr('value', json.regions[i].ID);
                                }
                                $('#fldRegion').show();
                            }
                            else {
                                $('#fldRegion').hide();
                            }
                        }
                    }); <%-- End of getJSON --%> 
            }
            else{
                $('#ddlRegion').empty();
                $('#fldRegion').hide();
            }
        }); <%-- End of COUNTRY_SELECTION_CHANGED --%> 
    });

    function validateRegion() {
        return $('option', $('#ddlRegion')).length > 0;
    }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Address 1
     -------------------------------------------%>
    <ui:InputField ID="fldAddress1" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Address1_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.TextBox("address1", null, new 
            {
                @maxlength = "100",
                @id = "txtAddress1",
                @validator = ClientValidators.Create()
                    .RequiredIf( "isAddress1Required", this.GetMetadata(".Address1_Empty"))
                    .MinLength( 2, this.GetMetadata(".Address_MinLength"))
            }
                ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptAddress1" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    function isAddress1Required() {
        return <%= this.IsAddress1Required.ToString().ToLowerInvariant() %>;
    }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        City
     -------------------------------------------%>
    <ui:InputField ID="fldCity" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".City_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.TextBox("city", null, new 
            {
                @maxlength = "50",
                @id = "txtCity",
                @validator = ClientValidators.Create()
                    .RequiredIf( "isCityRequired", this.GetMetadata(".City_Empty"))
                    .MinLength(2, this.GetMetadata(".City_MinLength"))
            }
                ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptCity" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    function isCityRequired() {
        return <%= this.IsCityRequired.ToString().ToLowerInvariant() %>;
    }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        PostalCode
     -------------------------------------------%>
    <ui:InputField ID="fldPostalCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".PostalCode_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.TextBox("postalCode", this.ViewData["postalCode"] == null ? null : this.ViewData["postalCode"].ToString(), new 
            {
                @maxlength = "20",
                @id = "txtPostalCode",
                @validator = ClientValidators.Create().RequiredIf("isPostalCodeRequired", this.GetMetadata(".PostalCode_Empty"))
            }
                ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptPostalCode" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    function isPostalCodeRequired() {
        return <%= this.IsPostalCodeRequired.ToString().ToLowerInvariant() %>;
    }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Mobile
     -------------------------------------------%>
    <div class="RegisterInfoPhonePromotions"><%= this.GetMetadata(".RegisterInfoPhonePromotions") %></div>
    <label for="txtMobile" class="inputfield_Label"><%= this.GetMetadata(".Mobile_Label").SafeHtmlEncode() %></label>
    <ui:InputField ID="fldMobile" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <ControlPart>
            <%: Html.DropDownList("mobilePrefix", GetPhonePrefixList(), new { @id = "ddlMobilePrefix", @class = "ddlPhonePrefix" })%>
            <%: Html.TextBox("mobile", GetMobile(), new 
            {
                @maxlength = "30",
                @id = "txtMobile",
                @class = "tbPhoneCode",
                @validator = ClientValidators.Create()
                    .RequiredIf( "isMobileRequired", this.GetMetadata(".Mobile_Empty"))
                    .MinLength(7, this.GetMetadata(".Mobile_Incorrect"))
                    .Number(this.GetMetadata(".Mobile_Incorrect"))
                    .Custom("validateMobileNumber")
            }
        ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptMobile" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
    $(function () {
        $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
            if (data.ID > 0)
                $('#ddlMobilePrefix').val(data.PhoneCode);
        });
    });

    function isMobileRequired() {
        return <%= this.IsMobileRequired.ToString().ToLowerInvariant() %>;
    }

    function validateMobileNumber() {
        var value = this;
        if (value.length > 0) {
            if( $('#ddlMobilePrefix').val() == '' )
                return '<%= this.GetMetadata(".PhonePrefix_Empty").SafeJavascriptStringEncode() %>';
        }
        return true;
    }
    </script>
    </ui:MinifiedJavascriptControl> 
    <ui:MinifiedJavascriptControl runat="server" ID="scriptReqMobile" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        $(function () {
            $('#ddlMobilePrefix').val('<%=Request["mobilePrefix"].ToString()%>');
        }); 
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        DOB
     -------------------------------------------%>
    <ui:InputField ID="fldDOB" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".DOB_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
            <%: Html.DropDownList( "ddlDay", GetDayList())%>
            <%: Html.DropDownList( "ddlMonth", GetMonthList())%>
            <%: Html.DropDownList("ddlYear", GetYearList(), new { @validator = ClientValidators.Create().RequiredIf( "isBirthDateRequired", this.GetMetadata(".DOB_Empty")).Custom("validateBirthday") })%>            
            <%: Html.TextBox("birth", GetBirth(), new 
            { 
                @id = "txtBirthday",
                @style = "display:none",
            } ) %>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptDOB" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
    function isBirthDateRequired(){
        return <%= this.IsBirthDateRequired.ToString().ToLowerInvariant() %>;
    }
    function validateBirthday() {
        if( $('#ddlDay').val() == '' || $('#ddlMonth').val() == '' || $('#ddlYear').val() == '' )
            return (!<%= this.IsBirthDateRequired.ToString().ToLowerInvariant() %>) || '<%= this.GetMetadata(".DOB_Empty").SafeJavascriptStringEncode() %>';

        $('#txtBirthday').val( $('#ddlYear').val() + '-' + $('#ddlMonth').val() + '-' + $('#ddlDay').val() );

        var maxDay = 31;
        switch( parseInt($('#ddlMonth').val(), 10) ){
            case 4: maxDay = 30; break;
            case 6: maxDay = 30; break;
            case 9: maxDay = 30; break;
            case 11: maxDay = 30; break;

            case 2:
            {
                var year = parseInt($('#ddlYear').val(), 10);
                if( year % 400 == 0 || year % 4 == 0 )
                    maxDay = 29;
                else
                    maxDay = 28;
                break;
            }
            default:
                break;
        }

        if( parseInt($('#ddlDay').val(), 10) > maxDay )
            return '<%= this.GetMetadata(".DOB_Empty").SafeJavascriptStringEncode() %>';

        var date = new Date();
        date.setFullYear(parseInt($('#ddlYear').val(), 10), parseInt($('#ddlMonth').val(), 10) - 1, parseInt($('#ddlDay').val(), 10));
        var compare = new Date();
        compare.setFullYear(compare.getFullYear()-__Registration_Legal_Age);    
        if (date > compare)
            return '<%= this.GetMetadata(".DOB_Under18").SafeJavascriptStringEncode() %>'.format(__Registration_Legal_Age);
        return true;
    }

        <%if (!string.IsNullOrWhiteSpace(this.GetBirth()))
        {%>
        $(function () {
            $('#ddlYear').blur();
        });
        <%}%>
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Title
     -------------------------------------------%>
    <ui:InputField ID="fldTitle" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Title_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.DropDownList("title"
                , GetTitleList()
                , new { @validator = ClientValidators.Create().RequiredIf( "isTitleRequired", this.GetMetadata(".Title_Empty")) }
                )%>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptTitle" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function isTitleRequired() {
            return <%= this.IsTitleRequired.ToString().ToLowerInvariant() %>;
        }
    </script>
    </ui:MinifiedJavascriptControl>

    
    <%------------------------------------------
        Security Question
     -------------------------------------------%>
    <ui:InputField ID="fldSecurityQuestion" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".SecurityQuestion_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
            <%: Html.DropDownList("securityQuestion", GetSecurityQuestionList(), new 
            {
                @id = "ddlSecurityQuestion",
                @validator = ClientValidators.Create()
                    .RequiredIf( "isSecurityQuestionRequired", this.GetMetadata(".SecurityQuestion_Empty"))
            })%>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptSecurityQuestion" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function isSecurityQuestionRequired() {
            return <%= this.IsSecurityQuestionRequired.ToString().ToLowerInvariant() %>;
        }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Security Answer
     -------------------------------------------%>
    <ui:InputField ID="fldSecurityAnswer" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".SecurityAnswer_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
    <%: Html.TextBox("securityAnswer", string.Empty, new 
    {
                @maxlength = 50,
                @id = "txtSecurityAnswer",
                @validator = ClientValidators.Create()
                    .RequiredIf("isSecurityAnswerRequired", this.GetMetadata(".SecurityAnswer_Empty"))
                    .MinLength(2, this.GetMetadata(".SecurityAnswer_MinLength"))
    }
    ) %>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptSecurityAnswer" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function isSecurityAnswerRequired() {
            return <%= this.IsSecurityAnswerRequired.ToString().ToLowerInvariant() %>;
        }
    </script>
    </ui:MinifiedJavascriptControl>


    <%------------------------------------------
        Currency
     -------------------------------------------%>
    <label for="ddlCurrency" class="inputfield_Label"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode() %></label>
    <ui:InputField ID="fldCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <ControlPart>
            <%: Html.DropDownList( "currency", GetCurrencyList(), new 
            {
                @id = "ddlCurrency",
                @validator = ClientValidators.Create().Required(this.GetMetadata(".Currency_Empty"))
            })%>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptCurrency" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        $(function () {
            $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
                if (data.ID > 0)
                    $('#ddlCurrency').val(data.CurrencyCode);
            });
        });
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Language
     -------------------------------------------%>
    <ui:InputField ID="fldLanguage" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Language_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
            <%: Html.DropDownList("language", GetLanguageList(), new 
            {
                @id = "ddlLanguage",
                @validator = ClientValidators.Create().Required(this.GetMetadata(".Language_Empty"))
            })%>
    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptLanguage" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        $(function () {
            $("#fldLanguage").css("display","none");
            $("#ddlLanguage").val("tr");
            if ($('#ddlLanguage > option').length <= 1)
                $('#fldLanguage').hide();
        });
    </script>
    </ui:MinifiedJavascriptControl>
    </div>
    <%--if (Settings.QuickRegistration.IsCaptchaRequired)
    { %>
        <% Html.RenderPartial("/Components/RegisterCaptcha", this.ViewData);  %>
    <%} --%>
    <div class="additional-fields">
    <ui:InputField ID="fldTermsConditions" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart></LabelPart>
    <ControlPart>
            <%: Html.CheckBox("acceptTermsConditions", false, new { @id = "btnTermsConditions", @validator = ClientValidators.Create().Required(this.GetMetadata(".TermsConditions_Error")) })%>
            <label id="lblTermsConditions" for="btnTermsConditions"><%= this.GetMetadata(".TermsConditions_Label").SafeHtmlEncode()%></label>
            <a href="<%= Settings.TermsConditions_Url.SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".TermsConditions_Link").SafeHtmlEncode()%></a>
        </ControlPart>
    </ui:InputField>
    </div>

    <div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Register_Button"), new { @type= "submit", @id = "btnRegisterUser"})%>
    </div>
    <div class="clear"></div>
<% } %>
</div>
<script type="text/javascript">
    $('.topContentMain').remove();
    var __Registration_Legal_Age = 18;
    function validateAbove18Option() {
        if ($("#btnAbove18").attr("checked"))
            return true;

        return '<%= this.GetMetadata(".LegalAge_Error").SafeJavascriptStringEncode()%>'.format(__Registration_Legal_Age);
    }

    $(function () {
        $('.topContentMain').remove();
        $('#ddlMobilePrefix').val("+90");
        $('#ddlCurrency').val("TRY");
        <%if(this.IsTermsConditionsVisible){%>
        $("#lblTermsConditions").html('<%= this.GetMetadata(".TermsConditions_Label").SafeJavascriptStringEncode()%>'.format(__Registration_Legal_Age));
        <%}%>
        $('#formQuickRegister').initializeForm();

        $('#btnRegisterUser').click(function (e) {
            e.preventDefault();

            if (!$('#formQuickRegister').valid())
                return;
            var $this = $(this);
            $this.toggleLoadingSpin(true);

            var options = {
                iframe: false,
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $this.toggleLoadingSpin(false);
                    $('div.register-input-view').html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    $this.toggleLoadingSpin(false);
                    //alert(errorThrown);
                }
            };
            $('#formQuickRegister').ajaxForm(options);
            $('#formQuickRegister').submit();
        });
    });
</script>