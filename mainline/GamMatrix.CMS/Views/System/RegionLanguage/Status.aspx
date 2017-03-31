<%@ Page Title="Region and Language" Language="C#" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Controllers.System.RegionLanguageParam>" %>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
    private static List<string> unTranslatedFileList = new List<string>();
    private static List<string> translateWords = new List<string>();
    private static List<string> allwords = new List<string>();
    private static int styleIndex = 0;
    private static int fileCount = 0;
    private static List<LanguageInfo> la = new List<LanguageInfo>();
    private static List<int> fileCounts = new List<int>();
    private static List<string> allFiles = new List<string>();
    private static int totalWordNumber = 0;
    private static List<int> wordNumberList = new List<int>();
    private static string sharedPath = "";
    private static string cacheKey = "";
    private static string DistinctName = "";
    private static string TemplateDomainDistinctName = "Shared";
    private static string[] discardKeys = new string[]{
            ".Url", 
            ".Image",
            "_Image",
            ".RouteName",
            ".CssClass",
            ".InlineCSS",
            ".Target",
            ".Flash",
            ".Link",
            "_Url",
            ".Symbol",
            ".Logo",
            ".BackgroundImage",
            ".UrlMatchExpression",
            ".Bonus_Code_TermsConditionsUrl",
            ".EnableBonusCodeInput",
            ".EnableBonusSelector",
            "Metadata\\Country",
            "Metadata\\Regions",
            "Metadata\\Casino\\",
            "Metadata\\Casino\\Games",
            "Metadata\\GmCoreErrorCodes",
            "Metadata\\Settings"  
        };
    private static List<LanguageInfo> PrepareLanguages()
    {
        List<LanguageInfo> la = new List<LanguageInfo>();
        if (!string.IsNullOrEmpty(DistinctName))
        {
            la = MultilingualMgr.LoadFromFile(DistinctName).ToList<LanguageInfo>();
        }
        if (la.Count < 1)
        {
            var cultures = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
               .Where(r => Regex.IsMatch(r.Name, @"^([a-z]{2}(\-[a-z]{2})?)$", RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant))
               .OrderBy(r => r.DisplayName)
               .Select(r => new { @Name = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), @LanguageCode = r.Name.ToLowerInvariant(), r.NativeName })
               .ToArray();
            for (int i = 0; i < cultures.Length; i++)
            {
                LanguageInfo lan = new LanguageInfo();
                lan.DisplayName = cultures[i].Name;
                lan.LanguageCode = cultures[i].LanguageCode;
                lan.CountryFlagName = cultures[i].NativeName;
                la.Add(lan);
            }
        }
        return la;
    }
    private static bool CheckPathFilter(string path)
    {

        if (path.Substring(path.Length - 3, 3) == ".en") return false;
        for (int i = 0; i < discardKeys.Length; i++)
        {
            if (path.IndexOf(discardKeys[i]) > 0)
            {
                return false;
            }
        }
        return true;
    }
    private static List<int> getDefaultCountList()
    {
        translateWords.Clear();
        unTranslatedFileList.Clear();
        List<int> fc = new List<int>();
        for (int i = 0; i < la.Count + 1; i++)
        {
            fc.Add(0);
            translateWords.Add("");
            unTranslatedFileList.Add("");
        }
        return fc;
    }
    private static int getMaxValue(List<int> vals)
    {
        try
        {
            int p = 0;
            for (int i = 0; i < vals.Count; i++)
            {
                p = p < vals[i] ? vals[i] : p;
            }
            return p;
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
            return 0;
        }
    }
    private static string GetAllDirList(string strBaseDir)
    {
        string Tempstr = "";
        DirectoryInfo di = new DirectoryInfo(strBaseDir);
        DirectoryInfo[] diA = di.GetDirectories();
        for (int i = 0; i < diA.Length; i++)
        {
            foreach (FileInfo NextFile in diA[i].GetFiles())
            {
                if (CheckPathFilter(NextFile.FullName))
                {
                    if (NextFile.Name.Split('.').Length < 3 && NextFile.Name.Split('.')[0] == "")
                    {
                        fileCount++;
                    }
                    Tempstr = GetOldPath(NextFile.FullName);
                }
            }
            GetAllDirList(diA[i].FullName);
        }
        return Tempstr;
    }
    private static string GetOldPath(string newPath)
    {
        if (fileCounts.Count <= 0)
        {
            fileCounts = getDefaultCountList();
        }
        if (newPath.IndexOf(sharedPath) != -1)
        {
            for (int i = 0; i < la.Count; i++)
            {
                string LangStr = "." + la[i].LanguageCode;

                if (newPath.Substring(newPath.Length - LangStr.Length, LangStr.Length) == LangStr)
                {

                    fileCounts[i]++;
                }

            }
        }
        return newPath;
    }

    private static void GetAllFiles(string strBaseDir)
    {
        DirectoryInfo di = new DirectoryInfo(strBaseDir);
        DirectoryInfo[] diA = di.GetDirectories();
        for (int i = 0; i < diA.Length; i++)
        {
            foreach (FileInfo NextFile in diA[i].GetFiles())
            {
                if (CheckPathFilter(NextFile.FullName))
                {
                    if (NextFile.Name.Split('.').Length < 3 && NextFile.Name.Split('.')[0] == "")
                    {
                        allFiles.Add(NextFile.FullName);
                    }
                }
            }
            GetAllFiles(diA[i].FullName);
        }
    }

    private static string RemoveSpecialTag(string oldstr)
    {
        string newstr = Regex.Replace(oldstr, @"<\/?[^>]+>", "", RegexOptions.IgnoreCase);
        newstr = Regex.Replace(newstr, @"\[metadata:\w+\(\w*\/*\w*\.{1}\w+\)\]", "", RegexOptions.IgnoreCase);
        newstr = newstr.Replace("&(quot|amp|lt|gt|nbsp|#34|#38|#60|#62|#160);", " ");
        newstr = newstr.Replace("\r\n", " ");
        newstr = Regex.Replace(newstr, @"[,.;:?'\""!=\+_`~\(\)\[\]{}\/\|«»#€$%▼►-]+", " ", RegexOptions.IgnoreCase);
        newstr = Regex.Replace(newstr, @"\d+", "", RegexOptions.IgnoreCase);
        
        return newstr.Trim();
    }

    private static int GetTotalWordNum(List<string> allFiles)
    {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < allFiles.Count(); i++)
        {
            using (StreamReader reader = new StreamReader(new FileStream(allFiles[i], FileMode.Open)))
            {
                //sb.Append(reader.ReadToEnd());
                string tempstr = string.Empty;
                while ((tempstr = reader.ReadLine()) != null)
                {
                    sb.Append(RemoveSpecialTag(tempstr.ToLowerInvariant()) + " ");
                }
            }
        }

        int total = 0;
        if (sb.Length > 0)
        {
            //var sbContent = RemoveSpecialTag(sb.ToString().ToLowerInvariant());

            allwords = sb.ToString().Split(' ').Where(f => f != "").ToList<string>();

            total = allwords.Count();
        }

        return total;
    }

    private static void GetTranslateWordNum(List<string> allFiles)
    {
        for (int i = 0; i < la.Count; i++)
        {
            string LangStr = "." + la[i].LanguageCode;
            StringBuilder sbTranslatedWords = new StringBuilder();
            StringBuilder sbUntranslatedFiles = new StringBuilder();
            for (int j = 0; j < allFiles.Count; j++)
            {
                if (File.Exists(allFiles[j] + LangStr))
                {
                    using (StreamReader reader = new StreamReader(new FileStream(allFiles[j], FileMode.Open)))
                    {
                        string tempstr = string.Empty;
                        while ((tempstr = reader.ReadLine()) != null)
                        {
                            sbTranslatedWords.Append(RemoveSpecialTag(tempstr.ToLowerInvariant()) + " ");
                        }
                    }
                }
                else
                {
                    sbUntranslatedFiles.Append(allFiles[j] + "<br />");
                }
            }

            unTranslatedFileList[i] = sbUntranslatedFiles.ToString();

            if (sbTranslatedWords.Length > 0)
            {
                List<string> tempTranslatedWordList = sbTranslatedWords.ToString().Split(' ').Where(f => f != "").ToList<string>();

                StringBuilder sbTempTranslatedWords = new StringBuilder();

                foreach (var tempitem in tempTranslatedWordList)
                {
                    sbTempTranslatedWords.Append(tempitem + " ");
                }
                translateWords[i] = sbTempTranslatedWords.ToString();
                wordNumberList[i] = tempTranslatedWordList.Count();
            }
        }
    }
</script>
<style type="text/css">
    .region-languages-table tbody tr td
    {
        min-height: 20px;
        text-align: center;
    }

    .region-languages-table tr .col-1
    {
        text-align: left;
        padding-left: 10px;
    }

    .region-languages-table tbody tr
    {
        background-color: #D9E8F4;
    }

    .region-languages-table tbody .alternate-row
    {
        background-color: #A8CAE6;
        width: 70px;
    }
</style>
<%
    if (this.Model != null && this.Model.DistinctName != null)
    {
        DistinctName = this.Model.DistinctName.DefaultDecrypt();
        var sites = SiteManager.GetSites().Where(b => b.DistinctName == DistinctName).Select(o => new { TemplateDomainDistinctName = o.TemplateDomainDistinctName }).ToArray();
        if (sites.Length > 0)
        {
            TemplateDomainDistinctName = sites[0].TemplateDomainDistinctName.ToString();
        }
    }
    la = PrepareLanguages();
    //fileCounts = getDefaultCountList();
    wordNumberList = getDefaultCountList();
    TemplateDomainDistinctName = (TemplateDomainDistinctName == "Shared" || TemplateDomainDistinctName == "MobileShared") ? TemplateDomainDistinctName : "Shared";
    sharedPath = @"" + System.Web.HttpContext.Current.Request.MapPath("/").ToString() + @"Views\" + TemplateDomainDistinctName;
    //cacheKey = "System_TranslationStatus_Desktop_" + (string.IsNullOrEmpty(DistinctName) ? TemplateDomainDistinctName : DistinctName);
    cacheKey = "System_TranslationNumber_Desktop_" + (string.IsNullOrEmpty(DistinctName) ? TemplateDomainDistinctName : DistinctName);
    
    List<int> cache = HttpRuntime.Cache[cacheKey] as List<int>;

    //if (cache != null && cache.Count > 0)
    //{
    //    fileCounts = cache;
    //    fileCount = getMaxValue(cache);
    //}
    //else
    //{
    //    HttpRuntime.Cache.Remove(cacheKey);
    //    GetAllDirList(sharedPath);
    //    if (DistinctName != "Shared" && DistinctName != "MobileShared")
    //    {
    //        sharedPath = @"" + System.Web.HttpContext.Current.Request.MapPath("/").ToString() + @"Views\" + DistinctName;
    //        GetAllDirList(sharedPath);
    //    }
    //    HttpRuntime.Cache.Insert(cacheKey, fileCounts, null, Cache.NoAbsoluteExpiration, TimeSpan.FromSeconds(180));
    //} 

    //if (cache != null && cache.Count > 0)
    //{
    //    fileCounts = cache;
    //    fileCount = getMaxValue(cache);
    //}
    //else
    //{
        HttpRuntime.Cache.Remove(cacheKey);
        
        if (DistinctName != "Shared" && DistinctName != "MobileShared")
        {
            sharedPath = @"" + System.Web.HttpContext.Current.Request.MapPath("/").ToString() + @"Views\" + DistinctName;
        }

        allFiles.Clear();
        GetAllFiles(sharedPath);
        totalWordNumber = GetTotalWordNum(allFiles);
        GetTranslateWordNum(allFiles);
        HttpRuntime.Cache.Insert(cacheKey, fileCounts, null, Cache.NoAbsoluteExpiration, TimeSpan.FromSeconds(180));
    //} 
%>
<div id="language-links">
<ul>
    <li id="trans-refresh"><a class="refresh" target="_self" href="javascript:void(0)">Refresh</a></li>
</ul>
</div>
<hr class="seperator">
<a href="javascript:void(0)" name="desktop"></a>

<table cellpadding="0" cellspacing="0" class="table-list region-languages-table "
    border="0" name="desktop">
    <thead>
        <tr>
            <th class="col-1">Language</th>
            <th class="col-2">Translated Word Count</th>
            <th class="col-3">Total Word Count</th>
            <th class="col-4">Translated Percentage</th>
            <th class="col-5"></th>
            <th class="col-6"></th>
            <th class="col-7">Package</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td class="col-1">EngLish</td>
            <td class="col-2">
            </td>
            <td class="col-3">
                <%=totalWordNumber %></td>
            <td class="col-4"></td>
            <td class="col-5"></td>
            <td class="col-6"></td>
            <td class="col-7"></td>
        </tr>
        <%  
        for (int i = 0; i < la.Count; i++)
        {
            //if (fileCounts[i] > 173)
            //{
                styleIndex++;
        %>
        <tr class="<%= styleIndex %2 !=0 ? "alternate-row" : "" %>">
            <td class="col-1">
                <%=la[i].DisplayName   %>(<%=la[i].CountryFlagName   %>)
            </td>
            <td class="col-2">
                <%=wordNumberList[i] %>
            </td>
            <td class="col-3">
                <%=totalWordNumber %>
            </td>
            <td class="col-4">
                <% =(Convert.ToDouble(wordNumberList[i]) / Convert.ToDouble(totalWordNumber)).ToString("0.00%")%>
            </td>
            <td class="col-5">
            </td>
            <td class="col-6">
                
            </td>
            <td class="col-7"><a href="/RegionLanguage/CreatePackage/<%= DistinctName.DefaultEncrypt() %>/<%=la[i].LanguageCode %>"
                target="_blank">Download</a>&nbsp;&nbsp;
                <a href="/RegionLanguage/CreatePackage/<%= DistinctName.DefaultEncrypt() %>/<%=la[i].LanguageCode %>/1" target="_blank">translated package to download</a>
            </td>
        </tr>
        <%  
                //}
            }
        styleIndex = 0;
        fileCount = 0;
        fileCounts.Clear();

        %>
    </tbody>
</table>
<script>
    $(function () {
        $("#trans-refresh").click(function () {
            LoadTransList();
        });
    });
</script>
 
