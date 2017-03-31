<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx<Dictionary<string, string>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.Web.UI" %>
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
<div class="UserBox NoHeadBox">
    <div class="BoxContent">
    <form action="<%= this.Url.RouteUrl("ForgotPassword", new { @action = "SetPassword", @key = Key}).SafeHtmlEncode()%>"
    method="post" enctype="application/x-www-form-urlencoded" id="formFindPassword" target="_self">
        
    <fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
		</legend>
    </fieldset>

    <ul class="FormList">
    <%------------------------------------------
                Password
             -------------------------------------------%>
			<li class="FormItem">
				<label class="FormLabel" for="registerPassword"><%= this.GetMetadata(".NewPassword_Label").SafeHtmlEncode()%></label>
                <%: Html.Password("newPassword", "", new Dictionary<string, object>()  
                { 
                    { "class", "FormInput" },
                    { "id", "registerPassword" },
                    { "autocomplete", "off" },
                    { "maxlength", Settings.Registration.PasswordMaxLength },
                    { "placeholder", this.GetMetadata(".NewPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".NewPassword_Empty")).MinLength(Settings.Registration.PasswordMinLength, this.GetMetadata(".NewPassword_Incorrect")).Custom("validatePassword") }
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
            <ui:MinifiedJavascriptControl runat="server" ID="scriptPassword" Enabled="true">
            <script type="text/javascript">
                function validatePassword() {
                    var value = this;
					<% if (Settings.Registration.AvoidSameUsernamePassword) 
				   { %>
                		var user = '<%= this.Username.SafeJavascriptStringEncode() %>';
                		if (value.toLowerCase() == user.toLowerCase())
                			return '<%= this.GetMetadata(".Password_SameWithUsername").SafeJavascriptStringEncode() %>';
        			<% }
			
					if (!string.IsNullOrWhiteSpace(Settings.Password_ValidationRegex)) 
					{ %>
                		var test = new RegExp(<%= Settings.Password_ValidationRegex %>).exec(value);
                		if (test == null || test.length == 0)
                			return '<%= this.GetMetadata(".Password_UnSafe").SafeHtmlEncode() %>';
					<% } %>
                    return true;
                }
            </script>
            </ui:MinifiedJavascriptControl>
            <%------------------------------------------
                Confirm Password
             -------------------------------------------%>
			<li class="FormItem">
				<label class="FormLabel" for="registerPassword2"><%= this.GetMetadata(".RepeatPassword_Label").SafeHtmlEncode()%></label>
                <%: Html.Password("password2", "", new Dictionary<string, object>()  
                { 
                    { "class", "FormInput" },
                    { "id", "registerPassword2" },
                    { "autocomplete", "off" },
                    { "maxlength", Settings.Registration.PasswordMaxLength },
                    { "placeholder", this.GetMetadata(".RepeatPassword_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".RepeatPassword_Empty")).EqualTo("#registerPassword", this.GetMetadata(".RepeatPassword_NotMatch")) }
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
    </ul>
    <div class="AccountButtonContainer">
		<button class="Button AccountButton" type="submit">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_SetPassword").SafeHtmlEncode()%></strong>
		</button>
	</div>
</form>
    </div>
</div>
<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>

</asp:Content>

