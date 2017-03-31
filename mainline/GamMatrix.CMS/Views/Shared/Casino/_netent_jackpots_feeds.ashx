<%@ WebHandler Language="C#" Class="_netent_jackpots_feeds" %>

using System;
using System.Linq;
using System.Web;
using System.Text;
using CM;
using Casino;
using GmCore;
using GamMatrixAPI;
using System.Globalization;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;

using System.Text.RegularExpressions;

public class _netent_jackpots_feeds : IHttpHandler
{

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/xml";
        string currency = context.Request.QueryString["Currency"].DefaultIfNullOrEmpty("EUR");
        StringBuilder xml = new StringBuilder();
        xml.AppendLine("<?xml version=\"1.0\" ?>");
        xml.AppendLine("<jackpots>");
        try
        {
            // cached by GameManager.GetJackpots 
            List<JackpotInfo> games = GameManager.GetJackpots(currency);
            Game game = null;
            foreach (JackpotInfo jackpot in games)
            {
                foreach (GameID gameID in jackpot.Games)
                {
                    game = gameID.GetGame();
                    if (game == null) continue;
                    xml.AppendFormat("\t<jackpot id=\"{0}\" currency=\"{1}\" amount=\"{2:N2}\" gameid=\"{3}\" gameName=\"{4}\"  />"
                        , jackpot.ID.SafeHtmlEncode()
                        , jackpot.Currency.SafeHtmlEncode()
                        , jackpot.Amount.ToString("N2").SafeHtmlEncode()
                        , game.ID.SafeHtmlEncode()
                        , game.Title.SafeHtmlEncode()
                        );
                }
            }
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
            xml.AppendLine("<error>");
          //  xml.AppendLine(ex.ToString().SafeHtmlEncode());
            xml.AppendLine("</error>");
        }
        xml.AppendLine("</jackpots>");
        context.Response.Write(xml.ToString());
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}