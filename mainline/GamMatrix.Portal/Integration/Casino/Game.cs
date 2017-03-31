using System;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text.RegularExpressions;
using CM.Content;
using CM.db;
using GamMatrixAPI;

namespace Casino
{
    /// <summary>
    /// Summary description for Game
    /// </summary>
    [Serializable]
    public sealed class Game
    {
        public static string NormaliseID(string id)
        {
            return Regex.Replace(id, @"[^(\w|\-|_)]", "_", RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant);
        }

        private cmSite Site { get; set; }
        private string MetadataPath { get; set; }

        public VendorID VendorID { get; private set; }
        public string ID { get; private set; }
        public bool IsNewGame { get; private set; }
        public bool IsMiniGame { get; private set; }
        public bool IsFunModeEnabled { get; private set; }
        public int InitialWidth { get; private set; }
        public int InitialHeight { get; private set; }
        public Finance.CountryList SupportedCountry { get; private set; }

        public string Title
        {
            get
            {
                string path = string.Format("{0}.Title", MetadataPath);
                return Metadata.Get(this.Site, path, MultilingualMgr.GetCurrentCulture());
            }
        }

        public string Description
        {
            get
            {
                string path = string.Format("{0}.Description", MetadataPath);
                return Metadata.Get(this.Site, path, null);
            }
        }

        public string Thumbnail
        {
            get
            {
                string path = string.Format("{0}.Thumbnail", MetadataPath);
                return Metadata.Get(this.Site, path, null);
            }
        }

        public string HelpFile
        {
            get
            {
                string path = string.Format("{0}.HelpFile", MetadataPath);
                return Metadata.Get(path);
            }
        }



        internal Game(string metadataPath, cmSite site)
        {
            this.Site = site;
            this.MetadataPath = metadataPath;

            string path = string.Format("{0}.ID", metadataPath);
            this.ID = Metadata.Get(site, path, "en");

            path = string.Format("{0}.IsNewGame", metadataPath);
            this.IsNewGame = string.Equals(Metadata.Get(site, path, "en"), "YES", StringComparison.OrdinalIgnoreCase);

            int temp;
            path = string.Format("{0}.InitialWidth", metadataPath);
            if( int.TryParse( Metadata.Get(site, path, "en"), out temp ) )
                this.InitialWidth = temp;
            path = string.Format("{0}.InitialHeight", metadataPath);
            if( int.TryParse( Metadata.Get(site, path, "en"), out temp ) )
                this.InitialHeight = temp;

            path = string.Format("{0}.IsMiniGame", metadataPath);
            this.IsMiniGame = string.Equals(Metadata.Get(site, path, "en"), "YES", StringComparison.OrdinalIgnoreCase);

            path = string.Format("{0}.IsFunModeEnabled", metadataPath);
            this.IsFunModeEnabled = string.Equals(Metadata.Get(site, path, "en").DefaultIfNullOrEmpty("YES"), "YES", StringComparison.OrdinalIgnoreCase);

            path = string.Format("{0}.Vendor", metadataPath);
            VendorID vendor;
            if (Enum.TryParse<VendorID>(Metadata.Get(site, path, "en"), out vendor))
            {
                this.VendorID = vendor;
            }

            path = string.Format("{0}.SupportedCountry", metadataPath);
            string base64 = Metadata.Get(site, path, "en");
            try
            {
                using (MemoryStream ms = new MemoryStream(Convert.FromBase64String(base64)))
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    this.SupportedCountry = (Finance.CountryList)bf.Deserialize(ms);
                }
            }
            catch
            {
                this.SupportedCountry = new Finance.CountryList();
                this.SupportedCountry.Type = Finance.CountryList.FilterType.Exclude;
            }
        }
    }
}