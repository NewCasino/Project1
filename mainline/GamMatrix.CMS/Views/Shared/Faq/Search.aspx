<%@ Page Language="C#" PageTemplate="/Faq/FaqMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<script runat="server">

    static readonly string[] ToBeSearchMetadataName = new[] { "Title", "Html" };
    /// <summary>
    /// Compiled regular expression for performance.
    /// </summary>
    static Regex _htmlRegex = new Regex("<.*?>", RegexOptions.Compiled);

    /// <summary>
    /// Remove HTML from string with compiled Regex.
    /// </summary>
    public static string StripTagsRegexCompiled(string source)
    {
        return _htmlRegex.Replace(source, string.Empty);
    }
    
    private string SearchKey
    {
        get
        {
            return ViewData["key"] as string;
        }
    }
    private string RootMetadataPath
    {
        get
        {
            return "/Metadata/Faq/";
        }
    }

    Regex SearchRegex;

    private void Search()
    {
        SearchMetadata(RootMetadataPath);
    }
   
    private void SearchMetadata(string path)
    {
        path = path.TrimEnd('/');
        if (!string.IsNullOrWhiteSpace(Metadata.Get(string.Format("{0}.{1}", path, "Html"))))
        {
            foreach (var mtName in ToBeSearchMetadataName)
            {
                string content = Metadata.Get(string.Format("{0}.{1}", path, mtName));
                if (string.IsNullOrWhiteSpace(content))
                    continue;

                MatchCollection mc = SearchRegex.Matches(content);
                if (mc.Count > 0)
                {
                    _subPaths.Add(path);
                    return;
                }
            }
        }
        else
        {
            var paths = Metadata.GetChildrenPaths(path);
            if (paths != null)
            {
                paths.ToList().ForEach(p => SearchMetadata(p));
            }
        }
    }

    private List<string> _subPaths = new List<string>();
    private string[] SubPaths
    {
        get
        {
            return _subPaths.ToArray();
        }
    }
    private string GetSubPath(string metadataPath)
    {
        return metadataPath.Substring(RootMetadataPath.Length).TrimStart('/').TrimEnd('/');
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

    int DesShortMax = 200;
    private string GetShortDes(string path)
    {

        var text = StripTagsRegexCompiled(this.GetMetadata(string.Format( "{0}.Html", path)));
        if (text.Length <= DesShortMax)
            return text;
        return text.Substring(0, DesShortMax);
    }

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        if (string.IsNullOrEmpty(SearchKey))
            HttpContext.Current.Response.Redirect("/Faq/");

        StringBuilder pattern = new StringBuilder();
        pattern.Append(@"\b");

        pattern.Append("(");
        foreach (char c in SearchKey)
        {
            pattern.AppendFormat(@"\u{0:X4}", (int)c);
        }
        pattern.Append(")");
        pattern.Append(@"\b");

        RegexOptions options = RegexOptions.Multiline | RegexOptions.CultureInvariant | RegexOptions.Compiled;
        options |= RegexOptions.IgnoreCase;
        SearchRegex = new Regex(pattern.ToString(), options);


        Search();
    }
     
    
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
    <script type="text/javascript" src="//cdn.everymatrix.com/CasinoCruise/js/jquery.highlight-4.js"></script>
    <div class="left-pane faq">
        <div class="searchWrap ItemPage">
            <% Html.RenderPartial("SearchForm", this.ViewData.Merge(new { @SearchKey = SearchKey })); %>
        </div>
     </div>
    <div class="main-pane faq">
        
        <section id="faqContent">
            <div class="contentWrap">
                <section id="searchResult">
                    <h1> <%=string.Format(this.GetMetadata(".SearchTitleFormat"),string.Format("<strong>{0}</strong>",SearchKey)) %> </h1>
                    <%if(SubPaths.Length >0){ %>
                    <p class="articlesFound">
                        <%=string.Format(this.GetMetadata(".Found_Result_Format"),SubPaths.Length) %> 
                    </p>
                    <%}else{ %>
                    <p class="nada"><%=this.GetMetadata(".No_Result_Text") %></p>
                    <%} %>
                    <ul class="articleList">
                        <%foreach (var path in SubPaths)
                          { 
                              if( string.IsNullOrWhiteSpace( this.GetMetadata( string.Format("{0}.Html",path))))
                                  continue;
                               %>
                        <li>
                            <a href="<%=GetItemUrl(path) %>"><i class="icon-article-doc"></i><span><%=GetTitle(path) %></span></a>
                            <p class="artDes">
                                <%=GetShortDes(path) %>
                            </p>
                        </li>
                        <%} %>
  
                    </ul>
                </section>
        
       
            </div>
        </section>
       
    </div>
    <script type="text/javascript">
        $(function () {
            $("#searchResult ul").highlight("<%=SearchKey %>");
        });
    </script>
</asp:content>

