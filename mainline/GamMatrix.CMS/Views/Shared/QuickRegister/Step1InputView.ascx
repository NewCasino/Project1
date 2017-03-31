<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Globalization" %>

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
        
    private bool IsUsernameVisible { get { return Settings.QuickRegistration.IsUserNameVisible; } }
    private bool IsPersonalIDVisible { get { return Settings.QuickRegistration.IsPersonalIDVisible; } }
    private bool IsRepeatEmailVisible { get { return Settings.QuickRegistration.IsRepeatEmailVisible; } }
    
    protected override void OnPreRender(EventArgs e)
    {
        fldRepeatEmail.Visible = this.IsRepeatEmailVisible;
        
        fldUsername.Visible = this.IsUsernameVisible;
        fldPersonalID.Visible = this.IsPersonalIDVisible;
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
</script>

<div class="register-input-view">
<% using (Html.BeginRouteForm("QuickRegister", new { @action = "Step2" }, FormMethod.Post, new { @id = "formQuickRegisterStep1" }))
   { %>
    
    <%------------------------------------------
    Username
    -------------------------------------------%>
    <ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata(".Username_Label").SafeHtmlEncode() %></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("username", null, new 
		    {
                @maxlength = Settings.Registration.UsernameMaxLength,
		        @id = "txtUsername",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Username_Empty"))
                    .MinLength(4, this.GetMetadata(".Username_Length"))
                    .Custom("validateUsername")
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueUsername", @message = this.GetMetadata(".Username_Exist") }))            
		    }
			    ) %>
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
    <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode() %></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("email", null, new
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
    </script>
    </ui:MinifiedJavascriptControl>
    
    <%------------------------------------------
    Retype Email
     -------------------------------------------%>
    <ui:InputField ID="fldRepeatEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata(".RepeatEmail_Label").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("repeatEmail", null, new
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
    <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("password",null, new 
		    {
                @maxlength = 20,
                @id = "txtPassword",
                @type = "password",
                @autocomplete = "off",
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
    </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Repeat Password
     -------------------------------------------%>
    <ui:InputField ID="fldRepeatPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("repeatPassword", null, new 
		    {
                @maxlength = 20,
                @id = "txtRepeatPassword",
                @type = "password",
                @autocomplete = "off",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".RepeatPassword_Empty"))
                    .EqualTo( "#txtPassword", this.GetMetadata(".RepeatPassword_NotMatch"))
		    }
			    ) %>
	    </ControlPart>
    </ui:InputField>

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

    <div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Continue_Button"), new { @type = "submit", @id = "btnRegisterContinue" })%>
    </div>
<% } %>
</div>

<script type="text/javascript">

    $(function () {
        $('#formQuickRegisterStep1').initializeForm();

        $('#formQuickRegisterStep1 #btnRegisterContinue').click(function (e) {
            e.preventDefault();

            if (!$('#formQuickRegisterStep1').valid())
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
            //$('#formQuickRegisterStep1').ajaxForm(options);
            $('#formQuickRegisterStep1').submit();
        });
    });
</script>
