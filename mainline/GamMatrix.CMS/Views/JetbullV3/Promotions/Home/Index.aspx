<%@ Page Language="C#" PageTemplate="/Promotions/PromotionsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<script runat="server" type="text/C#">
    protected string MetadataPath
    {
        get { return this.ViewData["MetadataPath"] as string; }
    }
    protected string Category
    {
        get { return this.ViewData["actionName"] as string; }
    }
    protected string CurrentTitle
    {
        get { return this.GetMetadata(string.Format("{0}/{1}.Title", this.MetadataPath, this.ViewData["actionName"].ToString())); }
    }
    protected override void OnInit(EventArgs e)
    {
        this.ViewData["MetadataPath"] = "/Metadata/Promotions";
        if (!string.IsNullOrEmpty(CurrentTitle))
        {
            this.Page.Title = this.CurrentTitle + this.GetMetadata(string.Format("{0}.TitlePostfix", MetadataPath));
        }
    }
</script><asp:Content ContentPlaceHolderID="cphHead" Runat="Server"></asp:Content><asp:Content ContentPlaceHolderID="cphMain" Runat="Server"><%
    string titlepath = "/Head/TopMenuItems/Promotions";
    if (string.IsNullOrEmpty(Category) || Category.Equals("index", StringComparison.OrdinalIgnoreCase) || Category.Equals("All", StringComparison.OrdinalIgnoreCase))    {
    }
    else
    {
        titlepath = string.Format("{0}/{1}", titlepath, Category);
    }
     %>
    <h1 class="PageTitle"><%=this.GetMetadata(string.Format("{0}.PageTitle", titlepath)).SafeHtmlEncode() %></h1>
    <%Html.RenderPartial("BlockList", this.ViewData.Merge(new { @Category = Category })); %>  
</asp:Content>

