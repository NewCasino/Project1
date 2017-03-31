<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Casino" %>
<%@ Import Namespace="GamMatrixAPI" %> 
<div id="casino-drawer-menu">
    <ul>
        <% foreach (GameCategory category in GameManager.GetCategories())

   {%>
        <li class="category" id="<%= category.ID %>"><span class="<%= category.GetName().SafeHtmlEncode().Replace(" ","_") %>"><a href="#">
            <%= category.GetName().SafeHtmlEncode() %></a></span>
            <ul class="games">
                <% 
        if (category.GameRefs != null)
        {
            int casinow2Count = 0;
            foreach (GameRef gameRef in category.GameRefs)
        
            {

                if (gameRef == null || gameRef.GameIDList == null)

                    continue;GameID [] games = gameRef.GameIDList.Where(g => g.VendorID == VendorID.NetEnt).ToArray();
                foreach ( GameID gameID in games)
                {
                    casinow2Count++;
                        Game game = gameID.GetGame();
                    if( game == null )

                        continue;
						string url = this.Url.RouteUrl("CasinoLoader", new {@action = "NetEntGame", @gameID = game.ID });%>
                <li class="game  <% if(casinow2Count % 2==0){ %>even<%} %>"><a href="<%= url.SafeHtmlEncode() %>" target="_blank" title="<%= game.Title.SafeHtmlEncode() %>">
                    <%= game.Title.SafeHtmlEncode() %></a></li>
                <%

                }

            }

        }

                %>
            </ul>
        </li>
        <% } %>
    </ul>
</div>
