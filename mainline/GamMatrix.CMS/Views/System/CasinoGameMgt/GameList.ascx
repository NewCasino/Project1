<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CasinoEngine" %>
<script language="C#" runat="server" type="text/C#">
private string ConvertToCommaSeperatedString(IEnumerable array)
{
    StringBuilder sb = new StringBuilder();
    foreach (object val in array)
    {
        if (sb.Length > 0) sb.Append(" , ");
        sb.Append(val.ToString());
    }
    return sb.ToString();
}
</script>


<%
    Dictionary<string,Game> games = CasinoEngineClient.GetGames(this.Model, false);

    foreach (var item in games)
    {
        if (!Regex.IsMatch(item.Key, @"^(\d+)$", RegexOptions.Compiled))
            continue;

        Game game = item.Value;
        if (game.VendorID != (VendorID)this.ViewData["VendorID"])
            continue;
         %>
         
    <table cellpadding="5" cellspacing="0" border="0" class="game-table">
        <thead>
            <tr>
                <th colspan="3" align="left">
                    <%= game.EnglishShortName.SafeHtmlEncode() %>
                    <a class="dialog-link" href="<%= this.Url.RouteUrl( "CasinoGameMgt", new { @action = "EditGameTranslation", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @gameID = game.ID }).SafeHtmlEncode()  %>" 
                    target="_blank" style="float:right">EDIT TRANSLATIONS...</a>
                </th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td colspan="3" align="left">
                    <%= game.EnglishDescription.SafeHtmlEncode() %>
                </td>
            </tr>
        </tbody>
        <tfoot>
            <tr>
                <td valign="top">
                    <ul class="game-attributes">
                        <li><strong>Name</strong> : <%= game.EnglishName.SafeHtmlEncode() %></li>
                        <li><strong>ID</strong> : <%= game.ID.SafeHtmlEncode() %></li>
                        <li><strong>Vendor</strong> : <%= game.VendorID.ToString().SafeHtmlEncode() %></li>
                        <li><strong>Categories</strong> : <%= ConvertToCommaSeperatedString(game.Categories).SafeHtmlEncode() %></li>

                        <li><strong>Free Play Mode</strong> : <%= game.IsFunModeEnabled ? "Enabled" : "<span style=\"color:red\">Disabled</span>" %></li>
                        <li><strong>Real Money Mode</strong> : <%= game.IsRealMoneyModeEnabled ? "Enabled" : "<span style=\"color:red\">Disabled</span>" %></li>
                        <li><strong>New Game</strong> : <%= game.IsNewGame ? "<span style=\"color:red\">Yes</span>" : "No"%></li>
                        <li><strong>Jackpot Game</strong> : <%= game.IsJackpotGame ? "<span style=\"color:red\">Yes</span>" : "No"%></li>
                        <li><strong>Platforms</strong> : <%= ConvertToCommaSeperatedString(game.Platforms).SafeHtmlEncode() %></li>
                        <li><strong>Tags</strong> : <%= ConvertToCommaSeperatedString(game.Tags).SafeHtmlEncode() %></li>
                        <li><strong>Restricted Territories</strong> : <%= ConvertToCommaSeperatedString(game.RestrictedTerritories).SafeHtmlEncode() %></li>
                    </ul>
                </td>
                <td align="center" valign="top" style="width:130px; background-color:#93BEE1; ">
                    Logo<br />
                    <img width="120" height="120" src="<%= game.LogoUrl.SafeHtmlEncode() %>" />
                </td>
                <td align="center" valign="top" style="width:130px">
                    Thumbnail<br />
                    <img width="120" height="70" src="<%= game.ThumbnailUrl.SafeHtmlEncode() %>" />
                </td>
            </tr>
        </tfoot>
    </table>

<% } %>


