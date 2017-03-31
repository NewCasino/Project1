using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

namespace BookSleeve
{
    /// <summary>
    /// Represents the state of an individual client connection to redis
    /// </summary>
    public sealed class ClientInfo
    {
        internal static ClientInfo[] Parse(string input)
        {
            if (input == null) return null;

            var clients = new List<ClientInfo>();
            using (var reader = new StringReader(input))
            {
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    var client = new ClientInfo();
                    string[] tokens = line.Split(' ');
                    for (int i = 0; i < tokens.Length; i++)
                    {
                        string tok = tokens[i];
                        int idx = tok.IndexOf('=');
                        if (idx < 0) continue;
                        string key = tok.Substring(0, idx), value = tok.Substring(idx + 1);

                        switch (key)
                        {
                            case "addr": client.Address = value; break;
                            case "age": client.AgeSeconds = int.Parse(value, CultureInfo.InvariantCulture); break;
                            case "idle": client.IdleSeconds = int.Parse(value, CultureInfo.InvariantCulture); break;
                            case "db": client.Database = int.Parse(value, CultureInfo.InvariantCulture); break;
                            case "name": client.Name = value; break;
                            case "sub": client.SubscriptionCount = int.Parse(value, CultureInfo.InvariantCulture); break;
                            case "psub": client.PatternSubscriptionCount = int.Parse(value, CultureInfo.InvariantCulture); break;
                            case "multi": client.TransactionCommandLength = int.Parse(value, CultureInfo.InvariantCulture); break;
                            case "cmd": client.LastCommand = value; break;
                            case "flags":
                                client.FlagsRaw = value;
                                ClientFlags flags = ClientFlags.None;
                                AddFlag(ref flags, value, ClientFlags.SlaveMonitor, 'O');
                                AddFlag(ref flags, value, ClientFlags.Slave, 'S');
                                AddFlag(ref flags, value, ClientFlags.Master, 'M');
                                AddFlag(ref flags, value, ClientFlags.Transaction, 'x');
                                AddFlag(ref flags, value, ClientFlags.Blocked, 'b');
                                AddFlag(ref flags, value, ClientFlags.TransactionDoomed, 'd');
                                AddFlag(ref flags, value, ClientFlags.Closing, 'c');
                                AddFlag(ref flags, value, ClientFlags.Unblocked, 'u');
                                AddFlag(ref flags, value, ClientFlags.CloseASAP, 'A');
                                client.Flags = flags;
                                break;
                        }
                    }
                    clients.Add(client);
                }
            }

            return clients.ToArray();
        }
        static void AddFlag(ref ClientFlags value, string raw, ClientFlags toAdd, char token)
        {
            if (raw.IndexOf(token) >= 0) value |= toAdd;
        }
        /// <summary>
        /// Format the object as a string
        /// </summary>
        public override string ToString()
        {
            return string.IsNullOrWhiteSpace(Name) ? Address : (Address + " - " + Name);
        }

        /// <summary>
        /// address/port of the client
        /// </summary>
        public string Address { get; private set; }
        /// <summary>
        /// total duration of the connection in seconds
        /// </summary>
        public int AgeSeconds { get; private set; }
        /// <summary>
        /// idle time of the connection in seconds
        /// </summary>
        public int IdleSeconds { get; private set; }
        /// <summary>
        /// current database ID
        /// </summary>
        public int Database { get; private set; }
        /// <summary>
        /// number of channel subscriptions
        /// </summary>
        public int SubscriptionCount { get; private set; }
        /// <summary>
        /// number of pattern matching subscriptions
        /// </summary>
        public int PatternSubscriptionCount { get; private set; }
        /// <summary>
        /// number of commands in a MULTI/EXEC context
        /// </summary>
        public int TransactionCommandLength { get; private set; }
        /// <summary>
        /// The client flags can be a combination of:
        /// O: the client is a slave in MONITOR mode
        /// S: the client is a normal slave server
        /// M: the client is a master
        /// x: the client is in a MULTI/EXEC context
        /// b: the client is waiting in a blocking operation
        /// i: the client is waiting for a VM I/O (deprecated)
        /// d: a watched keys has been modified - EXEC will fail
        /// c: connection to be closed after writing entire reply
        /// u: the client is unblocked
        /// A: connection to be closed ASAP
        /// N: no specific flag set
        /// </summary>
        public string FlagsRaw { get; private set; }
        /// <summary>
        /// The flags associated with this connection
        /// </summary>
        public ClientFlags Flags { get; private set; }
        /// <summary>
        ///  last command played
        /// </summary>
        public string LastCommand { get; private set; }

        /// <summary>
        /// The name allocated to this connection, if any
        /// </summary>
        public string Name { get; private set; }
    }
    /// <summary>
    /// The client flags can be a combination of:
    /// O: the client is a slave in MONITOR mode
    /// S: the client is a normal slave server
    /// M: the client is a master
    /// x: the client is in a MULTI/EXEC context
    /// b: the client is waiting in a blocking operation
    /// i: the client is waiting for a VM I/O (deprecated)
    /// d: a watched keys has been modified - EXEC will fail
    /// c: connection to be closed after writing entire reply
    /// u: the client is unblocked
    /// A: connection to be closed ASAP
    /// N: no specific flag set
    /// </summary>
    [Flags]
    public enum ClientFlags : long
    {
        /// <summary>
        /// no specific flag set
        /// </summary>
        None = 0,
        /// <summary>
        /// the client is a slave in MONITOR mode
        /// </summary>
        SlaveMonitor = 1,
        /// <summary>
        /// the client is a normal slave server
        /// </summary>
        Slave = 2,
        /// <summary>
        /// the client is a master
        /// </summary>
        Master = 4,
        /// <summary>
        /// the client is in a MULTI/EXEC context
        /// </summary>
        Transaction = 8,
        /// <summary>
        /// the client is waiting in a blocking operation
        /// </summary>
        Blocked = 16,
        /// <summary>
        /// a watched keys has been modified - EXEC will fail
        /// </summary>
        TransactionDoomed = 32,
        /// <summary>
        /// connection to be closed after writing entire reply
        /// </summary>
        Closing = 64,
        /// <summary>
        /// the client is unblocked
        /// </summary>
        Unblocked = 128,
        /// <summary>
        /// connection to be closed ASAP
        /// </summary>
        CloseASAP = 256,
        
    }
}
