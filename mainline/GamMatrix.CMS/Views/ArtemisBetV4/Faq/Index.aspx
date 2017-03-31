<%@ Page Language="C#" PageTemplate="/Faq/FaqMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>
<%@ Import Namespace="System.IO" %>
<script runat="server">
    private string RootPath
    {
        get
        {
            return "/Metadata/Faq/";
        }
    }
    private string GetTitle(string path)
    {
        return this.GetMetadata(string.Format("{0}.Title", path))
            .DefaultIfNullOrEmpty(System.IO.Path.GetFileNameWithoutExtension(path));
    }

    private string GetSubPath(string metadataPath)
    {
        return metadataPath.Substring(RootPath.Length).TrimStart('/').TrimEnd('/');
    }
    private string GetItemUrl(string metadataPath)
    {
        return "/Faq/" + GetSubPath(metadataPath);
    }

    private List<string> PopularItemPaths = new List<string>();

    private void FindPopularItems()
    {
        foreach (var subPath in Metadata.GetChildrenPaths(RootPath))
        {
            foreach (var grandPath in Metadata.GetChildrenPaths(subPath))
            {
                if (Settings.SafeParseBoolString(this.GetMetadata(string.Format("{0}.IsPopular", grandPath)), false))
                {
                    PopularItemPaths.Add(grandPath);
                }
            }
        }
    }
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        FindPopularItems();
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">

   <div class="ContentWrap">
       <div class="search-wrap ">
           <%: Html.H1(this.GetMetadata(".Search_Title")) %>
           <% Html.RenderPartial("SearchForm", this.ViewData.Merge(new { @SearchEmptyText= this.GetMetadata(".Search_PlaceHolder")})); %>
       </div>

        <ui:Panel runat="server" ID="pnFAQ" CssClass="panel">
            <div class="faq-parents">
                <ul>
                      <%
                          var index = 0;
                          foreach (var subPath in Metadata.GetChildrenPaths(RootPath))
                          {
                              index++;
                              var title = GetTitle(subPath);
                            %>
                         <li class="faq-parent-item faq-<%=Path.GetFileNameWithoutExtension(subPath.TrimEnd('/')).ToLower() %>">
                             <a href="<%=GetItemUrl(subPath) %>">
                <h2 class="faq-parent-title"><%=title %></h2>
                <div class="faq-parent-total"><span ><%=Metadata.GetChildrenPaths(subPath).Length.ToString() %></span> <%=this.GetMetadata(".Articles") %> </div>
                                 </a>
            </li> 
                          
                        <%} %>
                </ul>
            </div>
           
       </ui:Panel>
       <section class="most-pop-arts">
           <h2><%=this.GetMetadata(".Popular_Title") %></h2>
           <%if(PopularItemPaths.Count >0) {
                 var splitIndex = PopularItemPaths.Count % 2 == 0 ? PopularItemPaths.Count/2 : PopularItemPaths.Count/2+1;
                 %>
           <ul class="popArticles">
               <%for(var i = 0; i<splitIndex;i++){ %>
               <li><a href="<%=GetItemUrl(PopularItemPaths[i]) %>"><i class="icon-article-doc"></i><span><%=GetTitle(PopularItemPaths[i]) %></span></a></li>
               <%} %>
           </ul>

           <ul class="popArticles">
               <%for(var i = splitIndex;i<PopularItemPaths.Count;i++){ %>
               <li><a href="<%=GetItemUrl(PopularItemPaths[i]) %>"><i class="icon-article-doc"></i><span><%=GetTitle(PopularItemPaths[i]) %></span></a></li>
               <%} %>
               </ul>
           <%} %>
       </section>                   
   </div>

</asp:content>

