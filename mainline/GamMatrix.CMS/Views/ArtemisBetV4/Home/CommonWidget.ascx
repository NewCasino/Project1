<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
    private string WidgetPath { get; set; } 
    protected override void OnInit(EventArgs e)
    {
        this.WidgetPath = this.ViewData["WidgetPath"] as string;
        base.OnInit(e);
    }
</script>
<div class="WidgetWrapper">
    <h2 class="WidgetTitle"><%= this.GetMetadata(WidgetPath + ".Title") %></h2>
    <p class="WidgetDescription"><%= this.GetMetadata(WidgetPath + ".Description") %></p>
    <ul class="WidgetList">
    <% 
                string[] table1paths = Metadata.GetChildrenPaths(WidgetPath);
                string Image, Link, TextV;
                for (int i = 0; i < table1paths.Length; i++)
                {
                    Image = Metadata.Get(string.Format("{0}.Image", table1paths[i])).DefaultIfNullOrEmpty(" ");
                    Link = Metadata.Get(string.Format("{0}.Link", table1paths[i])).DefaultIfNullOrEmpty(" ");
                    TextV = Metadata.Get(string.Format("{0}.Text", table1paths[i])).DefaultIfNullOrEmpty(" ");
            %>
        <li class="Widget_item">
            <a href="<%=Link%>" title="Şimdi <%=TextV%> oynayın!">
                <img class="widget_Img" src="<%=Image%>" width="376" height="250" alt="<%=TextV%>" />
                <span><%=TextV%></span>
            </a>
        </li>
    <% } %>
    </ul>
    <p class="MoreInfo"><%= this.GetMetadata(WidgetPath + ".MoreInfo") %></p>
    <a href="<%= this.GetMetadata(WidgetPath + ".MoreLink") %>" class="Button ShowMore"><%= this.GetMetadata(WidgetPath + ".MoreText") %></a>
</div>
