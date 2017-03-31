using System;
using System.Collections.Generic;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;
using GamMatrixAPI;
using System.Runtime.Serialization;
using System.IO;
using System.Xml;

namespace CE.db
{
    public enum LicenseType
    {
        None = 0,
        Alderney = 1,
        Malta = 2,
        Curacao = 4,
    }

    [Flags]
    public enum JackpotType
    {
        None = 0,
        Local = 1,
        Global = 2,
    }
    public class ceCasinoGameRounds : ceCasinoGameKey {
        public int GameRounds { get; set; }
    }
    public class ceCasinoGameWins : ceCasinoGameKey {
        public string PostingAmountEUR { get; set; }
    }
    public class ceCasinoGameTranStatus : ceCasinoGameKey
    {
        public string TransCompleted { get; set; } 
    }
    public class ceCasinoGameKey {

        [PrimaryKey, Identity]
        public long ID { get; set; }
        public string GameCode { get; set; }
        public string GameID { get; set; } 
        public string GameName { get; set; }
        public VendorID VendorID { get; set; }
    
    }
    public class ceCasinoGameBaseKey
    {
        public int VendorID { get; set; }
        public string GameCode { get; set; }
        public long Popularity { get; set; }
    }
    [Serializable]
    public sealed class CasinoGameLimitAmount
    {
        public decimal MinAmount;
        public decimal MaxAmount;
    }
    /// <summary>
    ///  ceCasinoGameBase table
    /// </summary>
    public class ceCasinoGameBase
    {
        [PrimaryKey, Identity]
        public long ID { get; set; }

        [DefaultValue("GETDATE()")]
        public DateTime Ins { get; set; }    

        public long DomainID { get; set; }

        public string SessionID { get; set; }

        public long SessionUserID { get; set; }

        public long HID { get; set; }

        public VendorID VendorID { get; set; }

        public VendorID OriginalVendorID { get; set; }

        public int ContentProviderID { get; set; }

        public string GameCode { get; set; }

        public string GameID { get; set; }

        public string ExtraParameter1 { get; set; }

        public string ExtraParameter2 { get; set; }

        public string GameName { get; set; }

        public string ShortName { get; set; }

        public string Thumbnail { get; set; }

        public string ScalableThumbnail { get; set; }

        public string Icon { get; set; }

        public string Logo { get; set; }

        public string BackgroundImage { get; set; }        

        public string Description { get; set; }

        public string Tags { get; set; }

        public string Slug { get; set; }

        public string GameCategories { get; set; }

        public string RestrictedTerritories { get; set; }

        public string ClientCompatibility { get; set; }

        public string ReportCategory { get; set; }

        public string InvoicingGroup { get; set; }

        public string GameLaunchUrl { get; set; }
        
        public string MobileGameLaunchUrl { get; set; }

        public decimal TheoreticalPayOut { get; set; }

        public decimal BonusContribution { get; set; }

        public decimal ThirdPartyFee { get; set; }

        public decimal JackpotContribution { get; set; }

        public decimal FPP { get; set; }

        public decimal PopularityCoefficient { get; set; }

        [DefaultValue("1")]
        public bool FunMode { get; set; }

        [DefaultValue("1")]
        public bool AnonymousFunMode { get; set; }

        [DefaultValue("1")]
        public bool RealMode { get; set; }

        [DefaultValue("1")]
        public bool NewGame { get; set; }

        [DefaultValue("0")]
        public bool AgeLimit { get; set; }

        [DefaultValue("0")]
        public bool LaunchGameInHtml5 { get; set; }

        public DateTime NewGameExpirationDate { get; set; }


        [DefaultValue("0")]
        public int Width { get; set; }

        [DefaultValue("0")]
        public int Height { get; set; }

        [DefaultValue("1")]
        public bool Enabled { get; set; }


        [DefaultValue("0")]
        public LicenseType License { get; set; }

        [DefaultValue("0")]
        public JackpotType JackpotType { get; set; }

        public string Languages { get; set; }

        [DefaultValue("1")]
        public bool OpVisible { get; set; }

        public decimal DefaultCoin { get; set; }

        [DefaultValue("0")]
        public bool ExcludeFromBonuses { get; set; }

        [DefaultValue("0")]
        public bool ExcludeFromBonuses_EditableByOperator { get; set; }

        public string SpinLines { get; set; }

        public string SpinCoins { get; set; }

        public string SpinDenominations { get; set; }

        [DefaultValue(false)]
        public bool SupportFreeSpinBonus { get; set; }

        public int? FreeSpinBonus_DefaultLine { get; set; }

        public int? FreeSpinBonus_DefaultCoin { get; set; }

        public decimal? FreeSpinBonus_DefaultDenomination { get; set; }
        public string LimitationXml { get; set; }
        public Dictionary<string, CasinoGameLimitAmount> LimitAmounts { get; set; }
        
        /*
        private LiveCasinoTableLimit _limit;

        [MapIgnore]
        public LiveCasinoTableLimit Limit
        {
            get
            {
                try
                {
                    if (_limit != null)
                    {
                        return _limit;
                    }
                    if (!string.IsNullOrWhiteSpace(this.LimitationXml))
                    {
                        DataContractSerializer formatter = new DataContractSerializer(typeof(LiveCasinoTableLimit));
                        using (StringReader sr = new StringReader(this.LimitationXml))
                        using (XmlReader xr = XmlTextReader.Create(sr))
                        {
                            _limit = (LiveCasinoTableLimit)formatter.ReadObject(xr);
                        }
                    }
                }
                catch
                {
                }
                if (_limit == null)
                {
                    _limit = new LiveCasinoTableLimit();
                }
                return _limit;
            }
            set
            {
                DataContractSerializer formatter = new DataContractSerializer(typeof(LiveCasinoTableLimit));
                using (StringWriter sw = new StringWriter())
                {
                    using (XmlWriter xw = XmlTextWriter.Create(sw))
                    {
                        formatter.WriteObject(xw, value);
                        xw.Flush();
                    }
                    this.LimitationXml = sw.ToString();
                }
                _limit = value;
            }
        }
        */
    }

    public class ceCasinoGameBaseEx : ceCasinoGameBase
    {
        public long CasinoGameId { get; set; }
        
        public string ScalableThumbnailPath { get; set; }
    }
}
