using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using System.Web.Script.Serialization;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class FileManagerController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            try
            {
                if (string.Equals(Request.Url.Host, "dev.gammatrix.com", StringComparison.InvariantCultureIgnoreCase))
                {
                    if (!Request.GetRealUserAddress().StartsWith("10.0.4.") &&
                        !Request.GetRealUserAddress().StartsWith("124.233.3.10"))
                    {
                        throw new UnauthorizedAccessException("File Manager is not available on test evironment");
                    }
                }

                distinctName = distinctName.DefaultDecrypt();

                this.ViewData["DistinctName"] = distinctName;
                return View("Index");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        private sealed class StaticFileInfo
        {
            public bool isFolder;
            public string filename;
        }

        private sealed class StaticFileList
        {
            public bool success;
            public string error;
            public StaticFileInfo[] list;
        }


        private string InsertOpNameIntoUrl(string url, string distinctName = null)
        {
            if (string.IsNullOrEmpty(url))
                return string.Empty;
            Func<string> _resolveDistinctName = () =>
            {
                string path = string.Empty;
                try
                {
                    Uri uri = new Uri(url);

                    var query = HttpUtility.ParseQueryString(uri.Query);
                    path = HttpUtility.UrlDecode(query["path"]);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                if (string.IsNullOrEmpty(path))
                    return null;

                path = path.TrimStart('/');

                return path.Substring(0, path.IndexOf('/'));
            };
            if (distinctName == null)
            {
                distinctName = _resolveDistinctName();
            }

            if (distinctName == null)
                return url;

            if (url.IndexOf('?') != -1)
            {
                return url + "&distinctName=" + distinctName;
            }
            else
                return url + "?distinctName=" + distinctName;

        }
        [HttpGet]
        public JsonResult GetChildren(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                var site = SiteManager.GetSiteByDistinctName(distinctName);
                path = string.Format("/{0}", path.DefaultDecrypt().Trim('/'));

                string relativePath = string.Format("/{0}/_files{1}", distinctName, path);

                string url = string.Format("{0}{1}"
                    , ConfigurationManager.AppSettings["StaticFileHost.FileManagerUrl"]
                    , ConfigurationManager.AppSettings["StaticFileHost.ListPath"]
                    );
                url = string.Format(url, HttpUtility.UrlEncode(relativePath), DateTime.Now.Ticks);
                url = InsertOpNameIntoUrl(url, distinctName);

                //Logger.Information("CMS FileManager", "url:{0}", url);

                StaticFileList data = null;
                using (WebClient webClient = new WebClient())
                {
                    string json = webClient.DownloadString(url);
                    JavaScriptSerializer jss = new JavaScriptSerializer();
                    data = jss.Deserialize<StaticFileList>(json);
                }

                if (data == null)
                    throw new Exception("No data is returned.");
                if (!data.success)
                {
                    throw new Exception(data.error);
                }

                List<dynamic> list = new List<dynamic>();
                foreach (dynamic item in data.list)
                {
                    string fileType = "other";
                    if (item.isFolder)
                        fileType = "0-dir";
                    else
                    {
                        string extName = Path.GetExtension(item.filename);

                        switch (extName.ToLowerInvariant())
                        {
                            case ".bmp":
                            case ".jpg":
                            case ".jpeg":
                            case ".png":
                            case ".gif":
                            case ".tiff":
                                fileType = "image";
                                break;

                            case ".xml":
                            case ".xsl":
                            case ".xslt":
                                fileType = "xml";
                                break;

                            case ".js":
                            case ".vbs":
                                fileType = "script";
                                break;

                            case ".swf":
                                fileType = "flash";
                                break;

                            case ".htm":
                            case ".html":
                                fileType = "html";
                                break;

                            case ".rar":
                            case ".zip":
                                fileType = "zip";
                                break;

                            case ".txt":
                                fileType = "txt";
                                break;

                            case ".flv":
                            case ".avi":
                            case ".wmv":
                            case ".wma":
                            case ".mp3":
                                fileType = "media";
                                break;

                            case ".exe":
                            case ".msi":
                                fileType = "exe";
                                break;

                            default:
                                break;
                        }
                    }
                    var siteStaticUrl = site.StaticFileServerDomainName.DefaultIfNullOrEmpty(
                            ConfigurationManager.AppSettings["StaticFileServer"].DefaultIfNullOrEmpty("cdn.everymatrix.com")
                          );
                    if (!siteStaticUrl.StartsWith("//"))
                        siteStaticUrl = "//" + siteStaticUrl;

                    string fullPath = string.Format("{0}/{1}/_files{2}/{3}"
                        , siteStaticUrl
                        , distinctName
                        , path == "/" ? string.Empty : path
                        , item.filename
                        );
                    list.Add(new
                    {
                        @FileName = item.filename,
                        @Path = StringExtension.DefaultEncrypt(path + "/" + item.filename),
                        @FullPath = fullPath,
                        @FileType = fileType
                    });
                }


                string parentPath = Regex.Replace(path, @"(\/[^\/]+)$", string.Empty);
                return this.Json(new
                {
                    @success = true,
                    @isRootDir = path == "/",
                    @parentPath = StringExtension.DefaultEncrypt(parentPath),
                    @children = list.ToArray().OrderBy(f => f.FileType)
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }

        }


        /*
        [HttpGet]
        public JsonResult Extract(string distinctName, string path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = string.Format("/{0}", path.DefaultDecrypt().TrimEnd('/').TrimStart('/'));
                string filename = Server.MapPath(string.Format("~/Views/{0}/_files{1}", distinctName, path));

                // 7zip.exe x -y -o"F:\NewCMS\GamMatrix.CMS\Views\System\_files" "F:\NewCMS\GamMatrix.CMS\Views\System\_files\_files.zip"
                using (Process process = new Process())
                {
                    process.StartInfo.FileName = Server.MapPath("~/7zip.exe");
                    process.StartInfo.ErrorDialog = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                    process.StartInfo.WorkingDirectory = Path.GetDirectoryName(filename);
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.Arguments = string.Format("x -y -o\"{0}\" \"{1}\"", Path.GetDirectoryName(filename), filename);
                    process.Start();

                    process.WaitForExit();
                }
                
                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
         * */

        [HttpPost]
        public JsonResult PrepareUpload(string distinctName, string path, string filename, int size)
        {
            try
            {
                if (!Regex.IsMatch(filename, @"((\.txt)|(\.jpg)|(\.xsl)|(\.xslt)|(\.jpeg)|(\.gif)|(\.png)|(\.zip)|(\.htm)|(\.html)|(\.xml)|(\.js)|(\.flv)|(\.swf)|(\.css)|(\.woff)|(\.ttf)|(\.svg)|(\.eot)|(\.otf))$", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant))
                    throw new Exception("Error, unsupported file type");

                if (size > 1024 * 1024 * 50)
                    throw new Exception("Error, the file is bigger than 50MB.");
                distinctName = distinctName.DefaultDecrypt();
                path = string.Format("/{0}", path.DefaultDecrypt().TrimEnd('/').TrimStart('/'));

                string relativePath = string.Format("/{0}/_files{1}", distinctName, path);

                string url = string.Format("{0}{1}"
                    , ConfigurationManager.AppSettings["StaticFileHost.FileManagerUrl"]
                    , ConfigurationManager.AppSettings["StaticFileHost.PrepareUploadPath"]
                    );
                url = string.Format(url
                    , HttpUtility.UrlEncode(relativePath)
                    , HttpUtility.UrlEncode(filename)
                    , size
                    , DateTime.Now.Ticks
                    );

                url = InsertOpNameIntoUrl(url, distinctName);

                StaticFileList data = null;
                using (WebClient webClient = new WebClient())
                {
                    string json = webClient.DownloadString(url);
                    JavaScriptSerializer jss = new JavaScriptSerializer();
                    data = jss.Deserialize<StaticFileList>(json);
                }


                if (!data.success)
                    throw new Exception(data.error);

                url = string.Format("{0}{1}"
                    , ConfigurationManager.AppSettings["StaticFileHost.FileManagerUrl"]
                    , ConfigurationManager.AppSettings["StaticFileHost.PartialUploadPath"]
                    );
                url = string.Format(url
                    , HttpUtility.UrlEncode(relativePath)
                    , HttpUtility.UrlEncode(filename)
                    );

                return this.Json(new { @success = true, @key = url.DefaultEncrypt() });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpPost]
        public ContentResult PartialUpload()
        {
            try
            {
                int offset = int.Parse(Request.Headers["CurrentPosition"]);
                string url = Request.Headers["UploadIdentity"].DefaultDecrypt();
                if (string.IsNullOrEmpty(url))
                    throw new Exception("Error, invalid parameter.");

                Stream stream = Request.InputStream;
                byte[] buffer = new byte[stream.Length];
                stream.Read(buffer, 0, buffer.Length);

                url = string.Format("{0}&offset={1}&length={2}", url, offset, buffer.Length);
                url = InsertOpNameIntoUrl(url);

                {
                    HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                    request.Method = "POST";
                    using (Stream requestStream = request.GetRequestStream())
                    {
                        requestStream.Write(buffer, 0, buffer.Length);
                        requestStream.Flush();
                    }
                    HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                    using (Stream responseStream = response.GetResponseStream())
                    using (StreamReader reader = new StreamReader(responseStream))
                    {
                        string json = reader.ReadToEnd();

                        StaticFileList data = null;
                        JavaScriptSerializer jss = new JavaScriptSerializer();
                        data = jss.Deserialize<StaticFileList>(json);

                        if (!data.success)
                            throw new Exception(data.error);
                    }
                }

                return this.Content("OK");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Content(ex.Message);
            }
        }

        [HttpPost]
        public JsonResult Delete(string distinctName, string[] path)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();

                using (WebClient webClient = new WebClient())
                {
                    foreach (var item in path)
                    {
                        string temp = string.Format("/{0}", item.DefaultDecrypt().TrimEnd('/').TrimStart('/'));

                        string relativePath = string.Format("/{0}/_files{1}", distinctName, temp);

                        string url = string.Format("{0}{1}"
                            , ConfigurationManager.AppSettings["StaticFileHost.FileManagerUrl"]
                            , ConfigurationManager.AppSettings["StaticFileHost.DeletePath"]
                            );
                        url = string.Format(url, HttpUtility.UrlEncode(relativePath), DateTime.Now.Ticks);
                        url = InsertOpNameIntoUrl(url, distinctName);


                        string json = webClient.DownloadString(url);
                        JavaScriptSerializer jss = new JavaScriptSerializer();
                        StaticFileList data = jss.Deserialize<StaticFileList>(json);

                        if (!data.success)
                            throw new Exception(data.error);
                    }
                }

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        public JsonResult CreateDir(string distinctName, string path, string dirname)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                path = string.Format("/{0}/", path.DefaultDecrypt().TrimEnd('/').TrimStart('/'));

                string relativePath = string.Format("/{0}/_files{1}{2}", distinctName, path, dirname);

                string url = string.Format("{0}{1}"
                    , ConfigurationManager.AppSettings["StaticFileHost.FileManagerUrl"]
                    , ConfigurationManager.AppSettings["StaticFileHost.CreateFolderPath"]
                    );
                url = string.Format(url, HttpUtility.UrlEncode(relativePath), DateTime.Now.Ticks);
                url = InsertOpNameIntoUrl(url, distinctName);

                using (WebClient webClient = new WebClient())
                {
                    string json = webClient.DownloadString(url);
                    JavaScriptSerializer jss = new JavaScriptSerializer();
                    StaticFileList data = jss.Deserialize<StaticFileList>(json);

                    if (!data.success)
                        throw new Exception(data.error);
                }

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }



    }
}
