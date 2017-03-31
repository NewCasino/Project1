<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<script type="text/C#" runat="server">
    private string GetLoggedInHtml() {
        if (!Profile.IsAuthenticated)
            return string.Empty;
        return this.GetMetadata(".LoggedInHtml").HtmlEncodeSpecialCharactors();
    }
    private string GetCategory() {
        string requestPath = Request.RawUrl;
        if (requestPath.Contains("/Index/")) {
            string category = requestPath.Substring(requestPath.IndexOf("/Index/") + 7);
            string categoryName = category.Replace("_", " ");
            return "<li class=\"BreadItem BreadCurrent\" role=\"menuitem\" itemtype=\"http://data-vocabulary.org/Breadcrumb\" itemscope=\"itemscope\"><a class=\"BreadLink url\" href=\"/LiveCasino/Hall/Index/" + category + "\" itemprop=\"url\" title=\"" + categoryName + "\"><span itemprop = \"title\" >" + categoryName + "</ span ></ a ></ li >";
        } else
            return string.Empty;
    }
    private string isFinal() {
        string requestPath = Request.RawUrl;
        if (requestPath.Contains("/Index/")) return "";
        else return " BreadCurrent";
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Breadcrumbs" role="navigation">
    <ul class="BreadMenu Container" role="menu">
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem <%=isFinal()%>" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/LiveCasino/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/LiveCasino/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/LiveCasino/.Name") %></span>
            </a>
        </li>
        <%=GetCategory()%>
    </ul>
</div>

<div class="Framework">

    <div class="Zone Container Intro AllSlidersContainer">
    
        <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Metadata/Sliders/LiveCasino/Main" })); %> 
    
        <div class="HomeWidget">
            <% if (!Profile.IsAuthenticated) {
                Html.RenderPartial("/QuickRegister/RegisterWidget");
            } else {
                Html.RenderPartial("/Home/DepositWidget");
            } %>
        </div>
    
    </div>
    
    <main class="MainContent">
    
        <% Html.RenderPartial("GameNavWidget/Main", this.ViewData.Merge( new { } )); %>
    
    </main>
    
    <aside class="Zone Container ExtraWidgets">
    
        <div class="LiveScoreWidget Column">
            <% Html.RenderPartial("/Casino/Hall/LiveScores"); %>
        </div>
        <div class="GamesWidgets Column">
            <div class="RecentWinnersWidget Column">
                <% Html.RenderPartial("/Casino/Lobby/RecentWinnersWidget", this.ViewData.Merge(new { })); %>
            </div>
        </div>
    </aside>
<%--
    <div class="LiveCasinoBottomWidget CasinoWidget">
        <% Html.RenderPartial("../../Home/CommonWidget", this.ViewData.Merge(new {@WidgetPath = "/Metadata/Widgets/Home/Casino/" }));%>
    </div>
--%>
</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        function ChangeHours() { 
            $('.OpenedTable').each(function(){
                $(this).find('.ExtraGameDetails').append($(this).find('.GTOpeningHours'));
                $(this).find('.GTOpeningHours').prepend('Opening Hours - ');
            });
        }
        
        $(function() {
            /*$('.AllTables .TabItem').on('hover', function(evt){
                var el = $(this);
                $('.AllTables .TabItem').removeClass('ActiveCat');
                el.addClass('ActiveCat');
            });
            $('.GamesCategories').on('mouseleave',function(evt){
                $('.AllTables .TabItem').removeAttr('style').removeClass('ActiveCat');
                var classNames= $.grep($('body').attr('class').split(" "), function(v, i){ return v.indexOf('Style') === 0;  }).join();
                classNames = classNames.replace('Style-','');
                var cat = 'cat-'+classNames;
                $("li."+cat).addClass('ActiveCat');
            });*/
        });
    </script>
</ui:MinifiedJavascriptControl>

</asp:Content>



