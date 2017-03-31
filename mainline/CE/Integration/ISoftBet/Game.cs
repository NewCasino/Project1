using System;

namespace ISoftBetIntegration
{
    [Serializable]
    public sealed class Game
    {
        private const string CACHE_FILE_FORMAT = "ISoftBet.CasinoGames.{0}.dat";

        #region Fields
        public PresentationType PresentationType { get; set; }

        public string CategoryID { get; set;}

        /// <summary>
        /// id
        /// </summary>
        public string ID { get; set; }

        public string SkinID { get; set; }

        /// <summary>
        /// n
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// simg
        /// </summary>
        public string Thumbnail { get; set; }

        /// <summary>
        /// limg
        /// </summary>
        public string Image { get; set; }

        /// <summary>
        /// html_img
        /// </summary>
        public string VerticalImage { get; set; }

        public string CustomBackgrounds { get; set; }

        /// <summary>
        /// img_v2
        /// </summary>
        public string BigImage { get; set; }

        /// <summary>
        /// fa
        /// </summary>
        public bool FunModel { get; set; }

        /// <summary>
        /// ra
        /// </summary>
        public bool RealModel { get; set; }

        /// <summary>
        /// tfa
        /// </summary>
        public bool TestFunMode { get; set; }

        /// <summary>
        /// tra
        /// </summary>
        public bool TestRealMode { get; set; }

        /// <summary>
        /// ta
        /// </summary>
        public string[] UserIDs { get; set; }

        /// <summary>
        /// c
        /// </summary>
        public decimal[] Coins { get; set; }

        /// <summary>
        /// cd
        /// </summary>
        public decimal DefaultCoin { get; set; }

        public decimal MinCoin { get; set; }
        public decimal MaxCoin { get; set; }

        /// <summary>
        /// main_cat
        /// </summary>
        public string MainCategory { get; set; }

        public string URL { get; set; }
        public string RealModeURL { get; set; }
        
        public string SwfRevision { get; set; }
        public string RealModeSwfRevision { get; set; }

        public string Host { get; set; }
        public string RealModeHost { get; set; }       

        public bool UseCustomLoader { get; set; }
        public bool RealModeUseCustomLoader { get; set; }
        public string CustomLoader { get; set; }
        public string RealModeCustomLoader { get; set; }

        public string WMode { get; set; }

        public string Casino { get; set; }

        /// <summary>
        /// rc
        /// </summary>
        public string[] RestrictedCountries { get; set; }

        /// <summary>
        /// translated
        /// </summary>
        public bool Translated { get; set; }

        /// <summary>
        /// i
        /// </summary>
        public string Identifier { get; set; }

        /// <summary>
        /// provider
        /// </summary>
        public string Provider { get; set; }

        /// <summary>
        /// d
        /// </summary>
        public string Description { get; set; }        
        #endregion Fields
    }

}
