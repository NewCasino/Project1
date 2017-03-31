using System.Text;
using System.Web;

namespace CM.Web
{
    public static class HttpContextExtension
    {
        private static string PAGE_STYLESHEET = "_page_inline_css";
        private static string PAGE_SCRIPT = "_page_inline_script";

        public static void AppendInlineCSS(this HttpContext context, string inlineCSS)
        {
            StringBuilder sb = context.Items[PAGE_STYLESHEET] as StringBuilder;
            if (sb == null)
            {
                sb = new StringBuilder();
                context.Items[PAGE_STYLESHEET] = sb;
            }

            sb.AppendLine(inlineCSS);
        }

        public static string GetInlineCSS(this HttpContext context)
        {
            StringBuilder sb = context.Items[PAGE_STYLESHEET] as StringBuilder;
            if (sb != null)
                return sb.ToString();

            return string.Empty;
        }

        public static void AppendScript(this HttpContext context, string script)
        {
            StringBuilder sb = context.Items[PAGE_SCRIPT] as StringBuilder;
            if (sb == null)
            {
                sb = new StringBuilder();
                context.Items[PAGE_SCRIPT] = sb;
            }

            sb.Append(';');
            sb.AppendLine(script);
        }

        public static string GetScript(this HttpContext context)
        {
            StringBuilder sb = context.Items[PAGE_SCRIPT] as StringBuilder;
            if (sb != null)
                return string.Format("<script>//<![CDATA[\n{0}\n//]]>\n</script>", sb.ToString());

            return string.Empty;
        }
    }
}
