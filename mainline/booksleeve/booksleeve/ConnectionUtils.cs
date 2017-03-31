using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookSleeve
{
    /// <summary>
    /// Provides utility methods for managing connections to multiple (master/slave) redis servers (with the same
    /// information - not sharding).
    /// </summary>
    public static class ConnectionUtils
    {
        /// <summary>
        /// Inspect the provided configration, and connect to the available servers to report which server is the preferred/active node.
        /// </summary>
        public static string SelectConfiguration(string configuration, out string[] availableEndpoints, TextWriter log = null)
        {
            return SelectConfiguration(configuration, out availableEndpoints, null, log);
        }
        /// <summary>
        /// Inspect the provided configration, and connect to the available servers to report which server is the preferred/active node.
        /// </summary>
        public static string SelectConfiguration(string configuration, out string[] availableEndpoints, string tieBreakerKey = null, TextWriter log = null)
        {
            string selected;
            using (SelectAndCreateConnection(configuration, log, out selected, out availableEndpoints, false, null, tieBreakerKey)) { }
            return selected;
        }
        /// <summary>
        /// Inspect the provided configration, and connect to the preferred/active node after checking what nodes are available.
        /// </summary>
        public static RedisConnection Connect(string configuration, TextWriter log = null)
        {
            // historically, it would auto-master by default
            return Connect(configuration, true, null, log);
        }

        /// <summary>
        /// Inspect the provided configration, and connect to the preferred/active node after checking what nodes are available.
        /// </summary>
        public static RedisConnection Connect(string configuration, bool autoMaster, string tieBreakerKey = null, TextWriter log = null)
        {
            string selectedConfiguration;
            string[] availableEndpoints;
            return SelectAndCreateConnection(configuration, log, out selectedConfiguration, out availableEndpoints, autoMaster, null, tieBreakerKey);
        }

        /// <summary>
        /// Subscribe to perform some operation when a change to the preferred/active node is broadcast.
        /// </summary>
        public static void SubscribeToMasterSwitch(RedisSubscriberConnection connection, Action<string> handler)
        {
            if (connection == null) throw new ArgumentNullException("connection");
            if (handler == null) throw new ArgumentNullException("handler");

            connection.Subscribe(RedisMasterChangedChannel, (channel, message) => handler(Encoding.UTF8.GetString(message)));
        }
        /// <summary>
        /// Using the configuration available, and after checking which nodes are available, switch the master node and broadcast this change.
        /// </summary>
        public static void SwitchMaster(string configuration, string newMaster, TextWriter log = null)
        {
            SwitchMaster(configuration, newMaster, null, log);
        }
        /// <summary>
        /// Using the configuration available, and after checking which nodes are available, switch the master node and broadcast this change.
        /// </summary>
        public static void SwitchMaster(string configuration, string newMaster, string tieBreakerKey = null, TextWriter log = null)
        {
            string newConfig;
            string[] availableEndpoints;

            SelectAndCreateConnection(configuration, log, out newConfig, out availableEndpoints, false, newMaster, tieBreakerKey);
        }

        const string RedisMasterChangedChannel = "__Booksleeve_MasterChanged";

        /// <summary>
        /// Prompt all clients to reconnect.
        /// </summary>
        public static void BroadcastReconnectMessage(RedisConnection connection)
        {
            if(connection == null) throw new ArgumentNullException("connection");

            connection.Wait(connection.Publish(RedisMasterChangedChannel, "*"));
        }
        private static RedisConnection SelectWithTieBreak(TextWriter log, List<RedisConnection> nodes, Dictionary<string, int> tiebreakers)
        {
            if (nodes.Count == 0) return null;
            if (nodes.Count == 1) return nodes[0];
            Func<string, int> valueOrDefault = key =>
            {
                int tmp;
                if (!tiebreakers.TryGetValue(key, out tmp)) tmp = 0;
                return tmp;
            };
            var tuples = (from node in nodes
                          let key = node.Host + ":" + node.Port
                          let count = valueOrDefault(key)
                          select new { Node = node, Key = key, Count = count }).ToList();

            // check for uncontested scenario
            int contenderCount = tuples.Count(x => x.Count > 0);
            switch (contenderCount)
            {
                case 0:
                    log.WriteLine("No tie-break contenders; selecting arbitrary node");
                    return tuples[0].Node;
                case 1:
                    log.WriteLine("Unaminous tie-break winner");
                    return tuples.Single(x => x.Count > 0).Node;
            }

            // contested
            int maxCount = tuples.Max(x => x.Count);
            var competing = tuples.Where(x => x.Count == maxCount).ToList();

            switch (competing.Count)
            {
                case 0:
                    return null; // impossible, but never rely on the impossible not happening ;p
                case 1:
                    log.WriteLine("Contested, but clear, tie-break winner");
                    break;
                default:
                    log.WriteLine("Contested and ambiguous tie-break; selecting arbitrary node");
                    break;
            }
            return competing[0].Node;
        }

        private static string[] GetConfigurationOptions(string configuration, out int syncTimeout, out bool allowAdmin, out string serviceName, out string clientName, out int keepAlive)
        {
            syncTimeout = 1000;
            allowAdmin = false;
            clientName = serviceName = null;
            keepAlive = -1;

            // break it down by commas
            var arr = configuration.Split(',');
            var options = new List<string>();
            foreach (var paddedOption in arr)
            {
                var option = paddedOption.Trim();

                if (string.IsNullOrWhiteSpace(option) || options.Contains(option)) continue;

                // check for special tokens
                int idx = option.IndexOf('=');
                if (idx > 0)
                {
                    if (option.StartsWith(SyncTimeoutPrefix))
                    {
                        int tmp;
                        if (int.TryParse(option.Substring(idx + 1).Trim(), out tmp)) syncTimeout = tmp;
                        continue;
                    }
                    else if (option.StartsWith(AllowAdminPrefix))
                    {
                        bool tmp;
                        if (bool.TryParse(option.Substring(idx + 1).Trim(), out tmp)) allowAdmin = tmp;
                        continue;
                    }
                    else if (option.StartsWith(ServiceNamePrefix))
                    {
                        serviceName = option.Substring(idx + 1).Trim();
                        continue;
                    }
                    else if (option.StartsWith(ClientNamePrefix))
                    {
                        clientName = option.Substring(idx + 1).Trim();
                        continue;
                    }
                    else if (option.StartsWith(KeepAlivePrefix))
                    {
                        int tmp;
                        if (int.TryParse(option.Substring(idx + 1).Trim(), out tmp)) keepAlive = tmp;
                        continue;
                    }
                }

                options.Add(option);
            }
            return options.ToArray();
        }

        internal const string AllowAdminPrefix = "allowAdmin=", SyncTimeoutPrefix = "syncTimeout=",
            ServiceNamePrefix = "serviceName=", ClientNamePrefix = "name=", KeepAlivePrefix = "keepAlive=";
        
        [Conditional("VERBOSE")]
        static void TraceWriteTime(string state)
        {
#if VERBOSE
            System.Diagnostics.Trace.WriteLine(DateTime.Now.ToString("HH:mm:ss.ffff") + " - " + state);
#endif
        }

        static string ExtractMasters(RedisConnection from, string value)
        {
            string line;
            var toKeep = new List<string>();
            using (var reader = new StringReader(value))
            {
                while ((line = reader.ReadLine()) != null)
                {
                    string[] parts = line.Split(' ');
                    if (parts.Length < 8) continue;
                    if (parts[6] != "connected") continue;
                    string addr;
                    switch(parts[2])
                    {
                        case "master":
                            addr = parts[1];
                            break;
                        case "myself,master":
                            addr = from.Host + ":" + from.Port;
                            break;
                        default:
                            continue; // not recognised
                    }
                    toKeep.Add(parts[0] + " " + addr + " " + parts[7]);
                }
            }
            toKeep.Sort();
            return string.Join(Environment.NewLine, toKeep);
        }

#if CLUSTER
        /// <summary>
        /// Obtains the happy nodes from what we know
        /// </summary>
        internal static RedisCluster.ClusterNode[] ConnectToCluster(string configuration, TextWriter log)
        {
            TraceWriteTime("Start: " + configuration);
            if(log == null) log = new StringWriter();
            int syncTimeout;
            bool allowAdmin;
            string serviceName;
            string clientName;
            int keepAlive;
            var arr = GetConfigurationOptions(configuration, out syncTimeout, out allowAdmin, out serviceName, out clientName, out keepAlive);

            log.WriteLine("{0} unique nodes specified", arr.Length);
            if (arr.Length == 0)
            {
                log.WriteLine("No nodes to consider");
                return null;
            }
            Task<string>[] infos, nodes;
            var connections = new List<RedisConnection>(arr.Length);
            var configSets = new List<string>();
            try
            {
                ConnectToNodes(log, null, syncTimeout, keepAlive, allowAdmin, clientName, arr, connections, out infos, out nodes, AuxMode.ClusterNodes);

                for (int i = 0; i < arr.Length; i++)
                {
                    if (infos[i].IsCompleted && nodes[i].IsCompleted)
                    {
                        string result = ExtractMasters(connections[i], nodes[i].Result);
                        if(!string.IsNullOrWhiteSpace(result)) configSets.Add(result);
                    }
                }

                var uniqueSets = configSets.GroupBy(x => x).ToList();
                string selectedConfig;
                switch(uniqueSets.Count)
                {
                    case 0:
                        log.WriteLine("No nodes responded to cluster-configuration");
                        return null;
                    case 1:
                        log.WriteLine("All {0} nodes agreed on cluster-configuration", configSets.Count);
                        selectedConfig = uniqueSets[0].Key;
                        break;
                    default:
                        var selectedGrp = uniqueSets.OrderBy(x => x.Count()).Last();
                        log.WriteLine("Cluster-configuration conflict; {0} unique combinations; taking concensus of {1}", uniqueSets.Count, selectedGrp.Count());
                        selectedConfig = selectedGrp.Key;
                        break;
                }
                log.WriteLine(selectedConfig);
                var toKeep = new List<RedisCluster.ClusterNode>();
                using (var reader = new StringReader(selectedConfig))
                {
                    string line;
                    while ((line = reader.ReadLine()) != null)
                    {
                        var parts = line.Split(' ', ':');
                        var host = parts[1];
                        int port = int.Parse(parts[2]);
                        int index = connections.FindIndex(x => x.Host == host && x.Port == port);
                        if (index >= 0)
                        {
                            var conn = connections[index];
                            toKeep.Add(new RedisCluster.ClusterNode(parts[0], conn, parts[3]));
                            connections.RemoveAt(index);
                        }
                    }
                }
                return toKeep.ToArray();
            }
            finally
            {
                TraceWriteTime("Start cleanup");
                foreach (var conn in connections)
                {
                    if (conn != null) try { conn.Dispose(); } catch { }
                }
                TraceWriteTime("End cleanup");
            }

        }
#endif
        internal static RedisConnection SelectAndCreateConnection(string configuration, TextWriter log, out string selectedConfiguration, out string[] availableEndpoints, bool autoMaster, string newMaster = null, string tieBreakerKey = null)
        {
            TraceWriteTime("Start: " + configuration);
            if (tieBreakerKey == null) tieBreakerKey = "__Booksleeve_TieBreak"; // default tie-breaker key
            int syncTimeout;
            int keepAlive;
            bool allowAdmin;
            string serviceName;
            string clientName;
            if(log == null) log = new StringWriter();
            var arr = GetConfigurationOptions(configuration, out syncTimeout, out allowAdmin, out serviceName, out clientName, out keepAlive);
            if (!string.IsNullOrWhiteSpace(newMaster)) allowAdmin = true; // need this to diddle the slave/master config

            log.WriteLine("{0} unique nodes specified", arr.Length);
            log.WriteLine("sync timeout: {0}ms, admin commands: {1}", syncTimeout,
                          allowAdmin ? "enabled" : "disabled");
            if (!string.IsNullOrEmpty(serviceName)) log.WriteLine("service: {0}", serviceName);
            if (!string.IsNullOrEmpty(clientName)) log.WriteLine("client: {0}", clientName);
            if (arr.Length == 0)
            {
                log.WriteLine("No nodes to consider");
                selectedConfiguration = null;
                availableEndpoints = new string[0];
                return null;
            }
            var connections = new List<RedisConnection>(arr.Length);
            RedisConnection preferred = null;

            try
            {
                Task<string>[] infos, tiebreakers;
                List<RedisConnection> masters = new List<RedisConnection>(arr.Length);
                List<RedisConnection> slaves = new List<RedisConnection>(arr.Length);
                Dictionary<string, int> breakerScores = new Dictionary<string, int>(arr.Length);

                ConnectToNodes(log, tieBreakerKey, syncTimeout, keepAlive, allowAdmin, clientName, arr, connections, out infos, out tiebreakers, AuxMode.TieBreakers);

                    
                for (int i = 0; i < tiebreakers.Length; i++ )
                {
                    var tiebreak = tiebreakers[i];
                    try
                    {
                        if (tiebreak.IsCompleted)
                        {
                            string key = tiebreak.Result;
                            if (string.IsNullOrWhiteSpace(key)) continue;
                            int score;
                            if (breakerScores.TryGetValue(key, out score)) breakerScores[key] = score + 1;
                            else breakerScores.Add(key, 1);
                        }
                        else
                        {
                            infos[i] = null; // forget it; took too long

                            if (tiebreak.IsFaulted)
                            {
                                GC.KeepAlive(tiebreak.Exception); // just an opaque method to show we've looked
                            }
                        }
                    }
                    catch { /* if a node is down, that's fine too */ }
                }

                TraceWriteTime("Check for sentinels");
                // see if any of our nodes are sentinels that know about the named service
                List<Tuple<RedisConnection, Task<Tuple<string, int>>>> sentinelNodes = null;
                foreach (var conn in connections)
                { // the "wait" we did during tie-breaker detection means we should now know what each server is
                    if (conn.ServerType == ServerType.Sentinel)
                    {
                        if (string.IsNullOrEmpty(serviceName))
                        {
                            log.WriteLine("Sentinel discovered, but no serviceName was specified; ignoring {0}:{1}", conn.Host, conn.Port);
                        }
                        else
                        {
                            log.WriteLine("Querying sentinel {0}:{1} for {2}...", conn.Host, conn.Port, serviceName);
                            if (sentinelNodes == null) sentinelNodes = new List<Tuple<RedisConnection, Task<Tuple<string, int>>>>();
                            sentinelNodes.Add(Tuple.Create(conn, conn.QuerySentinelMaster(serviceName)));
                        }
                    }
                }

                // wait for sentinel results, if any
                if(sentinelNodes != null)
                {
                    var discoveredPairs = new Dictionary<Tuple<string, int>, int>();
                    foreach(var pair in sentinelNodes)
                    {
                        var conn = pair.Item1;
                        try {
                            var master = conn.Wait(pair.Item2);
                            if(master == null)
                            {
                                log.WriteLine("Sentinel {0}:{1} is not configured for {2}", conn.Host, conn.Port, serviceName);
                            }
                            else
                            {
                                log.WriteLine("Sentinel {0}:{1} nominates {2}:{3}", conn.Host, conn.Port, master.Item1, master.Item2);
                                int count;
                                if (discoveredPairs.TryGetValue(master, out count)) count = 0;
                                discoveredPairs[master] = count + 1;
                            }
                        } catch (Exception ex) {
                            log.WriteLine("Error from sentinel {0}:{1} - {2}", conn.Host, conn.Port, ex.Message);
                        }
                    }
                    Tuple<string, int> finalChoice;
                    switch (discoveredPairs.Count)
                    {
                        case 0:
                            log.WriteLine("No sentinels nominated a master; unable to connect");
                            finalChoice = null;
                            break;
                        case 1:
                            finalChoice = discoveredPairs.Single().Key;
                            log.WriteLine("Sentinels nominated unanimous master: {0}:{1}", finalChoice.Item1, finalChoice.Item2);
                            break;
                        default:
                            finalChoice = discoveredPairs.OrderByDescending(kvp => kvp.Value).First().Key;
                            log.WriteLine("Sentinels nominated multiple masters; choosing arbitrarily: {0}:{1}", finalChoice.Item1, finalChoice.Item2);
                            break;
                    }

                    if (finalChoice != null)
                    {
                        RedisConnection toBeDisposed = null;
                        try
                        { // good bet that in this scenario the input didn't specify any actual redis servers, so we'll assume open a new one
                            log.WriteLine("Opening nominated master: {0}:{1}...", finalChoice.Item1, finalChoice.Item2);
                            toBeDisposed = new RedisConnection(finalChoice.Item1, finalChoice.Item2, allowAdmin: allowAdmin, syncTimeout: syncTimeout);
                            if (keepAlive >= 0) toBeDisposed.SetKeepAlive(keepAlive);
                            toBeDisposed.Wait(toBeDisposed.Open());
                            if (toBeDisposed.ServerType == ServerType.Master)
                            {
                                var tmp = toBeDisposed;
                                toBeDisposed = null; // so we don't dispose it
                                selectedConfiguration = tmp.Host + ":" + tmp.Port;
                                availableEndpoints = new string[] { selectedConfiguration };
                                return tmp;
                            }
                            else
                            {
                                log.WriteLine("Server is {0} instead of a master", toBeDisposed.ServerType);
                            }
                        }
                        catch (Exception ex)
                        {
                            log.WriteLine("Error: {0}", ex.Message);
                        }
                        finally
                        { // dispose if something went sour
                            using (toBeDisposed) { }
                        }
                    }
                    // something went south; BUT SENTINEL WINS TRUMPS; quit now
                    selectedConfiguration = null;
                    availableEndpoints = new string[0];
                    return null;
                }

                TraceWriteTime("Check tie-breakers");
                // check for tie-breakers (i.e. when we store which is the master)
                switch (breakerScores.Count)
                {
                    case 0:
                        log.WriteLine("No tie-breakers found ({0})", tieBreakerKey);
                        break;
                    case 1:
                        log.WriteLine("Tie-breaker ({0}) is unanimous: {1}", tieBreakerKey, breakerScores.Keys.Single());
                        break;
                    default:
                        log.WriteLine("Ambiguous tie-breakers ({0}):", tieBreakerKey);
                        foreach (var kvp in breakerScores.OrderByDescending(x => x.Value))
                        {
                            log.WriteLine("\t{0}: {1}", kvp.Key, kvp.Value);
                        }
                        break;
                }

                TraceWriteTime("Check connections");
                for (int i = 0; i < connections.Count; i++)
                {
                    if (infos[i] == null)
                    {
                        log.WriteLine("Server did not respond - {0}:{1}...", connections[i].Host, connections[i].Port);
                        connections[i].Close(abort:true);
                        continue;
                    }
                    log.WriteLine("Reading configuration from {0}:{1}...", connections[i].Host, connections[i].Port);
                    try
                    {
                        if (!infos[i].Wait(syncTimeout))
                        {
                            log.WriteLine("\tTimeout fetching INFO");
                            continue;
                        }
                        var infoPairs = new StringDictionary();
                        using (var sr = new StringReader(infos[i].Result))
                        {
                            string line;
                            while ((line = sr.ReadLine()) != null)
                            {
                                int idx = line.IndexOf(':');
                                if (idx < 0) continue;
                                string key = line.Substring(0, idx).Trim(),
                                       value = line.Substring(idx + 1, line.Length - (idx + 1)).Trim();
                                infoPairs[key] = value;
                            }
                        }
                        string role = infoPairs["role"];
                        switch (role)
                        {
                            case "slave":
                                log.WriteLine("\tServer is SLAVE of {0}:{1}",
                                          infoPairs["master_host"], infoPairs["master_port"]);
                                log.Write("\tLink is {0}, seen {1} seconds ago",
                                                 infoPairs["master_link_status"], infoPairs["master_last_io_seconds_ago"]);
                                if (infoPairs["master_sync_in_progress"] == "1") log.Write(" (sync is in progress)");
                                log.WriteLine();
                                slaves.Add(connections[i]);
                                break;
                            case "master":
                                log.WriteLine("\tServer is MASTER, with {0} slaves", infoPairs["connected_slaves"]);
                                masters.Add(connections[i]);
                                break;
                            default:
                                if (!string.IsNullOrWhiteSpace(role))
                                {
                                    log.WriteLine("\tUnknown role: {0}", role);
                                }
                                break;
                        }
                        string tmp = infoPairs["connected_clients"];
                        int clientCount, channelCount, patternCount;
                        if (string.IsNullOrWhiteSpace(tmp) || !int.TryParse(tmp, out clientCount)) clientCount = -1;
                        tmp = infoPairs["pubsub_channels"];
                        if (string.IsNullOrWhiteSpace(tmp) || !int.TryParse(tmp, out channelCount)) channelCount = -1;
                        tmp = infoPairs["pubsub_patterns"];
                        if (string.IsNullOrWhiteSpace(tmp) || !int.TryParse(tmp, out patternCount)) patternCount = -1;
                        log.WriteLine("\tClients: {0}; channels: {1}; patterns: {2}", clientCount, channelCount, patternCount);
                    }
                    catch (Exception ex)
                    {
                        log.WriteLine("\tError reading INFO results: {0}", ex.Message);
                    }
                }

                TraceWriteTime("Check masters");
                if (newMaster == null)
                {
                    switch (masters.Count)
                    {
                        case 0:
                            switch (slaves.Count)
                            {
                                case 0:
                                    log.WriteLine("No masters or slaves found");
                                    break;
                                case 1:
                                    log.WriteLine("No masters found; selecting single slave");
                                    preferred = slaves[0];
                                    break;
                                default:
                                    log.WriteLine("No masters found; considering {0} slaves...", slaves.Count);
                                    preferred = SelectWithTieBreak(log, slaves, breakerScores);
                                    break;
                            }
                            if (preferred != null)
                            {
                                if (autoMaster)
                                {
                                    //LogException("Promoting redis SLAVE to MASTER");
                                    log.WriteLine("Promoting slave to master...");
                                    if (allowAdmin)
                                    { // can do on this connection
                                        preferred.Wait(preferred.Server.MakeMaster());
                                    }
                                    else
                                    { // need an admin connection for this
                                        using (var adminPreferred = new RedisConnection(preferred.Host, preferred.Port, allowAdmin: true, syncTimeout: syncTimeout))
                                        {
                                            adminPreferred.Open();
                                            adminPreferred.Wait(adminPreferred.Server.MakeMaster());
                                        }
                                    }
                                }
                                else
                                {
                                    log.WriteLine("Slave should be promoted to master (but not done yet)...");
                                }
                            }
                            break;
                        case 1:
                            log.WriteLine("One master found; selecting");
                            preferred = masters[0];
                            break;
                        default:
                            log.WriteLine("Considering {0} masters...", masters.Count);
                            preferred = SelectWithTieBreak(log, masters, breakerScores);
                            break;
                    }


                }
                else
                { // we have been instructed to change master server
                    preferred = masters.Concat(slaves).FirstOrDefault(conn => (conn.Host + ":" + conn.Port) == newMaster);
                    if (preferred == null)
                    {
                        log.WriteLine("Selected new master not available: {0}", newMaster);
                    }
                    else
                    {
                        int errorCount = 0;
                        try
                        {
                            log.WriteLine("Promoting to master: {0}:{1}...", preferred.Host, preferred.Port);
                            preferred.Wait(preferred.Server.MakeMaster());
                            // if this is a master, we expect set/publish to work, even on 2.6
                            preferred.Strings.Set(0, tieBreakerKey, newMaster);
                            preferred.Wait(preferred.Publish(RedisMasterChangedChannel, newMaster));
                        }
                        catch (Exception ex)
                        {
                            log.WriteLine("\t{0}", ex.Message);
                            errorCount++;
                        }

                        if (errorCount == 0) // only make slaves if the master was happy
                        {
                            foreach (var conn in masters.Concat(slaves))
                            {
                                if (conn == preferred) continue; // can't make self a slave!

                                try
                                {
                                    log.WriteLine("Enslaving: {0}:{1}...", conn.Host, conn.Port);

                                    // try to set the tie-breaker **first** in case of problems
                                    var didSet = conn.Strings.Set(0, tieBreakerKey, newMaster);
                                    // and broadcast to anyone who thinks this is the master
                                    var didPublish = conn.Publish(RedisMasterChangedChannel, newMaster);
                                    // now make it a slave
                                    var didEnslave = conn.Server.MakeSlave(preferred.Host, preferred.Port);
                                    // these are best-effort only; from 2.6, readonly slave servers may reject these commands
                                    try { conn.Wait(didSet); } catch {}
                                    try { conn.Wait(didPublish); } catch {}
                                    // but this one we'll log etc
                                    conn.Wait(didEnslave);
                                }
                                catch (Exception ex)
                                {
                                    log.WriteLine("\t{0}",ex.Message);
                                    errorCount++;
                                }
                            }
                        }
                        if (errorCount != 0)
                        {
                            log.WriteLine("Things didn't go smoothly; CHECK WHAT HAPPENED!");
                        }

                        // want the connection disposed etc
                        preferred = null;
                    }
                }

                TraceWriteTime("Outro");
                if (preferred == null)
                {
                    selectedConfiguration = null;
                }
                else
                {
                    selectedConfiguration = preferred.Host + ":" + preferred.Port;
                    log.WriteLine("Selected server {0}", selectedConfiguration);
                }

                availableEndpoints = (from conn in masters.Concat(slaves)
                                      select conn.Host + ":" + conn.Port).ToArray();
                TraceWriteTime("Return");
                return preferred;
            }
            finally
            {
                TraceWriteTime("Start cleanup");
                foreach (var conn in connections)
                {
                    if (conn != null && conn != preferred) try { conn.Dispose(); }
                        catch { }
                }
                TraceWriteTime("End cleanup");
            }
        }
        enum AuxMode {
            TieBreakers,
            ClusterNodes
        }
        private static void ConnectToNodes(TextWriter log, string tieBreakerKey, int syncTimeout, int keepAlive, bool allowAdmin, string clientName, string[] arr, List<RedisConnection> connections, out Task<string>[] infos, out Task<string>[] aux, AuxMode mode)
        {
            TraceWriteTime("Infos");
            infos = new Task<string>[arr.Length];
            aux = new Task<string>[arr.Length];
            var opens = new Task[arr.Length];
            for (int i = 0; i < arr.Length; i++)
            {
                var option = arr[i];
                if (string.IsNullOrWhiteSpace(option)) continue;

                RedisConnection conn = null;
                try
                {

                    var parts = option.Split(':');
                    if (parts.Length == 0) continue;

                    string host = parts[0].Trim();
                    int port = 6379, tmp;
                    if (parts.Length > 1 && int.TryParse(parts[1].Trim(), out tmp)) port = tmp;
                    conn = new RedisConnection(host, port, syncTimeout: syncTimeout, allowAdmin: allowAdmin);
                    conn.Name = clientName;
                    log.WriteLine("Opening connection to {0}:{1}...", host, port);
                    if (keepAlive >= 0) conn.SetKeepAlive(keepAlive);
                    opens[i] = conn.Open();
                    var info = conn.GetInfoImpl(null, false, false);
                    connections.Add(conn);
                    infos[i] = info;
                    switch (mode)
                    {
                        case AuxMode.TieBreakers:
                            if (tieBreakerKey != null)
                            {
                                aux[i] = conn.Strings.GetString(0, tieBreakerKey);
                            }
                            break;
                        case AuxMode.ClusterNodes:
                            aux[i] = conn.Cluster.GetNodes();
                            break;
                    }
                    
                }
                catch (Exception ex)
                {
                    if (conn == null)
                    {
                        log.WriteLine("Error parsing option \"{0}\": {1}", option, ex.Message);
                    }
                    else
                    {
                        log.WriteLine("Error connecting: {0}", ex.Message);
                    }
                }
            }

            TraceWriteTime("Wait for infos");
            RedisConnectionBase.Trace("select-create", "wait...");
            var watch = new Stopwatch();
            foreach (Task task in infos.Concat(aux).Concat(opens))
            {
                if (task != null)
                {
                    try
                    {
                        int remaining = unchecked((int)(syncTimeout - watch.ElapsedMilliseconds));
                        if (remaining > 0) task.Wait(remaining);
                    }
                    catch { }
                }
            }
            watch.Stop();
            RedisConnectionBase.Trace("select-create", "complete");
        }
    }
}
