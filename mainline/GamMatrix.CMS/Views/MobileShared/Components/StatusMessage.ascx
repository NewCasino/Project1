<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
	/// <summary>
	/// Gets status type from view data;
	/// Recognized values are: ok, warning, error, info
	/// </summary>
	/// <returns>The status type</returns>
	private string Type
	{
		get
		{
			return (this.ViewData["Type"] as string ?? "info").ToLower();
		}
	}

    private string ID
    {
        get {
            return this.ViewData["ID"] as string ?? string.Empty;
        }
    }

	private string Title
	{
		get
		{
			return this.ViewData["Title"] as string ?? String.Empty;
		}
	}
	
	private string Message
	{
		get
		{
			return this.ViewData["Message"] as string ?? String.Empty;
		}
	}

	private bool IsHtml
	{
		get
		{
			return this.ViewData["IsHtml"] as bool? ?? false;
		}
	}

	private string GetStatusStyle()
	{
		return System.Globalization.CultureInfo.CurrentCulture.TextInfo.ToTitleCase(Type) + "Status";
	}
</script>

<div class="<%: GetStatusStyle() %> StatusContainer" <%=string.IsNullOrEmpty(ID) ? "" : string.Format(@"id=""{0}""",ID)%>>
	<div class="StatusBackground">
		<div class="StatusIcon">Status</div>
		<%	if (!String.IsNullOrEmpty(Title)) 
			{
		%>
		<div class="StatusTitle"><%= Title.SafeHtmlEncode()%></div>
		<% 
			} 
		%>
		
		<% 
			if (IsHtml)
			{
		%>
		<div class="StatusMessage"><%= Message.HtmlEncodeSpecialCharactors()%></div>
		<%
			}
			else
			{
		%>
		<div class="StatusMessage"><%= Message.SafeHtmlEncode()%></div>
		<%
			}
		%>
	</div>
</div>

