using System;
using System.Threading.Tasks;

namespace BookSleeve
{
    internal interface IClusterCommands
    {
        Task<string> GetNodes();
    }
    partial class RedisConnection : IClusterCommands
    {
        internal IClusterCommands Cluster { get { return this; } }

        Task<string> IClusterCommands.GetNodes()
        {
            return ExecuteString(RedisMessage.Create(-1, RedisLiteral.CLUSTER, RedisLiteral.NODES), false);
        }
    }
}
