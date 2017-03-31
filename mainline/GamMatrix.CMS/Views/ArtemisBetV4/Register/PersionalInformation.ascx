<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="OAuth" %>
<script language="C#" runat="server" type="text/C#">
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

    private SelectList GetTitleList()
    {
        Dictionary<string, string> titleList = new Dictionary<string, string>();
        titleList.Add("", this.GetMetadata(".Title_Choose"));
        titleList.Add("Mr.", this.GetMetadata("/Metadata/Title.Mr"));
        titleList.Add("Ms.", this.GetMetadata("/Metadata/Title.Ms"));
        titleList.Add("Mrs.", this.GetMetadata("/Metadata/Title.Mrs"));
        titleList.Add("Miss", this.GetMetadata("/Metadata/Title.Miss"));
        var list = titleList.AsEnumerable().Where(t => !string.IsNullOrWhiteSpace(t.Value)).Distinct(new TitleComparer());

        string selectedValue = Request["gender"].DefaultIfNullOrEmpty(string.Empty);
        if (this.Model != null && !string.IsNullOrWhiteSpace(this.Model.Title))
            selectedValue = this.Model.Title.Trim();

        if (!string.IsNullOrEmpty(selectedValue))
        {
            if (!selectedValue.Equals("Mr.", StringComparison.OrdinalIgnoreCase))
            {
                selectedValue = "Ms.";
            }
        }


        return new SelectList(list, "Key", "Value", selectedValue);
    }

    private SelectList GetFavoriteTeamList()
    {
        Dictionary<string, string> favoriteTeamList = new Dictionary<string, string>();
        favoriteTeamList.Add("Other", "Other");
        favoriteTeamList.Add("Galatasaray S.K.", "Galatasaray S.K.");
        favoriteTeamList.Add("Beşiktaş J.K.", "Beşiktaş J.K.");
        favoriteTeamList.Add("Fenerbahçe S.K.", "Fenerbahçe S.K.");
        favoriteTeamList.Add("Trabzonspor", "Trabzonspor");
        favoriteTeamList.Add("Bursaspor", "Bursaspor");
        return new SelectList(favoriteTeamList, "Key", "Value");
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
        return new SelectList(dayList, "Key", "Value", selectedValue);
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
        return new SelectList(dayList, "Key", "Value", selectedValue);
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
        return new SelectList(dayList, "Key", "Value", selectedValue);
    }

    private string GetFirstname()
    {
        if (this.Model != null)
        {
            if (!string.IsNullOrWhiteSpace(this.Model.FirstName))
                return this.Model.FirstName.Trim();
        }
        else if (this.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ExternalUserInfo.Firstname))
                return ReplaceSymbols(this.ExternalUserInfo.Firstname.Trim());
        }
        else
        {
            return Request["firstname"];
        }
        return string.Empty;
    }

    private string GetPersonalID()
    { //CM.db.cmUser
        if (this.Model != null && !string.IsNullOrWhiteSpace(this.Model.PersonalID))
            return this.Model.PersonalID.Trim();
        return string.Empty;
    }
    //private string GetCPRNumber()
    //{

    //    if (this.Model != null && !string.IsNullOrWhiteSpace(this.Model.CPRNumber))
    //        return this.Model.CPRNumber.Trim();
    //    return string.Empty;
    //}
    private string GetSurname()
    {
        if (this.Model != null)
        {
            if (!string.IsNullOrWhiteSpace(this.Model.Surname))
                return this.Model.Surname.Trim();
        }
        else if (this.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ExternalUserInfo.Lastname))
                return ReplaceSymbols(this.ExternalUserInfo.Lastname.Trim());
        }
        else
        {
            return Request["surname"];
        }
        return string.Empty;
    }

    private string GetEmail()
    {
        if (this.Model != null)
        {
            if (!string.IsNullOrWhiteSpace(this.Model.Email))
                return this.Model.Email.Trim();
        }
        else if (this.ExternalUserInfo != null)
        {
            if (this.ReferrerData.GetAssociateStatus() == AssociateStatus.EmailAlreadyRegistered)
                return string.Empty;

            if (!string.IsNullOrWhiteSpace(this.ExternalUserInfo.Email))
                return this.ExternalUserInfo.Email.Trim();
        }
        else
        {
            return Request["email"];
        }
        return string.Empty;
    }

    private string GetBirth()
    {
        if (this.Model != null && this.Model.Birth.HasValue)
        {
            return string.Format("{0}-{1:00}-{2:00}"
                , this.Model.Birth.Value.Year
                , this.Model.Birth.Value.Month
                , this.Model.Birth.Value.Day
                );
        }
        else if (this.ExternalUserInfo != null
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
        if (this.Model != null && this.Model.Birth.HasValue)
        {
            return this.Model.Birth.Value;
        }
        else if (this.ExternalUserInfo != null
            && this.ExternalUserInfo.Birth.HasValue)
        {
            return this.ExternalUserInfo.Birth.Value;
        }
        return null;
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

    private string GetPersonalIdJson()
    {
        string PersonalID_Label = this.GetMetadata(".PersonalID_Label").SafeJavascriptStringEncode();
        StringBuilder json = new StringBuilder();
        json.Append("{");

        List<CountryInfo> countries = CountryManager.GetAllCountries().Where(c => c.IsPersonalIdVisible).ToList();
        foreach (CountryInfo country in countries)
        {
            json.AppendFormat(CultureInfo.InvariantCulture
                , "'{0}':{{IsPersonalIdVisible:{1}, IsPersonalIdMandatory:{2}, PersonalIdValidationRegularExpression:\"{3}\", PersonalIdMaxLength:{4}, PersonalIDDisplayName:\"{5}\"}},"
                , country.InternalID
                , country.IsPersonalIdVisible.ToString().ToLowerInvariant()
                , country.IsPersonalIdMandatory.ToString().ToLowerInvariant()
                , country.PersonalIdValidationRegularExpression.SafeJavascriptStringEncode()
                , country.PersonalIdMaxLength.ToString("D0")
                , string.IsNullOrWhiteSpace(country.PersonalIDDisplayName) ? PersonalID_Label : country.PersonalIDDisplayName.SafeJavascriptStringEncode()
                );
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);

        json.Append("}");
        return json.ToString();
    }

    private bool IsTitleVisible { get { return this.Model != null || Settings.Registration.IsTitleVisible; } }
    private bool IsTitleRequired { get { return this.Model != null || Settings.Registration.IsTitleRequired; } }
    private bool IsFirstnameVisible { get { return this.Model != null || Settings.Registration.IsFirstnameVisible; } }
    private bool IsFirstnameRequired { get { return this.Model != null || Settings.Registration.IsFirstnameRequired; } }
    private bool IsSurnameVisible { get { return this.Model != null || Settings.Registration.IsSurnameVisible; } }
    private bool IsSurnameRequired { get { return this.Model != null || Settings.Registration.IsSurnameRequired; } }
    private bool IsBirthDateVisible { get { return this.Model != null || Settings.Registration.IsBirthDateVisible; } }
    private bool IsBirthDateRequired { get { return this.Model != null || Settings.Registration.IsBirthDateRequired; } }
    private bool IsEmailVisiible { get { return this.Model == null; } }
    private bool IsRepeatEmailVisible { get { return this.Model == null && Settings.Registration.IsRepeatEmailVisible; } }
    private bool IsPersonalIDVisible { get { return Settings.Registration.IsPersonalIDVisible || Settings.IsDKLicense; } }
    //private bool IsCPRNumberVisible { get { return Settings.IsDenmarkLicenceCheckEnabled; } }

    private bool IsIntendedVolumeRequired { get { return Settings.IsDKLicense; } }
    private bool IsDOBPlaceRequired { get { return Settings.IsDKLicense; } }
    
    protected override void OnPreRender(EventArgs e)
    {
        fldCPRNumber.Visible = Settings.IsDKLicense;
        scriptCPRNumber.Visible = fldCPRNumber.Visible;
        fldRepeatEmail.Visible = this.IsRepeatEmailVisible;

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
        fldEmail.Visible = this.IsEmailVisiible;

        fldPersonalID.Visible = this.IsPersonalIDVisible || Settings.IsDKLicense;
        scriptPersonalID.Visible = this.IsPersonalIDVisible || Settings.IsDKLicense;

        fldHasDKAccount.Visible = Settings.IsDKLicense;
        scriptHasDKAccount.Visible = Settings.IsDKLicense;

        fldIntendedVolume.Visible = Settings.IsDKLicense;
        scriptIntendedVolume.Visible = fldIntendedVolume.Visible;


        fldDOBPlace.Visible = Settings.IsDKLicense;
        scriptDOBPlace.Visible = fldDOBPlace.Visible;
        
        
        base.OnPreRender(e);
    }

    protected string ReplaceSymbols(string text)
    {
        var pattern = @"[\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f]";
        return Regex.Replace(text, pattern, " ");
    }

</script>


<script type="text/javascript">
    var __Registration_Legal_Age = 18;
</script>
<%------------------------------------------
    Title
 -------------------------------------------%>
<ui:InputField ID="fldTitle" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Title_Label").SafeHtmlEncode() %></labelpart>
    <controlpart>
    <%: Html.DropDownList("title"
            , GetTitleList()
            , new { @validator = ClientValidators.Create().RequiredIf( "isTitleRequired", this.GetMetadata(".Title_Empty")) }
            )%>
</controlpart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptTitle" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function isTitleRequired() {
            return <%= this.IsTitleRequired.ToString().ToLowerInvariant() %>;
        }
    </script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Firstname
 -------------------------------------------%>
<ui:InputField ID="fldFirstName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode() %></labelpart>
    <controlpart>
<%: Html.TextBox("firstname", GetFirstname(), new 
    {
                @maxlength = "50",
        @id = "txtFirstname", @validator = ClientValidators.Create()
                    .RequiredIf( "isFirstnameRequired", this.GetMetadata(".Firstname_Empty"))
                    .Custom("validateFirstname")
    }
) %>
</controlpart>
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
    <labelpart><%= this.GetMetadata(".Surname_Label").SafeHtmlEncode() %></labelpart>
    <controlpart>
<%: Html.TextBox("surname", GetSurname(), new 
{
            @maxlength = "50",
    @id = "txtSurname", @validator = ClientValidators.Create()
                .RequiredIf( "isSurnameRequired", this.GetMetadata(".Surname_Empty"))
                .Custom("validateSurname")
}
) %>
</controlpart>
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
    Email
 -------------------------------------------%>
<ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode() %></labelpart>
    <controlpart>
<%: Html.TextBox("email", GetEmail(), new
        {
            @maxlength = "50",
            @id = "txtEmail",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".Email_Empty"))
                .Email(this.GetMetadata(".Email_Incorrect"))
                .Custom("validateEmailDomain")                
                .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".Email_Exist") }))
        }
        )%>
</controlpart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptEmail" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function validateEmailDomain() {        
            var value = this;

            var regex = <%= GetEmailValidationRegex() %>;
            var ret = regex.exec(value);
            if( ret != null && ret.length > 0 )
                return '<%= this.GetMetadata(".Email_UnallowedDomain").SafeJavascriptStringEncode() %>';
            
            var excludedEmails = '<%=Metadata.Get("/Metadata/Settings/Registration.Excluded_mailing_list").DefaultIfNullOrEmpty(string.Empty).SafeJavascriptStringEncode() %>';
            if (excludedEmails != null && excludedEmails.length > 0) {
                var excludedEmailList = excludedEmails.split('\u000A');
                for (var i=0; i< excludedEmailList.length; i++) {
                    if (excludedEmailList[i].toLowerCase() == value.toLowerCase())
                        return '<%= this.GetMetadata(".Excluded_mailing_message").SafeJavascriptStringEncode() %>';
                }
            }

            return true;
        }

        <%if (!string.IsNullOrWhiteSpace(this.GetEmail()))
          {%>
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
    <labelpart><%= this.GetMetadata(".RepeatEmail_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
<%: Html.TextBox("repeatEmail", GetEmail(), new
        {
            @maxlength = "50",
            @id = "txtRepeatEmail",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".RepeatEmail_Empty"))
                .EqualTo("#txtEmail", this.GetMetadata(".RepeatEmail_NotMatch"))
        }
        )%>
</controlpart>
</ui:InputField>


<%------------------------------------------
    DOB
 -------------------------------------------%>
<ui:InputField ID="fldDOB" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".DOB_Label").SafeHtmlEncode() %></labelpart>
    <controlpart>
        <%: Html.DropDownList( "ddlDay", GetDayList())%>
        <%: Html.DropDownList( "ddlMonth", GetMonthList())%>
        <%: Html.DropDownList("ddlYear", GetYearList(), new { @validator = ClientValidators.Create().RequiredIf( "isBirthDateRequired", this.GetMetadata(".DOB_Empty")).Custom("validateBirthday") })%>
        <%: Html.TextBox("birth", GetBirth(), new 
            { 
                @id = "txtBirthday",
                @style = "display:none",
            } ) %>
</controlpart>
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
    CPR Number
 -------------------------------------------%>
<ui:InputField ID="fldCPRNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".CPRNumber_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <span class="CPRDOB">
            <span class="CPRDOBDay"></span>
            <span class="CPRDOBMonth"></span>
            <span class="CPRDOBYear"></span>
        </span>
        <span class="CPRNum">
<%: Html.TextBox("preCPRNumber", "", new 
    {
            @maxlength =6,
        @id = "preCPRNumber", @validator = ClientValidators.Create()
                    .RequiredIf("isCPRNumberRequired", this.GetMetadata(".CPRNumber_Empty"))
                    .Custom("validateCPRNumber")             
    }
) %>
        <%: Html.TextBox("CPRNumber", "", new 
    {
            @maxlength =4,
        @id = "txtCPRNumber", @validator = ClientValidators.Create()
                    .RequiredIf("isCPRNumberRequired", this.GetMetadata(".CPRNumber_Empty"))
                    .Custom("validateCPRNumber")             
    }
) %></span>
</controlpart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptCPRNumber" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">  
        $("#ddlDay,#ddlMonth,#ddlYear").change(function(){
            if(!isNaN($("#ddlYear").val()))
            {
                $(".CPRDOBYear").text($("#ddlYear").val().substr(2,2));
            }
            $(".CPRDOBMonth").text($("#ddlMonth").val());

            $(".CPRDOBDay").text($("#ddlDay").val());
            $("#preCPRNumber").val($(".CPRDOBDay").text()+$(".CPRDOBMonth").text()+$(".CPRDOBYear").text());
        });
        function isCPRNumberRequired() {
            return true;
        }
        function validateCPRNumber(){
            return true;
        }
    </script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Personal ID
 -------------------------------------------%>
<ui:InputField ID="fldPersonalID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= Settings.IsDKLicense ? this.GetMetadata(".PersonalID_DKLabel").SafeHtmlEncode() : this.GetMetadata(".PersonalID_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <%: Html.TextBox("personalID", GetPersonalID(), new 
    {
        @id = "txtPersonalID", @validator = ClientValidators.Create()
                    .RequiredIf("isPersonalIDRequired", this.GetMetadata(".PersonalID_Empty"))
                    .Custom("validatePersonalID")
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniquePersonalID", @message = this.GetMetadata(".PersonalID_Exist") }))            
    }
) %>
</controlpart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptPersonalID" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        var __isPersonalIdMandatory = false;
        var __personalIdValidationRegularExpression = null;
        var isDKPersonal = <%=Settings.IsDKLicense.ToString().ToLower()%>;

        $(function(){
            
        });

    

            function isPersonalIDRequired() {
                return <%=Settings.Registration.IsPersonalIDVisible.ToString().ToLowerInvariant() %>;
            }

            function validatePersonalID() {
                var value = this;
                var ret = <%=this.GetMetadata(".PersonIDRegex") %>;
                if(!ret.test(value)){
                    return '<%= this.GetMetadata(".PersonalID_Illegal").SafeJavascriptStringEncode() %>'.format($('#fldPersonalID .inputfield_Label').text());
                }
                return true;
            }
    </script>
</ui:MinifiedJavascriptControl>


<ui:InputField ID="fldHasDKAccount" runat="server"   BalloonArrowDirection="Left">
<LabelPart></LabelPart>
<ControlPart>
        <%: Html.CheckBox("hasDKAccount", false, new { @id = "btnHasDKAccount" })%>
        <label for="btnHasDKAccount"><%= this.GetMetadata(".HasDKAccount_Label").SafeHtmlEncode()%></label>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptHasDKAccount" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    $(function () {
        $("#btnHasDKAccount").click(function(){
            if( $("#ddlCountry").val()==64){
                //if( $("#btnHasDKAccount").attr("checked") !="checked" &&  $("#btnHasDKAccount").attr("checked") !="true"){
                //    $("#fldUsername,#fldPassword,#fldRepeatPassword,#fldSecurityQuestion,#fldSecurityAnswer,#fldDOBPlace").hide();
                //    $("#fldPersonalID").show();
                //}else{
                //    $("#fldUsername,#fldPassword,#fldRepeatPassword,#fldSecurityQuestion,#fldSecurityAnswer,#fldDOBPlace").show(); 
                //    $("#fldPersonalID").hide();
                //}
                $("#fldPersonalID,#fldDOBPlace").hide();
            }else{
                if( $("#btnHasDKAccount").attr("checked") !="checked" &&  $("#btnHasDKAccount").attr("checked") !="true"){
                    $("#fldPersonalID").show();
                    $("#fldDOBPlace").hide();
                
                }else{
                    $("#fldDOBPlace").show();
                    $("#fldPersonalID").hide();
                
                }
            }
        });
    });
</script>
</ui:MinifiedJavascriptControl>
 <ui:InputField ID="fldDOBPlace" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".DOBPlace_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("DOBPlace", "", new 
{
            @maxlength = 98,
            @id = "txtDOBPlace",
            @validator = ClientValidators.Create()
                .RequiredIf("isDOBPlaceRequired", this.GetMetadata(".DOBPlace_Empty")) 
}
) %>
</ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptDOBPlace" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    $("#fldDOBPlace,#fldCPRNumber").hide();
    function isDOBPlaceRequired() {
        return <%= this.IsDOBPlaceRequired.ToString().ToLowerInvariant() %>;
    }
</script>
</ui:MinifiedJavascriptControl>


<ui:InputField ID="fldIntendedVolume" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".IntendedVolume_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("intendedVolume", "", new 
{
            @maxlength = 98,
            @id = "txtIntendedVolume",
            @validator = ClientValidators.Create()
                .RequiredIf("isIntendedVolumeRequired", this.GetMetadata(".IntendedVolume_Empty")) 
}
) %>
</ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptIntendedVolume" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function isIntendedVolumeRequired() {
        return <%= this.IsIntendedVolumeRequired.ToString().ToLowerInvariant() %>;
    }
</script>
</ui:MinifiedJavascriptControl>

<% if(Profile.IsAuthenticated) { %>
<ui:InputField ID="fldFavoriteTeam" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".FavoriteTeam_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
      <%: Html.DropDownList("favoriteTeam", GetFavoriteTeamList(), new
            {
                @id = "txtFavoriteTeam"
            })%>
</controlpart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptFavoriteTeam" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$("#txtFavoriteTeam").val($(".FavoriteTeamHiddenVal").val());
</script>
</ui:MinifiedJavascriptControl>
<% } %>