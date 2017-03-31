<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.UserFlowNavigationViewModel>" %>

<div class="AccountButtonContainer">
	<ul class="DepLinks Container">
		<% 
			if (this.Model.BackButtonEnabled)
			{
		%>
		<li class="DepItem BackItem">
			<a class="Button RegLink DepLink BackLink" href="#">
                <span class="ButtonIcon DepLinkIcon icon-arrow-left"></span>
				<span class="ButtonText"><%= this.GetMetadata(".Back").SafeHtmlEncode() %></span>
			</a>
		</li>
		<% 
			}
			if (this.Model.NextButtonEnabled)
			{
				if (this.Model.IsFormSection)
				{
		%>
		<li class="DepItem NextItem">
			<button type="submit" class="Button RegLink DepLink NextStepLink">
                <span class="ButtonIcon DepLinkIcon icon-arrow-right"></span>
				<span class="ButtonText"><%= this.Model.NextName.DefaultIfNullOrEmpty(this.GetMetadata(".Next")).SafeHtmlEncode()%></span>
			</button>
		</li>
		<% 
				}
				else
				{
		%>
		<li class="DepItem NextItem">
			<a class="Button RegLink DepLink NextStepLink" href="<%= this.Model.NextUrl.SafeHtmlEncode()%>" id="sectionNextLink">
                <span class="ButtonIcon DepLinkIcon icon-arrow-right"></span>
				<span class="ButtonText"><%= this.Model.NextName.DefaultIfNullOrEmpty(this.GetMetadata(".Next")).SafeHtmlEncode()%></span>
			</a>
		</li>
		<% 
				}
			}
		%>
	</ul>
</div>

<script type="text/javascript">
	$(function () {
		new CMS.views.BackBtn('.AccountButtonContainer .BackLink');
		$('form').submit(function () {
            setTimeout(function () {
                $("button[type='submit']").attr('disabled', 'disabled');
                setTimeout(function () {
                    $("button[type='submit']").removeAttr('disabled');
                }, 5000);
            }, 100);

        });

	});
	
</script>