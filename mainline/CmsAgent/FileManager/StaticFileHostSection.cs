using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace CmsAgent.FileManager
{
    public class StaticFileHostSection : ConfigurationSection
    {
        [ConfigurationProperty("", IsDefaultCollection = true, IsKey = false, IsRequired = false)]
        [ConfigurationCollection(typeof(StaticFileHostConfigCollection),
            AddItemName = "add",
            ClearItemsName = "clear",
            RemoveItemName = "remove")]
        public StaticFileHostConfigCollection Collection
        {
            get
            {
                StaticFileHostConfigCollection urlsCollection =
                    (StaticFileHostConfigCollection)base[""];
                return urlsCollection;
            }
            set
            {
                base[""] = value;
            }
        }
    }
}
