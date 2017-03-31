using System;
using System.IO;
using System.Runtime.Serialization;
using System.Xml;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;

namespace CE.db
{
    /// <summary>
    ///  ceLiveCasinoTable table
    /// </summary>
    public class ceLiveCasinoTable
    {
        [Identity, PrimaryKey]
        public long ID { get; set; }

        public DateTime Ins { get; set; }

        public long DomainID { get; set; }

        public string SessionID { get; set; }

        public long SessionUserID { get; set; }

        public long HID { get; set; }

        public long LiveCasinoTableBaseID { get; set; }

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

        public bool? Enabled { get; set; }

        public string ClientCompatibility { get; set; }

        public string LimitationXml { get; set; }

        [DefaultValue("0")]
        public bool VIPTable { get; set; }

        [DefaultValue("0")]
        public bool NewTable { get; set; }

        [DefaultValue("GETDATE()")]
        public DateTime NewTableExpirationDate { get; set; }

        [DefaultValue("0")]
        public bool ExcludeFromRandomLaunch { get; set; }

        [DefaultValue("0")]
        public bool TurkishTable { get; set; }

        [DefaultValue("0")]
        public bool BetBehindAvailable { get; set; }

        [DefaultValue("0")]
        public bool SeatsUnlimited { get; set; }

        [DefaultValue("0")]
        public DealerGender DealerGender { get; set; }

        [DefaultValue("0")]
        public DealerOrigin DealerOrigin { get; set; }

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

        public bool? OpVisible { get; set; }

        public string TableStudioUrl { get; set; }
    }

 
}
