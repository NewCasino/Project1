using System.Web.Mvc;
using System.Web;
using System.IO.Compression;
using CM.Content;

namespace CM.Web
{
    /// <summary>
    /// CompressFilter, inherited from ActionFilterAttribute. provide ability to compress the response of special action
    /// </summary>
    public class CompressFilter : ActionFilterAttribute
    {
        /// <summary>
        /// override OnActionExecuting
        /// </summary>
        /// <param name="filterContext">ActionExecutingContext</param>
        public override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            if (Metadata.Get("Metadata/Settings.EnableGzipCompress").ParseToBool(false))
            {
                HttpRequestBase request = filterContext.HttpContext.Request;

                string acceptEncoding = request.Headers["Accept-Encoding"];

                if (string.IsNullOrEmpty(acceptEncoding)) return;

                acceptEncoding = acceptEncoding.ToUpperInvariant();

                HttpResponseBase response = filterContext.HttpContext.Response;

                if (acceptEncoding.Contains("GZIP"))
                {
                    response.AppendHeader("Content-encoding", "gzip");
                    response.Filter = new GZipStream(response.Filter, CompressionMode.Compress);
                }
                else if (acceptEncoding.Contains("DEFLATE"))
                {
                    response.AppendHeader("Content-encoding", "deflate");
                    response.Filter = new DeflateStream(response.Filter, CompressionMode.Compress);
                }

            }
        }
    }
}
