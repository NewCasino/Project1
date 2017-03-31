<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.Web.UI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox NoHeadBox">
    <div class="BoxContent">
    <form action="<%= this.Url.RouteUrl("ForgotPassword", new { @action = "SendEmail" }).SafeHtmlEncode()%>"
    method="post" enctype="application/x-www-form-urlencoded" id="formFindPassword" target="_self">

    <fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
		</legend>

        <ul class="FormList">

            <%------------------------------------------
                Email
             -------------------------------------------%>
			<li class="FormItem">
				<label class="FormLabel" for="findPasswordEmail"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("email", "", new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
                    { "id", "findPasswordEmail" },
                    { "maxlength", "50" },
                    { "type", "email" },
                    { "placeholder", this.GetMetadata(".Email_Choose") },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Email_Empty")).Email(this.GetMetadata(".Email_Incorrect"))}                    
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>

            <%------------------------------------------
                Captcha
             -------------------------------------------%>
			<li class="FormItem">
				<% Html.RenderPartial("/Components/Captcha", this.ViewData); %>
			</li>

        </ul>

        <div class="AccountButtonContainer">
			<button class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit").SafeHtmlEncode()%></strong>
			</button>
		</div>

    </fieldset>
</form>
    </div>
</div>

<script type="text/javascript">
	$(CMS.mobile360.Generic.input);
</script>
</asp:Content>

