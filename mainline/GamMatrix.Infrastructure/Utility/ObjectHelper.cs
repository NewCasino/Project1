using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Runtime.Serialization;
using System.Xml.Serialization;
using System.Collections.Concurrent;
using System.Threading;

public static class ObjectHelper
{
    public static T GetFieldValue<T>(object obj, string attributeName)
    {
        if (obj == null)
            return default(T);
        Type type = obj.GetType();

        PropertyInfo propertyInfo = type.GetProperty(attributeName, BindingFlags.Instance | BindingFlags.Public);
        if (propertyInfo != null)
        {
            MethodInfo methodInfo = propertyInfo.GetGetMethod();
            return (T)methodInfo.Invoke(obj, null);
        }

        return default(T);
    }

    public static string GetFieldValue(object obj, string attributeName)
    {
        obj = GetFieldValue<object>(obj, attributeName);
        if (obj == null)
            return null;
        return obj.ToString();
    }


    public static bool SetFieldValue(object obj, string attributeName, object value)
    {
        if (obj == null || string.IsNullOrEmpty(attributeName) )
            return false;
        Type type = obj.GetType();

        PropertyInfo propertyInfo = type.GetProperty(attributeName, BindingFlags.Instance | BindingFlags.Public);
        if (propertyInfo != null)
        {
            MethodInfo methodInfo = propertyInfo.GetSetMethod();
            methodInfo.Invoke(obj, new object[] {value});
            return true;
        }

        return false;
    }



    /// <summary>
    /// Deep clone the object
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="obj"></param>
    /// <returns></returns>
    public static T DeepClone<T>(T obj)
    {
        return DeepCopyByExpressionTrees.DeepCopyByExpressionTree(obj);
    }

    /// <summary>
    /// Serialize object to xml file
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="obj"></param>
    /// <param name="filePath"></param>
    public static void XmlSerialize<T>(T obj, string filePath)
    {
        try
        {
            string dir = Path.GetDirectoryName(filePath);
            if (!Directory.Exists(dir))
                Directory.CreateDirectory(dir);
            DataContractSerializer dcs = new DataContractSerializer(typeof(T));
            using (FileStream fs = new FileStream(filePath, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete))
            {
                fs.SetLength(0);
                dcs.WriteObject(fs, obj);
                fs.Flush();
                fs.Close();
            }
        }
        catch (Exception ex)
        {
        }
    }

    /// <summary>
    /// Deserialize object from xml file
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="obj"></param>
    /// <param name="filePath"></param>
    /// <param name="defaultValue"></param>
    /// <returns></returns>
    public static T XmlDeserialize<T>(string filePath, T defaultValue)
    {
        try
        {
            if (File.Exists(filePath))
            {
                DataContractSerializer dcs = new DataContractSerializer(typeof(T));
                using (FileStream fs = new FileStream(filePath
                    , FileMode.Open
                    , FileAccess.Read
                    , FileShare.ReadWrite | FileShare.Delete))
                {
                    return (T)dcs.ReadObject(fs);
                }
            }
            return defaultValue;
        }
        catch(Exception ex)
        {
            return defaultValue;
        }
    }


    public static T XmlDeserialize<T>(byte[] data)
    {
        DataContractSerializer formatter = new DataContractSerializer(typeof(T));
        using (MemoryStream ms = new MemoryStream(data))
        {
            return (T)formatter.ReadObject(ms);
        }
    }

    public static byte [] XmlSerialize(object obj)
    {
        DataContractSerializer formatter = new DataContractSerializer(obj.GetType());
        using (MemoryStream ms = new MemoryStream())
        {
            formatter.WriteObject(ms, obj);
            return ms.ToArray();
        }
    }



    /// <summary>
    /// Binary Serialize
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="obj"></param>
    /// <param name="filePath"></param>
    public static void BinarySerialize<T>(T obj, string filePath)
    {
        try
        {
            // Invalidate memory cache
            Tuple<DateTime, object> cachedObj;
            cachedObjects.TryRemove(filePath, out cachedObj);
            //string tempFile = filePath + ".tmp";
            using (FileStream fs = new FileStream(filePath, FileMode.OpenOrCreate, FileAccess.Write, FileShare.None))
            {
                fs.SetLength(0);
                BinaryFormatter bf = new BinaryFormatter();
                bf.Serialize(fs, obj);
                fs.Flush();
                fs.Close();
            }
            //File.Copy(tempFile, filePath, true);
            //File.Delete(tempFile);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(string.Format("BinarySerialize ({0} -> {1}): {2}", typeof(T), filePath, ex.ToString()));
        }
    }

    private static ConcurrentDictionary<string, Tuple<DateTime, object>> cachedObjects = new ConcurrentDictionary<string, Tuple<DateTime, object>>();
    private const long CACHED_OBJECTS_CLEAN_INTERVAL = 60000;
    private static Timer timer = new Timer(new TimerCallback(cachedObjectsCleanup), null, CACHED_OBJECTS_CLEAN_INTERVAL, CACHED_OBJECTS_CLEAN_INTERVAL);

    private static void cachedObjectsCleanup(object state)
    {
        foreach (var entry in cachedObjects)
        {
            if (entry.Value.Item1 < DateTime.UtcNow)
            {
                Tuple<DateTime, object> cachedObj;
                cachedObjects.TryRemove(entry.Key, out cachedObj);
            }
        }
    }

    /// <summary>
    /// Binary Deserialize
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="filePath"></param>
    /// <param name="defaultValue"></param>
    /// <returns></returns>
    public static T BinaryDeserialize<T>(string filePath, T defaultValue)
    {
        try
        {
            // Check memory cache
            Tuple<DateTime, object> cachedObj;
            if (cachedObjects.TryGetValue(filePath, out cachedObj) && cachedObj.Item1 < DateTime.UtcNow)
            {
                return (T)cachedObj.Item2;
            }
            else
            {
                if (File.Exists(filePath))
                {
                    using (FileStream fs = new FileStream(filePath
                    , FileMode.Open
                    , FileAccess.Read
                    , FileShare.ReadWrite | FileShare.Delete))
                    {
                        fs.Position = 0;
                        BinaryFormatter bf = new BinaryFormatter();
                        object newObj = bf.Deserialize(fs);
                        cachedObjects[filePath] = new Tuple<DateTime, object> (DateTime.UtcNow.AddMinutes(1), newObj);
                        return (T)newObj;
                    }
                }
                return defaultValue;
            }
        }
        catch
        {
            return defaultValue;
        }
    }
    
}

