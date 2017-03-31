using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.Serialization;
using CE.db;
using Newtonsoft.Json;

namespace CE.Integration.Metadata
{
    [DataContract]
    [Serializable]
    public sealed class CasinoGame
    {
        public ulong GameInformationHash { get; private set; }

        private ceDomainConfig Domain { get; set; }

        public string GetGameInformation(string lang)
        {
            return Translation.GetByHash(this.Domain, lang, this.GameInformationHash);
        }

        public static string GetGameInformation(ceDomainConfig domain, long id, string lang)
        {
            Dictionary<long, CasinoGame> casinoGames = GetAll(domain);
            CasinoGame casinoGame;
            if (casinoGames.TryGetValue(id, out casinoGame))
                return casinoGame.GetGameInformation(lang);

            return null;
        }


        /// <summary>
        /// Get all the casino games for a specific vendor
        /// </summary>
        /// <param name="domain"></param>
        /// <param name="reloadCache"></param>
        /// <returns></returns>
        public static Dictionary<long, CasinoGame> GetAll(ceDomainConfig domain, bool reloadCache = false)
        {
            string cacheFile = MetadataFileCache.GetPath<CasinoGame>(domain.DomainID.ToString(CultureInfo.InvariantCulture));

            if (reloadCache)
                DelayUpdateCache<Dictionary<long, CasinoGame>>.SetExpired(cacheFile);

            Func<Dictionary<long, CasinoGame>> func = () =>
            {
                var dic = new Dictionary<long, CasinoGame>();

                try
                {
                    // {"8101":{"game-information":"12027250142368842869"},"8102":{"game-information":"5380242421959168179"}}
                    string json = MetadataClient.GetCasinoGames(domain);
                    using (StringReader sr = new StringReader(json))
                    using (JsonTextReader reader = new JsonTextReader(sr))
                    {

                        if (!reader.Read() || reader.TokenType != JsonToken.StartObject)
                            throw new Exception("Unknown format from metadata");

                        CasinoGame casinoGame = null;
                        while (reader.Read())
                        {
                            if (casinoGame == null)
                            {
                                if (reader.TokenType == JsonToken.PropertyName)
                                {
                                    casinoGame = new CasinoGame() { Domain = domain };
                                    dic[ConvertHelper.ToInt64(reader.Value)] = casinoGame;

                                    if (!reader.Read() || reader.TokenType != JsonToken.StartObject)
                                        throw new Exception("Unknown format from metadata");
                                }
                                else if (reader.TokenType == JsonToken.EndObject)
                                    break;
                                else
                                    throw new Exception("Unknown format from metadata");
                            }
                            else
                            {
                                if (reader.TokenType == JsonToken.EndObject)
                                {
                                    casinoGame = null;
                                }
                                else if (reader.TokenType == JsonToken.PropertyName)
                                {
                                    string propertyName = reader.Value.ToString().ToLowerInvariant();
                                    reader.Read();
                                    switch (propertyName)
                                    {
                                        case "game-information":
                                            casinoGame.GameInformationHash = ConvertHelper.ToUInt64(reader.Value);
                                            break;


                                        default:
                                            break;
                                    }
                                }
                                else
                                    throw new Exception("Unknown format from metadata");
                            }
                        }
                    }
                }
                catch
                {

                }

                return dic;
            };

            Dictionary<long, CasinoGame> cache = null;
            bool ret = DelayUpdateCache<Dictionary<long, CasinoGame>>.TryGetValue(cacheFile, out cache, func, 36000);
            if (ret)
                return cache;

            return func();
        }


    }

}
