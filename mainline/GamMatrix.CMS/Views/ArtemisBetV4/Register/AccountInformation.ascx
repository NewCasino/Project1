<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="GmCore"  %>
<%@ Import Namespace="Bingo"  %>
<%@ Import Namespace="OAuth" %>
<script language="C#" type="text/C#" runat="server">
    protected ReferrerData ReferrerData
    {
        get
        {
            if (this.ViewData["ReferrerData"] == null)
                return null;

            return this.ViewData["ReferrerData"] as ReferrerData;
        }
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

    private string selectedQuestionValue { get; set; }
    
    private SelectList GetSecurityQuestionList()
    {
        string [] paths = Metadata.GetChildrenPaths("/Metadata/SecurityQuestion");

        var list = paths.Select(p => new { Key = this.GetMetadata(p, ".Text"), Value = this.GetMetadata(p, ".Text") }).ToList();
        list.Insert(0, new { Key = "", Value = this.GetMetadata(".SecurityQuestion_Select") });

        if (this.Model != null)
        {
            foreach (var path in paths)
            {
                foreach (var lang in SiteManager.Current.GetSupporttedLanguages())
                {
                    if (this.Model.SecurityQuestion.Equals(Metadata.Get(string.Format("{0}.Text", path), lang.LanguageCode)))
                    {
                        selectedQuestionValue = Metadata.Get(string.Format("{0}.Text", path));
                    }
                }
            }
        }
        
        return new SelectList(list, "Key", "Value");
    }

    private SelectList GetLanguageList()
    {
        string selectedValue = this.Model == null ? HttpContext.Current.GetLanguage() : this.Model.Language;
        SelectList list = new SelectList(SiteManager.Current.GetSupporttedLanguages().Select(l => new { Key = l.LanguageCode, Value = l.DisplayName }).ToList()
                    , "Key"
                    , "Value"
                    , selectedValue
                    );
        return list;
    }

    private string GetUsername()
    {
        if (this.ReferrerData!= null && this.ReferrerData.ExternalUserInfo != null)
        {
            if (!string.IsNullOrWhiteSpace(this.ReferrerData.ExternalUserInfo.Username))
                return this.ReferrerData.ExternalUserInfo.Username.Trim();
        }
        return Request["username"].DefaultIfNullOrEmpty(string.Empty);
    }
    private string GetPassword()
    {
        return Request["password"].DefaultIfNullOrEmpty(string.Empty);
    }
    
    private List<GamMatrixAPI.AvatarEntry> GetBingoAvatarList()
    {
        return BingoManager.GetBingoAvatarList(Settings.Bingo_AvatarCategory);
    }

    private bool IsUsernameVisible { get { return this.Model == null; } }
    private bool IsPasswordVisible { get { return this.Model == null; } }
    private bool IsAliasVisible 
    { 
        get 
        {
            bool isVisible = Settings.Registration.IsAliasVisible;

            if (isVisible && this.Model != null && !string.IsNullOrWhiteSpace(this.Model.Alias))
                isVisible = false;
            return isVisible; 
        } 
    }

    private bool IsAvatarVisible
    {
        get
        {
            if (!GamMatrixClient.GetGamingVendors().Exists(v => v.VendorID == GamMatrixAPI.VendorID.BingoNetwork))
                return false;

            if (this.Model == null)
                return Settings.Registration.IsAvatarVisible;

            return true;
        }
    }
    private bool IsCurrencyVisible { get { return this.Model == null || (this.Model != null && string.IsNullOrWhiteSpace(this.Model.Currency)); } }

    private bool IsSecurityQuestionVisible { get { return this.Model != null || Settings.Registration.IsSecurityQuestionVisible; } }
    private bool IsSecurityQuestionRequired { get { return Settings.Registration.IsSecurityQuestionRequired; } }

    private bool IsSecurityAnswerVisible { get { return this.Model != null || Settings.Registration.IsSecurityAnswerVisible; } }
    private bool IsSecurityAnswerRequired { get { return Settings.Registration.IsSecurityAnswerRequired; } }

    protected override void OnPreRender(EventArgs e)
    {
        fldUsername.Visible = this.IsUsernameVisible;
        scriptUsername.Visible = this.IsUsernameVisible;

        fldPassword.Visible = this.IsPasswordVisible;
        fldRepeatPassword.Visible = this.IsPasswordVisible;

        fldAlias.Visible = this.IsAliasVisible;
        scriptAlias.Visible = this.IsAliasVisible;

        fldCurrency.Visible = this.IsCurrencyVisible;
        scriptCurrency.Visible = this.IsCurrencyVisible;

        fldSecurityQuestion.Visible = this.IsSecurityQuestionVisible;
        scriptSecurityQuestion.Visible = this.IsSecurityQuestionVisible;
        fldSecurityQuestion.ShowDefaultIndicator = this.IsSecurityQuestionRequired;

        fldSecurityAnswer.Visible = this.IsSecurityAnswerVisible;
        scriptSecurityAnswer.Visible = this.IsSecurityAnswerVisible;
        fldSecurityAnswer.ShowDefaultIndicator = this.IsSecurityAnswerRequired;

        fldAvatar.Visible = this.IsAvatarVisible;
        scriptAvatar.Visible = this.IsAvatarVisible;

        scriptCurrency.Visible = this.Model == null;


        
        
        base.OnPreRender(e);
    }
</script>



<%------------------------------------------
    Username
 -------------------------------------------%>
<ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Username_Label").SafeHtmlEncode() %></LabelPart>
<ControlPart>
<%: Html.TextBox("username", GetUsername(), new 
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
    Alias
 -------------------------------------------%>
<ui:InputField ID="fldAlias" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Alias_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
    <%: Html.TextBox("alias", string.Empty, new 
{
            @maxlength = 11,
            @id = "txtAlias",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".Alias_Empty"))
                .Custom("validateAlias")
                .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueAlias", @message = this.GetMetadata(".Alias_Exist") })) 
}
) %>
</ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptAlias" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function validateAlias() {
    var value = this;
    var ret = /^(\w{5,11})$/.exec(value);
    if (ret == null || ret.length == 0)
        return '<%= this.GetMetadata(".Alias_Length").SafeJavascriptStringEncode() %>';
    return true;
}

$(function () {
    $('#txtAlias').keypress(function (e) {
        if (e.which > 0) {
            var STR = '\x20\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
            var c = String.fromCharCode(e.which);
            if (STR.indexOf(c) >= 0) {
                e.preventDefault();
            }
        }
    });

    $('#txtAlias').change(function (e) {
        var val = $(this).val();
        var REGEX = /[\s|\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
        if (val.length > 0) {
            val = val.replace(REGEX, '');
            $(this).val(val);
        }
    });
});  
</script>
</ui:MinifiedJavascriptControl>




<%------------------------------------------
    Password
 -------------------------------------------%>
<ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
<%: Html.TextBox("password",GetPassword(), new 
{
            @maxlength = Settings.Registration.PasswordMaxLength,
            @id = "txtPassword",
            @type = "password",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".Password_Empty"))
                .MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata(".Password_Incorrect"))
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
            if(value.toLowerCase()==$("#txtUsername").val().toLowerCase() || value.toLowerCase() == $("#txtEmail").val().toLowerCase())
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
<%: Html.TextBox("repeatPassword", GetPassword(), new 
{
            @maxlength = Settings.Registration.PasswordMaxLength,
            @id = "txtRepeatPassword",
            @type = "password",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".RepeatPassword_Empty"))
                .EqualTo( "#txtPassword", this.GetMetadata(".RepeatPassword_NotMatch"))
}
) %>
</ControlPart>
</ui:InputField>


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
<%: Html.TextBox("securityAnswer", (this.Model == null) ? string.Empty : this.Model.SecurityAnswer, new 
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
        if( $('#ddlLanguage > option').length <= 1 )
            $('#fldLanguage').hide();
    });
</script>
</ui:MinifiedJavascriptControl>


<%------------------------------------------
    Avatar
 -------------------------------------------%>
 <% if (this.IsAvatarVisible)
    { %>
<div style="display:none" id="dlg-avatar-selector">
    <% 
        this.ViewData["AvatarUrl"] = "";
        foreach (GamMatrixAPI.AvatarEntry entry in GetBingoAvatarList())
        {
            if (this.Model != null &&
                string.Equals(this.Model.Avatar, entry.idField.ToString(), StringComparison.OrdinalIgnoreCase))
            {
                this.ViewData["AvatarUrl"] = entry.urlField;
            }
           %>
       <div class="avatar-entry-wrap" align="center">
            <img alt="" src="<%= entry.urlField.SafeHtmlEncode() %>" border="0" id="<%= entry.idField %>" />            
       </div>
    <% } %>
</div>
<% } %>
<ui:InputField ID="fldAvatar" runat="server" ShowDefaultIndicator="false" >
<LabelPart><%= this.GetMetadata(".Avatar_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
    <img id="imgAvatar" src="<%= (this.ViewData["AvatarUrl"] as string).SafeHtmlEncode() %>" />
    <%: Html.Hidden("avatar", (this.Model == null) ? string.Empty : this.Model.Avatar) %>
    <a id="lnkChangeAvatar" href="javascript:void(0)" target="_self"><%= this.GetMetadata(".Avatar_Change").SafeHtmlEncode()%></a>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptAvatar" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$(function () {
    $('#dlg-avatar-selector > div.avatar-entry-wrap').mouseover(function () { $(this).addClass("hover"); }).mouseout(function () { $(this).removeClass("hover"); }).click(function () {
        $('#imgAvatar').attr('src', $('img', $(this)).attr('src'));
        $('input[name="avatar"]', $('#fldAvatar')).val($('img', $(this)).attr('id'));
        $.modal.close();
    });
    var images = $('#dlg-avatar-selector img');
    if (images.length > 0 && $('input[name="avatar"]').val() == '' ) {
        $('#imgAvatar').attr('src', $(images[0]).attr('src'));
        $('input[name="avatar"]').val($(images[0]).attr('id'));
    }

    $('#lnkChangeAvatar').click(function () {
        $('#dlg-avatar-selector').modalex(500, 210, true);
    });
});
</script>
</ui:MinifiedJavascriptControl>
<script type="text/javascript">
    $(function() {
        var selectedQuestionValue = '<%=selectedQuestionValue.SafeJavascriptStringEncode() %>';
    if (selectedQuestionValue != '') {
        $('#ddlSecurityQuestion').val(selectedQuestionValue);
    }
});
</script>