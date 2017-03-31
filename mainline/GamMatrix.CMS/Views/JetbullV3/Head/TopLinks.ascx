<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div id="toplinks">
    <%
        string urlMatchExpression = string.Empty;
        bool isSelected = false;
        string [] paths = Metadata.GetChildrenPaths("/Head/TopLink");
        foreach (string path in paths)
        {
            urlMatchExpression = Metadata.Get(string.Format("{0}.UrlMatchExpression", path));
            if (!string.IsNullOrEmpty(urlMatchExpression))
            {
              isSelected = Regex.Match(Request.Url.PathAndQuery, urlMatchExpression.Trim(), RegexOptions.Singleline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant).Success;
            }
          %>
            <%=string.Format(@" <li class=""TopLinksItem{4} {2}""><a href=""{0}"" class=""{2}"" target=""{3}"">{1}</a></li>"
                        , this.GetMetadata(path + ".Url").SafeHtmlEncode()
                        , this.GetMetadata(path+".Text").SafeHtmlEncode()
                        , path.Substring(path.LastIndexOf("/") + 1)
                        , this.GetMetadata(path + ".Target").DefaultIfNullOrEmpty("_self").SafeHtmlEncode()
                        , isSelected ? " ActiveItem" : string.Empty
                        ) %>
      <% } %>
</div>