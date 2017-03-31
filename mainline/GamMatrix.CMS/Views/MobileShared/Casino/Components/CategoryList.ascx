<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrix.CMS.Models.MobileShared.Casino.Components.GameCategoryData>>" %>

<%
	foreach (var category in this.Model)
	{
        string friendId = this.GetMetadata("/Metadata/_CasinoEngine/Category/" + category.Id  + ".FriendlyID").DefaultIfNullOrEmpty(category.Id.SafeHtmlEncode());
%>
	<div class="Box GameCategory OpenCategory Category-<%=  friendId %>">
		<h2 class="GameCatTitle">
			<a class="GameCatLink" href="#" title="Toggle this game category">
				<span class="ToggleIcon"><span class="ToggleText"><%= this.GetMetadata(".Toggle").SafeHtmlEncode()%></span></span>
				<span class="CatIcon"><span class="CatIconText"><%= this.GetMetadata(".Icon_Category").SafeHtmlEncode()%></span></span>
				<span class="GameCatText"><%= category.Name.DefaultIfNullOrEmpty(this.GetMetadata(".Category_NoName")).SafeHtmlEncode()%></span>
			</a>
		</h2>
		<%	Html.RenderPartial("/Casino/Components/GameTileList", category.Games);%>
	</div>
<%
	}
%>

<script type="text/javascript">
	function CategoryList() {
		$.each($('.GameCategory'), function (index, element) {
			element = $(element);
			element.find('.GameCatLink').unbind('click').click(onCategoryClick);
			if (index)
				element
					.removeClass('OpenCategory')
					.find('.GameList')
						.hide();
			else
				element.addClass('OpenCategory');
		});

		function onCategoryClick() {
			$(this).closest('.GameCategory')
				.toggleClass('OpenCategory')
				.find('.GameList')
					.slideToggle('fast');
		}
	}

	$(function () {
		new CategoryList();
	});
</script>