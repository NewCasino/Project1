using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace CmsAgent.FileManager
{
    public class StaticFileHostConfigCollection : ConfigurationElementCollection
    {
        public StaticFileHostConfigCollection()
        {
        }

        public override ConfigurationElementCollectionType CollectionType
        {
            get
            {
                return ConfigurationElementCollectionType.AddRemoveClearMap;
            }
        }

        protected override ConfigurationElement CreateNewElement()
        {
            return new StaticFileHostConfigElement();
        }

        protected override Object GetElementKey(ConfigurationElement element)
        {
            return ((StaticFileHostConfigElement)element).Name;
        }

        public StaticFileHostConfigElement this[int index]
        {
            get
            {
                return (StaticFileHostConfigElement)BaseGet(index);
            }
            set
            {
                if (BaseGet(index) != null)
                {
                    BaseRemoveAt(index);
                }
                BaseAdd(index, value);
            }
        }

        new public StaticFileHostConfigElement this[string Name]
        {
            get
            {
                return (StaticFileHostConfigElement)BaseGet(Name);
            }
        }

        public int IndexOf(StaticFileHostConfigElement url)
        {
            return BaseIndexOf(url);
        }

        public void Add(StaticFileHostConfigElement url)
        {
            BaseAdd(url);
        }
        protected override void BaseAdd(ConfigurationElement element)
        {
            BaseAdd(element, false);
        }

        public void Remove(StaticFileHostConfigElement url)
        {
            if (BaseIndexOf(url) >= 0)
                BaseRemove(url.Name);
        }

        public void RemoveAt(int index)
        {
            BaseRemoveAt(index);
        }

        public void Remove(string name)
        {
            BaseRemove(name);
        }

        public void Clear()
        {
            BaseClear();
        }
    }
}
