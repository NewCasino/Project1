<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
    private SelectList GetIntendedVolumeList()
    {
        Dictionary<string, string> indendedVolumedayList = new Dictionary<string, string>();
        string[] indendedVolumeTypes = Enum.GetNames(typeof(IntendedVolume));
        string[] indendedVolumepaths = Metadata.GetChildrenPaths("/Metadata/Settings/DKLicense/IntendedVolume");
        string indendedVolumeText;
        int indendedVolumeValue = 0;
        for (int i = 0; i < indendedVolumepaths.Length; i++)
        {
            indendedVolumeText = indendedVolumepaths[i].Substring(indendedVolumepaths[i].LastIndexOf("/") + 1);
            for (int c = 0; c < indendedVolumeTypes.Length; c++)
            {
                if (indendedVolumeTypes[c].Equals(indendedVolumeText))
                {
                    indendedVolumeValue = Convert.ToInt32(Enum.Parse(typeof(IntendedVolume), indendedVolumeTypes[c]));
                    indendedVolumeText = this.GetMetadata(string.Format("{0}.Text", indendedVolumepaths[i])).DefaultIfNullOrEmpty(c.ToString());
                    indendedVolumedayList.Add(indendedVolumeValue.ToString(), indendedVolumeText);
                }
            }
        }
        return new SelectList(indendedVolumedayList, "Key", "Value");
    }

    private DateTime? GetBirthday { get; set; }

    private SelectList GetDayList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Day"));
        for (int i = 1; i <= 31; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        string selectedValue = string.Empty;
        if (this.GetBirthday.HasValue)
        {
            selectedValue = string.Format("{0:00}", this.GetBirthday.Value.Day);
        }
        return new SelectList(dayList, "Key", "Value", selectedValue);
    }

    private SelectList GetMonthList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Month"));
        for (int i = 1; i <= 12; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        string selectedValue = string.Empty;
        if (this.GetBirthday.HasValue)
        {
            selectedValue = string.Format("{0:00}", this.GetBirthday.Value.Month);
        }
        return new SelectList(dayList, "Key", "Value", selectedValue);
    }

    private SelectList GetYearList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add("", this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Year"));
        for (int i = DateTime.Now.Year - 18; i > 1900; i--)
        {
            dayList.Add(i.ToString(), i.ToString());
        }
        string selectedValue = string.Empty;
        if (this.GetBirthday.HasValue)
        {
            selectedValue = this.GetBirthday.Value.Year.ToString();
        }
        var list = new SelectList(dayList, "Key", "Value", selectedValue);
        return list;
    }

    private bool isShowPopup { get; set; }

    private bool hasPersonalID { get; set; }

    private bool isInMigrationListForCountries { get; set; }
    protected string Username
    {
        get
        {
            if (this.ViewData["username"] != null)
                return this.ViewData["username"] as string;
            else return string.Empty;
        }
    }
    protected override void OnInit(EventArgs e)
    {
        if (Settings.SafeParseBoolString(this.GetMetadata(".EnabledCPRPopup"), false))
        {
            cmUser user = null;
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            if (!string.IsNullOrWhiteSpace(Username))
            {
                user = ua.GetByUsernameOrEmail(SiteManager.Current.DomainID, Username, Username);
            }
            else if (Profile.IsAuthenticated)
            {
                user = ua.GetByID(Profile.UserID);
            }

            if (user != null && user.CountryID == 64)
            {
                this.GetBirthday = user.Birth;
                if (string.IsNullOrWhiteSpace(user.PersonalID))
                {
                    isShowPopup = true;
                }
                else if (Profile.IsAuthenticated && Settings.SafeParseBoolString(this.GetMetadata(".EnabledDirectionPopup"), false))
                {
                    hasPersonalID = true;
                }
            }
        }
        else if (Profile.IsAuthenticated && Settings.SafeParseBoolString(this.GetMetadata(".SwitchMigrationCountries"), false))
        {
            string countries = this.GetMetadata(".MigrationListForCountries").DefaultIfNullOrEmpty(string.Empty);
            if (!string.IsNullOrWhiteSpace(countries))
            {
                string[] countryList = countries.Split(new char[] { ',' });
                if (countryList.Length > 0 && countryList.Contains(Profile.UserCountryID.ToString()))
                {
                    isInMigrationListForCountries = true;
                }
            }
        }

        base.OnInit(e);
    }
</script>

<% if (isShowPopup)
   { %>
<div class="CprAndIntended-Style">
<%= this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
</div>
<div class="CprAndIntended-Overlay">
    <div class="CprAndIntended-Wrap">
        <a class="Close"></a>
        <div class="CprAndIntended-Box">
            <% using (Html.BeginRouteForm("Profile", new { @action = "UpdateCPR" }, FormMethod.Post, new { @id = "UpdateCPRForm" }))
            { %>
            <div class="CprAndIntended_Desc"><%=this.GetMetadata(".Description").HtmlEncodeSpecialCharactors() %></div>
            <ul class="FormList">
                <%------------------------------------------
                    DOB & CPR Number
                 -------------------------------------------%>
                 <li class="FormItem DOBFormItem" id="fldCPRNumber" runat="server">
                 <label class="FormLabel"><%= this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Label").SafeHtmlEncode() %></label>
                        <span class="CPRDOB">
                            <span class="CPRDOBDay2"></span>
                            <span class="CPRDOBMonth2"></span>
                            <span class="CPRDOBYear2"></span>
                        </span>
                        <span class="CPRNum">
                        <%: Html.DropDownList( "day", GetDayList(), new Dictionary<string, object>()  
                            { 
                                { "id", "ddlDay2" },
                                { "required", "required" },
                                { "data-validator", ClientValidators.Create()
                                                                .RequiredIf( "isBirthDateRequired", this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Empty"))
                                                                .Custom("validateBirthday") }
                            }
                        )%>
                        <%: Html.DropDownList( "month", GetMonthList(), new Dictionary<string, object>()  
                            { 
                                { "id", "ddlMonth2" },
                                { "required", "required" },
                                { "data-validator", ClientValidators.Create()
                                                                .RequiredIf( "isBirthDateRequired", this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Empty"))
                                                                .Custom("validateBirthday") }
                            }
                        )%>
                        <%: Html.DropDownList("year", GetYearList(), new Dictionary<string, object>()  
                            { 
                                { "id", "ddlYear2" },
                                { "required", "required" },
                                { "data-validator", ClientValidators.Create()
                                                                .RequiredIf( "isBirthDateRequired", this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Empty"))
                                                                .Custom("validateBirthday") }
                            }
                        )%>

                        <%: Html.TextBox("birth", GetBirthday.HasValue ? string.Format("{0}-{1:00}-{2:00}"
                                                                                    , this.GetBirthday.Value.Year
                                                                                    , this.GetBirthday.Value.Month
                                                                                    , this.GetBirthday.Value.Day
                                                                                    ) : string.Empty
                                , new Dictionary<string, object>() 
                                { 
                                    { "id", "txtBirthday2"},
                                    { "style", "display:none"}
                                } ) %>
                        <%: Html.TextBox("preCPRNumber2", "", new Dictionary<string, object>()  
                            {
                                { "class", "FormInput" },
                                { "id", "preCPRNumber2" },
                                { "maxlength", "6" },
                                { "style", "display:none;" },
                            }
                        ) 
                        %><%: Html.TextBox("CPRNumber", "", new Dictionary<string, object>()  
                            {
                                { "class", "FormInput" },
                                { "id", "txtCPRNumber2" },
                                { "maxlength", "4" },
                                { "placeholder", this.GetMetadata(".CPRNumber_Holder") },
                                { "required", "required" },
                                { "data-validator", ClientValidators.Create()
                                                                .RequiredIf( "isCPRNumberRequired", this.GetMetadata(".CPRNumber_Empty"))
                                                                .Custom("validateCPRNumber") }
                            }
                        ) %>
                        </span>
                        <span class="FormStatus">Status</span>
                        <span class="FormHelp"></span>
                </li>
                <ui:MinifiedJavascriptControl runat="server" ID="scriptCPRNumber" AppendToPageEnd="true" Enabled="false">
                    <script type="text/javascript">
                        var __Registration_Legal_Age = 18;
                        function isBirthDateRequired() {
                            return true;
                        }

                        function validateBirthday() {
                            if ($('#ddlDay2').val() == '' || $('#ddlMonth2').val() == '' || $('#ddlYear2').val() == '')
                                return '<%= this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Empty").SafeJavascriptStringEncode() %>';

                            $('#txtBirthday2').val($('#ddlYear2').val() + '-' + $('#ddlMonth2').val() + '-' + $('#ddlDay2').val());

                            var maxDay = 31;
                            switch (parseInt($('#ddlMonth2').val(), 10)) {
                                case 4: maxDay = 30; break;
                                case 6: maxDay = 30; break;
                                case 9: maxDay = 30; break;
                                case 11: maxDay = 30; break;

                                case 2:
                                    {
                                        var year = parseInt($('#ddlYear2').val(), 10);
                                        if (year % 400 == 0 || year % 4 == 0)
                                            maxDay = 29;
                                        else
                                            maxDay = 28;
                                        break;
                                    }
                                default:
                                    break;
                            }

                            if (parseInt($('#ddlDay2').val(), 10) > maxDay)
                                return '<%= this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Empty").SafeJavascriptStringEncode() %>';

                            var date = new Date();
                            date.setFullYear(parseInt($('#ddlYear2').val(), 10), parseInt($('#ddlMonth2').val(), 10) - 1, parseInt($('#ddlDay2').val(), 10));
                            var compare = new Date();
                            compare.setFullYear(compare.getFullYear() - __Registration_Legal_Age);
                            if (date > compare)
                                return '<%= this.GetMetadata("/Register/_PersionalInformation_ascx.DOB_Under18").SafeJavascriptStringEncode() %>'.format(__Registration_Legal_Age);
                            return true;
                        }
                        function updatePreCPRNumber() {
                            if (!isNaN($("#ddlYear2").val())) {
                                $(".CPRDOBYear2").text($("#ddlYear2").val().substr(2, 2));
                            }
                            $(".CPRDOBMonth2").text($("#ddlMonth2").val());

                            $(".CPRDOBDay2").text($("#ddlDay2").val());
                            $("#preCPRNumber2").val($(".CPRDOBDay2").text() + $(".CPRDOBMonth2").text() + $(".CPRDOBYear2").text());
                        }

                        $("#ddlDay2,#ddlMonth2,#ddlYear2").change(function () {
                            updatePreCPRNumber();
                        });
                        function isCPRNumberRequired() {
                            return true;
                        }
                        function validateCPRNumber() {
                            if ($("#txtCPRNumber2").val().length != 4 || isNaN($("#txtCPRNumber2").val())) {
                                return "<%=this.GetMetadata(".CPRNumber_Format_Error")%>";
                            }
                            <%if(Settings.Registration.IsVerifyCprAndAge) {%>
                            var errorMsg;
                            $.ajax({
                                type: "GET",
                                url: "/Register/DKValidateCprAndAge",
                                async: false,
                                data: {
                                    cpr: encodeURIComponent($("#preCPRNumber2").val() + $("#txtCPRNumber2").val().toString())
                                },
                                dataType: "json",
                                success: function (data) {
                                    try {
                                        if (data.data.CprStatus != 1) {

                                            errorMsg = '<%=this.GetMetadata("/Metadata/ServerResponse.Register_CPRInvalid").DefaultIfNullOrEmpty("CPR Exclude").SafeJavascriptStringEncode()%>';
                                        }

                                        if (data.data.AgeStatus != 0) {
                                            errorMsg = '<%=this.GetMetadata("/Metadata/ServerResponse.Register_InvalidCPRAge").DefaultIfNullOrEmpty("Over age limit").SafeJavascriptStringEncode()%>';

                                        }

                                        if (data.data.ErrorDetails != '') {
                                            errorMsg = data.data.ErrorDetails;
                                        }
                                    } catch (err) { }
                                }
                            });
                            if (errorMsg != null)
                                return errorMsg;
                            <%}%>
                            $('#ddlYear2').click();
                            return true;
                        }
                    </script>
                </ui:MinifiedJavascriptControl>      

                <li class="FormItem IntendedVolumeFormItem" id="fldIntendedVolume2" runat="server">
                <label class="FormLabel"><%= this.GetMetadata(".IntendedVolume_Label").SafeHtmlEncode()%></label>
                    <%: Html.DropDownList("intendedVolume", GetIntendedVolumeList(), new Dictionary<string, object>()  
                            { 
                                { "id", "txtIntendedVolume2" },
                                { "data-validator", ClientValidators.Create()
                                                                .Required(this.GetMetadata(".IntendedVolume_Empty")) }
                            }
                        )%>
                </li>
            </ul>
            <div class="extra-desc"><%=this.GetMetadata(".Extra_Desc").HtmlEncodeSpecialCharactors() %></div>
            <div class="CprAndIntended-Buttons">
                <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type="button", @class="CprAndIntendedButton button" } )%>
            </div>
            <% } %>
        </div>
    </div>
</div>
<script type="text/javascript">
    $(function () {
        updatePreCPRNumber();
        var $container = $('body', top.document);

        if ($('.CprAndIntended-Overlay', $container).length == 0) {
            $('.CprAndIntended-Style, .CprAndIntended-Overlay').appendTo($container);
        }

        $('#UpdateCPRForm').initializeForm();

        $('.CprAndIntended-Overlay').off('click', '.Close').on('click', '.Close', function (e) {
            $('.CprAndIntended-Overlay').remove();
            window.location = "/Login/SignOut";
        });

        var left = parseInt(($container.width() - $('.CprAndIntended-Wrap', $container).width()) / 2);
        $('.CprAndIntended-Wrap', $container).css('left', left);
        $('.CprAndIntended-Overlay', $container).width($container.width()).height($container.height()).css('display', 'block');

        $container.off('click', '.CprAndIntendedButton.button').on('click', '.CprAndIntendedButton.button', function (e) {
            e.preventDefault();
            if (!$('#UpdateCPRForm').valid() || !$('#txtCPRNumber2').valid())
                return false;

            var options = {
                iframe: false,
                data: {
                    cpr: encodeURIComponent($("#preCPRNumber2").val() + $("#txtCPRNumber2").val()),
                    intendedVolume: $("#txtIntendedVolume2").val()
                },
                url: $('#UpdateCPRForm').attr('action'),
                dataType: "json",
                type: 'POST',
                success: function (data) {
                    //$('.CprAndIntendedButton').toggleLoadingSpin(false);
                    if (data.success) {
                        alert('<%=this.GetMetadata(".success").SafeJavascriptStringEncode()%>');
                        //$('.CprAndIntended-Overlay .Close').trigger('click');
                        window.location.reload();
                    } else {
                        alert(data.error);
                        window.location = "/Login/SignOut";
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    //$('.CprAndIntendedButton').toggleLoadingSpin(false);
                    alert(errorThrown);
                    window.location = "/Login/SignOut";
                }
            };
            $.ajax(options);
            //$('#UpdateCPRForm').ajaxForm(options);
            //$('#UpdateCPRForm').submit();
        });

        $container.bind('resize', function () {
            var left = parseInt(($container.width() - $('.CprAndIntended-Wrap', $container).width()) / 2);
            $('.CprAndIntended-Wrap', $container).css('left', left);
        });

        <%--if (this.GetBirthday.HasValue)
        {--%>
        //$('#ddlDay2,#ddlMonth2,#ddlYear2').prop('readonly', true).prop('disabled', true);
        $('#txtCPRNumber2').blur();
        <%--}--%>
    });
</script>
 <%  } 
else if (hasPersonalID)
{ %>
<div class="CprAndIntended-Style">
<%= this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
</div>
<div class="CprAndIntended-Overlay">
    <div class="CprAndIntended-Wrap hasPersonalID">
        <div class="CprAndIntended-Box">
            <div class="Disclaimer_Desc"><%=this.GetMetadata(".Disclaimer_Text").HtmlEncodeSpecialCharactors() %></div>
        </div>
    </div>
</div>
<script type="text/javascript">
    $(function () {
        var $container = $('body', top.document);

        if ($('.CprAndIntended-Overlay', $container).length == 0) {
            $('.CprAndIntended-Style, .CprAndIntended-Overlay').appendTo($container);
        }

        var left = parseInt(($container.width() - $('.CprAndIntended-Wrap', $container).width()) / 2);
        $('.CprAndIntended-Wrap', $container).css('left', left);
        $('.CprAndIntended-Overlay', $container).width($container.width()).height($container.height()).css('display', 'block');

        $container.bind('resize', function () {
            var left = parseInt(($container.width() - $('.CprAndIntended-Wrap', $container).width()) / 2);
            $('.CprAndIntended-Wrap', $container).css('left', left);
        });

        setTimeout(function () {
            var directUrl = '<%=this.GetMetadata(".DKSite_Url").SafeJavascriptStringEncode() %>';
            if (directUrl != '') {
                top.window.location = directUrl;
            }
        }, 10000);
    });
</script>
 <%  }
else if (isInMigrationListForCountries)
{ %>
<div class="CprAndIntended-Style">
<%= this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
</div>
<div class="CprAndIntended-Overlay">
    <div class="CprAndIntended-Wrap hasPersonalID">
        <div class="CprAndIntended-Box">
            <div class="Disclaimer_Desc"><%=this.GetMetadata(".MigrationDisclaimer_Text").HtmlEncodeSpecialCharactors() %></div>
        </div>
    </div>
</div>
<script type="text/javascript">
    $(function () {
        var $container = $('body', top.document);

        if ($('.CprAndIntended-Overlay', $container).length == 0) {
            $('.CprAndIntended-Style, .CprAndIntended-Overlay').appendTo($container);
        }

        var left = parseInt(($container.width() - $('.CprAndIntended-Wrap', $container).width()) / 2);
        $('.CprAndIntended-Wrap', $container).css('left', left);
        $('.CprAndIntended-Overlay', $container).width($container.width()).height($container.height()).css('display', 'block');

        $container.bind('resize', function () {
            var left = parseInt(($container.width() - $('.CprAndIntended-Wrap', $container).width()) / 2);
            $('.CprAndIntended-Wrap', $container).css('left', left);
        });

        setTimeout(function () {
            var directUrl = '<%=this.GetMetadata(".MigrationSite_Url").SafeJavascriptStringEncode() %>';
            if (directUrl != '') {
                top.window.location = directUrl;
            }
        }, 10000);
    });
</script>
<% } %>