<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script type="text/C#" runat="server">
	private IList GetPopularBets()
	{
		return new List<dynamic>();
	}
</script>


<ol class="MenuList L ToggleContent">
	<%
		foreach (var item in GetPopularBets())
		{
	%>
	<li class="MenuItem X">
		<a class="MenuLink A Container" href="#"> <span class="Page I">Page:</span> <span class="PageName N MatchName">Team 1 - Team 2</span> </a>
	</li>
	<%
		}
	%>
</ol>