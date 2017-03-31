<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Dictionary<string, string>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<script runat="server">
    private string Key { get; set; }
    private string Username { get; set; }

    protected override void OnInit(EventArgs e)
    {
        if (this.Model != null)
        {
            Key = this.Model.ContainsKey("Key") ? this.Model["Key"] : string.Empty;
            Username = this.Model.ContainsKey("Username") ? this.Model["Username"] : string.Empty; 
        }
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ChangePassword/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ChangePassword/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="forgot-pwd-wrapper" class="content-wrapper main-pane">
     <h1> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>


<ui:Panel runat="server" ID="pnForgotPwd">
<br />
<% using( Html.BeginRouteForm( "ForgotPassword", new { @action = "SetPassword", @key = Key }, FormMethod.Post, new { @id="formResetPassword", @target="_self" } ) )
   { %>

<%------------------------------------------
    New Password
 -------------------------------------------%>
<label for="confirmPassword" class="inputfield_Label"><%= this.GetMetadata(".NewPassword_Label").SafeHtmlEncode()%></label>
<ui:InputField ID="fldNewPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
<ControlPart>
        <%: Html.TextBox("newPassword", "", new
            {
                @maxlength = Settings.Registration.PasswordMaxLength,
                @id = "txtNewPassword",
                @type="password",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".NewPassword_Empty"))
                    .MinLength( Settings.Registration.PasswordMinLength, this.GetMetadata(".NewPassword_Invalid"))
                    .Custom("validatePassword")
            })%>
</ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptPassword" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function validatePassword() {
        var value = this;
        if(avoidSameUsernamePassword())
        {   
            if(value.toLowerCase()=='<%=this.Username.SafeJavascriptStringEncode() %>'.toLowerCase())
                return '<%= this.GetMetadata(".Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        }
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
    Confirm Password
 -------------------------------------------%>
<label for="confirmPassword" class="inputfield_Label"><%= this.GetMetadata(".ConfirmPassword_Label").SafeHtmlEncode()%> </label>
<ui:InputField ID="fldConfirmPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
<ControlPart>
        <%: Html.TextBox("confirmPassword", "", new
            {
                @maxlength = Settings.Registration.PasswordMaxLength,
                @type = "password",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".ConfirmPassword_Empty"))
                    .EqualTo("#txtNewPassword", this.GetMetadata(".ConfirmPassword_Mismatch"))
            })%>
</ControlPart>
</ui:InputField>
    <%: Html.Button(this.GetMetadata(".Button_SetPassword"), new { @id="btnSetPassword", @type="submit" })%>
<% } %>
</ui:Panel>


</div>

<script type="text/javascript">
    $(function () {
        $('#formResetPassword').initializeForm();
    });
</script>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('AuthenticatedProfile ChangePassword');
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

