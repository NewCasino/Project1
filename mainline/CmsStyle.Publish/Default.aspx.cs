using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Script.Serialization;
using System.Text;
using System.IO;
using System.Configuration;

namespace CmsStyle.Publish
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        private List<string> _AllDirectories = null;
        public List<string> AllDirectories
        {
            get {
                if (_AllDirectories == null)
                {
                    _AllDirectories = new List<string>();
                    string workingCopyPath = ConfigurationManager.AppSettings["WorkingCopy.Path"];
                    string _name = "";
                    foreach (string dir in Directory.GetDirectories(workingCopyPath))
                    {
                        _name = dir.Substring(dir.LastIndexOf("\\") + 1);
                        if (!_name.StartsWith("."))
                            _AllDirectories.Add(_name);
                    }
                }
                return _AllDirectories;
            }
        }

        public string GetAllDirectoriesJson()
        {
            JavaScriptSerializer jss = new JavaScriptSerializer();
            return jss.Serialize(new { 
                @source = AllDirectories
            });
        }

        public string GetAllDirectoriesHtml()
        {
            string itemFormat = @"<li><input type=""checkbox"" id=""subdir-{1}"" name=""subdir"" value=""{0}"" /><label for=""subdir-{1}""> {0}</label></li>";

            StringBuilder sb = new StringBuilder();
            int _index = 0;
            foreach (string dir in AllDirectories)
            {
                _index++;
                sb.AppendLine(string.Format(itemFormat, dir, _index));
            }

            return sb.ToString();
        }
    }
}