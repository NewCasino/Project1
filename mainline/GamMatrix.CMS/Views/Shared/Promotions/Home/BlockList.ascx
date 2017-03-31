<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
    private string CurrentActionName { get { return this.ViewData["actionName"] as string; } }
    private bool _ShowAll = false;
    private bool ShowAll { 
        get { return _ShowAll; }
        set { _ShowAll = value; }
    }
    
    string name,image = "", text = "", title = "", subPath="";

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (string.IsNullOrEmpty(CurrentActionName) || CurrentActionName.Equals("index", StringComparison.OrdinalIgnoreCase) || CurrentActionName.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            ShowAll = true;
        }
    }
</script>


<ui:Panel runat="server" CssClass="promoton-list" ID="pnPromotionList">
<% 

    ArrayList paths = new ArrayList();
    if (ShowAll)
    {
        string[] categoryPaths = Metadata.GetChildrenPaths(this.MetadataPath);
        foreach (string categoryPath in categoryPaths)
        {
            paths.AddRange(Metadata.GetChildrenPaths(categoryPath));
        }
    }
    else
    {
        paths.AddRange(Metadata.GetChildrenPaths(string.Format("{0}/{1}", this.MetadataPath,this.ViewData["actionName"].ToString())));
    }
    int _index = 0;
    string _temp;
    foreach (string path in paths)
    {
        _index++;
        _temp = path.Substring(0, path.LastIndexOf("/"));

        subPath = (_temp.Substring(_temp.LastIndexOf("/"))+ path.Substring(path.LastIndexOf("/"))).ToLowerInvariant();
        
        image = this.GetMetadata(path + ".Image");
        text = this.GetMetadata(path + ".Text");
        title = this.GetMetadata(path + ".Title");
        %>
        <ui:Panel CssClass="promotiom-item" runat="server" ID="pnPromotionItem">
            <div class="promotiom-item-head"><%= title.HtmlEncodeSpecialCharactors()%></div>
            <div class="promotiom-item-image"><%= image.HtmlEncodeSpecialCharactors()%></div>
            <div class="promotiom-item-text"><%= text.HtmlEncodeSpecialCharactors()%></div>
            <div class="promotiom-item-button-wrapper">
            <%: Html.LinkButton(this.GetMetadata(".BUTTON_TERMS_TEXT"), new { @class = "promotion-button", @href = this.Url.RouteUrl("Promotions_TermsConditions") + subPath })%>
            <% if (!Profile.IsAuthenticated)
               {%>
               <%: Html.LinkButton(this.GetMetadata(".BUTTON_SIGNUP_TEXT"), new { @class = "promotion-button", @href = this.Url.RouteUrl("Register", new { @action = "Index" }) })%>
               <%}
                else
                {%>
                <%: Html.LinkButton(this.GetMetadata(".BUTTON_DEPOSIT_TEXT"), new { @class = "promotion-button", @href = this.Url.RouteUrl("Deposit", new { @action = "Index" }) })%>
                <%} %>
            </div>
        </ui:Panel>
        <%
    }
    %>
</ui:Panel>

