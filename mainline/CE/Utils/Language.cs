using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Globalization;
using System.Runtime.Serialization;

namespace CE.Utils
{
    [DataContract]
    public class Language
    {
        [DataMember(Name = "code")]
        public string Code { get; set; }

        [DataMember(Name = "name")]
        public string Name { get; set; }

        [DataMember(Name = "nativeName")]
        public string NativeName { get; set; }

        public static readonly ReadOnlyDictionary<string, Language> All = new ReadOnlyDictionary<string, Language>(
            new Dictionary<string, Language>(1000, StringComparer.InvariantCultureIgnoreCase)
            {
                { "bg", new Language() {  Name = "Bulgarian", Code = "bg", NativeName = "български" } },
                { "cs", new Language() {  Name = "Czech", Code = "cs", NativeName = "čeština" } },
                { "da", new Language() {  Name = "Danish", Code = "da", NativeName = "dansk" } },
                { "de", new Language() {  Name = "German", Code = "de", NativeName = "Deutsch" } },
                { "el", new Language() {  Name = "Greek", Code = "el", NativeName = "Ελληνικά" } },
                { "en", new Language() {  Name = "English", Code = "en", NativeName = "English" } },
                { "es", new Language() {  Name = "Spanish", Code = "es", NativeName = "español" } },
                { "et", new Language() {  Name = "Estonian", Code = "et", NativeName = "eesti" } },
                { "fi", new Language() {  Name = "Finnish", Code = "fi", NativeName = "suomi" } },
                { "fr", new Language() {  Name = "French", Code = "fr", NativeName = "français" } },
                { "he", new Language() {  Name = "Hebrew", Code = "he", NativeName = "עברית" } },
                { "hu", new Language() {  Name = "Hungarian", Code = "hu", NativeName = "magyar" } },
                { "it", new Language() {  Name = "Italian", Code = "it", NativeName = "italiano" } },
                { "ja", new Language() {  Name = "Japanese", Code = "ja", NativeName = "日本語" } },//old value: jp
                { "ko", new Language() {  Name = "Korean", Code = "ko", NativeName = "한국어" } },
                { "nl", new Language() {  Name = "Dutch", Code = "nl", NativeName = "Nederlands" } },
                { "no", new Language() {  Name = "Norwegian", Code = "no", NativeName = "norsk" } },
                { "pl", new Language() {  Name = "Polish", Code = "pl", NativeName = "polski" } },
                { "pt", new Language() {  Name = "Portuguese", Code = "pt", NativeName = "Português" } },
                { "ro", new Language() {  Name = "Romanian", Code = "ro", NativeName = "română" } },
                { "ru", new Language() {  Name = "Russian", Code = "ru", NativeName = "русский" } },
                { "sr", new Language() {  Name = "Serbian", Code = "sr", NativeName = "srpski" } },
                { "sq", new Language() {  Name = "Albanian", Code = "sq", NativeName = "shqipe" } },
                { "sv", new Language() {  Name = "Swedish", Code = "sv", NativeName = "svenska" } },
                { "tr", new Language() {  Name = "Turkish", Code = "tr", NativeName = "Türkçe" } },
                { "uk", new Language() {  Name = "Ukrainian", Code = "uk", NativeName = "українська" } },
                { "zhcn", new Language() {  Name = "Chinese (Simplified)", Code = "zh-cn", NativeName = "中文(中华人民共和国)" } },//old value: zhcn
                { "zhtw", new Language() {  Name = "Chinese (Traditional)", Code = "zh-tw", NativeName = "中文(台灣)" } },//old value: zhtw
           }
        );
        public static string getAllLanguagesToString()
        {
            return string.Join(",", All.Keys.ToArray());
        }
    }
}
