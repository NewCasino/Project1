using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Xml.Linq;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using GamMatrix.Infrastructure;
using GamMatrixAPI;
using GmCore;
using Newtonsoft.Json;

namespace LiveCasino
{
    /// <summary>
    /// Summary description for GameManager
    /// </summary>
    public static class GameManager
    {
        private sealed class GameListCache : CacheEntryBase<List<Game>>
        {
            public override int ExpirationSeconds
            {
                get { return 30; }
            }

            public GameListCache(List<Game> games)
                : base(games)
            {
            }
        }

        #region Last Winners XML
/*
<?xml version="1.0" encoding="utf-8"?>
<response xmlns="apiWinnersData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<errorCode xmlns="apiResultData">0</errorCode>
<description xmlns="apiResultData"/>
	<winnersList>
		<winner>
			<username>frappicino</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>675.0000</prize>
		</winner>
		<winner>
			<username>abdullatif85</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>500.0000</prize>
		</winner>
		<winner>
			<username>salih34</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>200.0000</prize>
		</winner>
		<winner>
			<username>juliusTR</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>198.9000</prize>
		</winner>
		<winner>
			<username>yasayanolu78</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>108.0000</prize>
		</winner>
		<winner>
			<username>Mstfsnm</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>62.5000</prize>
		</winner>
		<winner>
			<username>dygrogrand</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>59.0000</prize>
		</winner>
		<winner>
			<username>arsenlupen</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>50.0000</prize>
		</winner>
		<winner>
			<username>alperjohn</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>37.5000</prize>
		</winner>
		<winner>
			<username>metinn</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>34.0000</prize>
		</winner>
		<winner>
			<username>alexithymic</username>
			<firstName>first</firstName>
			<lastName>l</lastName>
			<prize>30.0000</prize>
		</winner>
	</winnersList>
</response>
         */
        #endregion

        /// <summary>
        /// Get the last winners
        /// </summary>
        /// <returns></returns>
        public static List<Winner> GetLastWinners()
        {
            string cacheKey = string.Format("_xpro_winners_{0}"
                , SiteManager.Current.DistinctName
                );

            List<Winner> list = HttpRuntime.Cache[cacheKey] as List<Winner>;
            if (list != null)
                return list;
            list = new List<Winner>();
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                XProGamingAPIRequest request = new XProGamingAPIRequest()
                {
                    GetLastWinners = true,
                    GetLastWinnersDaysBack = 30,
                };
                request = client.SingleRequest<XProGamingAPIRequest>(request);

                
//                var test = @"<?xml version=""1.0"" encoding=""utf-8""?>
//<response xmlns=""apiWinnersData"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">
//<errorCode>0</errorCode>
//<description/>
//	<winnersList>
//		<winner>
//			<username>elvishe</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>675.0000</prize>
//		</winner>
//		<winner>
//			<username>elvishe</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>500.0000</prize>
//		</winner>
//		<winner>
//			<username>_Api_Cms</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>200.0000</prize>
//		</winner>
//		<winner>
//			<username>_Api_Cms</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>198.9000</prize>
//		</winner>
//		<winner>
//			<username>elvishe</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>108.0000</prize>
//		</winner>
//		<winner>
//			<username>first</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>62.5000</prize>
//		</winner>
//		<winner>
//			<username>dygrogrand</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>59.0000</prize>
//		</winner>
//		<winner>
//			<username>arsenlupen</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>50.0000</prize>
//		</winner>
//		<winner>
//			<username>alperjohn</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>37.5000</prize>
//		</winner>
//		<winner>
//			<username>metinn</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>34.0000</prize>
//		</winner>
//		<winner>
//			<username>alexithymic</username>
//			<firstName>first</firstName>
//			<lastName>l</lastName>
//			<prize>30.0000</prize>
//		</winner>
//	</winnersList>
//</response>";

                var lastWinnersResult = JsonConvert.DeserializeObject<Dictionary<string, string>>(request.GetLastWinnersResponse);

                foreach (var item in lastWinnersResult)
                {
                    XElement root = XElement.Parse(item.Value);
                    XNamespace ns = root.GetDefaultNamespace();

                    if (root.Element(ns + "errorCode").Value != "0")
                        throw new Exception(root.Element(ns + "description").Value);

                    List<KeyValuePair<long, string>> domain2UsernameMap = new List<KeyValuePair<long, string>>();

                    IEnumerable<XElement> winners = root.Element(ns + "winnersList").Elements(ns + "winner");
                    foreach (XElement winner in winners)
                    {
                        var usernameArr = winner.Element(ns + "username").Value.Split('~');

                        var userName = usernameArr.Length > 1 ? usernameArr[1] : winner.Element(ns + "username").Value;
                        var domainId = SiteManager.Current.DomainID;

                        if (usernameArr.Length > 0)
                        {
                            int.TryParse(usernameArr[0], out domainId);
                        }

                        Winner winnerToAdd = new Winner()
                        {
                            Username = userName,
                            Firstname = winner.Element(ns + "firstName").Value,
                            Lastname = winner.Element(ns + "lastName").Value,
                            Price = decimal.Parse(winner.Element(ns + "prize").Value, CultureInfo.InvariantCulture),
                            Currency = item.Key
                        };
                        list.Add(winnerToAdd);

                        domain2UsernameMap.Add(new KeyValuePair<long, string>(domainId, winnerToAdd.Username));
                    }

                    List<cmUser> users = UserAccessor.GetUsersByUsername(domain2UsernameMap);
                    foreach (Winner win in list)
                    {
                        cmUser user = users.FirstOrDefault(u => string.Equals(u.Username, win.Username, StringComparison.OrdinalIgnoreCase));
                        if (user != null)
                        {
                            win.DisplayName = string.Format("{0}.{1}"
                                , user.FirstName.Truncate(1).DefaultIfNullOrEmpty(string.Empty).ToUpper()
                                , user.Surname.Truncate(1).DefaultIfNullOrEmpty(string.Empty).ToUpper()
                                );

                            List<CountryInfo> countries = CountryManager.GetAllCountries();
                            CountryInfo country = countries.FirstOrDefault(c => c.InternalID == user.CountryID);
                            win.CountryInfo = country;
                        }
                        else
                            win.DisplayName = win.Username;

                    }
                }
            }

            HttpRuntime.Cache.Insert(cacheKey, list, null, DateTime.Now.AddMinutes(15), Cache.NoSlidingExpiration);

            return list;
        }

        #region Game List XML
        /*
<response xmlns="apiGamesLimitsListData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <gamesList>
    <game>
      <limitSetList>
        <limitSet>
          <limitSetID>1</limitSetID>
          <minBet>1.00</minBet>
          <maxBet>20.00</maxBet>
          <minInsideBet>1.00</minInsideBet>
          <maxInsideBet>5000.00</maxInsideBet>
          <minOutsideBet>1.00</minOutsideBet>
          <maxOutsideBet>5000.00</maxOutsideBet>
        </limitSet>
        <limitSet>
          <limitSetID>45</limitSetID>
          <minBet>10.00</minBet>
          <maxBet>3000.00</maxBet>
          <minInsideBet>400.00</minInsideBet>
          <maxInsideBet>300000.00</maxInsideBet>
          <minOutsideBet>400.00</minOutsideBet>
          <maxOutsideBet>300000.00</maxOutsideBet>
        </limitSet>
      </limitSetList>
      <gameID>3</gameID>
      <gameType>1</gameType>
      <gameName>Europe Test 1 LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=3&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList>
        <limitSet>
          <limitSetID>1</limitSetID>
          <minBet>1.00</minBet>
          <maxBet>20.00</maxBet>
          <minInsideBet>1.00</minInsideBet>
          <maxInsideBet>5000.00</maxInsideBet>
          <minOutsideBet>1.00</minOutsideBet>
          <maxOutsideBet>5000.00</maxOutsideBet>
        </limitSet>
        <limitSet>
          <limitSetID>43</limitSetID>
          <minBet>10.00</minBet>
          <maxBet>2000.00</maxBet>
          <minInsideBet>200.00</minInsideBet>
          <maxInsideBet>150000.00</maxInsideBet>
          <minOutsideBet>200.00</minOutsideBet>
          <maxOutsideBet>150000.00</maxOutsideBet>
        </limitSet>
        <limitSet>
          <limitSetID>44</limitSetID>
          <minBet>10.00</minBet>
          <maxBet>1000.00</maxBet>
          <minInsideBet>50.00</minInsideBet>
          <maxInsideBet>100000.00</maxInsideBet>
          <minOutsideBet>50.00</minOutsideBet>
          <maxOutsideBet>100000.00</maxOutsideBet>
        </limitSet>
        <limitSet>
          <limitSetID>45</limitSetID>
          <minBet>10.00</minBet>
          <maxBet>3000.00</maxBet>
          <minInsideBet>400.00</minInsideBet>
          <maxInsideBet>300000.00</maxInsideBet>
          <minOutsideBet>400.00</minOutsideBet>
          <maxOutsideBet>300000.00</maxOutsideBet>
        </limitSet>
      </limitSetList>
      <gameID>4</gameID>
      <gameType>1</gameType>
      <gameName>Europe Test 2 LCPP</gameName>
      <dealerName>Dealer</dealerName>
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/1.jpg</dealerImageUrl>
      <isOpen>1</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=4&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList>
        <limitSet>
          <limitSetID>1</limitSetID>
          <minBet>1.00</minBet>
          <maxBet>20.00</maxBet>
          <minInsideBet>1.00</minInsideBet>
          <maxInsideBet>5000.00</maxInsideBet>
          <minOutsideBet>1.00</minOutsideBet>
          <maxOutsideBet>5000.00</maxOutsideBet>
        </limitSet>
      </limitSetList>
      <gameID>12</gameID>
      <gameType>1</gameType>
      <gameName>Auto Roulette LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=12&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>23:00</openHour>
      <closeHour>22:59</closeHour>
    </game>
    <game>
      <limitSetList>
        <limitSet>
          <limitSetID>1</limitSetID>
          <minBet>1.00</minBet>
          <maxBet>20.00</maxBet>
          <minInsideBet>1.00</minInsideBet>
          <maxInsideBet>5000.00</maxInsideBet>
          <minOutsideBet>1.00</minOutsideBet>
          <maxOutsideBet>5000.00</maxOutsideBet>
        </limitSet>
      </limitSetList>
      <gameID>15</gameID>
      <gameType>1</gameType>
      <gameName>Casino Live Roulette LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=15&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>18:00</openHour>
      <closeHour>03:30</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>5</gameID>
      <gameType>2</gameType>
      <gameName>Test Blackjack 1 LCPP</gameName>
      <dealerName>Dealer</dealerName>
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/1.jpg</dealerImageUrl>
      <isOpen>1</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=5&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>6</gameID>
      <gameType>2</gameType>
      <gameName>Live Blackjack 1 LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=6&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>7</gameID>
      <gameType>2</gameType>
      <gameName>Test Blackjack 2 LCPP</gameName>
      <dealerName>Dealer</dealerName>
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/1.jpg</dealerImageUrl>
      <isOpen>1</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=7&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>8</gameID>
      <gameType>2</gameType>
      <gameName>Live Blackjack 2 LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=8&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>23:00</openHour>
      <closeHour>22:59</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>13</gameID>
      <gameType>2</gameType>
      <gameName>High Blackjack LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=13&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>14</gameID>
      <gameType>2</gameType>
      <gameName>Vegas 365 BJ Privé LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=14&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>18:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>17</gameID>
      <gameType>2</gameType>
      <gameName>Vegas Privé LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=17&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>18:00</closeHour>
    </game>
    <game>
      <limitSetList>
        <limitSet>
          <limitSetID>42</limitSetID>
          <minBet>5.00</minBet>
          <maxBet>500000.00</maxBet>
          <minPlayerBet>5.00</minPlayerBet>
          <maxPlayerBet>50000.00</maxPlayerBet>
        </limitSet>
        <limitSet>
          <limitSetID>52</limitSetID>
          <minBet>1.00</minBet>
          <maxBet>500000000.00</maxBet>
          <minPlayerBet>5.00</minPlayerBet>
          <maxPlayerBet>5000000.00</maxPlayerBet>
        </limitSet>
      </limitSetList>
      <gameID>9</gameID>
      <gameType>4</gameType>
      <gameName>Test Baccarat 1 LCPP</gameName>
      <dealerName>Dealer</dealerName>
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/1.jpg</dealerImageUrl>
      <isOpen>1</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=9&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>10:00</openHour>
      <closeHour>22:00</closeHour>
    </game>
    <game>
      <limitSetList>
        <limitSet>
          <limitSetID>3</limitSetID>
          <minBet>5.00</minBet>
          <maxBet>500.00</maxBet>
          <minPlayerBet>5.00</minPlayerBet>
          <maxPlayerBet>500.00</maxPlayerBet>
        </limitSet>
      </limitSetList>
      <gameID>10</gameID>
      <gameType>4</gameType>
      <gameName>Live Baccarat 1 LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=10&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>13:00</openHour>
      <closeHour>05:00</closeHour>
    </game>
    <game>
      <limitSetList />
      <gameID>19</gameID>
      <gameType>8</gameType>
      <gameName>SP Test 1 LCPP</gameName>
      <dealerName />
      <dealerImageUrl>http://lcppflash.xprogaming.com/dealers/0.jpg</dealerImageUrl>
      <isOpen>0</isOpen>
      <connectionUrl>https://lcpp.xprogaming.com/livegames/GeneralGame.aspx?audienceType=1&amp;gameID=19&amp;operatorID=47&amp;languageID={1}&amp;loginToken={2}&amp;securityCode={3}</connectionUrl>
      <winParams>'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'</winParams>
      <openHour>00:00</openHour>
      <closeHour>00:00</closeHour>
    </game>
  </gamesList>
  <errorCode>0</errorCode>
  <description />
</response>
         * */
        #endregion

        /// <summary>
        /// Get the live casino game list
        /// </summary>
        /// <returns></returns>
        public static List<Game> GetGameList()
        {
            string cacheKey = string.Format( CultureInfo.InvariantCulture, "_xpro_game_list_{0}_{1}"
                , SiteManager.Current.DistinctName
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserID : 0
                );
            GameListCache cache = HttpRuntime.Cache[cacheKey] as GameListCache;
            if (cache != null && !cache.IsExpried)
                return cache.Value;
            List<Game> list = new List<Game>();
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                XProGamingAPIRequest request = new XProGamingAPIRequest()
                {
                    GetGamesListWithLimits = true,
                    GetGamesListWithLimitsGameType = (int)GameType.AllGames,
                    GetGamesListWithLimitsOnlineOnly = 0,
                };
                if( CustomProfile.Current.IsAuthenticated )
                    request.GetGamesListWithLimitsUserName = CustomProfile.Current.UserName;
                request = client.SingleRequest<XProGamingAPIRequest>(request);

                XElement root = XElement.Parse(request.GetGamesListWithLimitsResponse);
                XNamespace ns = root.GetDefaultNamespace();
                if (root.Element( ns + "errorCode").Value != "0")
                    throw new Exception(root.Element(ns + "description").Value);

                IEnumerable<XElement> games = root.Element(ns + "gamesList").Elements(ns + "game");
                foreach (XElement game in games)
                {
                    // Live Dragon Tiger Filter 
                    if (game.Element(ns + "gameID").Value == "36")
                    {
                        continue;
                    }
                    Game gameToAdd = new Game()
                    {
                        GameID = game.Element(ns + "gameID").Value,
                        GameType = (GameType)int.Parse(game.Element(ns + "gameType").Value),
                        GameName = game.Element(ns + "gameName").Value,
                        ConnectionUrl = game.Element(ns + "connectionUrl").Value,
                        WindowParams = game.Element(ns + "winParams").Value,
                        OpenHour = game.Element(ns + "openHour").Value,
                        CloseHour = game.Element(ns + "closeHour").Value,
                        DealerName = game.Element(ns + "dealerName").Value,
                        DealerImageUrl = game.Element(ns + "dealerImageUrl").Value,
                        IsOpen = string.Equals( game.Element(ns + "isOpen").Value, "1"),
                    };

                    IEnumerable<XElement> limitSets = game.Element(ns + "limitSetList").Elements(ns + "limitSet");
                    foreach (XElement limitSet in limitSets)
                    {
                        LimitSet limitSetToAdd = new LimitSet();

                        decimal temp;
                        limitSetToAdd.ID = limitSet.Element(ns + "limitSetID").Value;
                        if (limitSet.Element(ns + "minBet") != null && decimal.TryParse(limitSet.Element(ns + "minBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MinBet = temp;
                        if (limitSet.Element(ns + "maxBet") != null && decimal.TryParse(limitSet.Element(ns + "maxBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MaxBet = temp;
                        if (limitSet.Element(ns + "minInsideBet") != null && decimal.TryParse(limitSet.Element(ns + "minInsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MinInsideBet = temp;
                        if (limitSet.Element(ns + "maxInsideBet") != null && decimal.TryParse(limitSet.Element(ns + "maxInsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MaxInsideBet = temp;
                        if (limitSet.Element(ns + "minOutsideBet") != null && decimal.TryParse(limitSet.Element(ns + "minOutsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MinOutsideBet = temp;
                        if (limitSet.Element(ns + "maxOutsideBet") != null && decimal.TryParse(limitSet.Element(ns + "maxOutsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MaxOutsideBet = temp;
                        if (limitSet.Element(ns + "minPlayerBet") != null && decimal.TryParse(limitSet.Element(ns + "minPlayerBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MinPlayerBet = temp;
                        if (limitSet.Element(ns + "maxPlayerBet") != null && decimal.TryParse(limitSet.Element(ns + "maxPlayerBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                            limitSetToAdd.MaxPlayerBet = temp; 

                        gameToAdd.LimitSets.Add(limitSetToAdd);
                    }

                    list.Add(gameToAdd);
                }
            }

            HttpRuntime.Cache.Insert(cacheKey, new GameListCache(list));
            return list;
        }


        /// <summary>
        /// Get the launch url of the game
        /// </summary>
        /// <param name="gameID"></param>
        /// <param name="limitSetID"></param>
        /// <param name="language"></param>
        /// <returns></returns>
        public static string GetLaunchUrl(string gameID, string limitSetID, string language)
        {
            Game game = GetGameList().First( g => string.Equals( g.GameID, gameID, StringComparison.OrdinalIgnoreCase));
            
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                XProGamingGameLaunchRequest request = new XProGamingGameLaunchRequest
                {
                    UserID = CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserID : 0,
                    GameURL = game.ConnectionUrl,
                    LanguageID = GetLCID(language),
                    RegisterTokenProps = string.IsNullOrWhiteSpace(limitSetID) ? null : string.Format( CultureInfo.InvariantCulture, "LimitSetID:{0}", limitSetID)
                };

                request = client.SingleRequest <XProGamingGameLaunchRequest>(request);
                return request.RedirectURL;
            }
        }

        /// <summary>
        /// Get the supported locale ID for Live Casino
        /// </summary>
        /// <param name="language">language codes</param>
        /// <returns>LCID in DEC</returns>
        public static string GetLCID(string language)
        {
            if( string.IsNullOrWhiteSpace(language) )
                language = "en";
            else
            {
                if( string.Equals( language.Truncate(2), "en", StringComparison.OrdinalIgnoreCase) )
                {
                    language = "en";
                }
                else if (string.Equals(language.Truncate(2), "fr", StringComparison.OrdinalIgnoreCase))
                {
                    language = "fr";
                }
                else
                {
                    switch (language.ToLower(CultureInfo.InvariantCulture))
                    {
                        case "hu":
                        case "tr":
                        case "it":
                        case "el":
                        case "es":
                        case "de":
                        case "pt":
                        case "ru":
                        case "ja":
                        case "th":
                            break;

                        default:
                            language = "en";
                            break;
                    }
                }
            }
            CultureInfo ci = new CultureInfo(language);
            return ci.LCID.ToString();
        }// GetLCID

        public static string GetMicrogamingLiveDealerLobbyUrl(string language)
        {
            string url = string.Empty;

            string token = string.Empty;
            if (CustomProfile.Current.IsAuthenticated)
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    VanguardGetSessionRequest request = new VanguardGetSessionRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                    };
                    request = client.SingleRequest<VanguardGetSessionRequest>(request);
                    token = request.Token;
                }
            }

            if (string.IsNullOrWhiteSpace(language))
                language = "en";
            else
            {
                switch (language.ToLower(CultureInfo.InvariantCulture))
                {
                    case "ja": language = "ja-jp"; break;
                    case "zh-cn": language = "zh-cn"; break;
                    case "zh-tw": language = "zh-tw"; break;
                    case "ko": language = "ko-kr"; break;
                    default: language = "en"; break;
                }
            }


            return string.Format( Settings.LiveCasino_MicrogamingLiveDealerLobbyUrl, language, token);
        }

        

    }
}