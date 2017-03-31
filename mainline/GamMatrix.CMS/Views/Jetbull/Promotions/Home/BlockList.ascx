<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server" type="text/C#">
    private string Category { get { return this.ViewData["Category"] as string; } }

    private string MetadataPath 
    { 
        get 
        {
            string metadata = this.ViewData["MetadataPath"] as string;
            //switch (Category.ToLowerInvariant())
            //{
            //    case "casino":
            //    case "sports":
            //        metadata += "/" + Category;
            //        break;
            //    default:
            //        break;
            //}

            return metadata;
        } 
    }
    private string CurrentActionName { get { return this.ViewData["actionName"] as string; } }
    private bool _ShowAll = false;
    private bool ShowAll { 
        get { return _ShowAll; }
        set { _ShowAll = value; }
    }
    
    string name,image = "", text = "", title = "", spcCss="odd", subPath="";
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (string.IsNullOrEmpty(CurrentActionName) || CurrentActionName.Equals("index", StringComparison.OrdinalIgnoreCase) || CurrentActionName.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            ShowAll = true;
        }
    }
</script>


<div ID="pnPromotionList">
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


        subPath = (_temp.Substring(_temp.LastIndexOf("/")) + path.Substring(path.LastIndexOf("/"))).ToLowerInvariant();
        
        image = this.GetMetadata(path + ".Image");
        text = this.GetMetadata(path + ".Text");
        title = this.GetMetadata(path + ".Title");
        spcCss = _index%2==0? "even":"odd";
        name = path.Substring(path.LastIndexOf("/") + 1).ToLower();

        string excludedCountries = this.GetMetadata(path + ".ExcludedCountries");
        bool isExcludedCountry = false;
        if (excludedCountries != null)
        {
            string[] countriesList = excludedCountries.Split('\n');
            foreach(string country in countriesList) 
            {
                if (country.Contains(Profile.UserCountryID.ToString())) 
                {
                    isExcludedCountry = true;
                    break;
                }
            }
        }

        if ( !isExcludedCountry && (!ShowAll || ( this.GetMetadata(path + ".ShowOnTops_Bool").ToLower() == "true" || this.GetMetadata(path + ".ShowOnTops_Bool").ToLower() == "1")))
        {
%>
        <div class="<%=_index%2==0? "even":"odd" %> promotion-item promotiom-<%=name %>">
            <div class="promotion-item-head"><%= title.HtmlEncodeSpecialCharactors()%></div>
            <div class="promotion-item-body">
            <a href="<%=this.Url.RouteUrl("Promotions_TermsConditions") + subPath %>" class="promotion-button" style="background-image:url(<%= image.HtmlEncodeSpecialCharactors()%>);">
<%--            <span class="promotion-item-image"><%= image.HtmlEncodeSpecialCharactors()%></span>--%>
            <span class="promotion-item-text"><%= text.HtmlEncodeSpecialCharactors()%></span>
            </a>
<%--            <div class="promotiom-item-button-wrapper">
            <%: Html.LinkButton(this.GetMetadata("..BUTTON_TERMS_TEXT"), new { @class = "promotion-button", @href = this.Url.RouteUrl("Promotions_TermsConditions") + subPath })%>
            <% if (!Profile.IsAuthenticated){%><%: Html.LinkButton(this.GetMetadata(".BUTTON_SIGNUP_TEXT"), new { @class = "promotion-button", @href = this.Url.RouteUrl("Register", new { @action = "Index" }) })%><%}%>
            </div>--%>
            </div>
        </div>
        <%}
    }
    %>
</div>
