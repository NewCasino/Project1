<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="Container QuickRegisterFormBox">
    <form class="Form QuickRegisterForm" method="POST" action="<%= this.Url.RouteUrl("QuickRegister", new { @action = "Index" }).SafeHtmlEncode() %>">
        <fieldset>
            <h3 class="Legend"> <%= this.GetMetadata(".Quick_Register")%> </h3>
            <div class="Container FormItem">
                <%= this.GetMetadata(".Start_Betting")%>
    <ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <ControlPart>
    <%: Html.TextBox("username", null, new 
    {
                @maxlength = Settings.Registration.UsernameMaxLength,
                @id = "txtUsername",
                @placeholder = this.GetMetadata(".Username_Label").SafeHtmlEncode(),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Empty"))
                    .MinLength(4, this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Length"))
                    .Custom("validateUsername")
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueUsername", @message = this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Exist") }))            
    }
    ) %>
    </ControlPart>
    </ui:InputField>
    <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <ControlPart>
    <%: Html.TextBox("password",null, new 
    {
                @maxlength = 20,
                @id = "txtPassword",
                @type = "password",
                @placeholder = this.GetMetadata(".Password_Label").SafeHtmlEncode(),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Empty"))
                    .MinLength(8, this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Incorrect"))
                    .Custom("validatePassword")
    }
    ) %>
    </ControlPart>
    </ui:InputField>
<%: Html.Button(this.GetMetadata(".Register"), new { @type= "submit", @id = "btnRegisterUser"})%>
            </div>
        </fieldset>
    </form>
</div>