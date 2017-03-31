using System;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Xml;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;
using GamMatrixAPI;

namespace CE.db
{
    public enum DealerGender
    {
        [Description("Not Fixed")]
        NotFixed = 0,
        Male = 1,
        Female = 2,
    }

    public enum DealerOrigin
    {
        [Description("Not Fixed")]
        NotFixed = 0,
        Europe = 1,
        Asia = 2,
    }
    /// <summary>
    ///  ceLiveCasinoTableBase table
    /// </summary>
    public class ceLiveCasinoTableBase
    {
        [PrimaryKey]
        public long ID { get; set; }

        public DateTime Ins { get; set; }

        public long DomainID { get; set; }

        public string SessionID { get; set; }

        public long SessionUserID { get; set; }

        public long HID { get; set; }

        public long CasinoGameBaseID { get; set; }

        public string ExtraParameter1 { get; set; }

        public string ExtraParameter2 { get; set; }

        public string ExtraParameter3 { get; set; }

        public string ExtraParameter4 { get; set; }

        public string LaunchParams { get; set; }

        public string TableName { get; set; }

        public string Category { get; set; }

        public string ShortName { get; set; }

        public string Thumbnail { get; set; }

        public string Logo { get; set; }

        public string BackgroundImage { get; set; }

        public string OpenHoursTimeZone { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public int OpenHoursStart { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public int OpenHoursEnd { get; set; }

        public string LimitationXml { get; set; }

        [BLToolkit.Mapping.DefaultValue("1")]
        public bool Enabled { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public bool VIPTable { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public bool NewTable { get; set; }

        [BLToolkit.Mapping.DefaultValue("GETDATE()")]
        public DateTime NewTableExpirationDate { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public bool ExcludeFromRandomLaunch { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public bool TurkishTable { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public bool BetBehindAvailable { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public bool SeatsUnlimited { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public DealerGender DealerGender { get; set; }

        [BLToolkit.Mapping.DefaultValue("0")]
        public DealerOrigin DealerOrigin { get; set; }

        public string ClientCompatibility { get; set; }

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

        [BLToolkit.Mapping.DefaultValue("1")]
        public bool OpVisible { get; set; }

        public string TableStudioUrl  { get; set; }

    }


    public class ceLiveCasinoTableBaseEx : ceLiveCasinoTableBase
    {
        public VendorID VendorID { get; set; }
        public string GameID { get; set; }


        public bool IsOpen(long domainID)
        {
            switch (this.VendorID)
            {
                case VendorID.XProGaming:
                    {
                        XProGaming.Game g = XProGaming.Game.Get(domainID, this.GameID);
                        return g == null || g.IsOpen;
                    }

                case VendorID.Microgaming:
                case VendorID.EvolutionGaming:
                    {
                        if (!string.IsNullOrWhiteSpace(this.OpenHoursTimeZone) &&
                            this.OpenHoursStart != this.OpenHoursEnd)
                        {
                            TimeZoneInfo timeZone = TimeZoneInfo.GetSystemTimeZones().FirstOrDefault(t => string.Equals(t.StandardName, this.OpenHoursTimeZone, StringComparison.InvariantCultureIgnoreCase));
                            if (timeZone != null)
                            {
                                DateTime now = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone);
                                int minutes = now.Hour * 60 + now.Minute;
                                if (this.OpenHoursStart < this.OpenHoursEnd)
                                {
                                    return minutes >= this.OpenHoursStart &&
                                        minutes < this.OpenHoursEnd;
                                }
                                else
                                {
                                    return minutes >= this.OpenHoursStart ||
                                        minutes < this.OpenHoursEnd;
                                }
                            }
                        }
                        return true;
                    }

                default:
                    return true;
            }
        }
    }
}
