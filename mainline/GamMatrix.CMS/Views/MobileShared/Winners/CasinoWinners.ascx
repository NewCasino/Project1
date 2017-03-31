<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CasinoEngine" %>

<script type="text/C#" runat="server">
	private string GetGameUrl(Game game, bool realMoney)
	{
		if (realMoney)
			return string.Format("{0}?_sid={1}", game.Url, HttpUtility.UrlEncode(Profile.SessionID));
		return game.Url;
	}

	private List<object> GetCasinoWinners(int maximum = 10)
    {
        List<CountryInfo> countries = CountryManager.GetAllCountries();
        List<CasinoEngine.WinnerInfo> winners = CasinoEngine.CasinoEngineClient.GetRecentWinners(SiteManager.Current, true);

        Func<string, string> getCountryFlagName = delegate(string countryCode)
		{
            CountryInfo country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, countryCode, StringComparison.InvariantCultureIgnoreCase));
            return country == null ? string.Empty : country.GetCountryFlagName();
        };
		
		var result = winners.Select(w => new 
        {
			@CountryCode = w.CountryCode,
			@DisplayName = w.DisplayName,
			@Currency = w.Currency,
			@Amount = w.Amount,
			@WinElapsedTime = Math.Truncate((DateTime.Now - w.DateTime).TotalSeconds / 60),
			@WinName = w.Game != null ? w.Game.ShortName : string.Empty,
			@WinUrl = w.Game != null ? GetGameUrl(w.Game, Profile.IsAuthenticated) : "#"
		}).Take(maximum).ToList<object>();
		
        return result;
    }
</script>

<% Html.RenderPartial("WinnerList", GetCasinoWinners(), ViewData.Merge()); %>