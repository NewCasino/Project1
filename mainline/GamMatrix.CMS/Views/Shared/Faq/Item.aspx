<%@ Page Language="C#" PageTemplate="/Faq/FaqMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<script runat="server">

    private string RootMetadataPath
    {
        get
        {
            return "/Metadata/Faq/";
        }
    }
    private List<string> Parameters
    {
        get
        {
            return ViewData["Parameters"] as List<string>;
        }
    }
    private string CurrentPath
    {
        get
        {
            return RootMetadataPath + string.Join("/", Parameters);
        }
    }


    private bool? _showList;
    private bool ShowList
    {
        get
        {
            if (_showList.HasValue)
                return _showList.Value;


            if (Parameters.Count == 0)
                _showList = true;
            else
            {
                _showList = SubPaths != null && SubPaths.Length > 0;
            }

            return _showList.Value;
        }
    }
    private string[] _subPaths;
    private string[] SubPaths
    {
        get
        {
            if (_subPaths != null)
                return _subPaths;

            if (Parameters.Count > 0)
                _subPaths = Metadata.GetChildrenPaths(CurrentPath);
            else
            {
                var secondPaths = Metadata.GetChildrenPaths(RootMetadataPath);
                if (secondPaths != null)
                {
                    _subPaths = Metadata.GetChildrenPaths(secondPaths[0]);
                }
            }

            return _subPaths;

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

    private string[] RelatedPaths = null;

    private string GetTitle(string path)
    {
        return this.GetMetadata(string.Format("{0}.Title", path))
            .DefaultIfNullOrEmpty(System.IO.Path.GetFileNameWithoutExtension(path));
    }

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);

        if (!ShowList)
        {
            List<string> relatedPaths = new List<string>();
            string str = null;
            using (System.IO.StringReader reader = new System.IO.StringReader(this.GetMetadata(string.Format("{0}.RelatedItems", CurrentPath))))
            {
                while (!string.IsNullOrWhiteSpace((str = reader.ReadLine())))
                {
                    if (!str.StartsWith(RootMetadataPath))
                    {
                        relatedPaths.Add(RootMetadataPath + str.TrimStart('/'));
                    }
                    else
                        relatedPaths.Add(str);
                }
            }

            RelatedPaths = relatedPaths.ToArray();
        }

    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
    <div class="left-pane faq">
        <div class="searchWrap ItemPage">
            <% Html.RenderPartial("SearchForm", this.ViewData); %>
        </div>
        <ui:Panel runat="server" ID="pnFaqSideMenu" CssClass="sidemenupanel">
            <% Html.RenderPartial("SideMenu", this.ViewData.Merge(new { @MetadataPath = RootMetadataPath })); %>
        </ui:Panel>
     </div>
    <div class="main-pane faq">
        
        <section id="faqContent">
            <div class="contentWrap">
             <%if (ShowList)
               { %>
        <% Html.RenderPartial("ItemList", this.ViewData.Merge(new { @RootPath = RootMetadataPath, @Path = CurrentPath, @SubPaths = SubPaths })); %>
        <%}
               else
               { %>
        <article id="fullArticle">
        <h1 class="title"><%=GetTitle(CurrentPath) %></h1>
    
        <div class="mainContent">
            <%=this.GetMetadata(string.Format("{0}.Html", CurrentPath)) %>
        </div>
    </article>
        <%} %>
                </div>
        </section>
        <%if (!ShowList && RelatedPaths.Length > 0)
          { %>
        <section class="related">
            <h3><%=this.GetMetadata(".Related_Title") %></h3>
            <ul>
             <%foreach(var path in RelatedPaths){ %>             
                    <li><a href="<%=GetItemUrl(path) %>"><i class="icon-article-doc"></i><span><%=GetTitle(path) %></span></a></li>
                       <%} %>         
            </ul>
        </section>
        <%} %>
       
    </div>

</asp:content>

