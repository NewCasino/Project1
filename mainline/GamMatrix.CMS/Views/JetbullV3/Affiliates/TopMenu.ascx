<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Text" %>
<div class="topmenu">
    <ul>
        <% 
				
            string text, url, target, title, urlMatchExpression, name, highLightCss, notification;
            bool isSelected = false;
            StringBuilder sbSubMenus = new StringBuilder(); 
            string[] paths = Metadata.GetChildrenPaths("/Metadata/Affiliate/TopMenu");
            for (int i = 0; i < paths.Length; i++)
            {
                text = Metadata.Get(string.Format("{0}.Text", paths[i])).DefaultIfNullOrEmpty("Untitled");
                url = Metadata.Get(string.Format("{0}.Url", paths[i])).DefaultIfNullOrEmpty("#");
                target = Metadata.Get(string.Format("{0}.Target", paths[i])).DefaultIfNullOrEmpty("_self");
                name = paths[i].Substring(paths[i].LastIndexOf("/") + 1).ToLower();
                urlMatchExpression = Metadata.Get(string.Format("{0}.UrlMatchExpression", paths[i])).DefaultIfNullOrEmpty(string.Empty);
                notification = Metadata.Get(string.Format("{0}.Notification", paths[i])).DefaultIfNullOrEmpty(string.Empty);
                isSelected = false;
                highLightCss = Metadata.Get(string.Format("{0}.highLight_CssName", paths[i]));
                if (!string.IsNullOrEmpty(urlMatchExpression))
                {
                    isSelected = Regex.Match(Request.Url.PathAndQuery, urlMatchExpression.Trim(), RegexOptions.Singleline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant).Success;
                }
                %>
        <li class='main-item menu-<%=name.ToLower()%> <%=i==0?"first" : i==paths.Length-1?"last":"" %><%=isSelected?" selected":"" %> <%=!isSelected && !string.IsNullOrEmpty(highLightCss) ? highLightCss :"" %>'>
<%--            <%: Html.LinkButton(text, new {@class =  " menu-item", @href = url.SafeHtmlEncode(), @target = target.SafeHtmlEncode() })%>
--%>            
            <a target="<%=target.SafeHtmlEncode() %>" onclick="this.blur();" href="<%=url.SafeHtmlEncode() %>" class="menu-item">
                <span class="menu-item_Right">
                    <span class="menu-item_Left">
                        <span class="menu-item_Center">
                            <span><%=text %></span>
                        </span>
                    </span>
                </span>
                <% if (String.Equals(name, "promotions" ,StringComparison.OrdinalIgnoreCase))
                   {%>
                   <span class="notification_icon icon_number"><%=notification %></span>
                <% } %>
                <% if (String.Equals(name, "bingo" ,StringComparison.OrdinalIgnoreCase))
                   {%>
                   <span class="notification_icon icon_number"><%=notification %></span>
                <% } %>
            </a>
        </li>
        <% if (isSelected)
           {
               sbSubMenus.AppendFormat(@"<ul class=""menu-sub {0}"">", isSelected ? " ActiveSub" : "");
               string[] subPaths = Metadata.GetChildrenPaths(paths[i]);
               if (subPaths != null && subPaths.Length > 0)
               {
                   for (int j = 0; j < subPaths.Length; j++)
                   {
                       text = Metadata.Get(string.Format("{0}.Text", subPaths[j])).DefaultIfNullOrEmpty("Untitled");
                       url = Metadata.Get(string.Format("{0}.Url", subPaths[j])).DefaultIfNullOrEmpty("#");
                       target = Metadata.Get(string.Format("{0}.Target", subPaths[j])).DefaultIfNullOrEmpty("_self");
                       name = subPaths[j].Substring(subPaths[j].LastIndexOf("/") + 1).ToLower();
                       urlMatchExpression = Metadata.Get(string.Format("{0}.UrlMatchExpression", subPaths[j])).DefaultIfNullOrEmpty(url);
                       var active = Regex.Match(Request.Url.PathAndQuery, urlMatchExpression, RegexOptions.Singleline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant).Success;
                       sbSubMenus.AppendFormat(@"<li class=""{1}"">{0}</li>", Html.LinkButton(text, new { @class = "menu-" + name.ToLower() + "-sub menu-item-sub", @href = url.SafeHtmlEncode(), @target = target.SafeHtmlEncode() }).ToHtmlString(), active ? "menu-sub-active" : "");
                   }
               }
               sbSubMenus.Append("</ul>");
           }%>
        <%}%>
    </ul>
    
</div>
<%=sbSubMenus.Length > 0 ? sbSubMenus.ToString() : @"<ul class=""menu-sub""></ul>" %>
