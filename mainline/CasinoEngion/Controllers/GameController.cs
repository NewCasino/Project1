using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;
using CE.db;
using CE.Integration.Metadata;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public class GameController : Controller
    {
        public ActionResult Information(long domainID, string id, string language)
        {
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
            {
                this.ViewData["ErrorMessage"] = "Invalid Url Parameter(s)!";
                return this.View("Error");
            }

            Dictionary<string, ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domain.DomainID);
            ceCasinoGameBaseEx game = null;
            if (!games.TryGetValue(id, out game))
            {
                this.ViewData["ErrorMessage"] = "Error, cannot find the game!";
                return this.View("Error");
            }

            language = GetISO639LanguageCode(language);

            var gameInformation = CasinoGame.GetGameInformation(domain, game.ID, string.IsNullOrWhiteSpace(language) ? "en" : language);
            if (!string.IsNullOrWhiteSpace(gameInformation))
            {
                var md = new MarkdownDeep.Markdown
                {
                    SafeMode = false,
                    ExtraMode = true,
                    AutoHeadingIDs = false,
                    MarkdownInHtml = true,
                    NewWindowForExternalLinks = true
                };
                var html = md.Transform(gameInformation.Replace("<", "&lt;").Replace(">", "&gt;"));
                this.ViewData["Domain"] = domain;
                this.ViewData["Language"] = language;
                this.ViewData["Html"] = html;
                return this.View("MetadataInfo", game);
            }

            switch (game.VendorID)
            {
                case VendorID.NetEnt:
                    this.ViewData["Domain"] = domain;
                    this.ViewData["Language"] = language;
                    return this.View("NetEntInfo", game);

                case VendorID.GreenTube:
                    try
                    {
                        //DomainManager.CurrentDomainID = domainID;
                        //var sb = GetGreenTubeGameInfo(game, language);
                        //var root = XDocument.Parse(sb.ToString());
                        //var descriptionElement = root.Elements("topics").Elements("topic").Elements("description").FirstOrDefault();
                        //var contentElement = root.Elements("topics").Elements("topic").Elements("articles").Elements("content").FirstOrDefault();
                        //if (descriptionElement == null || contentElement == null)
                        //    throw new Exception("The content is not available now");
                        //this.ViewData["Description"] = descriptionElement.Value;
                        //this.ViewData["Content"] = contentElement.Value;
                        this.ViewData["Domain"] = domain;
                        this.ViewData["Language"] = language;
                        return this.View("GreenTubeInfo", game);
                    }
                    catch
                    {
                        this.ViewData["ErrorMessage"] = "The content is not available now";
                        return this.View("Error");
                    }

                default:
                    this.ViewData["ErrorMessage"] = "The content is not available now";
                    return this.View("Error");
            }
        }

        public ActionResult Error(string code, string locale, string data = null)
        {
            ViewData["ErrorCode"] = code;
            ViewData["ErrorLanguage"] = locale;
            ViewData["ErrorMessage"] = data;

            return View("Error");
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

    }
}
