using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Web;
using System.Web.Caching;
using System.Globalization;
using Yahoo.Yui.Compressor;
using CM.Sites;

namespace CmsStyle.Publish
{
    public class CombineCSS
    {
        public static void CombineCSSFile(string themeName)
        {
            if (string.IsNullOrEmpty(themeName))
                return;
            StringBuilder sb = new StringBuilder();
            string absolutePath = string.Format("{0}/{1}/_import.css", Settings.WorkingCopyPath, themeName);
            sb.AppendLine(ParseCss(absolutePath, themeName));

            // minify the css
            Byte[] bitCSS = Encoding.UTF8.GetBytes(CssCompressor.Compress(sb.ToString()));

            string strFolder = HttpContext.Current.Server.MapPath("/CombinedCSS/" + themeName);
            if (!Directory.Exists(strFolder))
                Directory.CreateDirectory(strFolder);
            //store file
            using (FileStream fStream = new FileStream(strFolder + "/_import.css", FileMode.OpenOrCreate))
            {
                fStream.Write(bitCSS, 0, bitCSS.Length);
                fStream.Flush();
            }
        }

        private static string ParseCss(string absolutePath,string themeName)
        {
            if (!File.Exists(absolutePath))
                return string.Empty;
            string content = null;
            using (StreamReader sr = new StreamReader(absolutePath))
            {
                content = sr.ReadToEnd();
                sr.Close();
            }

            CssReplacer replacer = new CssReplacer()
            {
                AbsolutePath = absolutePath
                ,
                ThemeName = themeName
            };
            content = Regex.Replace(content, @"url(\s*)\((\s*)(?<quot>(\""|\')?)(?<path>[^\""\'\)]*)\k<quot>(\s*)\)"
                , replacer.OnImageMatch
                , RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.Multiline | RegexOptions.Compiled | RegexOptions.CultureInvariant
                );

            content = Regex.Replace(content, @"\@import(\s+)url(\s*)\((\s*)(?<quot>(\""|\')?)(?<path>[^\""\']*)\k<quot>(\s*)\)(\s*)(\;?)"
                , replacer.OnImportMatch
                , RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.Multiline | RegexOptions.Compiled | RegexOptions.CultureInvariant
                );
            return content;
        }
        private sealed class CssReplacer
        {
            public string AbsolutePath { get; set; }
            public string ThemeName { get; set; }
            internal string OnImportMatch(Match m)
            {
                if (m.Groups.Count == 0 || m.Groups["path"] == null)
                    return string.Empty;

                string path = m.Groups["path"].Value;
                if (path.StartsWith("/"))
                {
                    return ParseCss(ResolvePath(Settings.WorkingCopyPath + ThemeName, path), ThemeName);
                }
                else
                {
                    path = path.Replace("\\", "/");
                    return ParseCss(ResolvePath(Path.GetDirectoryName(AbsolutePath), path), ThemeName);
                }
            }

            internal string OnImageMatch(Match m)
            {
                if (m.Groups.Count == 0 || m.Groups["path"] == null)
                    return string.Empty;

                string path = m.Groups["path"].Value;
                if (path.StartsWith("/") ||
                    path.StartsWith("http://") ||
                    path.StartsWith("https://"))
                {
                    return m.Value;
                }

                if (string.IsNullOrWhiteSpace(path))
                    return string.Empty;
                return string.Format("url(\"{0}\")", path.Replace(string.Format("/App_Themes/{0}", ThemeName), ".").Replace("/App_Themes", string.Empty));
            }

            private string ResolvePath(string absolutePath, string relativePath)
            {
                try
                {
                    bool isFilePath = !absolutePath.StartsWith("/");
                    if (relativePath.StartsWith("/"))
                    {
                        relativePath = relativePath.Substring("/".Length);
                        return this.ResolvePath(Path.GetDirectoryName(absolutePath), relativePath);
                    }
                    if (relativePath.StartsWith("./"))
                    {
                        relativePath = relativePath.Substring("./".Length);
                        return this.ResolvePath(absolutePath, relativePath);
                    }
                    else if (relativePath.StartsWith("../"))
                    {
                        relativePath = relativePath.Substring("../".Length);
                        if (isFilePath)
                            return this.ResolvePath(Path.GetDirectoryName(absolutePath), relativePath);
                        else
                            return this.ResolvePath(VirtualPathUtility.GetDirectory(absolutePath), relativePath);
                    }
                    else
                    {
                        if (isFilePath)
                            return Path.Combine(absolutePath, relativePath);
                        return VirtualPathUtility.Combine(absolutePath, relativePath);
                    }
                }
                catch (Exception ex)
                {
                    return string.Empty;
                }
            }
        }
    }
}