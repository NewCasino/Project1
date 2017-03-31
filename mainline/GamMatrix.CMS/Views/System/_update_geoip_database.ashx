<%@ WebHandler Language="C#" Class="_update_geoip_database" %>

using System;
using System.Web;
using System.Collections;
using System.Net;
using System.IO;
using System.Configuration;
using System.Web.Hosting;

using CM.State;

public class _update_geoip_database : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        //CustomProfile.Current.Init(context);
        if (string.Equals(context.Request.QueryString["type"], "reload", StringComparison.InvariantCultureIgnoreCase))
        {
            Reload(context);
        }
        else if (string.Equals(context.Request.QueryString["type"], "reloadonly", StringComparison.InvariantCultureIgnoreCase))
        {
            IPLocation.Reload();
            context.Response.Write("OK");
        }
        else if (string.Equals(context.Request.QueryString["type"], "internal", StringComparison.InvariantCultureIgnoreCase))
        {
            IPLocation.DownloadGeoIPDatabase();
            context.Response.Write("OK");
        }   
        else
        {
            Distribute(context);
        }
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

    private void Distribute(HttpContext context)
    {
        string[] local = new string[]
        {
            "localhost",
        };

        string[] dev = new string[]
        {
            "10.0.11.240",
        };

        string[] qa = new string[]
        {
            "10.0.11.42",
        };

        string[] stage = new string[]
        {
            "10.0.11.238",
            "10.0.11.239",
            "61.221.24.86",
            "61.221.24.88",
        };

        string[] prod = new string[]
        {
            //prod env1
            "10.0.10.246",
            "10.0.10.237",
            "10.0.10.240",

            //prod env3
            "10.0.11.56",
            "10.0.11.58",
            "10.0.10.202",
            "10.0.10.205",
            "10.0.10.159",
            "10.0.10.102",
            "10.0.11.33",
            "10.0.11.41",
            "10.0.11.144",
            "10.0.11.7",
            "10.0.11.8",
            "10.0.11.100",
            "10.0.11.120",
            "10.8.22.11",
            "10.8.22.12",
        };

        string[] servers = dev;

        foreach (string server in servers)
        {
            string url = string.Format("http://{0}/_update_geoip_database.ashx?type=reload", server);
            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.KeepAlive = false;
            request.Method = "POST";
            request.ProtocolVersion = Version.Parse("1.0");
            request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
            request.Accept = "text/plain";

            using (Stream stream = request.GetRequestStream())
            using (StreamWriter writer = new StreamWriter(stream))
            {
                //writer.Write(json);
                writer.Flush();
            }

            HttpWebResponse response = request.GetResponse() as HttpWebResponse;
            string respText = null;
            using (Stream stream = response.GetResponseStream())
            {
                using (StreamReader sr = new StreamReader(stream))
                {
                    respText = sr.ReadToEnd();
                }
            }
            response.Close();

            bool success = string.Compare(respText, "OK", true) == 0;
            context.Response.Write(string.Format("{0}: {1}<br />", server, respText));
            //if (!success)
            //    Logger.Information(string.Format("Error to clear cache {0} \n\n{1}", url, respText));
            //else
            //    Logger.Information(string.Format("Clear cache successfully! \n {0}", url));
        }
    }

    private void Reload(HttpContext context)
    {
        try
        {
            string geoIPFile = HostingEnvironment.MapPath("~/App_Data/geoip_new.dat");

            DownloadGeoIPDatabase(geoIPFile);
            UpdateFile(geoIPFile);
            IPLocation.Reload();
            context.Response.Write("OK");
        }
        catch (Exception ex)
        {
            context.Response.Write(ex.Message);
        }
        
    }

    public static void DownloadGeoIPDatabase(string geoIPFile)
    {
        try
        {
            string url = ConfigurationManager.AppSettings["GeoIP.DownloadUrl"];
            url += "?_t=" + DateTime.Now.Ticks.ToString();

            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.KeepAlive = false;
            request.Method = "GET";
            request.ProtocolVersion = Version.Parse("1.0");
            //request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
            //request.Accept = "text/plain";
            request.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";
            request.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36";
            request.Headers["Accept-Encoding"] = "gzip, deflate, sdch";

            HttpWebResponse response = request.GetResponse() as HttpWebResponse;

            using (Stream stream = response.GetResponseStream())
            using (FileStream fs = new FileStream(geoIPFile, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete))
            using (BinaryWriter writer = new BinaryWriter(fs))
            {
                byte[] buffer = new byte[4096];
                int size;
                while ((size = stream.Read(buffer, 0, buffer.Length)) > 0)
                    writer.Write(buffer, 0, size);
                writer.Flush();
                writer.Close();
            }
            response.Close();
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
            throw;
        }
        finally
        {
        }
    }

    public static void UpdateFile(string geoIPFile)
    {
        FileInfo info = new FileInfo(geoIPFile);
        //if the file length is less than 1M, it is not correct, ignore it.
        if (info.Length < 1048576)
            return;

        string dataFile = HostingEnvironment.MapPath("~/App_Data/geoip.dat");
        File.Copy(geoIPFile, dataFile, true);
        File.Delete(geoIPFile);
    }


}