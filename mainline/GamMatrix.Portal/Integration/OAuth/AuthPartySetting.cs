using System.Text.RegularExpressions;
using CM.Content;

namespace OAuth
{
    //public static class AuthPartyID
    //{
    //    private const string _Yandex_APP_ID = "4b9fcf167c224d54ba99fad71387858d";
    //    private const string _Yandex_APP_SECRET = "c5df801da7df48eaa534528b89b8430b";
    //    public static string Yandex_APP_ID
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Yandex_APP_ID")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Yandex_APP_ID");
    //            }
    //            return _Yandex_APP_ID;
    //        }
    //    }
    //    public static string Yandex_APP_SECRET
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Yandex_APP_SECRET")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Yandex_APP_SECRET");
    //            }
    //            return _Yandex_APP_SECRET;
    //        }
    //    }

    //    private const string _VKontakte_APP_ID = "4265370";
    //    private const string _VKontakte_APP_SECRET = "94g4aPX1h8QuKWtiLQmk";
    //    public static string VKontakte_APP_ID
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.VKontakte_APP_ID")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.VKontakte_APP_ID");
    //            }
    //            return _VKontakte_APP_ID;
    //        }
    //    }
    //    public static string VKontakte_APP_SECRET
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.VKontakte_APP_SECRET")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.VKontakte_APP_SECRET");
    //            }
    //            return _VKontakte_APP_SECRET;
    //        }
    //    }

    //    private const string _Twitter_APP_ID = "IKgjiQ2RmBGlRUCVztszQ";
    //    private const string _Twitter_APP_SECRET = "ADkpXYtpATMgMdYgyykDRceZkqGXZJUi9CJNEOUyGU";
    //    public static string Twitter_APP_ID
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Twitter_APP_ID")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Twitter_APP_ID");
    //            }
    //            return _Twitter_APP_ID;
    //        }
    //    }
    //    public static string Twitter_APP_SECRET
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Twitter_APP_SECRET")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Twitter_APP_SECRET");
    //            }
    //            return _Twitter_APP_SECRET;
    //        }
    //    }

    //    private const string _MailRu_APP_ID = "718662";
    //    private const string _MailRu_APP_SECRET = "d5826a9b5d0fcb30b87a26703f1ba331";
    //    public static string MailRu_APP_ID
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.MailRu_APP_ID")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.MailRu_APP_ID");
    //            }
    //            return _MailRu_APP_ID;
    //        }
    //    }
    //    public static string MailRu_APP_SECRET
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.MailRu_APP_SECRET")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.MailRu_APP_SECRET");
    //            }
    //            return _MailRu_APP_SECRET;
    //        }
    //    }

    //    private const string _Google_APP_ID = "1096884915117-3ujonkcpkpjocc5v4k8j6d6r9g9ru35k.apps.googleusercontent.com";
    //    private const string _Google_APP_SECRET = "ZqSkRtS45LvycQ-WbyCOZaUg";
    //    public static string Google_APP_ID
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Google_APP_ID")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Google_APP_ID");
    //            }
    //            return _Google_APP_ID;
    //        }
    //    }
    //    public static string Google_APP_SECRET
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Google_APP_SECRET")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Google_APP_SECRET");
    //            }
    //            return _Google_APP_SECRET;
    //        }
    //    }

    //    private const string _Facebook_APP_ID = "212032622339759";
    //    private const string _Facebook_APP_SECRET = "1aaac7d8dc706155c07f0418e14c820c";
    //    public static string Facebook_APP_ID
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Facebook_APP_ID")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Facebook_APP_ID");
    //            }
    //            return _Facebook_APP_ID;
    //        }
    //    }
    //    public static string Facebook_APP_SECRET
    //    {
    //        get
    //        {
    //            if (!string.IsNullOrWhiteSpace(Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Facebook_APP_SECRET")))
    //            {
    //                return Metadata.Get("/Metadata/Settings/ThirdPartyConnect/.Facebook_APP_SECRET");
    //            }
    //            return _Facebook_APP_SECRET;
    //        }
    //    }
    //}

    public static class AuthParty_Setting
    {
        private static bool SafeParseBoolString(string path, bool defValue)
        {
            if (string.IsNullOrWhiteSpace(path))
                return defValue;
            string text = Metadata.Get(path).Trim();
            if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return true;

            if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return false;

            return defValue;
        }
        public static bool Enable_VKontakte {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_VKontakte", true);
            }
        }
        public static bool Enable_Yandex {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_Yandex", true);
            }
        }
        public static bool Enable_Twitter {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_Twitter", true);
            }
        }
        public static bool Enable_MailRu {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_MailRu", true);
            }
        }
        public static bool Enable_Google {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_Google", true);
            }
        }
        public static bool Enable_Facebook {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_Facebook", true);
            }
        }
        public static bool Enable_Login
        {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_Login", true);
            }
        }
        public static bool Enable_Register
        {
            get
            {
                return SafeParseBoolString("/Metadata/Settings/ThirdPartyConnect/.Enable_Register", true);
            }
        }
    }
}
