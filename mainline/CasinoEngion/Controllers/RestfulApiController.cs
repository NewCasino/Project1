using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Web;
using System.Web.Mvc;
using System.Xml.Linq;
using CE.db;
using CE.db.Accessor;
using GamMatrixAPI;
using System.Net;
using System.Web.Script.Serialization;

namespace CasinoEngine.Controllers
{
    [DataContract]
    public sealed class LiveCasinoSeat
    {
        [DataMember(Name = "totalSeats")]
        public int TotalSeats { get; set; }

        [DataMember(Name = "takenSeats")]
        public int TakenSeats { get; set; }
    }


    public partial class RestfulApiController : ServiceControllerBase
    {
        [HttpGet]
        public ContentResult GetLiveCasinoTableStatus(string apiUsername, string callback)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            Dictionary<string, LiveCasinoSeat> seats = new Dictionary<string, LiveCasinoSeat>();

            DomainManager.CurrentDomainID = domain.DomainID;
            string cacheKey = string.Format("RestfulApiController.GetLiveCasinoTableStatus.LiveCasinoDic.{0}", domain.DomainID);

            List<ceLiveCasinoTableBaseEx> tables = null;
            {
                tables = HttpRuntime.Cache[cacheKey] as List<ceLiveCasinoTableBaseEx>;
                if (tables == null)
                {
                    tables = LiveCasinoTableAccessor.GetDomainTables(domain.DomainID, null, true, true);
                    HttpRuntime.Cache.Insert(cacheKey, tables, null, DateTime.Now.AddMinutes(5), TimeSpan.Zero);
                }
            }


            List<ceLiveCasinoTableBaseEx> xproTables = tables.Where(t => t.VendorID == VendorID.XProGaming).ToList();
            if (xproTables.Count > 0)
            {
                XProGamingAPIRequest request = new XProGamingAPIRequest()
                {
                    GetGamesListWithLimits = true,
                    GetGamesListWithLimitsGameType = (int)XProGaming.GameType.AllGames,
                    GetGamesListWithLimitsOnlineOnly = 0,
                    GetGamesListWithLimitsCurrency = "EUR",
                    //GetGamesListWithLimitsUserName = "_Api_Ce",
                };
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    request = client.SingleRequest<XProGamingAPIRequest>( domain.DomainID, request);
                }
                /*
<response xmlns="apiGamesLimitsListData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <gamesList>
      <game>
         <limitSetList>
            <limitSet>
               <limitSetID>1</limitSetID>
               <minBet>0.00</minBet>
               <maxBet>800.00</maxBet>
            </limitSet>
            <limitSet>
               <limitSetID>45</limitSetID>
               <minBet>1.00</minBet>
               <maxBet>5.00</maxBet>
            </limitSet>
         </limitSetList>
         <gameID>3</gameID>
         <gameType>1</gameType>
         <gameName>Dragon Roulette LCPP</gameName>
         <dealerName>Dealer</dealerName>
         <dealerImageUrl>http://lcpp.xprogaming.com/LiveGames/Games/dealers/1.jpg</dealerImageUrl>
         <isOpen>1</isOpen>
         <connectionUrl>https://lcpp.xprogaming.com/LiveGames/GeneralGame.aspx?audienceType=1&amp;gameID=3&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
         <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
         <openHour>00:00</openHour>
         <closeHour>23:59</closeHour>
         <PlayersNumber xsi:nil="true" />
         <PlayersNumberInGame xsi:nil="true" />
      </game>
   <errorCode>0</errorCode>
   <description />
</response>
                 */

                XElement root = XElement.Parse(request.GetGamesListWithLimitsResponse);
                XNamespace ns = root.GetDefaultNamespace();
                if (root.Element(ns + "errorCode").Value != "0")
                    throw new Exception(root.Element(ns + "description").Value);

                IEnumerable<XElement> games = root.Element(ns + "gamesList").Elements(ns + "game");
                foreach (XElement game in games)
                {
                    string gameID = game.Element(ns + "gameID").Value;
                    XElement playersNumberElement = game.Element(ns + "PlayersNumber");
                    XElement playersNumberInGameElement = game.Element(ns + "PlayersNumberInGame");
                    if (playersNumberElement == null ||
                        playersNumberInGameElement == null ||
                        playersNumberElement.Value == null ||
                        playersNumberInGameElement.Value == null)
                    {
                        continue;
                    }

                    int seatTaken = 0, totalSeats = 0;
                    if (!int.TryParse(playersNumberElement.Value, out totalSeats) ||
                        !int.TryParse(playersNumberInGameElement.Value, out seatTaken))
                    {
                        continue;
                    }

                    foreach (ceLiveCasinoTableBaseEx xproTable in xproTables.Where(t => t.GameID == gameID))
                    {
                        seats.Add(xproTable.ID.ToString()
                                , new LiveCasinoSeat() { TakenSeats = seatTaken, TotalSeats = totalSeats }
                                );
                    }
                }
            }


            List<ceLiveCasinoTableBaseEx> netentTables = tables.Where(t => t.VendorID == VendorID.NetEnt).ToList();
            if (netentTables.Count > 0)
            {
                string url = domain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL);
                url = string.Format(url, "EUR");
                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.Accept = "application/json";
                request.ContentType = "application/json";
                request.Method = "POST";

                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                using (Stream s = response.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(s))
                    {
                        string json = sr.ReadToEnd();
                        JavaScriptSerializer jss = new JavaScriptSerializer();
                        NetEntAPI.RawNetEntLiveCasinoTable[] rawTables = jss.Deserialize<NetEntAPI.RawNetEntLiveCasinoTable[]>(json);

                        foreach (var rawTable in rawTables)
                        {
                            if (rawTable.Games.Length == 0 
                                || rawTable.Slots.Length == 0)
                                continue;

                            string gameID = rawTable.Games[0].GameID;
                            ceLiveCasinoTableBaseEx netentTable = netentTables.FirstOrDefault(t => t.GameID == gameID);
                            if (netentTable == null)
                                continue;

                            int seatTaken = rawTable.Slots.Count(slot => slot.Available == false);
                            int totalSeats = rawTable.Slots.Length;

                            seats.Add(netentTable.ID.ToString()
                                , new LiveCasinoSeat() { TakenSeats = seatTaken, TotalSeats = totalSeats }
                            );
                            
                        }
                    }
                }
            }

            DataContractJsonSerializer serializer = new DataContractJsonSerializer(seats.GetType()
                , new DataContractJsonSerializerSettings() { UseSimpleDictionaryFormat = true }
                );

            string jsonp;
            using (MemoryStream ms = new MemoryStream())
            {
                serializer.WriteObject(ms, seats);
                string json = Encoding.UTF8.GetString(ms.ToArray());

                jsonp = string.Format("{0}({1})", callback, json);
            }


            return this.Content(jsonp);
        }

    }
}
