using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Runtime.Serialization;
using System.Web.Script.Serialization;

namespace NetEntAPI
{
    [Serializable]
    [DataContract]
    public class RawNetEntLiveCasinoTable
    {
        [DataMember(Name = "tableId")]
        public int TableID { get; set; }

        [DataMember(Name = "tableType")]
        public string TableType { get; set; }

        [DataMember(Name = "games")]
        public RawNetEntLiveCasinoGame [] Games { get; set; }

        [DataMember(Name = "slots")]
        public RawNetEntLiveCasinoSlot [] Slots { get; set; }

        public static RawNetEntLiveCasinoTable [] Get(string url)
        {
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
                    return jss.Deserialize<RawNetEntLiveCasinoTable[]>(json);
                }
            }
        }
    }

    [Serializable]
    [DataContract]
    public class RawNetEntLiveCasinoGame
    {
        [DataMember(Name = "gameId")]
        public string GameID { get; set; }

        public Dictionary<string, object> @params { get; set; }
    }

    [Serializable]
    [DataContract]
    public class RawNetEntLiveCasinoSlot
    {
        [DataMember(Name = "index")]
        public int Index { get; set; }

        [DataMember(Name = "available")]
        public bool Available { get; set; }
    }

    /*
[
   {
      "tableId": 1003,
      "tableType": "AUTOMATIC_ROULETTE",
      "games": [
         {
            "gameId": "lcrouletteautofrenchlp_sw",
            "params": {
               "mediumWinMultiplier": "12",
               "gameOrder": "10",
               "CORNER": "50000",
               "SIXLINE": "75000",
               "gameType": "FLASH",
               "MINBET": "200",
               "binaryFilename": "roulette-application.swf",
               "STRAIGHT": "12500",
               "width": "1024",
               "bigWinMultiplier": "35",
               "DOZEN": "150000",
               "MAXBET": "2000000",
               "ODDEVEN": "250000",
               "SPLIT": "25000",
               "COLUMN": "150000",
               "gameServerIdentifier": "lcroulettelp",
               "REDBLACK": "250000",
               "height": "768",
               "DEFAULTDENOMINATION": "100",
               "HIGHLOW": "250000",
               "fullName": "LiveCasino French Auto Roulette La Partage",
               "THREELINE": "37500",
               "DENOMINATIONS": "100,500,2500,10000,100000"
            }
         },
         {
            "gameId": "lcrouletteauto_sw",
            "params": {
               "mediumWinMultiplier": "12",
               "gameOrder": "10",
               "CORNER": "50000",
               "SIXLINE": "75000",
               "gameType": "FLASH",
               "MINBET": "100",
               "binaryFilename": "roulette-application.swf",
               "STRAIGHT": "12500",
               "width": "1024",
               "bigWinMultiplier": "35",
               "DOZEN": "150000",
               "MAXBET": "2000000",
               "ODDEVEN": "250000",
               "SPLIT": "25000",
               "COLUMN": "150000",
               "gameServerIdentifier": "lcroulette",
               "REDBLACK": "250000",
               "height": "768",
               "DEFAULTDENOMINATION": "100",
               "HIGHLOW": "250000",
               "fullName": "LiveCasino Auto Roulette",
               "THREELINE": "37500",
               "DENOMINATIONS": "100,500,2500,10000,100000"
            }
         },
         {
            "gameId": "lcrouletteautolp_sw",
            "params": {
               "mediumWinMultiplier": "12",
               "gameOrder": "10",
               "CORNER": "50000",
               "SIXLINE": "75000",
               "gameType": "FLASH",
               "MINBET": "200",
               "binaryFilename": "roulette-application.swf",
               "STRAIGHT": "12500",
               "width": "1024",
               "bigWinMultiplier": "35",
               "DOZEN": "150000",
               "MAXBET": "2000000",
               "ODDEVEN": "250000",
               "SPLIT": "25000",
               "COLUMN": "150000",
               "gameServerIdentifier": "lcroulettelp",
               "REDBLACK": "250000",
               "height": "768",
               "DEFAULTDENOMINATION": "100",
               "HIGHLOW": "250000",
               "fullName": "LiveCasino Auto Roulette La Partage",
               "THREELINE": "37500",
               "DENOMINATIONS": "100,500,2500,10000,100000"
            }
         },
         {
            "gameId": "lcrouletteautofrench_sw",
            "params": {
               "mediumWinMultiplier": "12",
               "gameOrder": "10",
               "CORNER": "50000",
               "SIXLINE": "75000",
               "gameType": "FLASH",
               "MINBET": "100",
               "binaryFilename": "roulette-application.swf",
               "STRAIGHT": "12500",
               "width": "1024",
               "bigWinMultiplier": "35",
               "DOZEN": "150000",
               "MAXBET": "2000000",
               "ODDEVEN": "250000",
               "SPLIT": "25000",
               "COLUMN": "150000",
               "gameServerIdentifier": "lcroulette",
               "REDBLACK": "250000",
               "height": "768",
               "DEFAULTDENOMINATION": "100",
               "HIGHLOW": "250000",
               "fullName": "LiveCasino French Auto Roulette",
               "THREELINE": "37500",
               "DENOMINATIONS": "100,500,2500,10000,100000"
            }
         }
      ],
      "dealer": {
         "nickName": null,
         "imageUrl": null
      }
   },
   {
      "tableId": 101,
      "tableType": "BLACKJACK_COMMON_DRAW",
      "games": [
         {
            "gameId": "lcblackjackcd_sw",
            "params": {
               "gameServerIdentifier": "lcblackjackcd",
               "gameOrder": "1",
               "height": "768",
               "DEFAULTDENOMINATION": "500",
               "gameType": "FLASH",
               "binaryFilename": "blackjack-application.swf",
               "MAX_BOX_BET": "50000",
               "width": "1024",
               "MIN_BOX_BET": "500",
               "fullName": "Blackjack Multiplayer Common Draw",
               "DENOMINATIONS": "100,500,2500,10000,50000"
            }
         }
      ],
      "dealer": {
         "nickName": "Anni",
         "imageUrl": "core/StaffImage/annkor"
      }
   }
]
     */
}
