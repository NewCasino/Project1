<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        try
        {
            var game = this.Model;
            var language = this.ViewData["Language"].ToString();
            var domain = (ceDomainConfigEx)this.ViewData["Domain"];
            DomainManager.CurrentDomainID = domain.DomainID;
            var sb = GetGreenTubeGameInfo(game, language);
            var root = XDocument.Parse(sb.ToString());
            var descriptionElement = root.Elements("topics").Elements("topic").Elements("description").FirstOrDefault();
            var contentElement = root.Elements("topics").Elements("topic").Elements("articles").Elements("content").FirstOrDefault();
            this.ViewData["Description"] = descriptionElement.Value;
            this.ViewData["Content"] = contentElement.Value;
        }
        catch
        {
            this.ViewData["Content"] = "The content is not available now";
        }
        base.OnInit(e);
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


</script>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title><%=this.ViewData["Description"] %></title>
    <link type="text/css" href="<%= Url.Content("~/css/game_information.css") %>" rel="stylesheet" />
</head>
<body>
    <h1><%= this.ViewData["Description"] %></h1>
    <%= ViewData["Content"] %>
    <p style="clear: both;">
        <button onclick="self.close();" style="float: right;">Close</button>
    </p>
</body>
</html>
