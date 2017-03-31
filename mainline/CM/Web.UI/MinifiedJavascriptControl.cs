using System.IO;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Yahoo.Yui.Compressor;

namespace CM.Web.UI
{
    [ParseChildren(false)]
    public class MinifiedJavascriptControl : WebControl
    {
        public bool AppendToPageEnd { get; set; }
        public bool EnableObfuscation { get; set; }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible)
                return;

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

                    if (this.Enabled)
                    {
                        try
                        {
                            string cacheKey = string.Format("MinifiedJavascriptControl_{0}_{1}_{2}"
                                , rendered.Length
                                , rendered.GetHashCode()
                                , EnableObfuscation
                                );
                            string script = HttpRuntime.Cache[cacheKey] as string;
                            if (!string.IsNullOrWhiteSpace(script))
                                rendered = script;

                            rendered = JavaScriptCompressor.Compress(rendered
                                    , false
                                    , EnableObfuscation
                                    , true
                                    , true
                                    , 1024
                                    );
                            HttpRuntime.Cache[cacheKey] = rendered;
                        }
                        catch
                        {
                        }
                    }

                    if (this.AppendToPageEnd)
                    {
                        HttpContext.Current.AppendScript(rendered);
                    }
                    else
                    {
                        writer.Write("<script>{0}</script>", rendered);
                    }
                    
                }// using
            }// using   
        }

        public override void RenderBeginTag(HtmlTextWriter writer)
        {
        }

        public override void RenderEndTag(HtmlTextWriter writer)
        {
        }
    }
}
