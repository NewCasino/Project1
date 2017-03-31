using System;
using System.Diagnostics;
using System.Text;
using System.Web;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;
using FileIO = System.IO;

namespace GamMatrix.CMS.Controllers.EnergyCasino
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class PDFController : ControllerEx
    {
        [HttpGet]
        public void Index(string gameId, string source)
        {
            try
            {
                string distinct = Server.MapPath(string.Format("/Views/EnergyCasino/PDF/gameinfo_{0}.pdf", gameId));

                if (!FileIO.Directory.Exists(Server.MapPath(string.Format("/Views/EnergyCasino/PDF"))))
                {
                    FileIO.Directory.CreateDirectory(Server.MapPath(string.Format("/Views/EnergyCasino/PDF")));
                }

                if (CreatePDF(source, distinct))
                {
                    string fileName = distinct.Substring(distinct.LastIndexOf("\\") + 1);
                    string filePath = distinct;

                    Response.Clear();
                    Response.ContentType = "application/octet-stream";
                    Response.AddHeader("Content-Disposition", "attachment;  filename=" + HttpUtility.UrlEncode(fileName, Encoding.UTF8));
                    Response.TransmitFile(filePath);
                    Response.Flush();
                    Response.End();
                }
            }
            catch(Exception ex)
            {
                Response.Redirect(source + (source.IndexOf("?") > 0 ? "&" : "?") + "error=" + ex.Message);
            }
        }

        public bool CreatePDF(string url, string path)
        {
            try
            {
                if (string.IsNullOrEmpty(url) || string.IsNullOrEmpty(path))
                    return false;
                Process p = new Process();
                string str = Server.MapPath("/App_Data/wkhtmltopdf/wkhtmltopdf.exe");
                if (!FileIO.File.Exists(str))
                    return false;

                p.StartInfo.FileName = str;
                p.StartInfo.Arguments = string.Format(@" ""{0}IsPrint=true"" ""{1}""", url + (url.IndexOf("?") > 0 ? "&": "?"), path);
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.RedirectStandardInput = true;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.RedirectStandardError = true;
                p.StartInfo.CreateNoWindow = true;
                p.Start();
                p.WaitForExit();

                return true;
            }
            catch (Exception ex)
            {
                Response.Write(ex);
            }
            return false;
        }

    }
}
