using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;


namespace JackpotsAlertService
{    
    public class Logger
    {
        private static string CreatFile()
        {
            string path = string.Format("{0}Log\\{1}-{2}-{3}\\"
                , System.Threading.Thread.GetDomain().BaseDirectory
                , DateTime.Now.Year
                , DateTime.Now.Month
                , DateTime.Now.Day);
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);

            path += "log.txt";
            if (!File.Exists(path))
                File.Create(path);

            return path;
        }

        public static void Append(string message)
        {
            string path = CreatFile();
            FileStream fs = new FileStream(path, FileMode.Append);
            StreamWriter sw = new StreamWriter(fs, Encoding.UTF8);
            sw.Write(message);
            sw.Close();
            fs.Close();
        }
    }
}
