<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
    internal sealed class SliderItem
    {
        internal string BackgroundUrl { get; set; }
        internal string Url { get; set; }
        internal string Html { get; set; }
    }

    private List<SliderItem> GetSliderItems()
    {
        List<SliderItem> sliders = new List<SliderItem>();
        string [] paths = Metadata.GetChildrenPaths("/Affiliates/Slider");
        foreach (string path in paths)
        {
            string metadataPath = string.Format(CultureInfo.InvariantCulture, "{0}.BackgroundImage", path);
            string img = ContentHelper.ParseFirstImageSrc(Metadata.Get(metadataPath));
            if (!string.IsNullOrWhiteSpace(img))
            {
                metadataPath = string.Format(CultureInfo.InvariantCulture, "{0}.Html", path);
                string html = Metadata.Get(metadataPath);
                
                SliderItem slider = new SliderItem()
                {
                    BackgroundUrl = img,
                    Html = html,
                };
                sliders.Add(slider);
            }
        }

        return sliders;
    }
</script>

<div class="AffSliderContainer">

<ul class="AffSlider">
<% 
    List<SliderItem> sliders = GetSliderItems();
    foreach (SliderItem slider in sliders)
    { %>
    <li class="AffSliderItem" style="background-image:url(<%= slider.BackgroundUrl.SafeHtmlEncode() %>)">
        <div class="AffSliderItem_Intro"><%= slider.Html.HtmlEncodeSpecialCharactors() %></div>
    </li>
<%  } %>
</ul>

<ul class="AffSliderControl">
	<li class="Prev">
		<a href="#" class="previouslink">&#9668;</a>
	</li>
	<li class="Next">
		<a href="#" class="nextlink">&#9658;</a>
	</li>
</ul>

</div>


<script type="text/javascript">
    $(function () {
        $('ul.AffSlider').css('width', 20000);

        var adjustSize = function () {
            $('li.AffSliderItem').css('width', $('div.AffSliderContainer').width().toString(10) + 'px');
        };
        adjustSize();
        $(window).bind('resize', adjustSize);



        $('div.AffSliderContainer ul.AffSliderControl a.previouslink').click(function (e) {
            e.preventDefault();
            if ($('div.AffSliderContainer ul.AffSlider li:animated').length > 0)
                return;

            var $first = $('ul.AffSlider > li:first');
            $first.clone(true).appendTo($('div.AffSliderContainer ul.AffSlider'));
            $first.animate({ 'marginLeft': -1 * $('div.AffSliderContainer').width() }
            , {
                duration: 200,
                easing: 'linear',
                complete: function () { $(this).remove(); $('div.AffSliderContainer ul.AffSlider li:animated').stop(); }
            });
        });

        $('div.AffSliderContainer ul.AffSliderControl a.nextlink').click(function (e) {
            e.preventDefault();
            if ($('div.AffSliderContainer ul.AffSlider li:animated').length > 0)
                return;

            var $last = $('div.AffSliderContainer ul.AffSlider > li:last');
            var $first = $last.clone(true).prependTo($('div.AffSliderContainer ul.AffSlider'));
            $first.css('marginLeft', -1 * $('div.AffSliderContainer').width());
            $first.animate({ 'marginLeft': 0 }
            , {
                duration: 200,
                easing: 'linear',
                complete: function () { $('div.AffSliderContainer ul.AffSlider > li:last').remove(); $('div.AffSliderContainer ul.AffSlider li:animated').stop(); }
            });
        });




    });
</script>
