using BLToolkit.DataAccess;

namespace CM.db
{
    /// <summary>
    /// Stores a hostname that is related to a domain.
    /// </summary>
    public class cmDomain
    {
        [Identity, PrimaryKey, NonUpdatable]
        public string ID { get; set; }

        public string Title { get; set; }

        public string Dsc { get; set; }

        public int UserID { get; set; }

        public PasswordEncryptionMode PasswordEncryptionMode { get; set; }

        public string SessionCookieName { get; set; }

        public string SessionCookieDomain { get; set; }

        public string Hosts { get; set; } 

        public string EmailHost { get; set; }

        public string DistinctName { get; set; }

        public string DefaultLanguage { get; set; }

        public string ApiUsername { get; set; }

        public string SecurityToken { get; set; }


    }
}
