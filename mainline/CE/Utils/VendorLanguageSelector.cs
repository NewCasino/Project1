using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using GamMatrixAPI;

namespace CE.Utils
{
   public class VendorLanguageSelector
    {
       public static string GetLanguage(VendorID vendor, string lang)
       {
           string language = string.Empty;
           switch (vendor)
           {
               case VendorID.Opus:
                   language = GetOpusLanguage(lang);
                   break;
               default:
                   language = lang;
                   break;
           }

           return language;
       }


       private static string GetOpusLanguage(string lang)
       {
           var dic = new Dictionary<string, string>();
           dic.Add("en", "en-US");
           dic.Add("zh", "zh-CN");
           dic.Add("th", "th-TH");
           dic.Add("vi", "vi-VN");
           dic.Add("ja", "ja-JP");
           dic.Add("id", "id-ID");
           dic.Add("it", "km-KH");
           if (string.IsNullOrWhiteSpace(lang))
               lang = "en";
           else
               lang = lang.Truncate(2).ToLowerInvariant();

           if (dic.Keys.Contains(lang))
               return dic[lang];

           return "en-US";
       }
    }
}
