using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace CmsSanityCheck.Misc
{
    public static class FileSystemHelper
    {
        public static string ReadWithoutLock(string filePath)
        {
            if (!File.Exists(filePath))
                return null;
            using (FileStream fs = new FileStream(filePath, FileMode.Open, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
            {
                using (StreamReader sr = new StreamReader(fs, Encoding.UTF8))
                {
                    return sr.ReadToEnd();
                }
            }
        }

        public static void WriteWithoutLock(string filePath, string content)
        {
            string dir = Path.GetDirectoryName(filePath);
            if (!Directory.Exists(dir))
                Directory.CreateDirectory(dir);
            using (FileStream fs = new FileStream(filePath, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete))
            {
                fs.SetLength(0);
                using (StreamWriter sw = new StreamWriter(fs, Encoding.UTF8))
                {
                    sw.Write(content);
                }
            }
        }

        public static void Delete(string filename)
        {
            FileInfo fi = new FileInfo(filename);
            if ((fi.Attributes & FileAttributes.Directory) == FileAttributes.Directory)
            {
                if (Directory.Exists(filename))
                {
                    string[] files = Directory.GetFiles(filename, "*", SearchOption.AllDirectories);
                    foreach (string file in files)
                        File.Delete(file);

                    string[] dirs = Directory.GetDirectories(filename, "*", SearchOption.AllDirectories);
                    foreach (string dir in dirs)
                        Directory.Delete(dir);

                    Directory.Delete(filename);
                }
            }
            else
            {
                if(File.Exists(filename))
                    File.Delete(filename);
            }
        }

    }
}
