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
        base.OnPreRender(e);
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

<div class="QuickRegister">
    <div class="StartBetting"><%= this.GetMetadata(".Start_Betting")%></div>
    <%------------------------------------------
    Email
    -------------------------------------------%>
    <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <ControlPart>
    <%: Html.TextBox("email", null, new
            {
                @maxlength = "50",
                @id = "txtEmail",
                @placeholder = this.GetMetadata(".Email_Address").SafeHtmlEncode(),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Empty"))
                    .Email(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Incorrect"))
                    .Custom("validateEmailDomain")                
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Exist") }))
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
            return '<%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_UnallowedDomain").SafeJavascriptStringEncode() %>';

        return true;
    }
    </script>
    </ui:MinifiedJavascriptControl>
    
    <%------------------------------------------
    Password
    -------------------------------------------%>
    <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <ControlPart>
    <%: Html.TextBox("password",null, new 
    {
                @maxlength = 20,
                @id = "txtPassword",
                @type = "password",
                @placeholder = this.GetMetadata(".PasswordPlaceholder").SafeHtmlEncode(),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Empty"))
                    .MinLength(8, this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Incorrect"))
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
                    return '<%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_SameWithUsername").SafeJavascriptStringEncode() %>';
            }
            //var ret = /(?=.*\d.+)(?=.*[a-z]+)(?=.*[A-Z]+)(?=.*[-_=+\\|`~!@#$%^&*()\[\]{};:'",./<>?]+).{8,}/.exec(value);
            var ret = <%=this.GetMetadata("Metadata/Settings.Password_ValidationRegex") %>.exec(value);
            if (ret == null || ret.length == 0)
                return '<%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_UnSafe").SafeJavascriptStringEncode() %>';
            return true;
        }

        function avoidSameUsernamePassword() {
            return <%= Settings.Registration.AvoidSameUsernamePassword.ToString().ToLowerInvariant() %>;
        }
    </script>
    </ui:MinifiedJavascriptControl>

    <div class="QuickRegisterCTA">
        <a class="button" href="/register" id="LandingRegisterContinue" onclick="this.blur();" title="<%=this.GetMetadata(".CTATitle") %>">
            <span class="ButtonText"><%=this.GetMetadata(".CTALabel") %></span>
        </a>
    </div>
    <div class="LoginLink"><%=this.GetMetadata(".LoginText") %> <a href="#" id="btn_Aff_Login"><%=this.GetMetadata(".Login") %></a> </div>
</div>

<script type="text/javascript">

    $(function () {
        
    });
</script>
