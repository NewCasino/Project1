<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<object>>" %>
<%@ Import Namespace="Finance" %>

<script type="text/C#" runat="server">
	private string listStyle
	{
		get
		{
			return ViewData["ListStyle"] as string ?? "WinnerList";
		}
	}

	private string itemStyle
	{
		get
		{
			return ViewData["ItemStyle"] as string ?? "Winner";
		}
	}

	private struct WinnerViewData
	{
		public string CountryFlag;
		public string DisplayName;
		public string WinName;
		public string WinUrl;
		public string FormattedAmount;
	}
	
	private List<WinnerViewData> FormatWinners()
	{
		Func<double, string> formatElapsedTime = delegate(double seconds)
		{
			if (seconds < 10)
				return this.GetMetadata(".Now");

			StringBuilder formattedTime = new StringBuilder();
			formattedTime.Append((seconds % 60) + this.GetMetadata(".Seconds"));

			int minutes = (int)(seconds / 60);
			if (minutes == 0)
				return formattedTime.ToString();

			formattedTime.Insert(0, ((minutes % 60) + this.GetMetadata(".Minutes") + ", "));

			int hours = (int)(minutes / 60);
			if (hours == 0)
				return formattedTime.ToString();

			formattedTime.Insert(0, (hours + this.GetMetadata(".Hours") + ", "));

			return formattedTime.ToString();
		};
		
		var winners = this.Model.Select(winner => new WinnerViewData()
		{
			@CountryFlag = ObjectHelper.GetFieldValue<string>(winner, "CountryFlagName"),
			@DisplayName = ObjectHelper.GetFieldValue<string>(winner, "DisplayName"),
			@WinName = ObjectHelper.GetFieldValue<string>(winner, "WinName"),
			@WinUrl = ObjectHelper.GetFieldValue<string>(winner, "WinUrl"),
			@FormattedAmount = MoneyHelper.FormatWithCurrencySymbol(
								ObjectHelper.GetFieldValue<string>(winner, "Currency"),
								ObjectHelper.GetFieldValue<decimal>(winner, "Amount")
							)
		}).ToList();

		return winners;
	}
</script>

<ol class="<%= listStyle %> Container L">
	<%
		foreach (var winnerData in FormatWinners())
		{
	%>
		<li class="<%= itemStyle %>">
			<span class="UserInfo"> <span class="WinnerName"><%= winnerData.DisplayName.SafeHtmlEncode()%></span> </span>
			<span class="WinnerDetails"> 
				<span class="WinAmmount Cash"><%= winnerData.FormattedAmount.SafeHtmlEncode() %></span> 
				<%
					if (!string.IsNullOrEmpty(winnerData.WinName))
					{
				%>
				<a class="WinAt" href="<%= winnerData.WinUrl.SafeHtmlEncode()%>"><%= winnerData.WinName.SafeHtmlEncode()%></a> 
				<%
					}
				%>
			</span>
		</li>
	<%
		}
	%>
</ol>