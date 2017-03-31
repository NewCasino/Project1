<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<ol class="MenuList L"> 
	<%-- to be enabled if FPP feature present
	<li class="MenuItem X">
		<a class="MenuLink A Container" href="<%= Url.RouteUrl("CasinoFPP", new { @action = "LearnMore" }).SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Page I">Page</span> <span class="PageName N"><%= this.GetMetadata(".FPPInfo").SafeHtmlEncode()%></span> </a>
	</li>
	<li class="MenuItem X">
		<a class="MenuLink A Container" href="<%= Url.RouteUrl("CasinoFPP", new { @action = "Rates" }).SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Page I">Page</span> <span class="PageName N"><%= this.GetMetadata(".FPPRates").SafeHtmlEncode()%></span> </a>
	</li> --%>
	<li class="MenuItem X">
		<a class="MenuLink A Container" href="<%= Url.RouteUrl("CasinoInfo", new { @action = "BonusContribution" }).SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Page I">Page</span> <span class="PageName N"><%= this.GetMetadata(".BonusContribution").SafeHtmlEncode()%></span> </a>
	</li>
</ol>