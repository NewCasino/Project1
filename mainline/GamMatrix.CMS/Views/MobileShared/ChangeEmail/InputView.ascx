<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.Web.UI" %>

<form class="InputForm ChangeEmailForm" id="changeEmailForm" action="<%= Url.RouteUrl("ChangeEmail", new { @action = "ChangeEmail" }).SafeHtmlEncode() %>" method="post">
    
	<fieldset>
		<legend class="Hidden">
			<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
		</legend>
		<ul class="FormList">
			<%------------------------------------------
				Email
				-------------------------------------------%>
			<li class="FormItem" id="fldEmail" runat="server">
				<label class="FormLabel" for="registerEmail"><%= this.GetMetadata(".NewEmail_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("email", string.Empty, new Dictionary<string, object>()
				{
					{ "class", "FormInput" },
					{ "maxlength", "50" },
					{ "type", "email" },
					{ "placeholder", this.GetMetadata(".NewEmail_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create()
														.Required(this.GetMetadata(".NewEmail_Empty"))
														.Email(this.GetMetadata(".NewEmail_Incorrect"))
														.Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".NewEmail_Exist") })) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
		<%------------------------------------------
            Password
         -------------------------------------------%>
        <li class="FormItem">
			<label class="FormLabel" for="changePasswordOldPassword"><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></label>  
			<%: Html.TextBox("password", "", new Dictionary<string, object>()
            {
                { "class", "FormInput" },
                { "maxlength", "20" },
                { "type", "password" },
                { "placeholder", this.GetMetadata(".Password_Label") },
                { "required", "required" },
                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Password_Empty"))}                    
            }) %>
			<span class="FormStatus">Status</span>
			<span class="FormHelp"></span>      
        </li>
			<li class="FormItem">
				<% Html.RenderPartial("/Components/Captcha", this.ViewData); %>
			</li>
		</ul>
		<div class="AccountButtonContainer">
			<button class="Button AccountButton" type="submit" id="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Button_ChangeEmail").SafeHtmlEncode()%></strong>
			</button>
		</div>
	</fieldset>
</form>