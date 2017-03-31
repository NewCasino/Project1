<%@ Page Language="C#" PageTemplate="/Bingo/BingoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>
<script type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {         
        if (!(Request.QueryString["key"] == null && Request.QueryString["key"].ToLowerInvariant() == "bingo"))
        {
            Server.Transfer("~/Bingo/");
            Response.End();
        }
        base.OnInit(e);
    }

</script>
<asp:content contentplaceholderid="cphHead" runat="Server"></asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
    
    <div id="bingo-wrapper" class="content-wrapper">
        <div class="Zone Container Intro">
            <div class="mainPanel">
                <%-- <%Html.RenderPartial("/Components/ImageSlider", this.ViewData.Merge(new { ShowIconButton = false, MetadataPath = "/Bingo/SliderItems" })); %>--%>
                <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Bingo/SliderItems" })); %> 
            </div>
            <div class="rightPanel">
            <h1 class="PageTitle"><%=this.GetMetadata(".PageTitle").SafeHtmlEncode() %></h1>
                <div class="bingo-banner">
                <% if (!Profile.IsAuthenticated)
                   {%>
                        <%=this.GetMetadata(".SignUpHtml")%>
                  <%}
                   else
                   {%>
                        <%=this.GetMetadata(".LoginHtml")%>
                    <%} %>
                  </div>

        </div>
        <div class="Zone Container Games">
            <div class="bingo-rooms-containner"></div>
        </div>
            
           <div class="w2c"></div>
           
       </div>

</asp:content>
