using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Xml.Linq;
using CM.db;

namespace CM.Content
{
    /// <summary>
    /// Summary description for ContentTree
    /// </summary>
    [Serializable]
    public sealed class ContentTree
    {
        private static ConcurrentDictionary<string, ContentTree> s_ContentTreeCache 
            = new ConcurrentDictionary<string, ContentTree>(StringComparer.OrdinalIgnoreCase);

        public ContentNode Root { get; private set; }
        public string DistinctName { get; private set; }
        public string TemplateDomainDistinctName { get; private set; }
        public ConcurrentDictionary<string, ContentNode> AllNodes { get; private set; }

	    private ContentTree()
	    {
            AllNodes = new ConcurrentDictionary<string, ContentNode>(StringComparer.OrdinalIgnoreCase);
	    }


        public static ContentTree GetByDistinctName(string distinctName, string templateDistinctName = null, bool useCache = true)
        {
            if (string.IsNullOrEmpty(distinctName))
                return null;

            ContentTree tree = null;

            // look for the cache
            string cacheKey = string.Format("{0}_{1}", distinctName, templateDistinctName);
            if (useCache)
            {
                if (s_ContentTreeCache.TryGetValue(cacheKey, out tree))
                {
                    return tree;
                }
            }

            tree = new ContentTree() { DistinctName = distinctName, TemplateDomainDistinctName = templateDistinctName};

            string physicalPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}", distinctName)).TrimEnd('\\');
            ContentNode root = new ContentNode(tree, physicalPath, "/", false);
            tree.Root = root;

            bool hasTemplateTree = false;
            if (!string.IsNullOrEmpty(templateDistinctName))
            {
                ContentTree templateTree = ObjectHelper.DeepClone<ContentTree>(GetByDistinctName(templateDistinctName, null, useCache));
                if (templateTree != null)
                {
                    hasTemplateTree = true;
                    tree = OverrideNodes(tree, templateTree);
                }
            }

            if (!hasTemplateTree)
            {
                foreach (KeyValuePair<string, ContentNode> item in tree.AllNodes)
                {
                    item.Value.NodeStatus = ContentNode.ContentNodeStatus.Normal;
                }
            }

            tree.UpdateHierarchicalStructure();

            // update the cache
            s_ContentTreeCache[cacheKey] = tree;
            return tree;
        }


        /// <summary>
        /// Copy nodes from tree to tree
        /// </summary>
        /// <param name="fromTree">the source tree to copy from</param>
        /// <param name="toTree">the destination tree</param>
        private static ContentTree OverrideNodes(ContentTree fromTree, ContentTree toTree)
        {
            // change the ditinctname of the detination tree
            toTree.DistinctName = fromTree.DistinctName;

            // mark every node in detination tree as ContentNodeStatus.Inherited
            foreach (KeyValuePair<string, ContentNode> item in toTree.AllNodes)
            {
                if( item.Key != "/" )
                    item.Value.NodeStatus = ContentNode.ContentNodeStatus.Inherited;
            }

            // copy each node from current tree to template tree
            foreach( KeyValuePair<string, ContentNode> fromItem in fromTree.AllNodes)
            {
                if (fromItem.Key != "/")
                {
                    // if already exists in template tree, mark as overrode
                    if (toTree.AllNodes.ContainsKey(fromItem.Key))
                    {
                        if (fromItem.Value.NodeStatus != ContentNode.ContentNodeStatus.Inherited)
                            fromItem.Value.NodeStatus = ContentNode.ContentNodeStatus.Overrode;
                        else
                            continue;// ignore the inheritted node
                     }
                    else
                        fromItem.Value.NodeStatus = ContentNode.ContentNodeStatus.Normal;

                    // copy the node from template tree
                    fromItem.Value.ContentTree = toTree;
                    toTree.AllNodes[fromItem.Key] = fromItem.Value;
                }
            }

            return toTree;
        }

        /// <summary>
        /// Update the hierarchical structure
        /// </summary>
        private void UpdateHierarchicalStructure()
        {
            // clear the Children for each node
            foreach (KeyValuePair<string, ContentNode> item in this.AllNodes)
                if(item.Value.Children.Count>0)
                    item.Value.Children.Clear();

            // get the paths order by length and populate the tree structure
            string[] paths = this.AllNodes.Keys.ToArray(); //.OrderBy(n => n.Length).ToArray();
            foreach (string path in paths)
            {
                if (path != "/")
                {
                    ContentNode node, parentNode;
                    if (this.AllNodes.TryGetValue(path, out node))
                    {
                        parentNode = node.Parent;
                        if (parentNode != null)
                            parentNode.Children[node.Name] = node;
                        else
                            throw new Exception(string.Format("Error, can't locate the parent node for {0}", node.PhysicalPath));
                    }
                    else
                        throw new Exception("Error, can't locate the node.");
                }
            }
        }
        public static bool CheckFileExists(string phisicalPath)
        {
            return File.Exists(phisicalPath); 
        }
        public static void EnsureDirectoryExistsForFile(cmSite domain, string filename)
        {
            string dir = Path.GetDirectoryName(filename);
            ContentTree.EnsureDirectoryExists(domain, dir);
        }

        public static void EnsureDirectoryExists( cmSite domain, string dirname)
        {
            if (Directory.Exists(dirname))
                return;

            string parentDir = Path.GetDirectoryName(dirname);
            EnsureDirectoryExists(domain, parentDir);

            // create the directory then look up in template dir
            Directory.CreateDirectory(dirname);

            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
            {
                string replaced = string.Format(@"\Views\{0}\", domain.TemplateDomainDistinctName);
                string templateDir = Regex.Replace(dirname
                    , string.Format(@"\\Views\\{0}\\", domain.DistinctName.Replace("-", "\\-"))
                    , replaced
                    , RegexOptions.IgnoreCase | RegexOptions.CultureInvariant| RegexOptions.Compiled
                    );
                if ( templateDir.Contains(replaced) && Directory.Exists(templateDir))
                {
                    ContentNode.ContentNodeType nodeType = ContentNode.ContentNodeType.Directory;
                    string propertyXml = Path.Combine(templateDir, ".properties.xml");
                    if (File.Exists(propertyXml))
                    {
                        XDocument doc = PropertyFileHelper.OpenReadWithoutLock(propertyXml);
                        if (!Enum.TryParse<ContentNode.ContentNodeType>(doc.Root.GetElementValue("Type"), out nodeType))
                        {
                            nodeType = ContentNode.ContentNodeType.Directory;
                        }
                    }

                    propertyXml = Path.Combine(dirname, ".properties.xml");
                    PropertyFileHelper.Save(propertyXml, new { @IsInherited = true, @Type = nodeType });
                }
            }
        }
    }
}