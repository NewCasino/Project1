<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server">
    private string CurrentPath
    {
        get
        {
            return ViewData["Path"] as string;
        }
    }
    private string[] SubPaths
    {
        get
        {
            return ViewData["SubPaths"] as string[];
        }
    }

    private string RootPath
    {
        get
        {
            return ViewData["RootPath"] as string;
        }
    }

    private string GetSubPath(string metadataPath)
    {
        return metadataPath.Substring(RootPath.Length).TrimStart('/').TrimEnd('/');
    }
    private string GetItemUrl(string metadataPath)
    {
        return "/Faq/" + GetSubPath(metadataPath);
    }
    private string GetTitle(string path)
    {
        return this.GetMetadata(string.Format("{0}.Title", path))
            .DefaultIfNullOrEmpty(System.IO.Path.GetFileNameWithoutExtension(path));
    }
    
    
</script>
<hgroup id="categoryHead">
    <h1><%=GetTitle(CurrentPath) %></h1>
</hgroup>
<ul class="articleList">
    <%foreach(var path in SubPaths){  %>
    <li><a href="<%=GetItemUrl(path) %>"><i class="icon-article-doc"></i><span><%=GetTitle(path) %></span></a></li>
    <%} %>
  
</ul>
