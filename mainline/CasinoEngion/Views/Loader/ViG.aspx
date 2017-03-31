<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        string baseGameUrl = mobileDevice ? Domain.GetCfg(ViG.MobileGameBaseURL) : Domain.GetCfg(ViG.GameBaseURL);
        string siteId = string.Format("EM{0}", Model.DomainID);

        StringBuilder url = new StringBuilder(baseGameUrl);
        url.AppendFormat("?siteID={0}&language={1}", siteId, Language);

        if (!FunMode)
        {
            Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
            ceLiveCasinoTableBaseEx table;
            if (!tables.TryGetValue(TableID, out table))
                throw new CeException("Invalid table id [{0}]", TableID);

            string tableId = string.Empty;
            string limitId = string.Empty;

            var tableDataDictionary = GetTableData(table.LaunchParams);
            
            List<NameValue> addParams = new List<NameValue> {};

            if (tableDataDictionary.TryGetValue("tableId", out tableId))
            {
                addParams.Add(new NameValue {Name = "table", Value = tableId});
            }
            else
            {
                throw new ApplicationException(String.Format("Launch params not set, or set in invalid format: {0}", table.LaunchParams));
            }

            if (tableDataDictionary.TryGetValue("limitId", out limitId))
            {
                addParams.Add(new NameValue { Name = "limitname", Value = limitId });
            }           

            TokenResponse responseToken = GetToken(addParams);
            url.AppendFormat("&OTP={0}", responseToken.TokenKey);
        }

        var startUrl = url.ToString();
        this.LaunchUrl = startUrl;

        if (mobileDevice)
        {
            Response.Redirect(startUrl);
        }
    }

    private Dictionary<string, string> GetTableData(string launchParams)
    {
        var tableDictionary = launchParams.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(value => value.Split('=')).Select(CheckParam)
                    .ToDictionary(split => split[0], split => split[1]);

        return tableDictionary;
    }

    private string[] CheckParam(string[] param)
    {
        if (param[0].Contains("\n"))
        {
            param[0] = Regex.Replace(param[0], "\\r?\\n", "");
            return param;
        }
        return param;
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= this.Language %>">
<head>
    <title><%= this.Model.GameName.SafeHtmlEncode()%></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="keywords" content="<%= this.Model.Tags.SafeHtmlEncode() %>" />
    <meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" />
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="content-language" content="<%= this.Language %>" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
            overflow: hidden;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>
</head>
<body>
    
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(ViG.CELaunchInjectScriptUrl) %>

</body>
</html>
