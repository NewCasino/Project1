<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="Casino" %>

<%@ Import Namespace="GamMatrixAPI" %>

<%@ Import Namespace="System.Text.RegularExpressions" %>



<script language="C#" runat="server" type="text/C#">

    private string GetCategoryCssClassName(GameCategory category)

    {

        return Regex.Replace(category.EnglishName, @"[^\w]", "_", RegexOptions.Compiled);

    }

</script>



<div id="casino-game-index">

<div id="casino-game-index-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>



<div id="casino-game-index-body">



<% foreach (GameCategory category in GameManager.GetCategories())

   { %>

   <div class="section <%= GetCategoryCssClassName(category).SafeHtmlEncode() %>">

        <%: Html.H3( category.GetName() ) %>

        <ul class="games">

            <% 

            if (category.GameRefs != null)

            {

                foreach (GameRef gameRef in category.GameRefs)

                {

                    if (gameRef == null || gameRef.GameIDList == null)

                        continue;

                    GameID [] games = gameRef.GameIDList.Where(g => g.VendorID == VendorID.NetEnt).ToArray();

                    if (games.Length == 1)

                    {

                        string url = this.Url.RouteUrl("CasinoLoader", new { @action = "NetEntGame", @gameID = games[0].ID });

                        Game game = games[0].GetGame();

                        if (game != null)

                        {   %>

                            <li class="game <%= game.IsNewGame ? "newgame" : string.Empty %>">

                                <h4><a href="<%= url.SafeHtmlEncode() %>" target="_blank" title="<%= game.Title.SafeHtmlEncode() %>"><%= game.Title.SafeHtmlEncode()%></a></h4>

                            </li>

                            <%

                        }

                    }

                    else if (games.Length > 1)

                    {

                        %>

                        <li class="sub-games">

                        <%: Html.H4(gameRef.GetGroupName()) %>

                        <ul class="group-games">



                        <%

                        foreach (GameID gameID in games)

                        {

                            Game game = gameID.GetGame();

                            if (game == null)

                                continue;

                            string url = this.Url.RouteUrl("CasinoLoader", new { @action = "NetEntGame", @gameID = game.ID });

                            %>

                            <li class="game <%= game.IsNewGame ? "newgame" : string.Empty %>">

                                <h5><a href="<%= url.SafeHtmlEncode() %>" target="_blank" title="<%= game.Title.SafeHtmlEncode() %>"><%= game.Title.SafeHtmlEncode()%></a></h5>

                            </li>

                            <%

                        }

                        %>



                        </ul>

                        </li>

                        <%

                    }

                }

            }

            %>

        </ul>

   </div>

<% } %>

<div style="clear:both"></div>

</div>





<div id="casino-game-index-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors()%></div>

</div>