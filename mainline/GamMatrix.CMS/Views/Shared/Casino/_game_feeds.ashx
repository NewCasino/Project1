<%@ WebHandler Language="C#" Class="_game_feeds" %>

using System;
using System.Collections.Generic;
using System.Web;
using System.Linq;
using System.Text;
using CM.Content;

using Casino;
using GamMatrixAPI;
using CM.State;

public class _game_feeds : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {

        ProfileCommon.Current.Init(context);
        StringBuilder xml = new StringBuilder();
        xml.AppendLine("<?xml version=\"1.0\" ?>");
        xml.AppendLine("<categories>");

        List<GameCategory> categories = GameManager.GetCategories();
        foreach (GameCategory category in categories)
        {
            xml.AppendFormat("<category id=\"{0}\" displayName=\"{1}\">\n", category.ID.SafeHtmlEncode(), category.GetName());

            if (category.GameRefs != null)
            {
                foreach (GameRef gameRef in category.GameRefs)
                {
                    GenerateXml(ref xml, gameRef);
                }
            }
            xml.AppendLine("</category>");
        }
            
        xml.AppendLine("</categories>");

        string xmlStr = xml.ToString();
        context.Response.Clear();
        context.Response.ContentType = "text/xml";
        context.Response.ContentEncoding = Encoding.UTF8;
        context.Response.AddHeader("Content-Length", xmlStr.Length.ToString());
        context.Response.Write(xmlStr);
        context.Response.Flush();
        context.Response.End();
    }

    private void GenerateXml(ref StringBuilder xml, GameRef gameRef)
    {
        if (gameRef.GameIDList == null )
            return;

        var games = gameRef.GameIDList.Where(g => g.VendorID == VendorID.NetEnt).ToArray();
        if (games.Length == 0)
            return;

        if (games.Length == 1)
        {
            Game game = games[0].GetGame();
            GenerateGameXml(ref xml, game);
        }
        else
        {
            xml.AppendFormat("<groupedGames id=\"{0}\" displayName=\"{1}\">\n", gameRef.ID.SafeHtmlEncode(), gameRef.GetGroupName().SafeHtmlEncode());
            foreach (GameID gameID in games)
            {
                GenerateGameXml(ref xml, gameID.GetGame());
            }
            xml.AppendLine("</groupedGames>");
        }
    }

    private void GenerateGameXml(ref StringBuilder xml, Game game)
    {
        if (game == null) return;
        xml.AppendFormat("<game displayName=\"{0}\">\n", game.Title.SafeHtmlEncode());
        xml.AppendFormat("<vendor>{0}</vendor>\n", game.VendorID.ToString());
        xml.AppendFormat("<id>{0}</id>\n", game.ID.SafeHtmlEncode());
        xml.AppendFormat("<title>{0}</title>\n", game.Title.SafeHtmlEncode());
        xml.AppendFormat("<description>{0}</description>\n", game.Description.SafeHtmlEncode());
        xml.AppendFormat("<isNewGame>{0}</isNewGame>\n", game.IsNewGame.ToString().ToLowerInvariant());
        xml.AppendFormat("<isMiniGame>{0}</isMiniGame>\n", game.IsMiniGame.ToString().ToLowerInvariant());
        xml.AppendFormat("<initialWidth>{0}</initialWidth>\n", game.InitialWidth.ToString());
        xml.AppendFormat("<initialHeight>{0}</initialHeight>\n", game.InitialHeight.ToString());
        xml.AppendFormat("<isFunModeEnabled>{0}</isFunModeEnabled>\n", game.IsFunModeEnabled.ToString().ToLowerInvariant());
        xml.AppendFormat("<thumbnail>{0}</thumbnail>\n", ContentHelper.ParseFirstImageSrc(game.Thumbnail).SafeHtmlEncode());
        xml.AppendFormat("<url>/Casino/Loader/{0}/{1}/</url>\n", HttpUtility.UrlEncode(game.VendorID.ToString()).SafeHtmlEncode(), HttpUtility.UrlEncode(game.ID).SafeHtmlEncode());
        xml.AppendFormat("<countries type=\"{0}\">", game.SupportedCountry.Type == Finance.FilteredListBase<int>.FilterType.Exclude ? "excluded" : "included");
        if (game.SupportedCountry.List != null && game.SupportedCountry.List.Count > 0)
        {
            var countries = CountryManager.GetAllCountries().Where(c => game.SupportedCountry.List.Contains(c.InternalID));
            foreach (var country in countries)
            {
                xml.AppendFormat("<iso3166Alpha2Code>{0}</iso3166Alpha2Code>\n", country.ISO_3166_Alpha2Code.SafeHtmlEncode());
            }
        }
        xml.AppendLine("</countries>");
        xml.AppendFormat("<helpUrl>{0}{1}</helpUrl>\n"
            , Settings.Casino_NetEntGameRulesBaseUrl.SafeHtmlEncode()
            , game.HelpFile.SafeHtmlEncode()
            );
        xml.AppendLine("</game>");
    } 
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}