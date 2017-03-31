<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<CasinoEngine.WinnerInfo>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>


<% string wrapperID = "_" + Guid.NewGuid().ToString("N"); %>

<div class="Box Winners BigWinners" id="<%= wrapperID %>">
	<h2 class="BoxTitle WinnersTitle">
		<span class="TitleIcon">&sect;</span>

        <% if (!string.IsNullOrWhiteSpace(this.ViewData["allWinnersUrl"] as string))
           { %>
		<a href="<%= (this.ViewData["allWinnersUrl"] as string).SafeHtmlEncode() %>" class="TitleLink" title="<%= this.GetMetadata(".All_Winners_Tip").SafeHtmlEncode() %>">
            <%= this.GetMetadata(".All_Winners").SafeHtmlEncode()%>
            <span class="ActionSymbol">&#9658;</span>
        </a>
        <% } %>

		<strong class="TitleText">
            <%= this.GetMetadata(".Title").SafeHtmlEncode() %>
        </strong>
	</h2>
	<ol class="LargeWinnersList">

    <%
        
        var countries = CountryManager.GetAllCountries();
        foreach (WinnerInfo winner in this.Model)
        {
            CountryInfo country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, winner.CountryCode, StringComparison.InvariantCultureIgnoreCase));
            string countryDisplayName = "";
            string countryFlagName = winner.CountryCode;
            if (country != null)
            {
                if (!Settings.Site_IsUnWhitelabel && CountryManager.IsFrenchNational(country.InternalID)) //If country is french national, show EU flag and name
                {
                    countryDisplayName = this.GetMetadata("/Metadata/Country.EUROPEAN_UNION");
                    countryFlagName = "europeanunion";
                }
                else
                {
                    countryDisplayName = country.DisplayName;
                    countryFlagName = country.GetCountryFlagName();
                }
            }
         %>

		<li class="Winner">
			<span class="WinnerName country-flags">
				<img class="FlagImage <%= countryFlagName.SafeHtmlEncode() %>" src="/images/transparent.gif" width="16" height="11" title="<%= countryDisplayName.SafeHtmlEncode() %>" alt="<%= countryDisplayName.SafeHtmlEncode() %>" />
                <%= winner.DisplayName.SafeHtmlEncode() %>
			</span>
			<span class="WinAmmount Cash">
            <%
                string currencySymbol = Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", winner.Currency));
                string money = string.Format("{0} {1:n0}"
                    , currencySymbol.DefaultIfNullOrEmpty(winner.Currency)
                    , winner.Amount
                    );
             %>
             <%= money.SafeHtmlEncode()%>
            </span>

            <%
            if (winner.Game != null)
            {
                 %>
			<a href="<%= this.Url.RouteUrl("CasinoGame", new { @action = "Index", @gameID = winner.Game.ID }).SafeHtmlEncode() %>" class="WinGame" data-gameID="<%= winner.Game.ID.SafeHtmlEncode() %>"
                title="<%= this.GetMetadataEx(".Win_Game_Tip_Format", winner.Game.ShortName).SafeHtmlEncode() %>">
				<span class="Button SmallButton"><%= this.GetMetadata(".Play").SafeHtmlEncode() %> <span class="ActionSymbol">&#9658;</span></span>

				<span class="LGWGameTitle"><%= winner.Game.ShortName.SafeHtmlEncode() %></span>
			</a>
<%          }  %>
		</li>

     <% } %>
	</ol>
</div>

<script type="text/javascript">
    $(function () {
        $('#<%= wrapperID%> li.Winner > a.WinGame').click(function (e) {
            try {
                var playForFun = <%= (!Profile.IsAuthenticated).ToString().ToLowerInvariant() %>;
                var gameID = $(this).data('gameID') || $(this).attr('data-gameID');
                __loadGame(gameID, playForFun);
                e.preventDefault();
            }
            catch (e) {
            }
        });
    });
</script>