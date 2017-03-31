<%@ WebHandler Language="C#" Class="_generate_contract" %>

using System;
using System.IO;
using System.Text;
using System.Web;
using System.Diagnostics;
using CM.db;
using CM.db.Accessor;
using GmCore;

public class _generate_contract : IHttpHandler
{
    private HttpContext _context;
    public void ProcessRequest(HttpContext context)
    {
        _context = context;
        long userid = -1L;
        if (!string.IsNullOrWhiteSpace(context.Request.QueryString["userid"]))
        {
            long.TryParse(context.Request.QueryString["userid"], out userid);
        }
        else
        {
            userid = ProfileCommon.Current.UserID;
        }

        string contractValidity = null;
        if (!string.IsNullOrWhiteSpace(context.Request.QueryString["contractValidity"]))
        {
            contractValidity = context.Request.QueryString["contractValidity"];
        }

        try
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(userid);

            if (user != null)
            {
                var contractRequest = GamMatrixClient.GetUserLicenseLTContractValidityRequest(user.ID);
                if (contractRequest != null && contractRequest.LastLicense != null && contractRequest.LastLicense.ContractExpiryDate >= DateTime.Now)
                {
                    var contractPdf = GamMatrixClient.GetUserImageRequest(user.ID, contractRequest.LastLicense.ContractImageID);
                    if (contractPdf != null && contractPdf.Image != null)
                    {
                        _context.Response.Clear();
                        _context.Response.ContentType = contractPdf.Image.ImageContentType;
                        _context.Response.AddHeader("Content-Disposition", "attachment;  filename=" + HttpUtility.UrlEncode(contractPdf.Image.ImageFileName, Encoding.UTF8));
                        _context.Response.BinaryWrite(contractPdf.Image.ImageFile);
                    }
                    else
                    {
                        _context.Response.Clear();
                        _context.Response.ContentType = "text/plain";
                        _context.Response.Write("can not find the document here.");
                    }
                }
                else
                {
                    DownloadPDF(userid, contractValidity);
                }
            }
            else
            {
                DownloadPDF(userid, contractValidity);
            }
        }
        catch (Exception ex)
        {
            Logger.Information("PDF error", ex.Message);
            _context.Response.Clear();
            _context.Response.ContentType = "text/plain";
            _context.Response.Write("get the document failure.");
            _context.Response.Flush();
            _context.Response.End();
        }
        
        _context.Response.Flush();
        _context.Response.End();
    }

    private void DownloadPDF(long userid, string contractValidity = null)
    {
        string source = string.Format("//{0}/Contract?userid={1}{2}", _context.Request.Url.Host, userid, string.IsNullOrEmpty(contractValidity) ? string.Empty : string.Format("&contractValidity={0}", contractValidity));
        //_context.Response.Redirect(source);
        string pdfPath = _context.Server.MapPath(string.Format("/PDF/{0}.pdf", userid));

        if (File.Exists(pdfPath)) File.Delete(pdfPath);

        if (!Directory.Exists(_context.Server.MapPath("~/PDF")))
        {
            Directory.CreateDirectory(_context.Server.MapPath("~/PDF"));
        }

        if (CreatePDF(source, pdfPath) && File.Exists(pdfPath))
        {
            string fileName = pdfPath.Substring(pdfPath.LastIndexOf("\\") + 1);

            _context.Response.Clear();
            _context.Response.ContentType = "application/octet-stream";
            _context.Response.AddHeader("Content-Disposition", "attachment;  filename=" + HttpUtility.UrlEncode(fileName, Encoding.UTF8));
            _context.Response.TransmitFile(pdfPath);
        }
        else
        {
            _context.Response.Clear();
            _context.Response.ContentType = "text/plain";
            _context.Response.Write("can not find the document here.");
        }
    }

    private bool CreatePDF(string url, string path)
    {
        try
        {
            if (string.IsNullOrEmpty(url) || string.IsNullOrEmpty(path))
                return false;
            Process p = new Process();
            string str = _context.Server.MapPath("/App_Data/wkhtmltopdf/wkhtmltopdf.exe");
            if (!File.Exists(str))
                return false;

            p.StartInfo.FileName = str;
            p.StartInfo.Arguments = string.Format(@" ""{0}IsPrint=true"" ""{1}""", url + (url.IndexOf("?") > 0 ? "&" : "?"), path);
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
            Logger.Information("Generate PDF1", "source:{0},Exception:{1}", url, ex.Message);
        }
        return false;
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}