<%@ Page Language="C#" PageTemplate="/Bingo/BingoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>


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

                   <div class="bingo-jackpots-containner"></div>

<%--                   <div class="bingo-winners-containner"></div>--%>
            </div>
        </div>

        <div class="Zone Container Games">
            <div class="bingo-rooms-containner"></div>
        </div>

           <div class="w2c"></div>
           
       </div>

       <script language="javascript" type="text/javascript">
           $(document).ready(function () {
               $("#bingo-wrapper").find(".bingo-rooms-containner").load('<%= this.Url.RouteUrl( "Bingo", new {@action="RoomsWidget" }).SafeJavascriptStringEncode() %>');
               $("#bingo-wrapper").find(".bingo-jackpots-containner").load('<%= this.Url.RouteUrl( "Bingo", new {@action="JackpotRotator"}).SafeJavascriptStringEncode() %>');
//               $("#bingo-wrapper").find(".bingo-winners-containner").load('<%= this.Url.RouteUrl( "Bingo", new {@action="LastWinners"}).SafeJavascriptStringEncode() %>');
           });
    </script>

</asp:content>
