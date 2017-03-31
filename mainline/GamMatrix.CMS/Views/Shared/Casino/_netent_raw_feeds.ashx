<%@ WebHandler Language="C#" Class="_netent_raw_jackpots" %>

using System;
using System.Linq;
using System.Web;
using System.Text;
using GmCore;
using GamMatrixAPI;
using System.Globalization;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;

using System.Text.RegularExpressions;

public class _netent_raw_jackpots : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        

        DateTime fromDate, toDate;
        if (!DateTime.TryParseExact(context.Request.QueryString["toDate"], "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture, DateTimeStyles.None, out toDate) )
            toDate = DateTime.Now.AddDays(5);
        if (!DateTime.TryParseExact(context.Request.QueryString["fromDate"], "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture, DateTimeStyles.None, out fromDate))
            fromDate = toDate.AddDays(-100);
        
        string type = context.Request.QueryString["type"];
        string currency = context.Request.QueryString["currency"];
        string occurrenceID = context.Request.QueryString["occurrenceID"];
        string name = context.Request.QueryString["name"];
        if (string.IsNullOrWhiteSpace(type))
            return;

        StringBuilder xml = new StringBuilder();
        xml.AppendLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
        xml.AppendLine("<raw_feeds>");

        switch (type.ToLowerInvariant())
        {
            case "jackpots":
                GenerateJackpotsXml(currency, ref xml);
                break;
                
            case "alltournaments":
                GenerateAllTournamentsXml(currency, fromDate, toDate, ref xml);
                break;

            case "leaderboard":
                if (string.IsNullOrWhiteSpace(occurrenceID))
                    throw new HttpException(500, "occurrenceID is missing");
                GenerateLeaderBoardXml(occurrenceID, ref xml);
                break;
                
            case "userintournament":
                if (string.IsNullOrWhiteSpace(occurrenceID))
                    throw new HttpException(500, "occurrenceID is missing");
                VerifySession(context);
                GenerateUserInTournamentXml(occurrenceID, ref xml);
                break;

            case "usertournaments":
                VerifySession(context);
                GenerateUserTournamentsXml(currency, fromDate, toDate, ref xml);
                break;

            case "currentoverview":
                GenerateCurrentOverviewXml(ref xml);
                break;

            case "tournamentdetail":
                GenerateTournamentDetailXml(currency, occurrenceID, ref xml);
                break;

            case "tournamentresult":
                GenerateTournamentResultXml(currency, occurrenceID, ref xml);
                break;

            case "purchaseticket":
                if (string.IsNullOrWhiteSpace(occurrenceID))
                    throw new HttpException(500, "occurrenceID is missing");
                VerifySession(context);
                GeneratePurchaseTicketXml(currency, occurrenceID, ref xml);
                break;

            case "namedquery":
                if (string.IsNullOrWhiteSpace(name))
                    throw new HttpException(500, "name is missing");
                List<string> args = new List<string>();
                {
                    for (int i = 1; i < 20; i++)
                    {
                        string keyName = string.Format("arg{0}", i);
                        if (context.Request.QueryString[keyName] != null)
                            args.Add(context.Request.QueryString[keyName]);
                    }
                }
                GenerateNamedQueryXml(name, args, ref xml);
                break;
            default:
                break;
        }


        xml.AppendLine("</raw_feeds>");

        context.Response.Clear();
        context.Response.ContentType = "text/xml";
        context.Response.ContentEncoding = Encoding.UTF8;
        context.Response.Write(xml.ToString());
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

    private void VerifySession(HttpContext context)
    {
        if( string.IsNullOrWhiteSpace(context.Request.QueryString["_sid"]) )
            throw new HttpException(500, "Invalid User Session!");

        ProfileCommon.Current.Init(context);
        if( !ProfileCommon.Current.IsAuthenticated )
            throw new HttpException(500, "Invalid User Session!");
    }

    #region SerializeObject
    
    private void SerializeObject(object graph, ref StringBuilder xml, params string[] excludedAttributes)
    {
        if (graph == null)
            return;

        Type type = graph.GetType();

        if (type == typeof(string))
        {
            string text = graph as string;
            if (!string.IsNullOrWhiteSpace(text))
                text = Regex.Replace(text, @"^(\d+\~)", string.Empty);
            xml.Append(text.SafeHtmlEncode());
            return;
        }
        if (type == typeof(int) ||
            type == typeof(long) ||
            type == typeof(decimal) ||
            type == typeof(float) ||
            type == typeof(double) )
        {
            xml.Append(graph);
            return;
        }
        if (type == typeof(DateTime))
        {
            xml.Append(((DateTime)graph).ToString("yyyy-MM-dd HH:mm:ss"));
        }
        else if (type == typeof(bool))
        {
            xml.Append(((bool)graph).ToString().ToLowerInvariant());
        }
        else if( type.IsClass )
        {

            PropertyInfo[] properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (PropertyInfo property in properties)
            {
                if (!property.Name.EndsWith("Field"))
                    continue;

                string name = property.Name.Truncate(property.Name.Length - "Field".Length);

                if (excludedAttributes != null && excludedAttributes.Contains(property.Name))
                    continue;

                Type attrType = property.PropertyType;
                object attrValue = property.GetValue(graph, null);

                if (Nullable.GetUnderlyingType(property.PropertyType) != null)
                {
                    attrType = Nullable.GetUnderlyingType(property.PropertyType);
                }

                
                xml.AppendFormat("<{0}>", name.SafeHtmlEncode());

                if (attrValue == null)
                {
                }
                else if (attrType.IsGenericType && attrType.GetGenericTypeDefinition() == typeof(List<>))
                {
                    IEnumerable enumerable = attrValue as IEnumerable;
                    foreach (var obj in enumerable)
                    {
                        xml.Append("<item>");
                        SerializeObject(obj, ref xml);
                        xml.Append("</item>");
                    }
                }
                else
                {
                    SerializeObject(attrValue, ref xml);
                }

                xml.AppendFormat("</{0}>", name.SafeHtmlEncode());
            }
        }
    }
    #endregion

    private void GenerateJackpotsXml(string currency, ref StringBuilder xml)
    {
        xml.AppendFormat("<jackpots ins=\"{0}\" currency=\"{1}\">\n", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"), currency.SafeHtmlEncode());

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetIndividualJackpotInfo = true,
                GetIndividualJackpotInfoCurrency = currency,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            foreach (Jackpot jackpot in request.GetIndividualJackpotInfoResponse)
            {
                xml.AppendLine("<jackpot>");
                SerializeObject(jackpot, ref xml);                
                xml.AppendLine("</jackpot>");
            }
        }
        
        xml.AppendLine("</jackpots>");
    }

    

    private void GenerateAllTournamentsXml(string currency, DateTime fromDate, DateTime toDate, ref StringBuilder xml)
    {
        xml.AppendFormat("<allTournaments ins=\"{0}\" currency=\"{1}\" fromDate=\"{2}\" toDate=\"{3}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , currency.SafeHtmlEncode()
            , fromDate.ToString("yyyy-MM-dd HH:mm:ss")
            , toDate.ToString("yyyy-MM-dd HH:mm:ss")
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetAllTournaments = true,
                GetAllTournamentsCurrency = currency,
                GetAllTournamentsFrom = fromDate,
                GetAllTournamentsTo = toDate,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            foreach (TournamentOccurrence tournament in request.GetAllTournamentsResponse)
            {
                
                xml.AppendLine("<tournament>");
                SerializeObject(tournament, ref xml, null);
                /*
                try
                {
                    NetEntAPIRequest req = new NetEntAPIRequest()
                    {
                        GetTournamentDetailsV2 = true,
                        GetTournamentDetailsV2Currency = currency,
                        GetTournamentDetailsV2OccurrenceID = long.Parse(tournament.occurenceIdField),
                    };
                    req = client.SingleRequest<NetEntAPIRequest>(req);

                    var details = req.GetTournamentDetailsV2Response;
                    SerializeObject(details, ref xml);
                }
                catch
                {
                    SerializeObject(tournament, ref xml, null);
                }
                 * */

                xml.AppendLine("</tournament>");
            }
        }

        xml.AppendLine("</allTournaments>");
    }

    


    private void GenerateCurrentOverviewXml(ref StringBuilder xml)
    {
        xml.AppendFormat("<currentOverview ins=\"{0}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetCurrentOverview = true,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);
            SerializeObject(request.GetCurrentOverviewResponse, ref xml, null);       
           
        }

        xml.AppendLine("</currentOverview>");
    }


    private void GenerateUserTournamentsXml(string currency, DateTime fromDate, DateTime toDate, ref StringBuilder xml)
    {
        if (!ProfileCommon.Current.IsAuthenticated)
            return;
        
        xml.AppendFormat("<userTournaments ins=\"{0}\" fromDate=\"{1}\" toDate=\"{2}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , fromDate.ToString("yyyy-MM-dd HH:mm:ss")
            , toDate.ToString("yyyy-MM-dd HH:mm:ss")
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                UserID = ProfileCommon.Current.UserID,
                SESSION_USERID = ProfileCommon.Current.UserID,
                GetUserTournaments = true,
                GetUserTournamentsFrom = fromDate,
                GetUserTournamentsTo = toDate,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            foreach (TournamentOccurrence tournament in request.GetUserTournamentsResponse)
            {
                xml.AppendLine("<tournament>");

                SerializeObject(tournament, ref xml, null);

                xml.AppendLine("</tournament>");
            }
        }

        xml.AppendLine("</userTournaments>");
    }


    private void GenerateLeaderBoardXml(string occurrenceID, ref StringBuilder xml)
    {
        xml.AppendFormat("<leaderBoard ins=\"{0}\" occurrenceID=\"{1}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , occurrenceID.SafeHtmlEncode()
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetLeaderBoard = true,
                GetLeaderBoardOccurrenceID = long.Parse(occurrenceID),
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            foreach (TournamentStanding standing in request.GetLeaderBoardResponse)
            {
                xml.AppendLine("<tournamentStanding>");
                SerializeObject(standing, ref xml, null);
                xml.AppendLine("</tournamentStanding>");
            }
        }

        xml.AppendLine("</leaderBoard>");
    }


    private void GenerateUserInTournamentXml(string occurrenceID, ref StringBuilder xml)
    {
        xml.AppendFormat("<isUserInTournament ins=\"{0}\" occurrenceID=\"{1}\">"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , occurrenceID.SafeHtmlEncode()
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                IsUserInTournament = true,
                IsUserInTournamentOccurrenceID = long.Parse(occurrenceID),
                UserID = ProfileCommon.Current.UserID,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            xml.Append(request.IsUserInTournamentResponse.ToString().ToLowerInvariant());
        }

        xml.AppendLine("</isUserInTournament>");
    }


    private void GeneratePurchaseTicketXml(string occurrenceID, ref StringBuilder xml)
    {
        xml.AppendFormat("<purchaseTicket ins=\"{0}\" occurrenceID=\"{1}\">"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , occurrenceID.SafeHtmlEncode()
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                PurchaseTicket = true,
                PurchaseTicketTournamentOccurrenceID = long.Parse(occurrenceID),
                UserID = ProfileCommon.Current.UserID,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            xml.Append(request.IsUserInTournamentResponse.ToString().ToLowerInvariant());
        }

        xml.AppendLine("</purchaseTicket>");
    }


    private void GenerateTournamentDetailXml(string currency, string occurrenceID, ref StringBuilder xml)
    {
        xml.AppendFormat("<tournamentDetail ins=\"{0}\" currency=\"{1}\" occurrenceID=\"{2}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , currency.SafeHtmlEncode()
            , occurrenceID.SafeHtmlEncode()
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetTournamentDetailsV2 = true,
                GetTournamentDetailsV2Currency = currency,
                GetTournamentDetailsV2OccurrenceID = long.Parse(occurrenceID),
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            SerializeObject(request.GetTournamentDetailsV2Response, ref xml);
        }

        xml.AppendLine("</tournamentDetail>");
    }


    private void GenerateTournamentResultXml(string currency, string occurrenceID, ref StringBuilder xml)
    {
        xml.AppendFormat("<tournamentResult ins=\"{0}\" occurrenceID=\"{1}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , occurrenceID.SafeHtmlEncode()
            );

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetTournamentResult = true,
                GetTournamentResultOccurrenceID = long.Parse(occurrenceID),
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            foreach (TournamentStanding standing in request.GetTournamentResultResponse)
            {
                xml.AppendLine("<tournamentStanding>");
                SerializeObject(standing, ref xml);
                xml.AppendLine("</tournamentStanding>");
            }            
        }

        xml.AppendLine("</tournamentResult>");
    }


    private void GeneratePurchaseTicketXml(string currency, string occurrenceID, ref StringBuilder xml)
    {
        xml.AppendFormat("<purchaseTicket ins=\"{0}\" occurrenceID=\"{1}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , occurrenceID.SafeHtmlEncode()
            );
        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            try
            {
                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    UserID = ProfileCommon.Current.UserID,
                    SESSION_USERID = ProfileCommon.Current.UserID,
                    PurchaseTicket = true,
                    PurchaseTicketTournamentOccurrenceID = long.Parse(occurrenceID),
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);

                xml.AppendFormat("<success>true</success><result>{0}</result>"
                    , request.PurchaseTicketResponse.SafeHtmlEncode()
                    );
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                xml.AppendFormat("<success>false</success><error>{0}</error>"
                    , GmException.TryGetFriendlyErrorMsg(ex).SafeHtmlEncode()
                    );
            }
        }
        xml.AppendLine("</purchaseTicket>");
    }

    private void GenerateNamedQueryXml(string name, List<string> args, ref StringBuilder xml)
    {
        xml.AppendFormat("<namedQuery ins=\"{0}\" name=\"{1}\">\n"
            , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            , name
            );
        using (GamMatrixClient client = GamMatrixClient.Get() )
        {

            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                UserID = ProfileCommon.Current.UserID,
                SESSION_USERID = ProfileCommon.Current.UserID,
                ExecuteNamedQuery = true,
                ExecuteNamedQueryName = name,
                ExecuteNamedQueryArgs = args,
            };
            request = client.SingleRequest<NetEntAPIRequest>(request);

            xml.Append("<success>true</success>");
            xml.Append("<result>");
            
            foreach( string item in request.ExecuteNamedQueryResponse)
            {
                xml.AppendFormat("<item>{0}</item>", item.SafeHtmlEncode());
            }

            xml.Append("</result>");

        }
        xml.AppendLine("</namedQuery>");
    }

}