namespace CE.DomainConfig
{
    /// <summary>
    /// BoomingGames class
    /// </summary>
    public static class BoomingGames
    {
        /// <summary>
        /// The vendor API base URL
        /// </summary>
        [Config(Comments = "Vendor API base Url",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "https://api.demo-games.net")]
        public const string VendorAPIBaseUrl = "BoomingGames.VendorAPIBaseUrl";

        /// <summary>
        /// The vendor API session URL path
        /// </summary>
        [Config(Comments = "Vendor API Session Url Path",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "/v1/session")]
        public const string VendorAPISessionUrlPath = "BoomingGames.VendorAPISessionUrlPath";

        /// <summary>
        /// The secret key
        /// </summary>
        [Config(Comments = "Secret Key",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "EtJeAeyJG13GMjNUNLdudmoE6TJ20lpFp/8QIIjeDgVc+tilIWrrRdMRH6iKQv8x")]
        public const string SecretKey = "BoomingGames.SecretKey";

        /// <summary>
        /// The API key
        /// </summary>
        [Config(Comments = "API Key",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "cjlNIek02f29CaV8wm/aow==")]
        public const string APIKey = "BoomingGames.APIKey";

        /// <summary>
        /// The call back URL
        /// </summary>
        [Config(Comments = "GIC End point (wallet api)",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "https://gamingapi-dev.gammatrix.com/gameapi/boominggames/wallet")]
        public const string CallBackURL = "BoomingGames.CallBackURL";

        /// <summary>
        /// The cancel URL
        /// </summary>
        [Config(Comments = "GIC End point (cancel api)",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "https://gamingapi-dev.gammatrix.com/gameapi/boominggames/cancel")]
        public const string CancelURL = "BoomingGames.CancelURL";

        /// <summary>
        /// The CE launch inject script URL
        /// </summary>
        [Config(Comments = "CE Launch Inject Script URL",
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "BoomingGames.CELaunchInjectScriptUrl";
    }
}