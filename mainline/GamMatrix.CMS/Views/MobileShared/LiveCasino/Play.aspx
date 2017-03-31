<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<CasinoEngine.LiveCasinoTable>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box GameBox CenterBox">
		<div style="background-image:url('<%= Model.BackgroundImageUrl.SafeHtmlEncode() %>');" class="GameImage Container"></div>
		<div class="BoxContent GameDetails">
			<h2 class="GameTitle"><strong><%= Model.ShortName.SafeHtmlEncode() %></strong></h2>
			<p class="GameDescription"><%= Model.Description.SafeHtmlEncode() %></p>
			<ul class="Cols-2 Container">
				<% if (Model.IsOpened)
					{
						if (Profile.IsAuthenticated)
						{			 
				%>	
				<a href="<%= Url.RouteUrl("LiveCasinoLobby", new { @action = "DirectPlay", tableID = Model.ID }).SafeHtmlEncode() %>" class="A GameButton PlayForReal"><span class="PromoTitle"><%= this.GetMetadata(".Button_Play_For_Real").SafeHtmlEncode()%></span></a>
				<%
						}
						else
						{
				%>	
				<a href="#" id="playForReal" class="A GameButton PlayForReal"><span class="PromoTitle"><%= this.GetMetadata(".Button_Play_For_Real").SafeHtmlEncode()%></span></a>
				<%
						}
					}
					else
					{
				%>	
				<span class="GameTableClosed"><%= string.Format(this.GetMetadata(".GameTable_Closed").SafeHtmlEncode(), Model.OpeningHours) %></span>
				<% } %>
			</ul>
		</div>
	</div>

	<div class="Box" id="loginBox">
	<% if (!Profile.IsAuthenticated)
	{ %>
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/LoginForm", new LoginFormViewModel { Hidden = true, RedirectUrl = Url.RouteUrl("LiveCasinoLobby", new { @action = "DirectPlay", tableID = this.Model.ID }) }); %>
		</div>
	<% } %>
	</div>
	
	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		function Play() {
			var realPlayButton = $('#playForReal'),
				loginForm = $('#loginContainer');

			if (realPlayButton.attr('href') == "#") {
				realPlayButton.click(function () {
					var scroll = loginForm.is(':hidden');
					loginForm.slideToggle('fast');

					if (scroll) {
						loginForm[0].scrollIntoView();
						window.loginForm.focus();
					}
				});
			}

			loginForm.removeClass('Hidden').hide();
		}

		$(function () {
			CMS.mobile360.Generic.init();
			new Play();
		});
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>

