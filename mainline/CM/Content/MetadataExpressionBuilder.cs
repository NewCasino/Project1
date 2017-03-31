using System.CodeDom;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Compilation;
using System.Web.UI;
using CM.Sites;

namespace CM.Content
{
    /// <summary>
    /// Inherited from ExpressionBuilder, provide the ability to parse the metadata tag in ASP.Net page
    /// &lt;$ Metadata:  &gt;
    /// </summary>
    [ExpressionPrefix("Metadata")]
    public sealed class MetadataExpressionBuilder : ExpressionBuilder
    {
        internal enum MetadataExpressionType
        {
            RawValue,
            HtmlEncode,
            ScriptEncode,
        }


        internal sealed class MetadataExpressionCache
        {
            public string Path;
            public MetadataExpressionType Type;
        }

        private static Regex evalRegex = new Regex(@"^(?<method>((value)|(htmlencode)|(scriptencode)))\((\s*)(?<path>[\.\/\w\-_]+)(\s*)\)$"
                    , RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant
                    );

        private static Regex currentpathRegex = new Regex(@"^((.*?)/Views/(\w+))?(?<currentPath>/.+)$"
                        , RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.ECMAScript
                        );

        /// <summary>
        /// get the value from expression
        /// </summary>
        /// <param name="expression"></param>
        /// <param name="virtualPath"></param>
        /// <returns></returns>
        public static object GetEvalData(string expression, string virtualPath)
        {
            string cacheKey = string.Format("MetadataExpressionBuilder.GetEvalData.{0}.{1}.{2}.{3}"
                , SiteManager.Current.DisplayName
                , MultilingualMgr.GetCurrentCulture()
                , expression
                , virtualPath
                );
            MetadataExpressionCache cached = HttpRuntime.Cache[cacheKey] as MetadataExpressionCache;
            if (cached == null)
            {

                Match match = evalRegex.Match(expression.Trim());
                if (match.Success)
                {
                   
                    string method = match.Groups["method"].Value;
                    string path = match.Groups["path"].Value;
                    match = currentpathRegex.Match(virtualPath);
                    if (match.Success)
                    {
                        string currentPath = Regex.Replace(match.Groups["currentPath"].Value
                            , @"(\/[^\/]+)$"
                            , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_", RegexOptions.Compiled)); }
                            , RegexOptions.Compiled | RegexOptions.CultureInvariant
                            );
                        cached = new MetadataExpressionCache()
                        {
                            Path = Metadata.ResolvePath(currentPath, path)
                        };
                        switch (method)
                        {
                            case "htmlencode": cached.Type = MetadataExpressionType.HtmlEncode; break;
                            case "scriptencode": cached.Type = MetadataExpressionType.ScriptEncode; break;
                            default: cached.Type = MetadataExpressionType.RawValue; break;
                        }
                    }
                    else
                    {
                        return string.Empty;
                    }
                }
                else
                {
                    return string.Empty;
                }
            }

            if (cached != null)
            {
                HttpRuntime.Cache.Insert(cacheKey, cached, null, Cache.NoAbsoluteExpiration, Cache.NoSlidingExpiration, CacheItemPriority.NotRemovable, null);
                switch (cached.Type)
                {
                    case MetadataExpressionType.RawValue:
                        return Metadata.Get(cached.Path);

                    case MetadataExpressionType.HtmlEncode:
                        return Metadata.Get(cached.Path).SafeHtmlEncode();

                    case MetadataExpressionType.ScriptEncode:
                        return Metadata.Get(cached.Path).SafeJavascriptStringEncode();

                    default:
                        break;
                }
            }
            return expression;
        }

        /// <summary>
        /// override EvaluateExpression
        /// </summary>
        /// <param name="target">The object containing the expression.</param>
        /// <param name="entry">The object that represents information about the property bound to by the expression.</param>
        /// <param name="parsedData">The object containing parsed data as returned by ParseExpression.</param>
        /// <param name="context">Contextual information for the evaluation of the expression.</param>
        /// <returns>An object that represents the evaluated expression; otherwise, Nothing if the inheritor does not implement EvaluateExpression.</returns>
        public override object EvaluateExpression(object target, BoundPropertyEntry entry,  object parsedData, ExpressionBuilderContext context)
        {
            return GetEvalData(entry.Expression, context.VirtualPath);
        }

        /// <summary>
        /// override GetCodeExpression
        /// </summary>
        /// <param name="entry">The object that represents information about the property bound to by the expression.</param>
        /// <param name="parsedData">The object containing parsed data as returned by ParseExpression. </param>
        /// <param name="context">Contextual information for the evaluation of the expression.</param>
        /// <returns>A CodeExpression that is used for property assignment.</returns>
        public override CodeExpression GetCodeExpression(BoundPropertyEntry entry, object parsedData, ExpressionBuilderContext context)
        {
            CodeExpression[] expressionArray1 = new CodeExpression[2];
            expressionArray1[0] = new CodePrimitiveExpression(entry.Expression.Trim());
            expressionArray1[1] = new CodePrimitiveExpression(context.VirtualPath);
            return new CodeCastExpression( typeof(string)
                , new CodeMethodInvokeExpression(new CodeTypeReferenceExpression(base.GetType()), "GetEvalData", expressionArray1)
                );
        }

        /// <summary>
        /// override SupportsEvaluate, return true always to indicate supporting evaluate
        /// </summary>
        public override bool SupportsEvaluate
        {
            get { return true; }
        }

    }
}
