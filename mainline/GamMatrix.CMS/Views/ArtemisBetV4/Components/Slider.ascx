<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
    private string ClientID { get; set; }
    private string [] SliderPaths { get; set; }

    protected override void OnInit(EventArgs e) {
        this.ClientID = "_" + Guid.NewGuid().ToString("N").Truncate(5);
        this.SliderPaths = Metadata.GetChildrenPaths((this.ViewData["SliderPath"] as string));
                /*.Where(p => !IsExcludedByCountry(p) &&
                    (!Profile.IsAuthenticated || (Profile.IsAuthenticated && Metadata.Get(string.Format("{0}.HiddenForRegistered", p)) != "true")))
                .ToArray();*/

        base.OnInit(e);
    }

    private bool IsExcludedByCountry(string path) {
        string excludedCountrys = Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.ExcludedCountries", path));
        if (!string.IsNullOrEmpty(excludedCountrys)) {
            string[] countries = excludedCountrys.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            if (countries.FirstOrDefault(c => c.Trim() == Profile.UserCountryID.ToString()) != null ||
                countries.FirstOrDefault(c => c.Trim() == Profile.IpCountryID.ToString()) != null) {
                return true;
            }
        }
        return false;
    }
</script>

<div class="GeneralSlider" id="<%= ClientID %>">
    <div class="jsSliderContainer">
        <% for (int i = 1; i <= SliderPaths.Length; i++) {
            string backgroundImage = ContentHelper.ParseFirstImageSrc( Metadata.Get( string.Format(CultureInfo.InvariantCulture, "{0}.BackgroundImage", SliderPaths[i - 1]) ) );
        %>
        <div data-slide="<%= i %>" class="SliderItem" style="background-image: url(<%= backgroundImage.SafeHtmlEncode() %>);">
            <div class="SliderContent">
                <%= Metadata.Get(string.Format(CultureInfo.InvariantCulture, "{0}.Html", SliderPaths[i - 1])).HtmlEncodeSpecialCharactors()%>
            </div>
        </div>
        <% } %>
    </div>
</div>

<script src="//cdn.everymatrix.com/ArtemisBetV4/js/jquery.slides.min.js"></script>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
  <script type="text/javascript">
    $(function() {
      $('.jsSliderContainer').slidesjs({
        play: {
          active: false,
          effect: "slide",
          interval: 5000,
          auto: true,
          swap: false,
          pauseOnHover: false,
          restartDelay: 2500,
        },
        navigation: false,
      });
    });
  </script>

</ui:MinifiedJavascriptControl>
