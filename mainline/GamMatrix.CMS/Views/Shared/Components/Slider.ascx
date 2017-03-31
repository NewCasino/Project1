<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
    private string ClientID { get; set; }
    private string [] SliderPaths { get; set; }


    protected override void OnInit(EventArgs e)
    {
        this.ClientID = "_" + Guid.NewGuid().ToString("N").Truncate(5);
        this.SliderPaths = Metadata.GetChildrenPaths((this.ViewData["SliderPath"] as string))
                .Where(p => !IsExcludedByCountry(p) &&
                    (!Profile.IsAuthenticated || (Profile.IsAuthenticated && Metadata.Get(string.Format("{0}.HiddenForRegistered", p)) != "true")))
                .ToArray();
        
        base.OnInit(e);
    }

    private bool IsExcludedByCountry(string path)
    {
        string excludedCountrys = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.ExcludedCountries", path));
        if (!string.IsNullOrEmpty(excludedCountrys))
        {
            string[] countries = excludedCountrys.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            if (countries.FirstOrDefault(c => c.Trim() == Profile.UserCountryID.ToString()) != null ||
                countries.FirstOrDefault(c => c.Trim() == Profile.IpCountryID.ToString()) != null)
            {
                return true;
            }
        }
        return false;
    }
</script>



<div class="GeneralSlider" id="<%= ClientID %>">
    <div class="PaginationBadgeContainer">
        <ul class="PaginationBadges">
            <% for (int i = 1; i <= SliderPaths.Length; )
               {                  
                   string cssClass = string.Empty;
                   if (i == 1) cssClass = "FirstBadge";
                   else if (i == SliderPaths.Length) cssClass = "LastBadge";
                    %>
            <li class="PaginationBadge">
                <a href="#" data-slide="<%= i %>" title="<%= i %>" class="Badge <%= cssClass %>"><%= i %></a>
            </li>
            <% 
                   i++;
                } %>
        </ul>
    </div>

    <ul class="SliderContainer">
        <% for (int i = 1; i <= SliderPaths.Length; i++)
           {
               string backgroundImage = ContentHelper.ParseFirstImageSrc(
                   Metadata.Get(
                    string.Format(CultureInfo.InvariantCulture, "{0}.BackgroundImage", SliderPaths[i - 1])
                   )
               );
                %>
        <li data-slide="<%= i %>" class="SliderItem" style="background-image: url(<%= backgroundImage.SafeHtmlEncode() %>);">
            <div class="SliderContent">
                <%= Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Html", SliderPaths[i - 1])).HtmlEncodeSpecialCharactors()%>
            </div>
        </li>
         <% } %>
    </ul>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
<script type="text/javascript">
    $(function () {
        var $slider = $('#<%= ClientID %>');
        var _timer = null;
        var _isMouseEnter = false;



        var resizeHandler = function () {
            $('ul.SliderContainer li.SliderItem', $slider).width($slider.width());
            var h = $('ul.SliderContainer', $slider).height().toString(10) + 'px';
            $('a.ActiveBadge', $slider).click();
        };
        resizeHandler();
        $(window).on('load', resizeHandler);
        $(window).on('resize', resizeHandler);

        var timerHandler = function () {
            if (_isMouseEnter) {
                $('ul.SliderContainer:animated', $slider).stop(true, false);
                return;
            }
            var currentIdx = $('a.ActiveBadge', $slider).data('slide');
            var idx = currentIdx + 1;
            var $link = $('a.Badge[data-slide="' + idx.toString(10) + '"]');
            if ($link.length == 0) {
                idx = 1;
                $link = $('a.Badge[data-slide="' + idx.toString(10) + '"]');
                if ($link.length == 0)
                    return;
            }

            $link.click();
        };
        _timer = setTimeout(timerHandler, 6000);

        $('a.Badge', $slider).click(function (e) {
            e.preventDefault();
            e.stopPropagation();
            $('a.ActiveBadge', $slider).removeClass('ActiveBadge');
            $(this).addClass('ActiveBadge');
            var marginLeft = ($(this).data('slide') - 1) * $slider.width();

            $('ul.SliderContainer:animated', $slider).stop(true, false);
            $('ul.SliderContainer li.SliderItem', $slider).width($slider.width());
            $('ul.SliderContainer', $slider).animate({ 'marginLeft': -1 * marginLeft }
            , {
                duration: 200,
                easing: 'linear'
            });

            if (_timer != null) {
                clearTimeout(_timer);
            }
            _timer = setTimeout(timerHandler, 6000);
        });
        $('a.Badge:first', $slider).click();

        $(document).on('INLINE_GAME_CLOSED', function () {
            $('a.Badge:first', $slider).click();
        });

        $slider.mouseenter(function (e) {
            _isMouseEnter = true;
        }).mouseleave(function (e) {
            _isMouseEnter = false;
            timerHandler();
        });


    });
</script>
</ui:MinifiedJavascriptControl>