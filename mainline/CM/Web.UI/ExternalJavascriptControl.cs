using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Hosting;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    [ParseChildren(false)]
    public class ExternalJavascriptControl : WebControl
    {
        private string SafeFilenamePrefix
        {
            get
            {
                return Regex.Replace(this.ClientID
                 , "(\\\\|\\/|\\:|\\*|\\?|\\\"|\\<|\\>|\\|)"
                 , "_"
                 , RegexOptions.ECMAScript | RegexOptions.Compiled
                 );
            }
        }

        public string GetOuterHtml()
        {
            using (StringWriter sw = new StringWriter())
            {
                using (HtmlTextWriter htw = new HtmlTextWriter(sw))
                {
                    this.RenderInternal(htw);
                }
                return sw.ToString();
            }
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible)
                return;

            var request = HttpContext.Current.Request;
            if (this.AutoDisableInAjaxRequest)
            {
                bool isAjaxRequest = ((request["X-Requested-With"] == "XMLHttpRequest") ||
                    ((request.Headers != null) && (request.Headers["X-Requested-With"] == "XMLHttpRequest")));
                if( isAjaxRequest )
                    return;
            }

            if (this.AutoDisableInPostbackRequest)
            {
                if (request.HttpMethod == "POST")
                    return;
            }

            RenderInternal(writer);
        }

        public bool AutoDisableInAjaxRequest { get; set; }
        public bool AutoDisableInPostbackRequest { get; set; }


        private void RenderInternal(HtmlTextWriter writer)
        {
            if (this.Enabled)
            {
                try
                {
                    using (StringWriter sw = new StringWriter())
                    {
                        using (HtmlTextWriter htw = new HtmlTextWriter(sw))
                        {
                            base.Render(htw);

                            // get the rendered content    
                            string rendered = sw.ToString();

                            // remove the script tag if exist    
                            rendered = Regex.Replace(rendered
                                , @"(<[\s\/]*script\b[^>]*>)"
                                , string.Empty
                                , RegexOptions.ECMAScript | RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                                );

                            // get the file path and name
                            string dir = string.Format("/temp/{0:0000}{1:00}{2:00}/", DateTime.Now.Year, DateTime.Now.Month, DateTime.Now.Day);
                            string path = HostingEnvironment.MapPath(dir);

                            string filename = string.Format("{0}_{1:X}_{2:X}.js"
                                , this.SafeFilenamePrefix
                                , rendered.GetHashCode()
                                , rendered.Length   
                                );

                            // save to temp file if not exist
                            if (!Directory.Exists(path)) Directory.CreateDirectory(path);
                            if (!File.Exists(path + filename))
                            {
                                using (StreamWriter output = new StreamWriter(path + filename, false, Encoding.UTF8))
                                {
                                    output.Write(rendered);
                                    output.Flush();
                                }
                            }

                            // write the external js file link
                            string js = dir + HttpUtility.UrlEncode(filename);
                            writer.Write("<script type=\"text/javascript\" src=\"{0}\"></script>"
                                , js
                                );
                        }// using
                    }// using   
                    return;
                }
                catch
                {
                }// trt-catch
            }// Enabled

            base.Render(writer);
        }

        public override void RenderBeginTag(HtmlTextWriter writer)
        {
        }

        public override void RenderEndTag(HtmlTextWriter writer)
        {
        }
    }
}
