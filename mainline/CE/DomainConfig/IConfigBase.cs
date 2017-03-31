using System;
using System.Collections.Generic;
using System.Configuration;
using System.Reflection;
using CE.db;
using CE.db.Accessor;

namespace CE.DomainConfig
{
    public abstract class IConfigBase
    {
        public static Dictionary<ConfigAttribute, ceDomainConfigItem> DirectReadAll<T>(long domainID) where T : IConfigBase
        {
            return DirectReadAll(domainID, typeof(T));
        }

        public static Dictionary<ConfigAttribute, ceDomainConfigItem> DirectReadAll(long domainID, Type type)
        {
            DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
            Dictionary<string, ceDomainConfigItem> items = dca.GetConfigurationItemsByDomainID(domainID);

            Dictionary<ConfigAttribute, ceDomainConfigItem> dic = new Dictionary<ConfigAttribute, ceDomainConfigItem>();

            FieldInfo [] fields = type.GetFields(BindingFlags.Public | BindingFlags.Static);
            foreach (FieldInfo field in fields)
            {
                object [] attributes = field.GetCustomAttributes(typeof(ConfigAttribute), false);
                if( attributes.Length == 0 ) continue;

                ConfigAttribute attr = attributes[0] as ConfigAttribute;
                if( attr == null ) continue;

                if (field.FieldType != typeof(string)) continue;
  
                string itemName = field.GetValue(null) as string;
                if( itemName == null ) continue;

                ceDomainConfigItem item = null;
                if (!items.TryGetValue(itemName, out item) || item == null)
                {
                    item = new ceDomainConfigItem()
                    {
                        ItemName = itemName,
                    };

                    if (!string.Equals(ConfigurationManager.AppSettings["ProductionMode"], "off", StringComparison.InvariantCultureIgnoreCase))
                    {
                        item.ItemValue = attr.ProductionDefaultValue;
                    }
                    else
                    {
                        item.ItemValue = attr.StagingDefaultValue;
                    }
                }

                dic[attr] = item;
            }

            return dic;
        }
    }
}
