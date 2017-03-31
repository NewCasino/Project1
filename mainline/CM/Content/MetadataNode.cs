using System;
using System.IO;
using System.Xml.Linq;
using CM.db;
using CM.Sites;

namespace CM.Content
{
    public sealed class MetadataNode
    {
        public ContentNode ContentNode { get; private set; }
        public DateTime? ValidFrom { get; set; }
        public DateTime? ExpiryTime { get; set; }
        public bool AvailableForUKLicense { get; set; }
        public bool AvailableForNonUKLicense { get; set; }

        public MetadataNode(ContentNode contentNode)
	    {
            if (contentNode.NodeType != Content.ContentNode.ContentNodeType.Metadata)
                throw new Exception("Error, invalid content node type.");
            this.ContentNode = contentNode;
            string file = Path.Combine( contentNode.PhysicalPath, ".properties.xml");
            if( !File.Exists(file) )
                return;

            XDocument doc = PropertyFileHelper.OpenReadWithoutLock(file);
            this.ValidFrom = ConvertHelper.ToDateTime(doc.Root.GetElementValue("ValidFrom"), DateTime.MinValue);
            this.ExpiryTime = ConvertHelper.ToDateTime(doc.Root.GetElementValue("ExpiryTime"), DateTime.MinValue);
            if (this.ValidFrom == DateTime.MinValue)
                this.ValidFrom = null;
            if (this.ExpiryTime == DateTime.MinValue)
                this.ExpiryTime = null;
            this.AvailableForUKLicense = ConvertHelper.ToBoolean(doc.Root.GetElementValue("AvailableForUKLicense", "1"), true);
            this.AvailableForNonUKLicense = ConvertHelper.ToBoolean(doc.Root.GetElementValue("AvailableForNonUKLicense", "1"), true);
	    }

        public void Save()
        {
            string file = this.ContentNode.RealPhysicalPath + "\\.properties.xml";

            cmSite domain = SiteManager.GetSiteByDistinctName(ContentNode.ContentTree.DistinctName);
            ContentTree.EnsureDirectoryExistsForFile(domain, file);

            PropertyFileHelper.Save(file, new { 
                @ValidFrom = this.ValidFrom, 
                @ExpiryTime = this.ExpiryTime, 
                @AvailableForUKLicense = this.AvailableForUKLicense,
                @AvailableForNonUKLicense = this.AvailableForNonUKLicense,
                @IsInherited = false 
            }, true);
        }
    }
}
