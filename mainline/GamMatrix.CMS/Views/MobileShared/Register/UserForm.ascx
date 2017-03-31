<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<form action="<%= this.Url.RouteUrl("Register", new { @action = "Step2" }).SafeHtmlEncode() %>" 
	method="post" enctype="application/x-www-form-urlencoded" id="formRegisterStep1" target="_self">
    
	<fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".Legend").SafeHtmlEncode()%>
		</legend>

		<% Html.RenderPartial("/Components/ProfilePersonalInput", this.ViewData.Merge(new { })); %>
		<% Html.RenderPartial("/Components/ProfileAddressInput", this.ViewData.Merge(new { })); %>

		<div class="AccountButtonContainer">
			<button class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Continue").SafeHtmlEncode() %></strong>
			</button>
		</div>
	</fieldset>
</form>