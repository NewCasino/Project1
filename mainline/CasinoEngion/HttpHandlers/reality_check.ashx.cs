using CasinoEngine.Hubs;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Xml;

namespace CasinoEngine.HttpHandlers
{
    /// <summary>
    /// Summary description for reality_check
    /// </summary>
    public class reality_check : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            if(string.IsNullOrEmpty(context.Request.QueryString["domainId"]) 
                || string.IsNullOrEmpty(context.Request.QueryString["userId"]))
                return;

            long domainId;
            long userId;

            if(!long.TryParse(context.Request.QueryString["domainId"], out domainId))
                return;

            if(!long.TryParse(context.Request.QueryString["userId"], out userId))
                return;

            string eventType = GetEventType(context.Request.InputStream);

            if (!string.IsNullOrEmpty(eventType))
            {
                SendGroupMessage(domainId, userId, eventType);
            }

            context.Response.Write("OK");
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
        
        private string GetEventType(Stream stream)
        {
            string eventType;
            XmlDocument xmlDoc = new XmlDocument();
            xmlDoc.Load(stream);
            XmlNamespaceManager namespaceManager = new XmlNamespaceManager(xmlDoc.NameTable);
            namespaceManager.AddNamespace("event", "http://accountlink.odobo.com/event");

            var nodes = xmlDoc.SelectNodes("/event:userResponseEvent/event:type", namespaceManager);
            if (nodes.Count != 1)
            {
                // Odobo event request: No event type was passed!!!
                return null;
            }

            XmlNode node = nodes[0];

            if (node.NodeType == XmlNodeType.Element && node.ChildNodes.Count == 1 && node.ChildNodes[0].NodeType == XmlNodeType.Text)
            {
                eventType = node.ChildNodes[0].Value;
            }
            else
            {
                eventType = nodes[0].Value;
            }

            return eventType;
        }

        private void SendGroupMessage(long domainId, long userId, string message)
        {
            string groupName = string.Format(RealityCheckHub.groupNameFormat, domainId, userId);
            GlobalHost.ConnectionManager.GetHubContext<RealityCheckHub>().Clients.Group(groupName).SendMessage(message);
        }
    }
}