using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Reflection;


public class FileSystemUtility
{
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

    public static void Delete(string path)
    {
        FileInfo info = new FileInfo(path);
        if ((int)info.Attributes == -1)
            return;
        else if ((info.Attributes & FileAttributes.Directory) != FileAttributes.Directory)
        {
            info.Delete();
            return;
        }

        DeleteDirectory(path);
    }

    private static void DeleteDirectory(string path)
    {
        var files = Directory.EnumerateFiles(path, "*", SearchOption.TopDirectoryOnly);
        foreach (string file in files)
        {
            File.Delete(file);
        }

        var dirs = Directory.EnumerateDirectories(path, "*", SearchOption.TopDirectoryOnly);
        foreach (string dir in dirs)
        {
            DeleteDirectory(dir);
        }

        Directory.Delete(path);
    }

    public static void EnsureDirectoryExist(string filename)
    {
        string dir = Path.GetDirectoryName(filename);
        if (!Directory.Exists(dir))
        {
            EnsureDirectoryExist(dir);
            Directory.CreateDirectory(dir);
        }
    }

    public static string GetWebSiteTempDirectory()
    {
        string path = Assembly.GetExecutingAssembly().Location;
        string strToFind = @"\Temporary ASP.NET Files\";
        int index = path.IndexOf(strToFind, StringComparison.InvariantCultureIgnoreCase);
        if (index > 0)
            return path.Substring(0, index + strToFind.Length);

        
        return Path.GetDirectoryName(path);
    }
}
