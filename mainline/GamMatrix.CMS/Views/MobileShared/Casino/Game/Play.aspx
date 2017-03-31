<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<CasinoEngine.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box GameBox CenterBox">
		<div style="background-image:url('<%= this.Model.BackgroundImageUrl.SafeHtmlEncode() %>');" class="GameImage Container"></div>
		<div class="BoxContent GameDetails">
			<h2 class="GameTitle"><strong><%= this.Model.ShortName.SafeHtmlEncode() %></strong></h2>
			<p class="GameDescription"><%= this.Model.Description.SafeHtmlEncode() %></p>
			<ul class="Cols-2 Container">
				<%
					if (this.Model.IsFunModeEnabled)
					{			
				%>
				<li class="Col">
					<a href="<%= Url.RouteUrl("CasinoGame", new { @action = "DirectPlay", @gameID = this.Model.ID }).SafeHtmlEncode()%>" class="A GameButton LowImportance PlayForFun"><span class="PromoTitle"><%= this.GetMetadata(".Button_Play_For_Fun").SafeHtmlEncode()%></span></a>
				</li>
				<%
					}
					if(this.Model.IsRealMoneyModeEnabled)
					{
						if(Profile.IsAuthenticated)
						{			 
				%>	
				<li class="Col">
					<a href="<%= Url.RouteUrl("CasinoGame", new { @action = "DirectPlay", @gameID = this.Model.ID, @realMoney = "true" }).SafeHtmlEncode() %>" class="A GameButton PlayForReal"><span class="PromoTitle"><%= this.GetMetadata(".Button_Play_For_Real").SafeHtmlEncode()%></span></a>
				</li>
				<%
						}
						else
						{
				%>	
				<li class="Col">
					<a href="#" id="playForReal" class="A GameButton PlayForReal"><span class="PromoTitle"><%= this.GetMetadata(".Button_Play_For_Real").SafeHtmlEncode()%></span></a>
				</li>
				<%
						}
					}
				%>	
			</ul>
		</div>
	</div>

	<div class="Box" id="loginBox">
	<% if (!Profile.IsAuthenticated)
	{ %>
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/LoginForm", new LoginFormViewModel { Hidden = true, RedirectUrl = Url.RouteUrl("CasinoGame", new { @action = "DirectPlay", @gameID = this.Model.ID, @realMoney = "true" }) }); %>
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

