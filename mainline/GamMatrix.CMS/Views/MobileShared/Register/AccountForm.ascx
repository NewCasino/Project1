<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<form action="<%= this.Url.RouteUrl("Register", new { @action = "Register" }).SafeHtmlEncode()%>"
	method="post" enctype="application/x-www-form-urlencoded" id="formRegisterStep2" target="_self">
    
	<fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
		</legend>
		<%: Html.Hidden("title", this.ViewData["title"]) %>
		<%: Html.Hidden("firstname", this.ViewData["firstname"])%>
		<%: Html.Hidden("surname", this.ViewData["surname"])%>
		<%: Html.Hidden("email", this.ViewData["email"])%>
		<%: Html.Hidden("country", this.ViewData["country"])%>
		<%: Html.Hidden("mobilePrefix", this.ViewData["mobilePrefix"])%>
		<%: Html.Hidden("mobile", this.ViewData["mobile"])%>
		<%: Html.Hidden("birth", this.ViewData["birth"])%>
		<%: Html.Hidden("address1", this.ViewData["address1"])%>
		<%: Html.Hidden("address2", this.ViewData["address2"])%>
		<%: Html.Hidden("city", this.ViewData["city"])%>
		<%: Html.Hidden("postalCode", this.ViewData["postalCode"])%>
		<%: Html.Hidden("allowNewsEmail", false)%>
		<%: Html.Hidden("allowSmsOffer", false)%>

		<% Html.RenderPartial("/Components/ProfileAccountInput", this.ViewData.Merge(new { })); %>

		<div class="AccountButtonContainer">
			<button class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Continue").SafeHtmlEncode() %></strong>
			</button>
		</div>
	</fieldset>
</form>