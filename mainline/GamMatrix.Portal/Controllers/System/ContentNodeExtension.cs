using System.Web.Mvc;
using CM.Content;

namespace GamMatrix.CMS.Controllers.System
{
    /// <summary>
    /// ContentNodeExtension
    /// </summary>
    public static class ContentNodeExtension
    {
        public static string GetActionUrl(this UrlHelper urlHelper, ContentNode contentNode)
        {
            switch (contentNode.NodeType)
            {
                case ContentNode.ContentNodeType.Directory:
                    return urlHelper.RouteUrl("DirectoryMgt"
                        , new { @action = "Index", @distinctName = contentNode.ContentTree.DistinctName.DefaultEncrypt(), @relativePath = contentNode.RelativePath.DefaultEncrypt() }
                        );

                case ContentNode.ContentNodeType.Page:
                    return urlHelper.RouteUrl("PageEditor"
                        , new { @action = "Index", @distinctName = contentNode.ContentTree.DistinctName.DefaultEncrypt(), @path = contentNode.RelativePath.DefaultEncrypt() }
                        );

                case ContentNode.ContentNodeType.View:
                case ContentNode.ContentNodeType.StaticContent:
                case ContentNode.ContentNodeType.PartialView:
                case ContentNode.ContentNodeType.PageTemplate:
                case ContentNode.ContentNodeType.HtmlSnippet:
                    return urlHelper.RouteUrl("ViewEditor", new { @action = "Index", @distinctName = contentNode.ContentTree.DistinctName.DefaultEncrypt(), @path = contentNode.RelativePath.DefaultEncrypt() }
                        );

                case ContentNode.ContentNodeType.Metadata:
                    return urlHelper.RouteUrl("MetadataEditor", new { @action = "Index", @distinctName = contentNode.ContentTree.DistinctName.DefaultEncrypt(), @path = contentNode.RelativePath.DefaultEncrypt() }
                        );

                default:
                    return string.Empty;
            }
        }
    }
}