using System;
using System.IO;
using System.Xml.Linq;
using CM.db;
using CM.Sites;

namespace CM.Content
{
    /// <summary>
    /// Summary description for PageNode
    /// </summary>
    public sealed class PageNode
    {
        public ContentNode ContentNode { get; private set; }
        public string Controller { get; set; }
        public string RouteName { get; set; }

        public PageNode(ContentNode contentNode)
	    {
            if (contentNode.NodeType != Content.ContentNode.ContentNodeType.Page)
                throw new Exception("Error, invalid content node type.");
            this.ContentNode = contentNode;
            string file = Path.Combine( contentNode.PhysicalPath, ".properties.xml");
            if( !File.Exists(file) )
                return;

            XDocument doc = PropertyFileHelper.OpenReadWithoutLock(file);
            this.Controller = doc.Root.GetElementValue("Controller");
            this.RouteName = doc.Root.GetElementValue("RouteName").DefaultIfNullOrEmpty(contentNode.RelativePath.Replace('/','_'));
	    }

        public void Save()
        {
            string file = this.ContentNode.RealPhysicalPath + "\\.properties.xml";

            cmSite domain = SiteManager.GetSiteByDistinctName(ContentNode.ContentTree.DistinctName);
            ContentTree.EnsureDirectoryExistsForFile(domain, file);

            PropertyFileHelper.Save(file, new { @Controller = this.Controller, @RouteName = this.RouteName, @IsInherited = false });
        }
    }
}