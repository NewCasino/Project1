<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %><%@ Import Namespace="System.Text" %><div id="tabs"><%  
	StringBuilder sbSubMenus = new StringBuilder();   
        string[] paths = Metadata.GetChildrenPaths("/Head/TabsLinkItems");
        for (int i = 0; i < paths.Length; i++)
        {
            string text = Metadata.Get(string.Format("{0}.Text", paths[i])).DefaultIfNullOrEmpty("Untitled");
            string url = Metadata.Get(string.Format("{0}.Url", paths[i])).DefaultIfNullOrEmpty("#");
            string target = Metadata.Get(string.Format("{0}.Target", paths[i])).DefaultIfNullOrEmpty("_self");
            string name = paths[i].Substring(paths[i].LastIndexOf("/")+1).ToLower();
            %><%: Html.LinkButton(text, new { @class = "menu-" + name.ToLower() + " menu-item", @href = url.SafeHtmlEncode(), @target = target.SafeHtmlEncode() })%><%           }      %></div>
