using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Configuration;
using System.IO;

namespace CmsStyle.Publish
{
    public class Settings
    {        
        public static string SvnUsername
        {
            get {
                return ConfigurationManager.AppSettings["Svn.Username"];
            }
        }

        public static string SvnPassword
        {
            get{
                return ConfigurationManager.AppSettings["Svn.Password"];
                
            }
        }

        public static string WorkingCopyPath
        {
            get {
                return ConfigurationManager.AppSettings["WorkingCopy.Path"];
            }
        }

        private static string[] _WorkingCopyDomainDirs = null;
        public static string[] WorkingCopyDomainDirs
        {
            get {
                if (_WorkingCopyDomainDirs == null)
                {
                    _WorkingCopyDomainDirs = new string[] { };
                    //string _name;
                    //foreach (string dir in Directory.GetDirectories(workingCopyPath))
                    //{
                    //    _name = dir.Substring(dir.LastIndexOf("\\") + 1);
                    //    if (!_name.StartsWith("."))
                    //    { }
                    //}
                }
                return _WorkingCopyDomainDirs;
            }
        }
    }
}