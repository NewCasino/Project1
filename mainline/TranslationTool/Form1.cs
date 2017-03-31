using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using System.Xml;
using System.Xml.Linq;
using System.Reflection;
using System.IO;

namespace TranslationTool
{
    public partial class Form1 : Form
    {
        const string SRC1_DIR = @"G:\cms2012\GamMatrix.CMS\Views\MobileShared\";

        public Form1()
        {
            InitializeComponent();
        }

        private void CopyLanguageFiles(string srcDir, string destDir, string languageCode)
        {
            var directories = Directory.GetDirectories(srcDir, "*", SearchOption.TopDirectoryOnly);
            foreach (var directory in directories)
            {
                if (directory.StartsWith(SRC1_DIR, StringComparison.OrdinalIgnoreCase))
                {
                    string relativePath = directory.Substring(SRC1_DIR.Length);
                    if (relativePath.StartsWith(@"Metadata\Casino\", StringComparison.OrdinalIgnoreCase) ||
                        relativePath.StartsWith(@"Metadata\Settings", StringComparison.OrdinalIgnoreCase) ||
                        relativePath.StartsWith(@"Metadata\Country", StringComparison.OrdinalIgnoreCase) ||
                        relativePath.StartsWith(@"Metadata\Help", StringComparison.OrdinalIgnoreCase) ||
                        relativePath.StartsWith(@"Metadata\Help", StringComparison.OrdinalIgnoreCase) ||
                        relativePath.StartsWith(@"Metadata\GmCoreErrorCodes", StringComparison.OrdinalIgnoreCase) ||
                        relativePath.StartsWith(@"Metadata\Regions", StringComparison.OrdinalIgnoreCase) )
                    {
                        continue;
                    }
                }

                string directoryName = Path.GetFileName(directory);
                string newDest = Path.Combine(destDir, directoryName);

                //if( directory.StartsWith("
                if (IsMetadataDirectory(directory))
                {
                    var files = Directory.GetFiles(directory, ".*", SearchOption.TopDirectoryOnly);
                    foreach (var file in files)
                    {
                        string filename = Path.GetFileName(file);
                        if (Regex.IsMatch(filename, @"^(\.[^\.]+)$", RegexOptions.Compiled))
                        {
                            if (!string.Equals(".Url", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".Image", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".RouteName", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".CssClass", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".InlineCSS", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".Target", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".UrlMatchExpression", filename, StringComparison.OrdinalIgnoreCase)&&
                                !string.Equals(".BonusCode_TermsConditonsUrl", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".EnableBonusCodeInput", filename, StringComparison.OrdinalIgnoreCase) &&
                                !string.Equals(".EnableBonusSelector", filename, StringComparison.OrdinalIgnoreCase))

                            {
                                string content = null;
                                using (StreamReader sr = new StreamReader(file))
                                {
                                    content = sr.ReadToEnd();
                                }
                                if (!string.IsNullOrWhiteSpace(content))
                                {
                                    if (!Regex.IsMatch(content.Trim(), @"^(\[Metadata\:).*?(\)\])$", RegexOptions.Compiled))
                                    {
                                        string destFile = Path.Combine(newDest, string.Format("{0}.{1}", filename, languageCode));

                                        if (!File.Exists(string.Format("{0}.{1}", file, languageCode)))
                                        {
                                            EnsureDirectoryExist(destFile);
                                            File.Copy(file, destFile);
                                        }
                                            /*
                                        else
                                        {
                                            EnsureDirectoryExist(destFile);
                                            File.Copy(string.Format("{0}.{1}", file, languageCode), destFile);
                                        }
                                             * */
                                    }
                                }
                            }
                        }
                    }
                }
                
                CopyLanguageFiles(directory, newDest, languageCode);
            }
        }

        public static void EnsureDirectoryExist(string filename)
        {
            string dir = Path.GetDirectoryName(filename);
            if (!Directory.Exists(dir))
                Directory.CreateDirectory(dir);
        }

        private bool IsMetadataDirectory(string dir)
        {
            string path = Path.Combine(dir, ".properties.xml");
            if (!File.Exists(path))
                return false;

            XDocument doc = XDocument.Load(path);
            if (string.Equals(doc.Element("root").Element("Type").Value, "Metadata", StringComparison.CurrentCulture))
                return true;

            return false;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Norwegian_Mobile", "MobileShared"), "no");
           // CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Norwegian", "Shared"), "no");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Bulgarian", "Shared"), "bg");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Turkish", "Shared"), "tr");
           // CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Spanish", "Shared"), "es");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "TranditionalChinese", "Shared"), "zh-cn");
            //
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "SimplifiedChinese", "Shared"), "zh-cn");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "TranditionalChinese", "Shared"), "zh-tw");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "German", "Shared"), "de");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Turkish", "Shared"), "tr");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Romanian", "Shared"), "ro");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Bulgarian ", "Shared"), "bg");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Russian", "Shared"), "ru");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Georgian", "Shared"), "ka");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Portuguese", "Shared"), "pt");
            //CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Turkish", "Shared"), "tr");
            /*
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Italian", "Shared"), "it");
            
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "French", "Shared"), "fr");
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "German", "Shared"), "de");
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Spanish", "Shared"), "es");
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Polish", "Shared"), "pl");
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Czech", "Shared"), "cs");
            CopyLanguageFiles(SRC1_DIR, Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "Swedish", "Shared"), "sv");
            */
            PrepareList();
        }

        private void PrepareList()
        {
            string path = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string[] directories = Directory.GetDirectories(path, "*", SearchOption.AllDirectories);

            lstDirectories.BeginUpdate();

            List<ListViewItem> appending = new List<ListViewItem>();
            foreach (string directory in directories)
            {
                string[] files = Directory.GetFiles(directory, ".*", SearchOption.TopDirectoryOnly);
                if (files.Length == 0)
                    continue;

                string relativePath = directory.Substring(path.Length);
                string name = string.Format("{0:00} - {1}", files.Length, relativePath);

                ListViewItem item = new ListViewItem(name)
                {
                    Tag = directory
                };

                if (relativePath.StartsWith(@"\Shared\Metadata\GmCoreErrorCodes\", StringComparison.OrdinalIgnoreCase))
                    appending.Add(item);
                else
                    lstDirectories.Items.Add(item);

                
            }
            lstDirectories.Items.AddRange(appending.ToArray());
            lstDirectories.EndUpdate();
        }

        private void lstDirectories_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (lstDirectories.SelectedItems.Count == 0)
                return;

            string path = lstDirectories.SelectedItems[0].Tag as string;

            ctlContainer.Padding = new System.Windows.Forms.Padding(10, 10, 10, 50);
            ctlContainer.RowCount = 0;
            ctlContainer.Controls.Clear();
            string[] files = Directory.GetFiles(path, ".*", SearchOption.TopDirectoryOnly);
            foreach (string file in files)
            {
                string name = Path.GetFileNameWithoutExtension(file).Trim('.');

                using (StreamReader sr = new StreamReader(file, Encoding.UTF8, false))
                {
                    TextBox input = new TextBox() { Multiline = true, Height = 50, Dock = DockStyle.Top, Text = sr.ReadToEnd(), Tag = file };
                    ctlContainer.Controls.Add(input);
                }

                Label label = new Label() { Text = name, Dock = DockStyle.Top };
                ctlContainer.Controls.Add(label);
            }
            ctlContainer.HorizontalScroll.Enabled = false;
            ctlContainer.HorizontalScroll.Visible = false;
            //
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            foreach (Control ctrl in ctlContainer.Controls)
            {
                TextBox input = ctrl as TextBox;
                if (input == null) continue;

                using (StreamWriter sw = new StreamWriter(input.Tag as string, false, Encoding.UTF8))
                {
                    sw.WriteLine(input.Text);
                }
            }
            MessageBox.Show("Changes have been saved successfully!");
        }
    }
}
