<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="MainMenu">
	<h2 class="MenuTitle Container">
		<span class="MenuTitleWrap">
			<a class="Close" href="#">
				<span class="CloseWrap">
					<span class="CloseIcon">&times;</span>
				</span>
			</a>
			<strong class="MTText"><%= this.GetMetadata(".Title")%></strong>
		</span>
	</h2>
	<%: Html.Partial("Navigation")%>
</div>