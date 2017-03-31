using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;
using System.Threading.Tasks;

namespace CasinoEngine.Hubs
{
    public class RealityCheckHub : Hub
    {
        public static string groupNameFormat = "{0}_{1}";

        public void Send(dynamic message)
        {
            Clients.All.SendMessage(message);
        }

        public void JoinGroup(long domainId, long userId)
        {
            string groupName = string.Format(groupNameFormat, domainId, userId);
            Groups.Add(Context.ConnectionId, groupName); 
        }

        public void RemoveFromGroup(long domainId, long userId)
        {
            string groupName = string.Format(groupNameFormat, domainId, userId);
            Groups.Remove(Context.ConnectionId, groupName);
        }
    }
}