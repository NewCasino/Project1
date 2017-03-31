using System;
using System.Collections.Generic;
using System.Web.Mvc;
using System.Reflection;

public static class ViewDataDictionaryExtension
{
    public static ViewDataDictionary Merge(this ViewDataDictionary viewData, object obj = null)
    {
        if (obj != null)
        {
            PropertyInfo[] properties = obj.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (PropertyInfo property in properties)
            {
                if (property.CanRead)
                {
                    viewData[property.Name] = property.GetValue(obj, null);
                }
            }
        }

        return viewData;
    }

    public static T GetValue<T>(this ViewDataDictionary viewData, string key, T defValue)
    {
        object val = viewData[key];
        if (val == null)
            return defValue;

        try
        {
            return (T)val;
        }
        catch
        {
            return defValue;
        }      
    }
}
