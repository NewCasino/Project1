<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.MenuListViewModel>" %>

<%@ Import Namespace="System.Text.RegularExpressions" %>

<script runat="server">
    private string getClassName(string path)
    {
        string strClassName = string.Empty;
        string[] items = path.Split(new string[] { "/", "." }, StringSplitOptions.RemoveEmptyEntries);
        if (items.Length > 1)
        {
            strClassName = items[items.Length - 2] + "_" + items[items.Length - 1];
        }
        return strClassName;
    }

    protected bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }
</script>
<ol class="MenuList L">
	<%if (!Model.NoData)
	{ 
		foreach (string path in Model.ContentPaths)
		{
            string isUK = Metadata.Get(string.Format("{0}.IsUK", path)).DefaultIfNullOrEmpty("No");
            if (!(Profile.IpCountryID == 230 || Profile.UserCountryID == 230) && SafeParseBoolString(isUK, false)) continue;                
		%>
    <li class="MenuItem X <%=getClassName(path) %>">
		<a class="MenuLink A Container" href="<%= Model.GetItemUrl(path).SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Page I"><%= this.GetMetadata(".Page").SafeHtmlEncode()%></span> <span class="PageName N"><%= Model.GetItemTitle(path).SafeHtmlEncode() %></span> </a>
	</li>
		<%
		}
	} %>	
</ol>