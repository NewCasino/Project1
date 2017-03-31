using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CE.db;
using CE.db.Accessor;
using GamMatrixAPI;
using System.Configuration;

public static class DomainManager
{   
    public static long CurrentDomainID
    {
        set { HttpContext.Current.Items["_CurrentDomainID"] = value; }
        get 
        {
            return (long)HttpContext.Current.Items["_CurrentDomainID"];
        }
    }

    public static bool AllowEdit()
    {
        var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
        if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
            domain = DomainManager.GetSysDomain();

        if (domain == null)
            return true;

        string disallowEdit = domain.GetCfg(CE.DomainConfig.Generic.DisallowEdit);
        if (string.Equals(string.IsNullOrWhiteSpace(disallowEdit) ? null : disallowEdit.ToLower(), "true", StringComparison.InvariantCultureIgnoreCase))
        {
            return false;
        }
        return true;
    }

    public static List<ceDomainConfigEx> GetDomains()
    {
        List<ceDomainConfigEx> domains = HttpRuntime.Cache[Constant.DomainCacheKey] as List<ceDomainConfigEx>;
        if (domains != null)
            return ObjectHelper.DeepClone(domains);

        lock (typeof(DomainManager))
        {
            domains = HttpRuntime.Cache[Constant.DomainCacheKey] as List<ceDomainConfigEx>;
            if (domains != null)
                return domains;

            DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
            domains = dca.GetAll(ActiveStatus.Active);

            CacheManager.AddCache(Constant.DomainCacheKey, domains);
        }
        return domains;
    }

    public static ceDomainConfigEx GetSysDomain()
    {
        ceDomainConfigEx domain = HttpRuntime.Cache[Constant.SysDomainCacheKey] as ceDomainConfigEx;
        if(domain!=null)
            return domain;

        lock (typeof(DomainManager))
        {
            domain = HttpRuntime.Cache[Constant.SysDomainCacheKey] as ceDomainConfigEx;
            if (domain != null)
                return domain;

            DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
            domain = dca.GetSys();

            CacheManager.AddCache(Constant.SysDomainCacheKey, domain);
        }

        return domain;
    }

    public static List<DomainVendorConfig> GetDomainVendors()
    {
        List<DomainVendorConfig> domainVendors = HttpRuntime.Cache[Constant.DomainVendorCacheKey] as List<DomainVendorConfig>;
        if (domainVendors != null)
            return domainVendors;

        lock (typeof(DomainManager))
        {
            domainVendors = HttpRuntime.Cache[Constant.DomainVendorCacheKey] as List<DomainVendorConfig>;
            if (domainVendors != null)
                return domainVendors;

            DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
            domainVendors = dca.GetEnabledVendorsForAllOperators(Constant.SystemDomainID);

            CacheManager.AddCache(Constant.DomainVendorCacheKey, domainVendors);
        }
        return domainVendors;
    }

    public static Dictionary<string, ceDomainConfigEx> GetApiUsername_DomainDictionary()
    {
        return GetDomains().Where( d => !string.IsNullOrWhiteSpace(d.ApiUsername) )
            .ToDictionary(d => d.ApiUsername, d => d, StringComparer.OrdinalIgnoreCase);
    }

    public static bool IsVendorEnabled(VendorID vendorID)
    {
        if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
            return true;

        CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
        List<VendorID> enabledVendors = cva.GetEnabledVendors(DomainManager.CurrentDomainID);
        return enabledVendors.Exists(v => v == vendorID);
    }
}
