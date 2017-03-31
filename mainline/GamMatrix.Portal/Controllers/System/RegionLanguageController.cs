using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.Sites;
using CM.Web;
using Finance;
using FileIO = System.IO;
//<%@ Import Namespace="System.IO" %>
//<%@ Import Namespace="System.Diagnostics" %>
//<%@ Import Namespace="System.Globalization" %>

namespace GamMatrix.CMS.Controllers.System
{
    public sealed class RegionLanguageParam
    {
        public string DistinctName { get; set; }
        public IEnumerable Languages { get; set; }
        public int Translated { get; set; }
    }

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}/{countryID}/{translated}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class RegionLanguageController : ControllerEx
    {
        private static IEnumerable PrepareLanguages()
        {
            var cultures = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
               .Where(r => Regex.IsMatch(r.Name, @"^([a-z]{2}(\-[a-z]{2})?)$", RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant))
               .OrderBy(r => r.DisplayName)
               .Select(r => new { @Name = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), @LanguageCode = r.Name.ToLowerInvariant(), r.NativeName })
               .ToArray();
            return cultures;
        }

        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                var site = SiteManager.GetSiteByDistinctName(distinctName);
                if (site == null)
                    throw new ArgumentException("distinctName");

                this.ViewData["CountryFlagNames"] = new string[] {
                    "ad","ae","af","ag","ai","al","am","an","ao","ar","as","at","au","aw","ax","az","ba",
                    "bb","bd","be","bf","bg","bh","bi","bj","bm","bn","bo","br","bs","bt","bv","bw","by","bz",
                    "ca","catalonia","cc","cd","cf","cg","ch","ci","ck","cl","cm","cn","co","cr","cs","cu","cv","cx","cy","cz",
                    "de","dj","dk","dm","do","dz",
                    "ec","ee","eg","eh","england","er","es","et","europeanunion",
                    "fam","fi","fj","fk","fm","fo","fr","fr_qc",
                    "ga","gb","gd","ge","gf","gh","gi","gl","gm","gn","gp","gq","gr","gs","gt","gu","gw","gy",
                    "hk","hm","hn","hr","ht","hu",
                    "id","ie","il","in","io","iq","ir","is","it",
                    "jm","jo","jp",
                    "ke","kg","kh","ki","km","kn","kp","kr","kw","ky","kz",
                    "la","lb","lc","li","lk","lr","ls","lt","lu","lv","ly",
                    "ma","mc","md","me","mg","mh","mk","ml","mm","mn","mo","mp","mq","mr","ms","mt","mu","mv","mw","mx","my","mz",
                    "na","nc","ne","nf","ng","ni","nl","no","np","nr","nu","nz",
                    "om",
                    "pa","pe","pf","pg","ph","pk","pl","pm","pn","pr","ps","pt","pw","py",
                    "qa",
                    "re","ro","rs","ru","rw",
                    "sa","sb","sc","scotland","sd","se","sg","sh","si","sj","sk","sl","sm","sn","so","sr","st","sv","sy","sz",
                    "tc","td","tf","tg","th","tj","tk","tl","tm","tn","to","tr","tt","tv","tw","tz",
                    "ua","ug","um","us","uy","uz",
                    "va","vc","ve","vg","vi","vn","vu",
                    "wales","wf","ws",
                    "ye","yt",
                    "za","zm","zw"
                };
                this.ViewData["cmSite"] = site;

                return View(new RegionLanguageParam()
                {
                    DistinctName = distinctName,
                    Languages = PrepareLanguages(),
                }
                );
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }


        [HttpGet]
        public ActionResult Status(string distinctName)
        {
            return View("Status", new RegionLanguageParam()
            {
                DistinctName = distinctName
            });
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Save(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                int total = int.Parse(Request["total"]);
                if (total < 0)
                    throw new Exception("Error! invalid parameter [total].");

                //LanguageInfo[] languages = new LanguageInfo[total];
                //CountryLanguageInfo[] countrylanguages = new CountryLanguageInfo[total];
                //foreach (string key in Request.Form.Keys)
                //{
                //    Match match = Regex.Match(key, @"^(?<propertyName>((LanguageCode)|(CountryFlagName)|(DisplayName)|(IsExclude)|(CountryIds)))_(?<index>\d+)$", RegexOptions.Compiled);
                //    Match match1 = Regex.Match(key, @"^(?<propertyName>((LanguageCode)|(CountryFlagName)|(DisplayName)))_(?<index>\d+)$", RegexOptions.Compiled);
                //    Match match2 = Regex.Match(key, @"^(?<propertyName>((LanguageCode)|(IsExclude)|(CountryIds)))_(?<index>\d+)$", RegexOptions.Compiled);
                //    if (match.Success)
                //    {
                //        int index = int.Parse(match.Groups["index"].Value);
                //        string propertyName = match.Groups["propertyName"].Value;
                //        if (index >= total)
                //            continue;

                //        if (languages[index] == null)
                //            languages[index] = new LanguageInfo();
                //        if (countrylanguages[index] == null)
                //            countrylanguages[index] = new CountryLanguageInfo();
                //        if (match1.Success)
                //            ObjectHelper.SetFieldValue(languages[index], propertyName, Request.Form[key]);
                //        if (match2.Success)
                //        {
                //            if (propertyName == "IsExclude")
                //                ObjectHelper.SetFieldValue(countrylanguages[index], propertyName, Convert.ToBoolean(Request.Form[key]));
                //            else
                //                ObjectHelper.SetFieldValue(countrylanguages[index], propertyName, Request.Form[key]);
                //        }
                //    }

                //}

                //CheckCountryLanguages(distinctName, countrylanguages);

                //MultilingualMgr.Save(distinctName, languages);
                //MultilingualMgr.SaveCountryLanguages(distinctName, countrylanguages);

                Language[] languages = new Language[total];
                foreach (string key in Request.Form.Keys)
                {
                    //Match match = Regex.Match(key, @"^(?<propertyName>((LanguageCode)|(CountryFlagName)|(DisplayName)|(IsExclude)|(CountryIds)))_(?<index>\d+)$", RegexOptions.Compiled);
                    Match match = Regex.Match(key, @"^(?<propertyName>((LanguageCode)|(CountryFlagName)|(DisplayName)|(CountryIds)))_(?<index>\d+)$", RegexOptions.Compiled);
                    if (match.Success)
                    {
                        int index = int.Parse(match.Groups["index"].Value);
                        string propertyName = match.Groups["propertyName"].Value;
                        if (index >= total)
                            continue;

                        if (languages[index] == null)
                            languages[index] = new Language();
                        //if (propertyName == "IsExclude")
                        //    ObjectHelper.SetFieldValue(languages[index], propertyName, Convert.ToBoolean(Request.Form[key]));
                        //else
                        ObjectHelper.SetFieldValue(languages[index], propertyName, Request.Form[key]);
                    }
                }

                LanguageManager.SaveLanguages(distinctName, languages);

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetLanguages(string distinctName)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                //return this.Json(new { @success = true, @data = MultilingualMgr.LoadFromFile(distinctName) }, JsonRequestBehavior.AllowGet);
                return this.Json(new { @success = true, @data = LanguageManager.GetLanguages(distinctName) }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetCountries(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            return this.Json(new { @success = true, @data = CountryManager.GetAllCountries(distinctName).Where(c => c.InternalID > 0).ToArray() }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveCountries(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();

            List<CountryInfo> countries = CountryManager.GetAllCountries(distinctName);
            bool isSystemAdmin = CM.State.CustomProfile.Current.IsInRole("CMS System Admin");
            // internal id <--> [ fieldname <--> value ]
            Hashtable table = new Hashtable();

            foreach (string key in Request.Form.AllKeys)
            {
                Match m = Regex.Match(key, @"^Country_(?<name>\w+)_(?<id>\d+)$", RegexOptions.Compiled | RegexOptions.ECMAScript);
                if (m.Success)
                {
                    string fieldName = m.Groups["name"].Value;
                    int id = int.Parse(m.Groups["id"].Value);
                    CountryInfo country = countries.FirstOrDefault(c => c.InternalID == id);

                    Hashtable innerTable = table[id] as Hashtable;
                    if (innerTable == null)
                    {
                        innerTable = new Hashtable();
                        innerTable["RestrictRegistrationByIP"] = null;
                        innerTable["RestrictLoginByIP"] = null;
                        innerTable["UserSelectable"] = null;
                        innerTable["AdminLock"] = null;

                        innerTable["IsPersonalIdVisible"] = null;
                        innerTable["IsPersonalIdMandatory"] = null;
                        innerTable["PersonalIdValidationRegularExpression"] = null;
                        innerTable["PersonalIdMaxLength"] = 0;

                        innerTable["RestrictRegistrationByRegion"] = null;
                        innerTable["RestrictRegistrationByRegionCode"] = null;

                        table[id] = innerTable;
                    }

                    switch (fieldName)
                    {
                        case "RestrictCreditCardWithdrawal":
                        case "RestrictRegistrationByIP":
                        case "UserSelectable":
                        case "RestrictLoginByIP":
                        case "RestrictRegistrationByRegion":
                        case "IsPersonalIdVisible":
                        case "IsPersonalIdMandatory":
                            if (country.AdminLock && !isSystemAdmin)
                                innerTable[fieldName] = string.Compare(ObjectHelper.GetFieldValue(country, fieldName), "true", true) == 0;
                            else
                                innerTable[fieldName] = string.Compare(Request.Form[key], "true", true) == 0;

                            break;
                        case "AdminLock":
                            if (isSystemAdmin)
                                innerTable[fieldName] = string.Compare(Request.Form[key], "true", true) == 0;
                            else
                                innerTable[fieldName] = string.Compare(ObjectHelper.GetFieldValue(country, fieldName), "true", true) == 0;
                            break;
                        case "RestrictRegistrationByRegionCode":
                            innerTable[fieldName] = Request.Form[key].Trim();
                            break;
                        case "PersonalIdMaxLength":
                            int temp = 0;
                            int.TryParse(Request.Form[key].Trim(), out temp);
                            innerTable[fieldName] = temp;
                            break;
                        default:
                            innerTable[fieldName] = Request.Form[key];
                            break;
                    }

                }
            }

            foreach (int key in table.Keys)
            {
                Hashtable innerTable = table[key] as Hashtable;
                if (innerTable != null)
                {
                    CountryInfo country = countries.FirstOrDefault(c => c.InternalID == key);
                    if (innerTable["RestrictRegistrationByIP"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["RestrictRegistrationByIP"] = country.RestrictRegistrationByIP;
                        else
                            innerTable["RestrictRegistrationByIP"] = false;
                    }
                    if (innerTable["RestrictRegistrationByRegion"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["RestrictRegistrationByRegion"] = country.RestrictRegistrationByRegion;
                        else
                            innerTable["RestrictRegistrationByRegion"] = false;
                    }
                    if (innerTable["RestrictCreditCardWithdrawal"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["RestrictCreditCardWithdrawal"] = country.RestrictCreditCardWithdrawal;
                        else
                            innerTable["RestrictCreditCardWithdrawal"] = false;
                    }
                    if (innerTable["RestrictLoginByIP"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["RestrictLoginByIP"] = country.RestrictLoginByIP;
                        else
                            innerTable["RestrictLoginByIP"] = false;
                    }
                    if (innerTable["UserSelectable"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["UserSelectable"] = country.UserSelectable;
                        else
                            innerTable["UserSelectable"] = false;
                    }
                    if (innerTable["IsPersonalIdVisible"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["IsPersonalIdVisible"] = country.IsPersonalIdVisible;
                        else
                            innerTable["IsPersonalIdVisible"] = false;
                    }
                    if (innerTable["IsPersonalIdMandatory"] == null)
                    {
                        if (country.AdminLock && !isSystemAdmin)
                            innerTable["IsPersonalIdMandatory"] = country.IsPersonalIdMandatory;
                        else
                            innerTable["IsPersonalIdMandatory"] = false;
                    }
                    if (innerTable["AdminLock"] == null)
                    {
                        if (!isSystemAdmin)
                            innerTable["AdminLock"] = country.AdminLock;
                        else
                            innerTable["AdminLock"] = false;
                    }
                }
            }
            CountryManager.SaveCountries(Request.RequestContext, distinctName, table);

            return this.Json(new { @success = true });
        }

        private KeyValuePair<string, string>[] GetAllowedNodeTypes()
        {
            List<KeyValuePair<string, string>> types = new List<KeyValuePair<string, string>>();

            types.Add(new KeyValuePair<string, string>("Metadata", "Metadata"));

            return types.ToArray();
        }

        public ActionResult PersonalIdDetails(string distinctName, int countryID)
        {
            try
            {
                CountryInfo country = CountryManager.GetAllCountries(distinctName).FirstOrDefault(c => c.InternalID == countryID);
                if (country == null)
                    throw new ArgumentException("Error, invalid country");

                distinctName = distinctName.DefaultDecrypt();

                string path = string.Format("/Metadata/Country/PersonalID/{0}", Regex.Replace(country.ISO_3166_Name, @"[^\w_]", "_"));

                CM.db.cmSite domain = SiteManager.GetSiteByDistinctName(distinctName);
                if (domain != null)
                {
                    ContentTree contentTree = ContentTree.GetByDistinctName(domain.DistinctName, domain.TemplateDomainDistinctName, false);
                    ContentNode node;
                    if (contentTree.AllNodes.TryGetValue(path, out node))
                    {
                        this.ViewData["NodeTypes"] = this.GetAllowedNodeTypes();
                        this.ViewData["HistorySearchPattner"] = "/.%";
                        return this.PartialView("PersonalIDDetails", node);
                    }
                }
                throw new Exception("Error, invalid parameter[path].");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }


        /// <summary>
        ///  translate status & package creater
        /// </summary>
        /// <param name="distinctName"></param>
        /// <param name="countryID"></param>
        /// <returns></returns>
        [HttpGet]
        public ActionResult CreatePackage(string distinctName, string countryID, int translated = 0)
        {
            var cultures = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
               .Select(r => new { @Name = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), @LanguageCode = r.Name.ToLowerInvariant(), r.NativeName })
               .Where(r => r.LanguageCode == countryID)
               .ToArray();
            return View("CreatePackage", new RegionLanguageParam()
            {
                DistinctName = distinctName,
                Languages = cultures,
                Translated = translated
            });
        }


        private static string ShareBasicPath = "";
        private static string NewBasicPath = "";
        private static string Lang = "ro";
        private static string LangStr = "." + Lang;
        private static string copyType = "totranslate";
        private static string DistinctName = "";
        private static string TemplateDomainDistinctName = "Shared";
        private static string d = DateTime.Now.Year.ToString() + "-" + DateTime.Now.Month.ToString() + "-" + DateTime.Now.Day.ToString();
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
        private static void GetAllDirListAndCreatePackage(string strOldDir, string strBaseDir, int translated)
        {
            try
            {
                FileIO.DirectoryInfo di = new FileIO.DirectoryInfo(strOldDir);
                FileIO.DirectoryInfo[] diA = di.GetDirectories();
                for (int i = 0; i < diA.Length; i++)
                {
                    foreach (FileIO.FileInfo NextFile in diA[i].GetFiles())
                    {
                        GetAndCopyFiles(NextFile.FullName, translated);
                    }
                    GetAllDirListAndCreatePackage(diA[i].FullName, strBaseDir, translated);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        private static void GetAndCopyFiles(string path, int translated)
        {
            if (!CheckPathFilter(path))
            {
                return;
            }
            if (path.IndexOf(ShareBasicPath) != -1)
            {
                string tpath = path.Split('\\')[path.Split('\\').Length - 1];
                if (translated == 1)
                {
                    if(tpath.EndsWith(LangStr))
                    {
                        string newPath = NewBasicPath + path.Substring(ShareBasicPath.Length, path.Length - ShareBasicPath.Length);
                        if (!CheckDataforNew(path))
                        {
                            CheckAndCreateDirectory(newPath);
                            FileIO.File.Copy(path, newPath, true);
                        }
                    }
                }
                else
                {
                    if (tpath.Split('.').Length < 3 && tpath.Split('.')[0] == "")
                    {
                        string newPath = NewBasicPath + path.Substring(ShareBasicPath.Length, path.Length - ShareBasicPath.Length) + LangStr;
                        if (!CheckDataforNew(path))
                        {
                            CheckAndCreateDirectory(newPath);
                            FileIO.File.Copy(path, newPath, true);
                        }
                    }
                }
            }
        }

        private static bool CheckPathFilter(string path)
        {
            if (path.Substring(path.Length - 3, 3) == ".en") return false;
            for (int i = 0; i < discardKeys.Length; i++)
            {
                if (path.IndexOf(discardKeys[i]) > 0) return false;
            }
            return true;
        }
        private static bool CheckDataforNew(string path)
        {
            if (FileIO.File.Exists(path))
            {
                string f1 = ReadfileContent(path).Trim();
                if (f1.Length == 0)
                {
                    return true;
                }
                if (CheckIsJustMetadata(f1))
                {
                    return true;
                }
                if (Regex.IsMatch(f1, @"^(\d)+$"))
                {
                    return true;
                }
                if (copyType == "totranslate")
                {
                    string newpath = path + LangStr;
                    if (FileIO.File.Exists(newpath))
                    {
                        string f2 = ReadfileContent(newpath).Trim();
                        if (f1 != f2)
                        {
                            return true;
                        }
                    }
                }
                return false;
            }
            else
            {
                return true;
            }
        }
        private static bool CheckIsJustMetadata(string str)
        {
            return Regex.IsMatch(str, @"^\[(m|M)etadata:(value|htmlencode)\(((\w|\/|\.)+)\)\]$") ? true : false;
        }
        private static void CheckAndCreateDirectory(string path)
        {
            string[] paths = path.Split('\\');
            string temppath = paths[0];
            for (int i = 1; i < paths.Length - 1; i++)
            {
                temppath = temppath + "\\" + paths[i];
                if (!FileIO.Directory.Exists(temppath))
                {
                    FileIO.Directory.CreateDirectory(temppath);
                }
            }
        }
        private static string ReadfileContent(string path)
        {
            try
            {
                string S = "";
                FileIO.StreamReader SR = FileIO.File.OpenText(path);
                string allContentStr = "";
                while ((S = SR.ReadLine()) != null)
                {
                    allContentStr += S;
                }
                SR.Close();
                return allContentStr;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return "";
            }
        }
        private void Compress(string distinctName, string path)
        {
            using (Process process = new Process())
            {
                process.StartInfo.FileName = @"" + Server.MapPath("/").ToString() + "7zip.exe";
                process.StartInfo.ErrorDialog = false;
                process.StartInfo.CreateNoWindow = true;
                process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.Arguments = string.Format("a -y \"{0}\" \"{1}\"", distinctName, path);
                process.Start();

                process.WaitForExit();
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult CreatePackageResult(string distinctName, string countryID, int translated = 0)
        {
            try
            {
                if (distinctName != null)
                {
                    DistinctName = distinctName.DefaultDecrypt();
                    var sites = SiteManager.GetSites().Where(b => b.DistinctName == DistinctName).Select(o => new { TemplateDomainDistinctName = o.TemplateDomainDistinctName }).ToArray();
                    if (sites.Length > 0) TemplateDomainDistinctName = sites[0].TemplateDomainDistinctName.ToString();
                    Lang = countryID;
                    LangStr = "." + Lang;
                }
                string zipUrl = @"/Temp/Lang/" + d + @"/" + Lang + @"/" + DistinctName + @"/" + Lang + ".zip";
                string zipPath = Server.MapPath("/").ToString() + @"\Temp\Lang\" + d + @"\" + Lang + @"\" + DistinctName + @"\" + Lang + ".zip";
                if (!FileIO.File.Exists(zipPath))
                {
                    if(translated == 0)
                    {
                        TemplateDomainDistinctName = string.IsNullOrEmpty(TemplateDomainDistinctName) ? DistinctName : TemplateDomainDistinctName;
                        ShareBasicPath = Server.MapPath("/").ToString() + @"Views\" + TemplateDomainDistinctName;
                        NewBasicPath = Server.MapPath("/").ToString() + @"Temp\Lang\" + d + @"\" + Lang + @"\" + DistinctName + @"\" + TemplateDomainDistinctName;
                        GetAllDirListAndCreatePackage(ShareBasicPath, NewBasicPath, translated);
                    }
                    
                    if (DistinctName != TemplateDomainDistinctName)
                    {
                        ShareBasicPath = Server.MapPath("/").ToString() + @"Views\" + DistinctName;
                        NewBasicPath = Server.MapPath("/").ToString() + @"Temp\Lang\" + d + @"\" + Lang + @"\" + DistinctName + @"\" + DistinctName;
                        GetAllDirListAndCreatePackage(ShareBasicPath, NewBasicPath, translated);
                    }

                    string filePath = Server.MapPath("/").ToString() + @"Temp\Lang\" + d + @"\" + Lang + @"\" + DistinctName;
                    CopyTranslateTool(filePath);
                    Compress(zipPath, filePath);
                    DeletePackageFiles(d, Lang, TemplateDomainDistinctName, DistinctName, translated);
                }
                distinctName = distinctName.DefaultDecrypt();
                return this.Json(new { @success = true, @data = zipUrl }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @data = ex.Message.ToString() }, JsonRequestBehavior.AllowGet);

            }
        }
        private void DeletePackageFiles(string sDate, string sLang, string sTemplateDomainDistinctName, string sDistinctName, int translated)
        {
            string filePath = Server.MapPath("/").ToString() + @"Temp\Lang\" + sDate + @"\" + sLang + @"\" + sDistinctName;
            try
            {
                if (translated == 0)
                {
                    FileIO.Directory.Delete(filePath + @"\" + sTemplateDomainDistinctName, true);
                }
                
                if (sDistinctName != "Shared" && sDistinctName != "MobileShared")
                {
                    FileIO.Directory.Delete(filePath + @"\" + sDistinctName, true);
                }
                FileIO.File.Delete(filePath + @"\Instructions of the translation tool.pdf");
                FileIO.File.Delete(filePath + @"\TranslationTool.exe");
                FileIO.File.Delete(filePath + @"\TranslationTool.exe.config");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        private void CopyTranslateTool(string filePath)
        {
            try
            {
                FileIO.File.Copy(Server.MapPath("/").ToString() + @"\Tools\TranslateTool\Instructions of the translation tool.pdf", filePath + @"\Instructions of the translation tool.pdf");
                FileIO.File.Copy(Server.MapPath("/").ToString() + @"\Tools\TranslateTool\TranslationTool.exe", filePath + @"\TranslationTool.exe");
                FileIO.File.Copy(Server.MapPath("/").ToString() + @"\Tools\TranslateTool\TranslationTool.exe.config", filePath + @"\TranslationTool.exe.config");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }



    }
}
