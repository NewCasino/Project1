using System;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;
using System.Runtime.Serialization;
using System.IO;
using System.Xml;
namespace CE.db
{
    public sealed class ceCasinoGame
    {
        [PrimaryKey, Identity]
        public long ID { get; set; }

        [DefaultValue("GETDATE()")]
        public DateTime Ins { get; set; }

        public long DomainID { get; set; }

        public string SessionID { get; set; }

        public long SessionUserID { get; set; }

        public long HID { get; set; }

        public long CasinoGameBaseID { get; set; }
        
        [DefaultValue("0")]
        public bool Enabled { get; set; }

        public string GameName { get; set; }

        public string ShortName { get; set; }

        public string Thumbnail { get; set; }

        public string ScalableThumbnail { get; set; }

        public string Logo { get; set; }

        public string Icon { get; set; }

        public string BackgroundImage { get; set; }

        public string Description { get; set; }

        public string Tags { get; set; }

        public string GameCategories { get; set; }

        public string ClientCompatibility { get; set; }

        public string ReportCategory { get; set; }

        public string InvoicingGroup { get; set; }

        public string GameLaunchUrl { get; set; }

        public string MobileGameLaunchUrl { get; set; }

        public decimal? TheoreticalPayOut { get; set; }

        public decimal? BonusContribution { get; set; }

        public decimal? ThirdPartyFee { get; set; }

        public decimal? JackpotContribution { get; set; }

        public decimal? FPP { get; set; }

        public decimal? PopularityCoefficient { get; set; }

        public bool? FunMode { get; set; }

        public bool? RealMode { get; set; }

        public bool? NewGame { get; set; }

        public DateTime? NewGameExpirationDate { get; set; }

        public bool? AnonymousFunMode { get; set; }
        
        public int? Width { get; set; }

        public int? Height { get; set; }

        public LicenseType? License { get; set; }

        public JackpotType? JackpotType { get; set; }

        public bool? OpVisible { get; set; }

        public decimal? DefaultCoin { get; set; }

        public bool? ExcludeFromBonuses { get; set; }

        public bool? ExcludeFromBonuses_EditableByOperator { get; set; }

        public string ExtraParameter1 { get; set; }

        public string SpinLines { get; set; }

        public string SpinCoins { get; set; }

        public string SpinDenominations { get; set; }

        public string RestrictedTerritories { get; set; }

        [DefaultValue(false)]
        public bool? SupportFreeSpinBonus { get; set; }

        public int? FreeSpinBonus_DefaultLine { get; set; }

        public int? FreeSpinBonus_DefaultCoin { get; set; }

        public decimal? FreeSpinBonus_DefaultDenomination { get; set; }

        public string Languages { get; set; }

        public string LimitationXml { get; set; }

        public bool? AgeLimit { get; set; }

        public bool? LaunchGameInHtml5 { get; set; }
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
                        return _limit;

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
                    _limit = new LiveCasinoTableLimit();
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
         * */
    }
}