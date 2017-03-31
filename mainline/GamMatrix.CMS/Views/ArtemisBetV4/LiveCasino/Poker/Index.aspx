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



<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Breadcrumbs" role="navigation">
    <ul class="BreadMenu Container" role="menu">
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem <%=isFinal()%>" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Poker/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Poker/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Poker/.Name") %></span>
            </a>
        </li>
        <%=GetCategory()%>
    </ul>
</div>

<div class="Framework">

    <div class="Zone Container Intro AllSlidersContainer">
    
        <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Metadata/Sliders/Poker" })); %> 
    
        <div class="HomeWidget">
            <% if (!Profile.IsAuthenticated) {
                Html.RenderPartial("/QuickRegister/RegisterWidget");
            } else {
                Html.RenderPartial("/Home/DepositWidget");
            } %>
        </div>
    
    </div>
    
    <main class="MainContent">
        <% Html.RenderPartial("/LiveCasino/Poker/GameListWidget", this.ViewData.Merge()); %>
    </main>
</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        var isLoggedIn = <%= this.Profile.IsAuthenticated.ToString().ToLowerInvariant() %>;
        $('body').addClass('LiveCasinoHall').addClass('PokerPage');
        
        function openPoker() {
            if( !isLoggedIn ){
                top.PopUpInIframe("/Login/Dialog","Login-popup",460,500);
            } else {
                if (<%=Profile.IsInRole("Incomplete Profile").ToString().ToLowerInvariant()%> == true) {
                    top.location = '/livecasino/hall/incompleteProfile';
                } else {
                var tableid = '<%=this.GetMetadata(".TableID").SafeJavascriptStringEncode() %>';
                var w = screen.availWidth * 9 / 10;
                var h = screen.availHeight * 9 / 10;
                var l = (screen.width - w)/2;
                var t = (screen.height - h)/2;
                var scrollbars='no';
                if($(this).data('vendorid')=='BetGames')
                    scrollbars='yes';
                var params = [
                    'height=768px',
                    'width=1024px',
                    'fullscreen=no',
                    'scrollbars='+scrollbars,
                    'status=yes',
                    'resizable=yes',
                    'menubar=no',
                    'toolbar=no',
                    'left=' + l,
                    'top=' + t,
                    'location=no',
                    'centerscreen=yes'
                ].join(',');
                window.open( '/LiveCasino/Hall/Start?tableID=' + tableid, 'live_casino_table', params);
                }
            }
        }
    </script>
</ui:MinifiedJavascriptControl>

</asp:Content>



