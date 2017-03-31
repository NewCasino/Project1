<%@ Application Language="C#" %>
<%@ Import Namespace="CM.Sites" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Reflection" %>
<script Language="C#" RunAt="server">
    
    private static bool m_IsInitialized = false;
    
    public override void Init()
    {
        // for .NET 4.5
        try
        {
            System.Runtime.GCSettings.LatencyMode = System.Runtime.GCLatencyMode.SustainedLowLatency;
        }
        catch
        {
        }
        
        if (m_IsInitialized)
            return;
        lock (this.GetType())
        {
            if (m_IsInitialized)
                return;
            m_IsInitialized = true;
        }
		
		CasinoEngine.Watcher.Initialize();

        EventLog log = new EventLog();
        log.Source = "CMS2012";
        log.WriteEntry("Application Pool Starting..." , EventLogEntryType.Information);
        
        try
        {
            base.Init();
            CM.Sites.SiteManager.InitialLoadConfiguration();
            //CM.Sites.SiteManager.ReloadSiteHostCache();
            //CM.State.IPLocation.UpdateToLatest();
            Logger.Information("CMS2012", "Application Pool finish loading");
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
        }
    }
    
    
    
    // eventcreate /ID 1 /L APPLICATION /T INFORMATION /SO CMS2012  /D "CMS2012"
    void Application_End(object sender, EventArgs e)
    {
        HttpRuntime runtime = (HttpRuntime) typeof(System.Web.HttpRuntime).InvokeMember("_theRuntime"
            , BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.GetField
            , null
            , null
            , null
            );
        if (runtime == null) return;
    
        string shutDownMessage = (string)runtime.GetType().InvokeMember("_shutDownMessage"
            , BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.GetField
            , null
            , runtime
            , null
            );

        string shutDownStack = (string)runtime.GetType().InvokeMember("_shutDownStack"
            , BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.GetField
            , null
            , runtime 
            , null
            );

        EventLog log = new EventLog();
        log.Source = "CMS2012";
        log.WriteEntry(String.Format("\r\n\r\n_shutDownMessage={0}\r\n\r\n_shutDownStack={1}"
            , shutDownMessage
            , shutDownStack
            )
            , EventLogEntryType.Warning
            );
    }

    void Application_Error(object sender, EventArgs e)
    {
        Exception ex = Server.GetLastError();
        ExceptionHandler.Process(ex);
    }
</script>