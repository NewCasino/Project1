using System;
using System.IO;
using System.Reflection;
using System.Text;
using System.Xml.Linq;

namespace CM.Content
{
    public sealed class PropertyFileHelper
    {
        public static XDocument OpenReadWithoutLock(string filename)
        {
            try
            {
                using (FileStream fs = new FileStream(filename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                {
                    XDocument doc = XDocument.Load(fs);
                    return doc;
                }
            }
            catch(Exception ex)
            {
                throw new Exception(string.Format("Error occurs in OpenReadWithoutLock when opening file [{0}].", filename), ex);
            }
        }
        public static void Save(string filename, object properties, bool removeEmpty = false)
        {
            XDocument doc = null;
            try
            {
                doc = OpenReadWithoutLock(filename);
            }
            catch
            {
                doc = new XDocument(new XDeclaration("1.0", "utf-8", "yes"), new XElement("root"));
            }
            PropertyInfo[] infos = properties.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (PropertyInfo property in infos)
            {
                switch (property.PropertyType.Name)
                {
                    default:
                        object val = property.GetValue(properties, null);
                        if (val != null)
                        {
                            doc.Root.ElementOrCreate(property.Name).Value = val.ToString();
                        }
                        else
                        {
                            if (removeEmpty)
                            {
                                doc.Root.ElementOrCreate(property.Name).Remove();
                            }
                        }
                        break;
                }
            }

            using (FileStream fs = new FileStream(filename, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite | FileShare.Delete))
            {
                fs.SetLength(0L);
                doc.Save(fs);
                fs.Close();
            }
        }
    }
}
