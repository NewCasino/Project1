<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Promotions.Home.PresentationListViewModel>" %>

<script runat="server">
	private int AutoSlideSeconds = 0;

	private string GetElementPath(int index)
	{
		return Model.ContentPaths.ElementAt(index);
	}

	private string GetBannerUrl(string path)
	{
		return this.GetMetadata(string.Format("{0}/.BannerUrl", path)).SafeHtmlEncode();
	}

	private string GetPromotionLink(string path)
	{
		string promoLink = this.GetMetadata(string.Format("{0}/.PromoLink", path));

		if (string.IsNullOrWhiteSpace(promoLink))
			promoLink = Model.GetTermsUrl(path);

		return promoLink.SafeHtmlEncode();
	}

	protected override void OnInit(EventArgs e)
	{
		int.TryParse(this.GetMetadata(".AutoSlide_Seconds"), out AutoSlideSeconds);
		
		base.OnInit(e);
	}
</script>

<div class="Box NewSlider noSwipe" id="newSlider">
	<ul class="NewSliderControls" id="sliderMenu">
		<li class="NSPrev">
			<a class="NSLink PrevLink" href="#">&#8250;</a>
		</li>
		<li class="NSNext">
			<a class="NSLink NextLink" href="#">&#8250;</a>
		</li>
		<% 
			for (int i = 0; i < this.Model.ContentPaths.Count(); i++)
			{
		%>
		<li class="NSNumber" id="m-<%= i %>">
			<a class="NSLink NumberLink" href="#" data-slideidx="<%= i %>"><%= i + 1 %></a>
		</li>
		<% } %>
	</ul>
	<div id="canvas" style="position:relative; overflow:hidden; display:block;">
		<ul class="SlideList Container" id="slidingList" style=" width:1832px;">
			<% 
				for (int i = 0; i < this.Model.ContentPaths.Count(); i++)
				{
			%>
			<li class="SlideItem ActiveItem" id="s-<%= i %>">
				<a class="SlideLink" href="<%= GetPromotionLink(GetElementPath(i))%>">
					<img class="SlideImage" src="<%= GetBannerUrl(GetElementPath(i))%>" width="400" height="200" alt="Slide <%= i %>" />
				</a>
			</li>
			<% } %>
		</ul>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="false">
<script type="text/javascript">
	$(function () {
		var slider = new CMS.mobile360.views.PromoSlider(<%= AutoSlideSeconds > 0 ? string.Format("{{ autoSlideTime: {0} }}", AutoSlideSeconds * 1000) : string.Empty%>);

		$("#newSlider").touchwipe({
			wipeLeft: function () { slider.handleMoveForward(); },
			wipeRight: function () { slider.handleMoveBack(); },
			wipeUp: function () { },
			wipeDown: function () { },
			min_move_x: 20,
			min_move_y: 20,
			preventDefaultEvents: true
		});
	});
</script>
</ui:MinifiedJavascriptControl>