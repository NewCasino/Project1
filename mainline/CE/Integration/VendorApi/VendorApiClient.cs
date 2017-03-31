using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using CE.Integration.VendorApi.Models;
using Newtonsoft.Json;

namespace CE.Integration.VendorApi
{
    public class VendorApiClient : IDisposable
    {       
         private const int TIMEOUT_MS = 150 * 1000;

        private string _serviceURL;
        private int _timeoutMs;
        private string _vendorName;

        public VendorApiClient(string vendorName)
            : this(ConfigurationManager.AppSettings["VendorApi.RestURL"], TIMEOUT_MS)
        {
           this._vendorName = vendorName.ToLower();
        }


        public VendorApiClient(string serviceURL, int timeoutMs)
        {
            this._serviceURL = serviceURL;
            this._timeoutMs = timeoutMs;
        }

        public CreateUserResponse CreateUser(CreateUserRequest createUserRequest)
        {
            string content = JsonConvert.SerializeObject(createUserRequest);
            string path = string.Format("/vendoruser/{0}/CreateUser", _vendorName);
            string response = Post(content, path);
            CreateUserResponse createUserResponse = JsonConvert.DeserializeObject<CreateUserResponse>(response);

            return createUserResponse;
        }

        public GetBalanceResponse GetVendorBalance(GetBalanceRequest getBalanceRequest)
        {
            string content = JsonConvert.SerializeObject(getBalanceRequest);
            string path = string.Format("/vendorwallet/{0}/GetBalance", _vendorName);
            string response = Post(content, path);
            GetBalanceResponse balanceResponse = JsonConvert.DeserializeObject<GetBalanceResponse>(response);

            return balanceResponse;
        }

        public GetBalanceResponse GetWalletBalance(GetBalanceRequest getBalanceRequest)
        {
            string content = JsonConvert.SerializeObject(getBalanceRequest);
            string path = "/vendorwallet/GetBalance";
            string response = Post(content, path);
            GetBalanceResponse balanceResponse = JsonConvert.DeserializeObject<GetBalanceResponse>(response);

            return balanceResponse;
        }

        public TransferResponse TransferMoney(TransferRequest transferRequest)
        {
            string content = JsonConvert.SerializeObject(transferRequest);
            string path = "/vendorwallet/TransferNotification";
            string response = Post(content, path);
            TransferResponse balanceResponse = JsonConvert.DeserializeObject<TransferResponse>(response);

            return balanceResponse;
        }     
        
        public GameListResponse GetGameList(GameListRequest gamesListRequest)
        {
            string content = JsonConvert.SerializeObject(gamesListRequest);
            string path = string.Format("/gamestatistics/{0}/GameList", _vendorName);
            string response = Post(content, path);
            GameListResponse gameConfiguratuionsResponse = JsonConvert.DeserializeObject<GameListResponse>(response);

            return gameConfiguratuionsResponse;
        }

        public GamesConfigurationsResponse GetGamesConfigurations(GamesConfigurationsRequest gamesConfigurationsRequest)
        {
            string content = JsonConvert.SerializeObject(gamesConfigurationsRequest);
            string path = string.Format("gamestatistics/{0}/GameConfigurations", _vendorName);
            string response = Post(content, path);
            GamesConfigurationsResponse gameConfiguratuionsResponse = JsonConvert.DeserializeObject<GamesConfigurationsResponse>(response);

            return gameConfiguratuionsResponse;
        }

        public CreateGameSessionResponse CreateGameSession(CreateGameSessionRequest gameSessionRequest)
        {
            string content = JsonConvert.SerializeObject(gameSessionRequest);
            string path = string.Format("/vendoruser/{0}/CreateGameSession", _vendorName);
            string response = Post(content, path);
            CreateGameSessionResponse createGameSessionResponse = JsonConvert.DeserializeObject<CreateGameSessionResponse>(response);

            return createGameSessionResponse;
        }       
    

        private string Post(string data, string path)
        {
            WebRequest request = HttpWebRequest.Create(GetApiURL(path));
            request.Method = "POST";
            request.ContentType = "application/json";
            request.Timeout = this._timeoutMs;

            using (StreamWriter writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(data);
            }

            WebResponse response = null;
            try
            {
                response = request.GetResponse();
                using (StreamReader reader = new StreamReader(response.GetResponseStream()))
                {
                    return reader.ReadToEnd();
                }
            }
            finally
            {
                if (response != null)
                    response.Close();
            }
        }

        private string GetApiURL(string path)
        {
            return string.Format("{0}{1}", this._serviceURL, path);
        }

        public void Dispose()
        {                      
        }
    }
}
