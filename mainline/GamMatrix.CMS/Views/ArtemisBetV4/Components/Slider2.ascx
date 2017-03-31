<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
    private string SliderPath { get; set; } 
    protected override void OnInit(EventArgs e)
    {
        this.SliderPath = this.ViewData["SliderPath"] as string;
        base.OnInit(e);
    }
</script>
<ul class="sliderList">
    <% 
        string[] table1paths = Metadata.GetChildrenPaths(SliderPath);
        string HtmlV;
        for (int i = 0; i < table1paths.Length; i++) {
            HtmlV = Metadata.Get(string.Format("{0}.Html", table1paths[i])).DefaultIfNullOrEmpty(" ");
    %>
        <li class="slider2_item"><%=HtmlV %></li>
    <% } %>
</ul>