<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Text" %>
<nav id="topmenu" class="MainMenu">
    <ul class="MainMenuList">
    <% 
        string text, url, target, title, urlMatchExpression, name, highLightCss, infonum, extra, linktitle;
        bool isSelected = false;
        StringBuilder sbSubMenus = new StringBuilder(); string[] paths = Metadata.GetChildrenPaths("/Head/TopMenuItems");
        for (int i = 0; i < paths.Length; i++) {
            text = Metadata.Get(string.Format("{0}.Text", paths[i])).DefaultIfNullOrEmpty("Untitled");
            extra = "";
            infonum = "";
            if (!string.IsNullOrEmpty(infonum) && infonum != "0" ) {
                extra = string.Format("<span class='promotions_info_count'>{0}</span>",infonum);
            }
            text = text + extra;
            url = Metadata.Get(string.Format("{0}.Url", paths[i])).DefaultIfNullOrEmpty("#");
            target = Metadata.Get(string.Format("{0}.Target", paths[i])).DefaultIfNullOrEmpty("_self");
            name = paths[i].Substring(paths[i].LastIndexOf("/") + 1).ToLower();
            urlMatchExpression = Metadata.Get(string.Format("{0}.UrlMatchExpression", paths[i])).DefaultIfNullOrEmpty(string.Empty);
            linktitle = "";
            linktitle = Metadata.Get(string.Format("{0}.Title", paths[i])).DefaultIfNullOrEmpty("Untitled");
            isSelected = false;
            highLightCss = Metadata.Get(string.Format("{0}.highLight_CssName", paths[i]));
            infonum = Metadata.Get(string.Format("{0}.Info_Num", paths[i]));
            if (!string.IsNullOrEmpty(urlMatchExpression)) {
                isSelected = Regex.Match(Request.Url.PathAndQuery, urlMatchExpression.Trim(), RegexOptions.Singleline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant).Success;
            }
    %>
    <li class="MainMenuItem Menu-<%=name.ToLower()%><%=i==0?" First" : i==paths.Length-1?" Last":"" %><%=isSelected?" Selected":"" %><%=!isSelected && !string.IsNullOrEmpty(highLightCss) ? highLightCss : "" %>">
        <%
            //: Html.LinkButton(text, new {@class =  " MainMenuLink", @href = url.SafeHtmlEncode(), @target = target.SafeHtmlEncode() })
        %>
        <a class="MainMenuLink" href="<%=url.SafeHtmlEncode()%>" target="<%=target.SafeHtmlEncode()%>" title="<%=linktitle%>"><%=text%></a>
    </li>
    <%
            sbSubMenus.AppendFormat(@"<ul class=""menu-{0}-sub {1}"">", name,isSelected?" active":"" );
            string[] subPaths = Metadata.GetChildrenPaths(paths[i]);
            if (subPaths != null && subPaths.Length > 0) {
                for (int j = 0; j < subPaths.Length; j++) {
                    text = Metadata.Get(string.Format("{0}.Text", subPaths[j])).DefaultIfNullOrEmpty("Untitled");
                    url = Metadata.Get(string.Format("{0}.Url", subPaths[j])).DefaultIfNullOrEmpty("#");
                    target = Metadata.Get(string.Format("{0}.Target", subPaths[j])).DefaultIfNullOrEmpty("_self");
                    name = subPaths[j].Substring(subPaths[j].LastIndexOf("/") + 1).ToLower();
                    sbSubMenus.AppendFormat(@"<li>{0}</li>", Html.LinkButton(text, new { @class = "menu-" + name.ToLower() + "-sub menu-item-sub", @href = url.SafeHtmlEncode(), @target = target.SafeHtmlEncode() }).ToHtmlString());
                }
            }
            sbSubMenus.Append("</ul>");
        }
    %>
    </ul>
</nav>
<nav class="SecondaryMenu"><%=sbSubMenus.ToString() %></nav>
