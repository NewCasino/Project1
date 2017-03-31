<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div id="toplinks">
    <%
        string urlMatchExpression = string.Empty;
        bool isSelected = false;
        foreach (string path in Metadata.GetChildrenPaths("/Head/TopLink"))
        {
            urlMatchExpression = Metadata.Get(string.Format("{0}.UrlMatchExpression", path)).DefaultIfNullOrEmpty(string.Empty);
            if (!string.IsNullOrEmpty(urlMatchExpression))
            {
              isSelected = Regex.Match(Request.Url.PathAndQuery, urlMatchExpression.Trim(), RegexOptions.Singleline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant).Success;
            }
          %>
            <%=string.Format(@" <li class=""TopLinksItem{4}""><a href=""{0}"" class=""{2}"" target=""{3}"">{1}</a></li>"
                        , this.GetMetadata(path + ".Url").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode()
                        , this.GetMetadata(path+".Text").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode()
                        , path.Substring(path.LastIndexOf("/") + 1)
                        , this.GetMetadata(path + ".Target").DefaultIfNullOrEmpty("_self").SafeHtmlEncode()
                        ,isSelected ? " ActiveItem" : string.Empty) %>
      <% } %>
</div>