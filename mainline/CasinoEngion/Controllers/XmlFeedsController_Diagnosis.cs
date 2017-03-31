using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.Serialization;
using System.Text;
using System.Web.Mvc;

using CE.db;
using CE.db.Accessor;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public partial class XmlFeedsController : ServiceControllerBase
    {

        [HttpGet]
        public ContentResult RawXml(string apiUsername, string vendor, string username)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            try
            {
                if (string.Equals(vendor, "IGT", StringComparison.InvariantCultureIgnoreCase))
                {
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        IGTAPIRequest request = new IGTAPIRequest()
                        {
                            GameListV2 = true,
                        };
                        request = client.SingleRequest<IGTAPIRequest>(domain.DomainID, request);

                        return this.Content(request.GameListV2Response, "text/xml");

                    }
                }
                else if (string.Equals(vendor, "IGTgames", StringComparison.InvariantCultureIgnoreCase))
                {
                    Dictionary<string, IGTIntegration.Game> games = GamMatrixClient.GetIGTGames(domain.DomainID);

                    StringBuilder output = new StringBuilder();
                    foreach (var game in games)
                    {
                        output.AppendFormat("{0} {1}\n", game.Key, game.Value.Title);
                    }
                    return this.Content(output.ToString(), "text/plain");
                }
                else if (string.Equals(vendor, "GTgameInfo", StringComparison.InvariantCultureIgnoreCase))
                {
                    GreenTubeAPIRequest request = new GreenTubeAPIRequest()
                    {
                        ArticlesGetRequest = new GreentubeArticlesGetRequest()
                        {
                            LanguageCode = "EN"
                        }
                    };
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        request = client.SingleRequest<GreenTubeAPIRequest>(domain.DomainID, request);
                        DataContractSerializer dcs = new DataContractSerializer(request.ArticlesGetResponse.GetType());

                        using (MemoryStream ms = new MemoryStream())
                        {
                            dcs.WriteObject(ms, request.ArticlesGetResponse);
                            byte[] buffer = ms.ToArray();
                            return this.Content(Encoding.UTF8.GetString(buffer, 0, buffer.Length)
                                , "text/xml"
                                );
                        }
                    }

                }
                else if (string.Equals(vendor, "XPRO", StringComparison.InvariantCultureIgnoreCase))
                {
                    XProGamingAPIRequest request = new XProGamingAPIRequest()
                    {
                        GetGamesListWithLimits = true,
                        GetGamesListWithLimitsGameType = (int)XProGaming.GameType.AllGames,
                        GetGamesListWithLimitsOnlineOnly = 0,
                        GetGamesListWithLimitsUserName = username,
                        GetUserCurrency = true,
                        GetUserCurrencyUserName = username,
                    };
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        request = client.SingleRequest<XProGamingAPIRequest>(domain.DomainID, request);

                        StringBuilder output = new StringBuilder();
                        output.AppendFormat("XProGamingAPIRequest.GetUserCurrencyResponse = [{0}]"
                            , request.GetUserCurrencyResponse
                            );
                        output.AppendLine();
                        output.AppendLine();
                        output.Append("XProGamingAPIRequest.GetGamesListWithLimitsResponse = \n");


                        using (StringWriter sw = new StringWriter())
                        {
                            System.Xml.XmlDocument doc = new System.Xml.XmlDocument();
                            doc.LoadXml(request.GetGamesListWithLimitsResponse);
                            doc.Save(sw);
                            output.Append(sw.ToString());
                        }

                        return this.Content(output.ToString(), "text/plain");
                    }

                }
                //else if (string.Equals(vendor, "BALLY", StringComparison.InvariantCultureIgnoreCase))
                //{
                //    BallyGetGamesListRequest request = new BallyGetGamesListRequest();
                //    using (GamMatrixClient client = new GamMatrixClient())
                //    {
                //        request = client.SingleRequest<BallyGetGamesListRequest>(domain.DomainID, request);

                //        DataContractSerializer formatter = new DataContractSerializer(request.Games.GetType());
                //        using (MemoryStream ms = new MemoryStream())
                //        {
                //            formatter.WriteObject(ms, request.Games);
                //            string xml = Encoding.UTF8.GetString(ms.ToArray());
                //            return this.Content(xml, "text/plain");
                //        }
                //    }
                //}
                //else if (string.Equals(vendor, "ISoftBet", StringComparison.InvariantCultureIgnoreCase))
                //{
                //    List<ISoftBetIntegration.Game> list = ISoftBetIntegration.GameMgt.LoadRawGameFeedsForSpecialLanguage(domain,"en").Values.ToList();
                //    DataContractSerializer formatter = new DataContractSerializer(typeof(List<ISoftBetIntegration.Game>));
                //    using (MemoryStream ms = new MemoryStream())
                //    {
                //        formatter.WriteObject(ms, list);
                //        string xml = Encoding.UTF8.GetString(ms.ToArray());
                //        return this.Content(xml, "text/xml");
                //    }
                //}
                else if (string.Equals(vendor, "Vivo", StringComparison.InvariantCultureIgnoreCase))
                {
                    Dictionary<string, string> dicGameName = new Dictionary<string, string>();
                    dicGameName.Add("Baccarat", "Baccarat");
                    dicGameName.Add("Roulette", "Roulette");
                    dicGameName.Add("Blackjack", "Blackjack");


                    long operatorID = 0;
                    long.TryParse(domain.GetCfg(CE.DomainConfig.Vivo.OperatorID), out operatorID);
                    string vivoWebServiceUrl = domain.GetCfg(CE.DomainConfig.Vivo.VivoWebServiceUrl);
                    List<VivoActiveTable> vivoTables;
                    Type t = typeof(VivoActiveTable);
                    PropertyInfo[] properties = t.GetProperties();

                    StringBuilder xml = new StringBuilder();
                    xml.AppendLine(@"<?xml version=""1.0"" encoding=""ISO-8859-1""?>");
                    xml.AppendLine(@"<root>");
                    foreach (string key in dicGameName.Keys)
                    {
                        vivoTables = VivoAPI.LiveCasinoTable.GetActiveTables(vivoWebServiceUrl, domain.DomainID, operatorID, dicGameName[key], "EUR");
                        if (vivoTables != null)
                        {
                            xml.AppendLine(string.Format("<{0}>", key));
                            foreach (VivoActiveTable table in vivoTables)
                            {
                                xml.AppendLine(string.Format("<table-{0}>", table.TableID));
                                foreach (PropertyInfo p in properties)
                                {
                                    xml.AppendLine(string.Format("<{0}>{1}</{0}>", p.Name, p.GetValue(table).ToString()));
                                }
                                xml.AppendLine(string.Format("</table-{0}>", table.TableID));
                            }
                            xml.AppendLine(string.Format("</{0}>", key));
                        }
                    }
                    xml.AppendLine(@"</root>");
                    return this.Content(xml.ToString(), "text/xml");
                }
                else if (string.Equals(vendor, "RecentWinners", StringComparison.InvariantCultureIgnoreCase))
                {
                    string sql = DwAccessor.GetCasinoGameRecentWinnersInternalSql(domain, false);
                    return this.Content(sql, "text/plain");
                }
                else if (string.Equals(vendor, "GreenTube", StringComparison.InvariantCultureIgnoreCase))
                {
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        GreenTubeAPIRequest request = new GreenTubeAPIRequest()
                        {
                            ArticlesGetRequest = new GreentubeArticlesGetRequest()
                            {
                                LanguageCode = "EN"
                            }
                        };
                        request = client.SingleRequest<GreenTubeAPIRequest>(domain.DomainID, request);

                        DataContractSerializer formatter = new DataContractSerializer(request.ArticlesGetResponse.GetType());
                        using (MemoryStream ms = new MemoryStream())
                        {
                            formatter.WriteObject(ms, request.ArticlesGetResponse);
                            string xml = Encoding.UTF8.GetString(ms.ToArray());
                            return this.Content(xml, "text/xml");
                        }
                    }
                }
                else
                {
                    throw new NotSupportedException();
                }
            }
            catch (Exception ex)
            {
                return this.Content(ex.Message);
            }


        }

    }
}