using System;
using System.Collections.Concurrent;
using System.IO;
using System.Linq;
using System.Web.Hosting;
using System.Xml.Linq;
using CM.State;

namespace CM.Content
{
    /// <summary>
    /// Summary description for ContentNode
    /// </summary>
    [Serializable]
    public sealed class ContentNode
    {
        public enum ContentNodeType
        {
            None,
            StaticContent,
            HtmlSnippet,
            HttpHandler,
            PartialView,            
            View,
            PageTemplate,
            Page,
            Metadata,
            
            Directory, 
            
            
     
            // for extended use only
            ClassicPage,
        }

        public enum ContentNodeStatus
        {
            Normal,
            Inherited,
            Overrode,
        }

        public string DisplayName { get; private set; }
        public string RelativePath { get; private set; }
        public string PhysicalPath { get; set; }

        public string GetFileContent()
        {
            return WinFileIO.ReadWithoutLock(this.PhysicalPath);
        }

        public string Name
        {
            get
            {
                return Path.GetFileName(PhysicalPath);
            }
        }

        public ContentNode Parent
        {
            get
            {
                if (this.RelativePath != null && this.RelativePath.Length > 1)
                {
                    int index = this.RelativePath.LastIndexOf('/');
                    if (index > 0)
                    {
                        string parentPath = this.RelativePath.Substring(0, index);
                        ContentNode found;
                        if (this.ContentTree.AllNodes.TryGetValue(parentPath, out found))
                            return found;
                    }
                    else
                        return this.ContentTree.Root;
                }
                return null;
            }
        }

        public string RealPhysicalPath 
        {
            get
            {
                string path = string.Format("~/Views/{0}{1}", this.ContentTree.DistinctName, this.RelativePath);
                return HostingEnvironment.MapPath(path);
            }
        }

        public ContentNode TemplateNode { get; set; }

        public ContentTree ContentTree { get; internal set; }

        
        public ContentNodeType NodeType { get; private set; }
        public ContentNodeStatus NodeStatus { get; internal set; }
        public bool IsDisabled { get; private set; }

        public ConcurrentDictionary<string, ContentNode> Children { get; private set; }


        /// <summary>
        /// 
        /// </summary>
        /// <param name="contentTree"></param>
        /// <param name="physicalPath"></param>
        /// <param name="relativePath"></param>
        public ContentNode(ContentTree contentTree, string physicalPath, string relativePath)
        {
            Children = new ConcurrentDictionary<string, ContentNode>(StringComparer.OrdinalIgnoreCase);

            this.NodeStatus = ContentNodeStatus.Normal;
            this.PhysicalPath = physicalPath;
            this.RelativePath = relativePath;
            this.ContentTree = contentTree;
            this.NodeType = ContentNodeType.None;
            contentTree.AllNodes[relativePath] = this;            

            FileInfo fileInfo = new FileInfo(PhysicalPath);
            if ((fileInfo.Attributes & FileAttributes.Directory) == 0)
            {
                switch (fileInfo.Extension)
                {
                    case ".ascx":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.PartialView;
                        break;
                    case ".aspx":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.View;
                        break;
                    case ".ashx":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.HttpHandler;
                        break;
                    case ".master":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.PageTemplate;
                        break;
                    case ".htm":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.StaticContent;
                        break;
                    case ".snippet":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.HtmlSnippet;
                        break;
                    default:
                        this.DisplayName = Path.GetFileName(physicalPath);
                        this.NodeType = ContentNodeType.None;
                        break;
                }
            }// file
            else
            {
                this.DisplayName = Path.GetFileName(physicalPath);
                NodeType = ContentNodeType.Directory;

                string xml = string.Format("{0}\\.properties.xml", this.PhysicalPath);
                if (File.Exists(xml))
                {
                    XDocument doc = PropertyFileHelper.OpenReadWithoutLock(xml);
                    XElement root = doc.Root;

                    ContentNodeType nodeType;
                    if (Enum.TryParse<ContentNodeType>(root.GetElementValue("Type"), out nodeType))
                    {
                        NodeType = nodeType;
                    }
                    if (string.Compare(root.GetElementValue("IsInherited", "false"), "true", true) == 0)
                    {
                        this.NodeStatus = ContentNodeStatus.Inherited;
                    }
                    if (string.Compare(root.GetElementValue("IsDisabled", "false"), "true", true) == 0)
                    {
                        this.IsDisabled = true;
                    }
                }

                LoadChildren();
            }// directory
        }//


        /// <summary>
        /// 
        /// </summary>
        /// <param name="contentTree"></param>
        /// <param name="physicalPath"></param>
        /// <param name="relativePath"></param>
        /// <param name="isFile"></param>
        public ContentNode(ContentTree contentTree, string physicalPath, string relativePath, bool isFile)
        {
            Children = new ConcurrentDictionary<string, ContentNode>(StringComparer.OrdinalIgnoreCase);

            this.NodeStatus = ContentNodeStatus.Normal;
            this.PhysicalPath = physicalPath;
            this.RelativePath = relativePath;
            this.ContentTree = contentTree;
            this.NodeType = ContentNodeType.None;
            contentTree.AllNodes[relativePath] = this;

            if (isFile)
            {
                switch (Path.GetExtension(relativePath))
                {
                    case ".ascx":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.PartialView;
                        break;
                    case ".aspx":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.View;
                        break;
                    case ".ashx":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.HttpHandler;
                        break;
                    case ".master":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.PageTemplate;
                        break;
                    case ".htm":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.StaticContent;
                        break;
                    case ".snippet":
                        this.DisplayName = Path.GetFileNameWithoutExtension(physicalPath);
                        this.NodeType = ContentNodeType.HtmlSnippet;
                        break;
                    default:
                        this.DisplayName = Path.GetFileName(physicalPath);
                        this.NodeType = ContentNodeType.None;
                        break;
                }
            }// file
            else
            {
                this.DisplayName = Path.GetFileName(physicalPath);
                NodeType = ContentNodeType.Directory;

                string xml = string.Format("{0}\\.properties.xml", this.PhysicalPath);
                if (File.Exists(xml))
                {
                    XDocument doc = PropertyFileHelper.OpenReadWithoutLock(xml);
                    XElement root = doc.Root;

                    ContentNodeType nodeType;
                    if (Enum.TryParse<ContentNodeType>(root.GetElementValue("Type"), out nodeType))
                    {
                        NodeType = nodeType;
                    }
                    if (string.Compare(root.GetElementValue("IsInherited", "false"), "true", true) == 0)
                    {
                        this.NodeStatus = ContentNodeStatus.Inherited;
                    }
                    if (string.Compare(root.GetElementValue("IsDisabled", "false"), "true", true) == 0)
                    {
                        this.IsDisabled = true;
                    }
                }

                LoadChildren();
            }// directory
        }//

        private void LoadChildren()
        {
            if (Directory.Exists(this.PhysicalPath))
            {
               CM.State.FileData[] files = CM.State.FastDirectoryEnumerator.GetFiles(this.PhysicalPath, "*", SearchOption.TopDirectoryOnly);
                //Directory.EnumerateFiles(this.PhysicalPath, "*", SearchOption.TopDirectoryOnly).Where(p => !Path.GetFileName(p).StartsWith("."));
                foreach (FileData file in files)
                {
                    if (file.Name.StartsWith("."))
                        continue;
                    new ContentNode(this.ContentTree, file.Path, string.Format("{0}/{1}", this.RelativePath.TrimEnd('/'), file.Name), true);
                }
                
                var dirs = Directory.EnumerateDirectories(this.PhysicalPath, "*", SearchOption.TopDirectoryOnly).Where(p => !Path.GetFileName(p).StartsWith("."));
                foreach (string dir in dirs)
                {
                    new ContentNode(this.ContentTree, dir, string.Format("{0}/{1}", this.RelativePath.TrimEnd('/'), Path.GetFileName(dir)), false);
                }
            }

        }

    }
}