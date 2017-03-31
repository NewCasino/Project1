using System;
using System.Collections;
using System.Collections.Generic;
using System.Web;
using System.Web.Caching;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;

public sealed class DelayUpdateCache<T>
{
    private DateTime m_LastUpdateTime;
    private T m_Value = default(T);
    private double m_ExpirySeconds = 10.00;
    private static Dictionary<string, object> s_LockObjs = new Dictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);

    private static object GetLockObj(string cacheKey)
    {
        object lockObj;
        if (s_LockObjs.TryGetValue(cacheKey, out lockObj))
            return lockObj;

        lock (s_LockObjs)
        {
            if (s_LockObjs.TryGetValue(cacheKey, out lockObj))
                return lockObj;

            lockObj = new object();
            s_LockObjs[cacheKey] = lockObj;
            return lockObj;
        }
    }

    public static bool TryGetValue(string cacheKey, out T value, Func<T> func, int expirySeconds, bool forceUpdate = false)
    {
        value = default(T);
        bool isAvailable = false;
        bool updateCache = true;

        DelayUpdateCache<T> cache = HttpRuntime.Cache[cacheKey] as DelayUpdateCache<T>;
        if (cache != null)
        {
            isAvailable = true;
            value = cache.m_Value;
            if ((DateTime.Now - cache.m_LastUpdateTime).TotalSeconds <= cache.m_ExpirySeconds)
            {
                updateCache = false;
            }
        }
        else
        {
            cache = new DelayUpdateCache<T>();
        }

        if (forceUpdate)
        {
            object lockObj = GetLockObj(cacheKey);
            if (Monitor.TryEnter(lockObj))
            {
                try
                {
                    cache.m_LastUpdateTime = DateTime.Now;
                    cache.m_Value = func();
                    cache.m_ExpirySeconds = expirySeconds;

                    SetCache(cacheKey, cache);

                    value = cache.m_Value;
                    isAvailable = true;
                }
                catch
                {
                }
                finally
                {
                    Monitor.Exit(lockObj);
                }
            }
        }
        else if (updateCache)
        {
            Task.Factory.StartNew(() =>
            {
                object lockObj = GetLockObj(cacheKey);
                if (Monitor.TryEnter(lockObj))
                {
                    try
                    {
                        cache.m_LastUpdateTime = DateTime.Now;
                        cache.m_Value = func();
                        cache.m_ExpirySeconds = expirySeconds;

                        SetCache(cacheKey, cache);
                    }
                    catch
                    {
                    }
                    finally
                    {
                        Monitor.Exit(lockObj);
                    }
                }
            });
        }


        return isAvailable;
    }

    public static void SetValue(string cacheKey, T value, int expirySeconds)
    {
        DelayUpdateCache<T> cache = new DelayUpdateCache<T>();
        cache.m_LastUpdateTime = DateTime.Now;
        cache.m_Value = value;
        cache.m_ExpirySeconds = expirySeconds;

        SetCache(cacheKey, cache);
    }

    public static void SetExpired(string cacheKey)
    {
        if (HttpRuntime.Cache[cacheKey] != null)
            HttpRuntime.Cache.Remove(cacheKey);
    }

    public static void SetExpiredByPrefix(string cacheKeyPrefix)
    {
        List<string> keys = new List<string>();
        IDictionaryEnumerator enumerator = HttpRuntime.Cache.GetEnumerator();
        while (enumerator.MoveNext())
        {
            string key = enumerator.Key.ToString();
            if (key.StartsWith(cacheKeyPrefix, StringComparison.InvariantCultureIgnoreCase))
                keys.Add(key);
        }
        foreach (string key in keys)
            SetExpired(key);
    }

    public static void SetCache(string cacheKey, DelayUpdateCache<T> cache)
    {
        HttpRuntime.Cache.Insert(cacheKey
            , cache
            , null
            , Cache.NoAbsoluteExpiration
            , Cache.NoSlidingExpiration
            , CacheItemPriority.NotRemovable
            , null
            );
    }
}
