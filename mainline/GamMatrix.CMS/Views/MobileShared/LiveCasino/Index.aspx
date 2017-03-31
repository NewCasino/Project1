<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrix.CMS.Models.MobileShared.LiveCasino.LiveTableCategory>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server">
	protected override void OnInit(EventArgs e)
	{
		if (!Settings.Vendor_EnableLiveCasino)
			throw new HttpException(404, "Section not enabled");
		
		base.OnInit(e);
	}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box">
		<div class="BoxContent">
		<%
			foreach (var category in Model)
			{
                if (category.Tables.Count == 0)
                    continue;
		%>
			<div class="Box TableCategory OpenCategory Category_<%= category.ID.SafeHtmlEncode() %>">
				<h2 class="TableCatTitle">
					<a class="TableCatLink" href="#">
						<span class="ToggleIcon"><span class="ToggleText"><%= this.GetMetadata(".Toggle").SafeHtmlEncode()%></span></span>
						<span class="CatIcon"><span class="CatIconText"><%= this.GetMetadata(".Icon_Category").SafeHtmlEncode()%></span></span>
						<span class="TableCatText"><%= category.Name.DefaultIfNullOrEmpty(this.GetMetadata(".Category_NoName")).SafeHtmlEncode()%></span>
					</a>
				</h2>
				<%	Html.RenderPartial("LiveTableDisplay", category.Tables);%>
			</div>
		<% } %>
		</div>
	</div>

	<script type="text/javascript">
		function Index() {
			$.each($('.TableCategory'), function (index, element) {
				element = $(element);
				element.find('.TableCatLink').click(onCategoryClick);
				if (index)
					element
						.removeClass('OpenCategory')
						.find('.TableList')
							.hide();
				else
					element.addClass('OpenCategory');
			});

			function onCategoryClick() {
				$(this).closest('.TableCategory')
					.toggleClass('OpenCategory')
					.find('.TableList')
						.slideToggle('fast');
			}
		}

		$(function () {
			CMS.mobile360.Generic.init();
			new Index();
		});
	</script>
</asp:Content>

