<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%
    List<CasinoEngine.Game> games = CasinoEngine.GameMgr.GetLiveDealers();

    if (games != null && games.Count() > 0)
    {%>
<ol>
    <%
        string title, name, image, slug;
        bool isNew = false;
        decimal fpp = 0.00M;
        bool haveInfo = false;
        foreach (var game in games)
        {
            name = game.Name;
            image = game.BackgroundImageUrl;
            slug = string.IsNullOrEmpty(game.Slug) ? game.ID : game.Slug;
            isNew = game.IsNewGame;
            fpp = game.FPP;
            
    %>
    <li class="LiveCasinoBox" data-type="<%= name%>" style="background-image: url(<%=image.HtmlEncodeSpecialCharactors() %>);">
        <div class="BoxTitle">
            <span class="TitleIcon">§</span><strong class="TitleText"><%=name %></strong></div>
        <div class="LiveCasinoBox_Content">
                <div class="AdditionalGame <%=haveInfo ? "AdditionalInfo" : string.Empty %>">
                    <%if (isNew)
                      { %>
                        <span class="GTnew">New</span>
                    <%} %>

                    <%if (fpp > 0)
                      { %>
                        <span class="GTfpp" title="<%=fpp %>">€</span>
                    <%} %>

                    <%if (haveInfo)
                      { %>
                        <div class="AdditionalContent">
                        <ul class="game_info">
                            <li class="Odd"><span class="MTitle">Status:</span> <span class="MText">Online</span></li>
                            <li class="Even"><span class="MTitle">Limit:</span> <span class="MText">50-2000</span></li>
                            <li class="Odd"><span class="MTitle">Open:</span> <span class="MText">00:00-11:59</span></li>
                            <li class="Even"><span class="MTitle">Dealer:</span> <span class="MText">Olympia</span></li>
                        </ul>
                        </div>
                    <%} %>
                </div>
        </div>
        <div class="LiveCasinoBox_Button">
            <%: Html.LinkButton(this.GetMetadata(".PlayNow"), new { @onclick = "return openLivedealer('"+slug+"');", @class = "button", @href="#" })%>
        </div>
        <%--                        <div class="container">
                            <%: Html.H3(name, new { @class="game_name" })%>
                            <div class="game_info">
                            <%=image.HtmlEncodeSpecialCharactors() %>
                            </div>
                            <div class="game_button" align="center">
                            <%: Html.LinkButton(this.GetMetadata(".PlayNow"), new { @onclick = "return openLivedealer('"+slug+"');", @class = "button_view_table" })%>
                            </div>
                        </div>--%>
    </li>
    <%  } %>
</ol>
<%}%>
<%--<ol>
<%
    string[] paths = Metadata.GetChildrenPaths("/Metadata/LiveDealer/");

    string title, image, slug, name;
    
    foreach (string path in paths)
    {
        title = this.GetMetadata(path + ".Title");
        image = this.GetMetadata(path + ".Image");
        slug = this.GetMetadata(path + ".Slug").DefaultIfNullOrEmpty("").Trim();
        
        name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
        %>
        <li class="live_casino_game live_dealer_game" data-type="<%= name%>">
            <div class="container">
                <%: Html.H3(title, new { @class="game_name" })%>
                <div class="game_info">
                <%=image.HtmlEncodeSpecialCharactors() %>
                </div>
                <div class="game_button" align="center">
                <%: Html.LinkButton(this.GetMetadata(".PlayNow"), new { @onclick = "return openLivedealer('"+slug+"');", @class = "button_view_table" })%>
                </div>
            </div>
        </li>
        <%
    }
 %>
</ol>--%>
<script type="text/javascript">
 function openLivedealer(slug)
    {
    <% if (!Profile.IsAuthenticated)
    { %>
            $('iframe.CasinoHallDialog').remove();
            $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Casino/Hall/Dialog?_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo(top.document.body);
            var $iframe = $('iframe.CasinoHallDialog', top.document.body).eq(0);
            $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
        //alert('<%= this.GetMetadata(".Anonymous_Message").SafeJavascriptStringEncode() %>');
            return false;
    <% }%>
        if(slug && slug.length>0)
        {
        window.open('/Casino/Game/Play/'+ slug +'?realMoney=True', 'newWindow', "status=0,toolbar=0,menubar=0,location=0,width=800,height=600");
        }
        else
        {
        
        }
        return false;        
    }
</script>
