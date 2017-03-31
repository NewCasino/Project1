using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;

using CE.db;
using CE.Integration.Metadata;
using CE.Utils;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public partial class XmlFeedsController : ServiceControllerBase
    {

        [HttpGet]
        public ContentResult GameInfo(string apiUsername, string gameID, string language)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;

            Dictionary<string, ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domain.DomainID);
            ceCasinoGameBaseEx game = null;
            games.TryGetValue(gameID, out game);

            try
            {
                if (game == null)
                    throw new HttpException(404, "Game is not available!");

                language = GetISO639LanguageCode(language);

                string cacheKey = string.Format("XmlFeedsController.GameInfo.{0}.{1}.{2}"
                    , DomainManager.CurrentDomainID
                    , gameID
                    , language
                    );
                StringBuilder sb = HttpRuntime.Cache[cacheKey] as StringBuilder;
                if (sb == null)
                {
                    sb = GetMetadataGameInfo(domain, game, language);
                    if (sb == null)
                    {
                        switch (game.VendorID)
                        {
                            case VendorID.GreenTube:
                                sb = GetGreenTubeGameInfo(game, language);
                                break;
                            default:
                                break;
                        }
                    }
                    if (sb != null)
                        HttpRuntime.Cache.Insert(cacheKey
                            , sb
                            , null
                            , DateTime.Now.AddMinutes(10)
                            , Cache.NoSlidingExpiration
                            );
                }
                return WrapResponse(ResultCode.Success, string.Empty, sb);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        private StringBuilder GetMetadataGameInfo(ceDomainConfigEx domain, ceCasinoGameBaseEx game, string lang)
        {
            var gameInformation = CasinoGame.GetGameInformation(domain, game.ID, string.IsNullOrWhiteSpace(lang) ? "en" : lang);
            if (string.IsNullOrWhiteSpace(gameInformation))
                return null;

            var md = new MarkdownDeep.Markdown
            {
                SafeMode = false,
                ExtraMode = true,
                AutoHeadingIDs = false,
                MarkdownInHtml = true,
                NewWindowForExternalLinks = true
            };
            var html = md.Transform(gameInformation.Replace("<", "&lt;").Replace(">", "&gt;"));

            var sb = new StringBuilder();
            sb.Append("<topics>");

            sb.Append("<topic>");

            sb.AppendFormat(CultureInfo.InvariantCulture, "<id>{0}</id>", game.ID);
            sb.AppendFormat(CultureInfo.InvariantCulture, "<description>{0}</description>", game.GameName.SafeHtmlEncode());

            {
                sb.Append("<articles>");
                sb.AppendFormat(CultureInfo.InvariantCulture, "<id>{0}</id>", game.ID);
                sb.AppendFormat(CultureInfo.InvariantCulture, "<title>{0}</title>", game.GameName.SafeHtmlEncode());
                sb.AppendFormat(CultureInfo.InvariantCulture, "<content>{0}</content>", html.SafeHtmlEncode());
                sb.Append("</articles>");
            }

            sb.Append("</topic>");

            sb.Append("</topics>");
            return sb;
        }

        private StringBuilder GetGreenTubeGameInfo(ceCasinoGameBaseEx game, string lang)
        {
            if (string.IsNullOrWhiteSpace(lang))
                lang = "EN";

            string cacheKey = string.Format("XmlFeedsController.GetGreenTubeGameInfo.{0}.{1}"
                , DomainManager.CurrentDomainID
                , lang
                );

            Dictionary<string, List<Topic>> dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, List<Topic>>;
            if (dic == null)
            {
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    GreenTubeAPIRequest request = new GreenTubeAPIRequest()
                    {
                        ArticlesGetRequest = new GreentubeArticlesGetRequest()
                        {
                            LanguageCode = lang.ToUpperInvariant()
                        }
                    };
                    request = client.SingleRequest<GreenTubeAPIRequest>(DomainManager.CurrentDomainID, request);
                    if (request.ArticlesGetResponse.ErrorCode < 0)
                        throw new Exception(request.ArticlesGetResponse.Message.Description);

                    if (request.ArticlesGetResponse.Topic != null &&
                        request.ArticlesGetResponse.Topic.Count > 0)
                    {
                        dic = new Dictionary<string, List<Topic>>(StringComparer.InvariantCultureIgnoreCase);
                        foreach (Topic topic in request.ArticlesGetResponse.Topic)
                        {
                            List<Topic> topics = null;
                            if (!dic.TryGetValue(topic.GameId.ToString(), out topics))
                            {
                                topics = new List<Topic>();
                                dic[topic.GameId.ToString()] = topics;
                            }

                            topics.Add(topic);
                        }
                        HttpRuntime.Cache.Insert(cacheKey, dic, null, DateTime.Now.AddMinutes(20), Cache.NoSlidingExpiration);
                    }
                }
            }

            List<Topic> found = null;
            if (dic != null &&
                dic.TryGetValue(game.GameID, out found))
            {
                StringBuilder sb = new StringBuilder();
                sb.Append("<topics>");

                foreach (Topic t in found)
                {
                    sb.Append("<topic>");

                    sb.AppendFormat(CultureInfo.InvariantCulture, "<id>{0}</id>", t.Id);
                    sb.AppendFormat(CultureInfo.InvariantCulture, "<description>{0}</description>", t.Description.SafeHtmlEncode());

                    {
                        sb.Append("<articles>");
                        foreach (Article article in t.ArticleList)
                        {
                            sb.AppendFormat(CultureInfo.InvariantCulture, "<id>{0}</id>", article.Id);
                            sb.AppendFormat(CultureInfo.InvariantCulture, "<title>{0}</title>", article.Title.SafeHtmlEncode());
                            sb.AppendFormat(CultureInfo.InvariantCulture, "<content>{0}</content>", article.Content.SafeHtmlEncode());
                        }
                        sb.Append("</articles>");
                    }

                    sb.Append("</topic>");
                }

                sb.Append("</topics>");
                return sb;
            }

            // if the translation is not found, try to search in English
            if (!string.Equals(lang, "en", StringComparison.InvariantCultureIgnoreCase))
            {
                return GetGreenTubeGameInfo(game, "en");
            }

            return null;
        }

        private string GetISO639LanguageCode(string lang)
        {
            if (string.IsNullOrWhiteSpace(lang))
                return "en";

            switch (lang.Truncate(2).ToLowerInvariant())
            {
                case "he": return "iw";
                case "ka": return "en";
                case "bg": return "en";
                default: return lang.ToLowerInvariant();
            }
        }

        private string Download(string url)
        {
            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.Method = "GET";
            using (HttpWebResponse resp = (HttpWebResponse)(request.GetResponse()))
            using (Stream stream = resp.GetResponseStream())
            using (StreamReader sr = new StreamReader(stream))
            {
                return sr.ReadToEnd();
            }
        }


    }
}