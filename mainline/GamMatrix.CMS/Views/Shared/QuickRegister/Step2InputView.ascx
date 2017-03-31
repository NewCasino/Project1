<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>

<script type="text/C#" runat="server">
    private string _PersonalID = null;
    private string PersonalID
    {
        get
        {
            if (_PersonalID == null)
            {
                if (this.ViewData["personalID"] != null)
                {
                    _PersonalID = this.ViewData["personalID"].ToString();
                }

                if (_PersonalID == null)
                    _PersonalID = string.Empty;
            }
            return _PersonalID;
        }
    }

    private int YearOfPersonalID    { get; set; }
    private int MonthOfPersonalID    { get; set; }
    private int DayOfPersonalID    { get; set; }
    private int GenderOfPersonalID    { get; set; }
    
    private int _CountryID = -1;
    private int CountryID {
        get {
            if (_CountryID == -1)
            {
                if (this.ViewData["country"] != null)
                    int.TryParse(this.ViewData["country"].ToString(), out _CountryID);
                
                if (_CountryID == -1)
                    _CountryID = 0;
            }
            return _CountryID;
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
        titleList.Add("Ms.", this.GetMetadata("/Metadata/Title.Ms"));
        titleList.Add("Mrs.", this.GetMetadata("/Metadata/Title.Mrs"));
        titleList.Add("Miss", this.GetMetadata("/Metadata/Title.Miss"));        
        var list = titleList.AsEnumerable().Where(t => !string.IsNullOrWhiteSpace(t.Value)).Distinct(new TitleComparer());

        string selectedValue = string.Empty;


        if (GenderOfPersonalID == 1)
            selectedValue = "Mr.";
        else if (GenderOfPersonalID == 2)
            selectedValue = "Ms.";


        return new SelectList(list, "Key", "Value", selectedValue);
    }

    private SelectList GetDayList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata(".DOB_Day"));
        for (int i = 1; i <= 31; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        object selectedValue = null;
        if (DayOfPersonalID > 0)
            selectedValue = string.Format("{0:00}", DayOfPersonalID);
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

        object selectedValue = null;
        if (MonthOfPersonalID > 0)
            selectedValue = string.Format("{0:00}", MonthOfPersonalID);
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
        object selectedValue = null;
        if (YearOfPersonalID > 0)
            selectedValue = YearOfPersonalID;
        return new SelectList(dayList, "Key", "Value", selectedValue);
    }

    private string GetFirstname()
    {
        if (this.ViewData["firstname"] != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ViewData["firstname"].ToString()))
                return this.ViewData["firstname"].ToString();
        }
        
        return string.Empty;
    }
    
    private string GetSurname()
    {
        if (this.ViewData["surname"] != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ViewData["surname"].ToString()))
                return this.ViewData["surname"].ToString();
        }
        
        return string.Empty;
    }

    private string GetBirth()
    {
        if (DayOfPersonalID>0 && MonthOfPersonalID>0 && YearOfPersonalID>0)
        {
            return string.Format("{0}-{1:00}-{2:00}", YearOfPersonalID, MonthOfPersonalID, DayOfPersonalID);            
        }
        return string.Empty;
    }

    private SelectList GetRegionList()
    {
        var regions = CountryManager.GetCountryRegions(CountryID)
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


        object selectedValue = null;


        if (CountryID > 0)
            selectedValue = CountryID;

        return new SelectList(list
            , "Key"
            , "Value"
            , selectedValue
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
        string selectedValue = null;

        return new SelectList(list, "Key", "Value", selectedValue);
    }

    private SelectList GetLanguageList()
    {
        SelectList list = new SelectList(SiteManager.Current.GetSupporttedLanguages().Select(l => new { Key = l.LanguageCode, Value = l.DisplayName }).ToList()
                    , "Key"
                    , "Value"
                    , HttpContext.Current.GetLanguage()
                    );
        return list;
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

    private void SetBirthAndGenderFromSSN()
    {
        if (!string.IsNullOrWhiteSpace(PersonalID))
        {
            string temp = PersonalID.Replace(" ", "").Replace("-", "");
            if(temp.Length != 10 && temp.Length != 12)
                return;
            string strYear;
            int year = 0 , month = 0, day=0, gender = -1;
            if (temp.Length == 10)
            {
                strYear = temp.Substring(0, 2);
                if (int.TryParse("19" + strYear, out year))
                {
                    if ((DateTime.Now.Year - year) > 100)
                    {
                        int tempYear = int.Parse("20" + strYear);
                        if (tempYear < (DateTime.Now.Year - 18))
                            year = tempYear;

                    }
                }
                
                int.TryParse(temp.Substring(2, 2), out month);
                int.TryParse(temp.Substring(4, 2), out day);
                int.TryParse(temp.Substring(8,1), out gender);
            }
            else
            {
                int.TryParse(temp.Substring(0, 4), out year);
                int.TryParse(temp.Substring(4, 2), out month);
                int.TryParse(temp.Substring(6, 2), out day);
                int.TryParse(temp.Substring(10, 1), out gender);
            }
            
            if(gender!=-1)
                gender = gender % 2 == 0 ? 2 : 1;

            YearOfPersonalID = year;
            MonthOfPersonalID = month;
            DayOfPersonalID = day;
            GenderOfPersonalID = gender;
            
        }
    }
    protected override void OnInit(EventArgs e)
    {
        SetBirthAndGenderFromSSN();
        base.OnInit(e);
    }
    
    private bool IsTitleVisible { get { return Settings.QuickRegistration.IsTitleVisible; } }
    private bool IsTitleRequired { get { return Settings.Registration.IsTitleRequired; } }
    private bool IsFirstnameVisible { get { return Settings.QuickRegistration.IsFirstnameVisible; } }
    private bool IsFirstnameRequired { get { return Settings.Registration.IsFirstnameRequired; } }
    private bool IsSurnameVisible { get { return Settings.QuickRegistration.IsSurnameVisible; } }
    private bool IsSurnameRequired { get { return Settings.Registration.IsSurnameRequired; } }
    private bool IsBirthDateVisible { get { return Settings.QuickRegistration.IsBirthDateVisible; } }
    private bool IsBirthDateRequired { get { return Settings.Registration.IsBirthDateRequired; } }
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
    
    private bool IsTermsConditionsVisible { get { return Settings.QuickRegistration.IsTermsConditionsVisible; } }

    private bool IsAllowNewsEmailVisible { get { return Settings.QuickRegistration.IsAllowNewsEmailVisible; } }
    private bool IsAllowSmsOfferVisible { get { return Settings.QuickRegistration.IsAllowSmsOfferVisible; } }
    
    private bool? _IsCountryEditable = null;
    private bool IsCountryEditable
    { 
        get {
            if (!_IsCountryEditable.HasValue)
            {
                if (this.ViewData["country"] != null)
                {
                    int temp = 0;
                    int.TryParse(this.ViewData["country"].ToString(), out temp);
                    if (temp > 0)
                        _IsCountryEditable = false;
                }
                if (!_IsCountryEditable.HasValue)
                    _IsCountryEditable = true;
            }
            return _IsCountryEditable.Value;
        } 
    }

    private bool IsStreetVisible { get { return this.Model != null || Settings.Registration.IsStreetVisible; } }
    private bool IsStreetRequired { get { return this.Model != null || Settings.Registration.IsStreetRequired; } }   

    protected override void OnPreRender(EventArgs e)
    {
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

        //scriptCountry.Visible = this.IsCountryEditable;
        scriptReqCountry.Visible = !string.IsNullOrEmpty(Request["country"]);

        fldRegion.Visible = this.IsRegionVisible;
        scriptRegion.Visible = this.IsRegionVisible;

        fldAddress1.Visible = this.IsAddress1Visible;
        fldAddress1.ShowDefaultIndicator = this.IsAddress1Required;
        scriptAddress1.Visible = this.IsAddress1Visible;

        fldStreetName.Visible = this.IsStreetVisible;
        fldStreetName.ShowDefaultIndicator = this.IsStreetRequired;
        scriptStreetName.Visible = this.IsStreetVisible;

        fldStreetNumber.Visible = this.IsStreetVisible;
        fldStreetNumber.ShowDefaultIndicator = this.IsStreetRequired;
        scriptStreetNumber.Visible = this.IsStreetVisible;

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

        fldSecurityQuestion.Visible = this.IsSecurityQuestionVisible;
        scriptSecurityQuestion.Visible = this.IsSecurityQuestionVisible;
        fldSecurityQuestion.ShowDefaultIndicator = this.IsSecurityQuestionRequired;

        fldSecurityAnswer.Visible = this.IsSecurityAnswerVisible;
        scriptSecurityAnswer.Visible = this.IsSecurityAnswerVisible;
        fldSecurityAnswer.ShowDefaultIndicator = this.IsSecurityAnswerRequired;

        fldLanguage.Visible = this.IsLanguageVisible;
        scriptLanguage.Visible = this.IsLanguageVisible;
        
        fldTermsConditions.Visible = this.IsTermsConditionsVisible;
        fldNewsOffers.Visible = this.IsAllowNewsEmailVisible;
        fldSmsOffer.Visible = this.IsAllowSmsOfferVisible;
        
        base.OnPreRender(e);
    }
</script>

<script type="text/javascript">
    var __Registration_Legal_Age = 18;
</script>
<div class="quickregister-input-view">
<% using (Html.BeginRouteForm("QuickRegister", new { @action = "Register" }, FormMethod.Post, new { @id = "formQuickRegisterStep2" }))
   {%>

    <%if (Settings.IovationDeviceTrack_Enabled)
            { %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
    
    <%: Html.Hidden("username", this.ViewData["username"])%>
    <%: Html.Hidden("email", this.ViewData["email"])%>
    <%: Html.Hidden("password", this.ViewData["password"])%>
    <%: Html.Hidden("personalId", this.ViewData["personalId"])%>

    <%if (!IsFirstnameVisible) { %>
        <%: Html.Hidden("firstname", this.ViewData["firstname"])%>
    <%} %>
    <%if (!IsSurnameVisible) { %>
        <%: Html.Hidden("surname", this.ViewData["surname"])%>
    <%} %>
    <%if (!IsAddress1Visible) { %>
        <%: Html.Hidden("address1", this.ViewData["address1"])%>
    <%} %>
    <%if (!IsStreetVisible) { %>
        <%: Html.Hidden("streetname", this.ViewData["streetname"])%>
        <%: Html.Hidden("streetnumber", this.ViewData["streetnumber"])%>
    <%} %>
    <%if (!IsCityVisible) { %>
        <%: Html.Hidden("city", this.ViewData["city"])%>
    <%} %>
    <%if (!IsPostalCodeVisible) { %>
        <%: Html.Hidden("postalCode", this.ViewData["postalCode"])%>
    <%} %>

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
            $('#ddlCountry').val('<%=Request["country"].ToString()%>').trigger('change');
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
            <%: Html.TextBox("address1", this.ViewData["address1"] == null ? null : this.ViewData["address1"].ToString(), new 
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
        Street Name
     -------------------------------------------%>
    <ui:InputField ID="fldStreetName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".StreetName_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.TextBox( "streetname", this.ViewData["streetname"] == null ? null : this.ViewData["streetname"].ToString(), new 
            {
                @maxlength = "100",
                @id = "txtStreetName",
                @validator = ClientValidators.Create()
                    .RequiredIf( "isStreetNameRequired", this.GetMetadata(".StreetName_Empty"))
                    .MinLength( 2, this.GetMetadata(".StreetName_MinLength"))
            }
                ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptStreetName" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function isStreetNameRequired() {
            return <%= this.IsStreetRequired.ToString().ToLowerInvariant() %>;
    }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Street Number
     -------------------------------------------%>
    <ui:InputField ID="fldStreetNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".StreetNumber_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.TextBox( "streetnumber", this.ViewData["streetnumber"] == null ? null : this.ViewData["streetnumber"].ToString(), new 
            {
                @maxlength = "100",
                @id = "txtStreetNumber",
                @validator = ClientValidators.Create()
                    .RequiredIf( "isStreetNumberRequired", this.GetMetadata(".StreetNumber_Empty"))
                    .Number(this.GetMetadata(".StreetNumber_Incorrect"))
            }
                ) %>
        </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptStreetNumber" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function isStreetNumberRequired() {
            return <%= this.IsStreetRequired.ToString().ToLowerInvariant() %>;
    }
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        City
     -------------------------------------------%>
    <ui:InputField ID="fldCity" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".City_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.TextBox("city", this.ViewData["city"] == null ? null : this.ViewData["city"].ToString(), new 
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
    <ui:InputField ID="fldMobile" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Mobile_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.DropDownList( "mobilePrefix", GetPhonePrefixList(), new { @id = "ddlMobilePrefix", @class = "ddlPhonePrefix" })%>
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
    <%: Html.TextBox("securityAnswer", "" , new 
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
    <ui:InputField ID="fldCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
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
            if ($('#ddlLanguage > option').length <= 1)
                $('#fldLanguage').hide();
        });
    </script>
    </ui:MinifiedJavascriptControl>

    <ui:InputField ID="fldTermsConditions" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart></LabelPart>
    <ControlPart>
            <%: Html.CheckBox("acceptTermsConditions", false, new { @id = "btnTermsConditions", @validator = ClientValidators.Create().Required(this.GetMetadata(".TermsConditions_Error")) })%>
            <label id="lblTermsConditions" for="btnTermsConditions"><%= this.GetMetadata(".TermsConditions_Label").SafeHtmlEncode()%></label>
            <a href="<%= Settings.TermsConditions_Url.SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".TermsConditions_Link").SafeHtmlEncode()%></a>
        </ControlPart>
    </ui:InputField>

    <ui:InputField ID="fldNewsOffers" runat="server" BalloonArrowDirection="Left">
    <LabelPart></LabelPart>
    <ControlPart>
            <%: Html.CheckBox("allowNewsEmail", false, new { @id = "btnAllowNewsEmail"})%>
            <label for="btnAllowNewsEmail"><%= this.GetMetadata(".NewsOffers_Label").SafeHtmlEncode() %> </label>            
        </ControlPart>
    </ui:InputField>

    <ui:InputField ID="fldSmsOffer" runat="server" BalloonArrowDirection="Left">
    <LabelPart></LabelPart>
    <ControlPart>
            <%: Html.CheckBox("allowSmsOffer", false, new { @id = "btnAllowSmsOffer" })%>
            <label for="btnAllowSmsOffer"><%= this.GetMetadata(".SmsOffers_Label").SafeHtmlEncode() %> </label>            
        </ControlPart>
    </ui:InputField>

    <div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Continue_Button"), new { @type = "submit", @id = "btnRegisterContinue" })%>
    </div>
<% } %>
</div>
<script type="text/javascript">
    function validateAbove18Option() {
        if ($("#btnAbove18").attr("checked"))
            return true;

        return '<%= this.GetMetadata(".LegalAge_Error").SafeJavascriptStringEncode()%>'.format(__Registration_Legal_Age);
    }

    $(function () {
        <%if(CountryID>0){%>
        var $country = $("#ddlCountry");
        $country.hide();
        $("#txtCountry").val($country.find(":selected").text()).show();
        <%} 
          if(this.IsTermsConditionsVisible){%>
        $("#lblTermsConditions").html('<%= this.GetMetadata(".TermsConditions_Label").SafeJavascriptStringEncode()%>'.format(__Registration_Legal_Age));
        <%} %>

        $('#formQuickRegisterStep2').initializeForm();

        $('#formQuickRegisterStep2 #btnRegisterContinue').click(function (e) {
            e.preventDefault();

            if (!$('#formQuickRegisterStep2').valid())
                return;
            var $this = $(this);
            $this.toggleLoadingSpin(true);

            var options = {
                iframe: false,
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $this.toggleLoadingSpin(false);
                    $('div.quickregister-input-view').html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    $this.toggleLoadingSpin(false);
                    //alert(errorThrown);
                }
            };
            $('#formQuickRegisterStep2').ajaxForm(options);
            $('#formQuickRegisterStep2').submit();
        });
    });
</script>