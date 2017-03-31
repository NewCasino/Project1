<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.Web.UI" %>

<form action="<%= Url.RouteUrl("ContactUs", new { @action = "Send" }).SafeHtmlEncode()%>" method="post" class="GeneralForm ContactForm" id="ContactForm">

    <fieldset>
        <legend class="hidden">
            <%= this.GetMetadata(".Legend").SafeHtmlEncode()%>
</legend>
        <ul class="FormList ContactList">
            <%------------------------------------------
                Name
             -------------------------------------------%>
            <% if (Profile.IsAnonymous)
               { %>
            <li class="FormItem ContactItem NameItem">
                <label class="FormLabel" for="contactName"><%= this.GetMetadata(".Name_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("name", string.Empty, new Dictionary<string, object>()  
                { 
                    { "class", "FormInput" },
                    { "id", "contactName" },
                    { "maxlength", "50" },
                    { "placeholder", this.GetMetadata(".Name_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Name_Empty")) }
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
            <% } %>

            <%------------------------------------------
                E-mail
             -------------------------------------------%>
            <% if (Profile.IsAnonymous)
               { %>
            <li class="FormItem ContactItem EmailItem">
                <label class="FormLabel" for="contactEmail"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("email", string.Empty, new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "contactEmail" },
                    { "maxlength", "50" },
                    { "type", "email" },
                    { "placeholder", this.GetMetadata(".Email_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Email_Empty")).Email(this.GetMetadata(".Email_Invalid")).Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata(".Email_Exist") })) }
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
            <% } %>

            <%------------------------------------------
                Subject
             -------------------------------------------%>
            <li class="FormItem ContactItem SubjectItem">
                <label class="FormLabel" for="contactSubject"><%= this.GetMetadata(".Subject_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("subject", "", new Dictionary<string, object>()  
                { 
                    { "class", "FormInput" },
                    { "id", "contactSubject" },
                    { "maxlength", "50" },
                    { "placeholder", this.GetMetadata(".Subject_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Subject_Empty")) }
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>

            <%------------------------------------------
                Message
             -------------------------------------------%>
            <li class="FormItem OK ContactItem MessageItem">
                <label class="FormLabel" for="contactMessage"><%= this.GetMetadata(".Content_Label").SafeHtmlEncode()%></label>
                <%: Html.TextArea("content", new Dictionary<string, object>
				{
					{"class", "FormInput"},
					{"id", "contactMessage"},
					{"maxlength", "150"},
					{"placeholder", this.GetMetadata(".Content_Choose")},
					{"required", "required"},
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Content_Empty"))}
				})%>
                <span class="FormHelp"></span>
            </li>

            <%------------------------------------------
                Captcha
             -------------------------------------------%>
            <li class="FormItem ContactItem CaptchaItem">
                <% Html.RenderPartial("/Components/Captcha"); %>
            </li>
        </ul>
        <div class="AccountButtonContainer ContactContainer">
            <button class="Button AccountButton ContactButton" type="submit" name="send" id="send">
                <strong class="ButtonText"><%= this.GetMetadata(".Button_Submit")%></strong>
            </button>
        </div>
    </fieldset>
</form>

<script type="text/javascript">
    $(function () {
        new CMS.views.RestrictedInput('#contactName', CMS.views.RestrictedInput.username);
    });
</script>
