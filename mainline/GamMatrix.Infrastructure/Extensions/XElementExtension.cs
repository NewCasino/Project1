using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Linq;


public static class XElementExtension
{
    /// <summary>
    /// Get the child element, if not exist, create
    /// </summary>
    /// <param name="parent"></param>
    /// <param name="name"></param>
    /// <returns></returns>
    public static XElement ElementOrCreate(this XElement parent, XName name)
    {
        XElement child = parent.Element(name);
        if (child != null)
            return child;

        child = new XElement(name);
        parent.Add(child);
        return child;
    }

    /// <summary>
    /// Get child element value
    /// </summary>
    /// <param name="parent"></param>
    /// <param name="name"></param>
    /// <param name="defaultValue"></param>
    /// <returns></returns>
    public static string GetElementValue(this XElement parent, XName name, string defaultValue = null)
    {
        XElement child = parent.Element(name);
        if (child == null)
            return defaultValue;

        return child.Value;
    }


    public static bool GetElementValue(this XElement parent, XName name, bool defaultValue)
    {
        XElement child = parent.Element(name);
        if (child == null)
            return defaultValue;

        return string.Equals(child.Value, "1") ||
             string.Equals(child.Value, "yes", StringComparison.InvariantCultureIgnoreCase) ||
             string.Equals(child.Value, "true", StringComparison.InvariantCultureIgnoreCase) ||
             string.Equals(child.Value, "OK", StringComparison.InvariantCultureIgnoreCase);
    }


    /// <summary>
    /// Get Attribute value
    /// </summary>
    /// <param name="parent"></param>
    /// <param name="name"></param>
    /// <param name="defaultValue"></param>
    /// <returns></returns>
    public static string GetAttributeValue(this XElement node, XName name, string defaultValue = null)
    {
        XAttribute attr = node.Attribute(name);
        if (attr == null)
            return defaultValue;

        return attr.Value;
    }

}

