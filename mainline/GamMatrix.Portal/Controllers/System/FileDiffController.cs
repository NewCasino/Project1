using System;
using System.Collections;
using System.IO;
using System.Text;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;
using GamMatrix.Infrastructure.DifferenceEngine;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "CompareFiles", ParameterUrl = "{sourceFile}/{destinationFile}")]
    public class FileDiffController : ControllerEx
    {
        [HttpPost]
        [ValidateInput(false)]
        [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
        public ActionResult ComparePostAndFile(string sourceFile)
        {
            sourceFile = sourceFile.DefaultDecrypt();
            string fileContent = Request["FileContent"] as string;

            string dir = string.Format("~/temp/{0:0000}{1:00}{2:00}{3:00}/"
                , DateTime.Now.Year
                , DateTime.Now.Month
                , DateTime.Now.Day
                , DateTime.Now.Hour
                );

            string path = this.Server.MapPath(dir);
            if( !Directory.Exists(path) )
                Directory.CreateDirectory(path);
            string tempFile = string.Format("{0}\\{1}_{2}.temp"
                , path.TrimEnd('\\')
                , fileContent.DefaultIfNullOrEmpty(string.Empty).GetHashCode()
                , Guid.NewGuid().ToString("N")
                );

            using (StreamWriter sw = new StreamWriter(tempFile, false, Encoding.UTF8))
            {
                sw.Write(fileContent);
                sw.Flush();
            }

            return View("Index", GetDiffLines(sourceFile, tempFile));
        }

        [HttpGet]
        public ActionResult CompareFiles(string src, string dest)
        {
            src = src.DefaultDecrypt();
            dest = dest.DefaultDecrypt();
            return View("Index", GetDiffLines(src, dest));
        }

        private ArrayList GetDiffLines(string src, string dest)
        {
            DiffList_TextFile sLF = new DiffList_TextFile(src);
            DiffList_TextFile dLF = new DiffList_TextFile(dest);

            DiffEngine engine = new DiffEngine();
            engine.ProcessDiff(sLF, dLF, DiffEngineLevel.SlowPerfect);

            this.ViewData["sLF"] = sLF;
            this.ViewData["dLF"] = dLF;
            return engine.DiffReport();

            /*
            foreach (DiffResultSpan drs in diffLines)
            {
                for (int i = 0; i < drs.Length; i++)
                {
                    string srcLine = (drs.SourceIndex >= 0) ? ((TextLine)sLF.GetByIndex(drs.SourceIndex + i)).Line : null;
                    string destLine = (drs.DestIndex >= 0) ? ((TextLine)sLF.GetByIndex(drs.DestIndex + i)).Line : null;
                    html.AppendFormat("<div class=\"line {0}\"><div class=\"src\"><span>{1}</span></div><div class=\"dest\"><span>{2}</span></div></div>"
                        , Enum.GetName( typeof(DiffResultSpanStatus), drs.Status)
                        , srcLine.SafeHtmlEncode().DefaultIfNullOrEmpty("&#160;")
                        , destLine.SafeHtmlEncode().DefaultIfNullOrEmpty("&#160;")
                        );
                }
            }


            return string.Format(@"<pre >{0}</div>"
                , html.ToString()
                );
             * */
        }

    }
}
