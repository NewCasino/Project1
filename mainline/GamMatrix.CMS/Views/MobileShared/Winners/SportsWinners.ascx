<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script type="text/C#" runat="server">
	private IList GetSportsWinners(int maximum = 10)
	{
		return new List<object>();
	}
</script>

<% Html.RenderPartial("WinnerList", GetSportsWinners(), ViewData.Merge()); %>