using System;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CmsAgent.FileManager
{
    public class StaticFileHostConfigElement : ConfigurationElement
    {
        public StaticFileHostConfigElement()
        {
            this.Port = 0;
        }

        [ConfigurationProperty("name", IsRequired = true, IsKey = true)]
        public string Name
        {
            get
            {
                return (string)this["name"];
            }
            set
            {
                this["name"] = value;
            }
        }

        [ConfigurationProperty("protocol", IsRequired = true, DefaultValue = "ftp")]
        [RegexStringValidator(@"^((ftp)|(sftp))$")]
        public string Protocol
        {
            get
            {
                return (string)this["protocol"];
            }
            set
            {
                this["protocol"] = value;
            }
        }

        [ConfigurationProperty("server", IsRequired = true)]
        public string Server
        {
            get
            {
                return (string)this["server"];
            }
            set
            {
                this["server"] = value;
            }
        }

        [ConfigurationProperty("port", DefaultValue = 0, IsRequired = false)]
        [IntegerValidator(MinValue = 0, MaxValue = 65535, ExcludeRange = false)]
        public int Port
        {
            get
            {
                return (int)this["port"];
            }
            set
            {
                this["port"] = value;
            }
        }

        [ConfigurationProperty("username", IsRequired = true)]
        public string Username
        {
            get
            {
                return (string)this["username"];
            }
            set
            {
                this["username"] = value;
            }
        }

        [ConfigurationProperty("password", IsRequired = true)]
        public string Password
        {
            get
            {
                return (string)this["password"];
            }
            set
            {
                this["password"] = value;
            }
        }

        [ConfigurationProperty("isPrimary", IsRequired = false, DefaultValue = false)]
        public bool IsPrimary
        {
            get
            {
                return (bool)this["isPrimary"];
            }
            set
            {
                this["isPrimary"] = value;
            }
        }


        [ConfigurationProperty("folder", IsRequired = false, DefaultValue = "/")]
        [RegexStringValidator(@"(\/)$")]
        public string Folder
        {
            get
            {
                return (string)this["folder"];
            }
            set
            {
                this["folder"] = value;
            }
        }

        [ConfigurationProperty("distinctName", IsRequired = false, DefaultValue = "")]
        public string DistinctName
        {
            get
            {
                return (string)this["distinctName"];
            }
            set
            {
                this["distinctName"] = value;
            }
        }

        [ConfigurationProperty("domainID", IsRequired = false, DefaultValue = 0)]
        public int DomainID
        {
            get
            {
                return (int)this["domainID"];
            }
            set
            {
                this["domainID"] = value;
            }
        }

        [ConfigurationProperty("privateKeyFileName", IsRequired = false, DefaultValue = "")]
        public string PrivateKeyFileName
        {
            get
            {
                return (string)this["privateKeyFileName"];
            }
            set
            {
                this["privateKeyFileName"] = value;
            }
        }

        [ConfigurationProperty("privateKeyPassword", IsRequired = false, DefaultValue = "")]
        public string PrivateKeyPassword
        {
            get
            {
                return (string)this["privateKeyPassword"];
            }
            set
            {
                this["privateKeyPassword"] = value;
            }
        }

    }
}
