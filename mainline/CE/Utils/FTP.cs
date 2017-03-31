using System.Configuration;
using System.IO;
using System.Net;
using System.Web;

namespace CE.Utils
{
    public static class FTP
    {
        public static void UploadFile(long domainID, string filePath, byte[] buffer)
        {
            int fileSize = GetFtpFileSize(filePath);
            if (fileSize == buffer.Length)
                return;

            string relativePath = VirtualPathUtility.GetDirectory(filePath);
            string filename = VirtualPathUtility.GetFileName(filePath);

            string url = string.Format("{0}{1}"
                , ConfigurationManager.AppSettings["StaticFileHost.FileManagerUrl"]
                , ConfigurationManager.AppSettings["StaticFileHost.PartialUploadPath"]
                );
            url = string.Format(url
                , HttpUtility.UrlEncode(relativePath)
                , HttpUtility.UrlEncode(filename)
                );


            url = string.Format("{0}&offset={1}&length={2}&domainID={3}", url, 0, buffer.Length, domainID);

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
                    reader.ReadToEnd();
                    response.Close();
                }
            }
        }

        public static byte[] DownloadFile(string filePath)
        {
            int filesize = GetFtpFileSize(filePath);
            if (filesize == 0)
                return null;

            string url = string.Format("{0}{1}", ConfigurationManager.AppSettings["FTP.Url"].TrimEnd('/'), filePath);
            FtpWebRequest request = (FtpWebRequest)WebRequest.Create(url);
            request.Method = WebRequestMethods.Ftp.DownloadFile;
            request.UseBinary = true;
            request.Credentials = new NetworkCredential(ConfigurationManager.AppSettings["FTP.Username"]
            , ConfigurationManager.AppSettings["FTP.Password"]
            );
            FtpWebResponse response = (FtpWebResponse)request.GetResponse();

            using (Stream responseStream = response.GetResponseStream())
            using (BinaryReader br = new BinaryReader(responseStream))
            {
                byte[] buffer = new byte[filesize];

                int totalSize = 0;
                while (totalSize < filesize)
                {
                    int read = br.Read(buffer, totalSize, buffer.Length - totalSize);
                    if (read == 0)
                        break;

                    totalSize += read;
                }
                

                return buffer;
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="filePath"></param>
        /// <returns>when error occurs, returns zero</returns>
        public static int GetFtpFileSize(string filePath)
        {
            try
            {
                string url = string.Format("{0}{1}", ConfigurationManager.AppSettings["FTP.Url"].TrimEnd('/'), filePath);
                FtpWebRequest request = (FtpWebRequest)WebRequest.Create(url);
                request.Method = WebRequestMethods.Ftp.GetFileSize;
                request.UseBinary = true;
                request.Credentials = new NetworkCredential(ConfigurationManager.AppSettings["FTP.Username"]
                , ConfigurationManager.AppSettings["FTP.Password"]
                );
                FtpWebResponse response = (FtpWebResponse)request.GetResponse();
                return (int)response.ContentLength;
            }
            catch (WebException)
            {
                return 0;
            }
        }




        
    }
}
