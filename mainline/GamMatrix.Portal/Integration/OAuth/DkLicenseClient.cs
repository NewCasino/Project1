using System;
using System.Collections.Generic;
using System.Configuration;
using System.Text;
using System.Web;
using CM.State;
using CM.Content;
using System.Net;
using System.IO;
using Newtonsoft.Json;
using CM.Sites;
using BLToolkit.Data;
using CM.db.Accessor;
using GmCore;
using GamMatrixAPI;
using BLToolkit.DataAccess;
using OAuth;

namespace GamMatrix.CMS.Integration.OAuth
{
    public enum CPRStatusType
    {
        CPRIsNotRegistered = 0,
        CPRIsRegistered = 1,
    }
    public enum AgeStatusType
    {
        AgeIs18OrAbove = 0,
        AgeIs17OrBelow = 1,
    }
    public enum RofusRegistrationType
    {
        Failed = 0,
        NotRegistered = 1,
        RegisteredIndefinitely = 2,
        RegisteredTemporarily = 3
    }
    public enum APIEventType {
        ValidateCprAndAge = 0,
        ValidateCpr = 1,
        GenerateUserLogin = 2,
        VerifyUserLogin = 3,
        CheckIsRofusSelfExcluded = 4
    }
    public class InvalidInputs
    {
        public string userFullName { get; set; }
        public string address { get; set; }
    }
    public enum CprValidationStatus
    {
        ValidationFailed = 0,
        ValidationPassed = 1,
        InternalError = 2
    }
    public class CprValidationResult
    {
        public CprValidationStatus CprValidationStatus { get; set; }
        public InvalidInputs InvalidInputs { get; set; }
        public string InternalError { get; set; }
    }
    public class VerifyUserLoginResponse
    {
        public string UserErrorMessage { get; set; }
        public string ErrorDetails { get; set; }
        public bool IsSucceded { get; set; }


        public RofusRegistrationType RofusStatus { get; set; }
        public string PID { get; set; }
        public string CPR { get; set; }
        public string FullName { get; set; }
        public string Email { get; set; }
    }

    public class CheckIsRofusSelfExcludedResponse
    {
        public RofusRegistrationType Status { get; set; }
        public string ErrorDetails { get; set; }
    }
    public class RegisterDkVerifyModel
    {
        public string GeneratedHTML { get; set; }
    }
    public class ValidateCprAndAgeResponse
    {

        public CPRStatusType CprStatus
        {
            get; set;
        }
        public AgeStatusType AgeStatus
        {
            get; set;
        }

        public string ErrorDetails
        {
            get; set;
        }
    }
    public class NemIDErrorHandler
    {
        private static readonly Dictionary<string, string> ErrorCodes =
            new Dictionary<string, string>
                {
                    { "certificate.Valid", "Gyldig"},
                    {"certificate.Invalid", "Ugyldigt"},
                    {"certificate.NotYetValid", "Ikke gyldigt endnu"},
                    {"certificate.Expired", "udløbet <br /><br /> Logger du på som privat NemID bruger?<br /> Din offentlige digitale signatur er udløbet, og du skal derfor bestille en ny.<br /> Bestil ny offentlig digital signatur til dit NemID [https://www.nemid.nu/genbestil] <br /><br /> Logger du på med NemID medarbejdersignatur?<br /> Din medarbejdersignatur er udl\u00f8bet. Kontakt din NemID-administrator. Er du selv administrator, skal du kontakte support.<br /> Kontakt NemID erhvervssupport [https://www.nets-danid.dk/kundeservice/]"},
                    {"certificate.Revoked", "Spærret"},

                    {"certificateTypes.poces", "personligt certifikat"},
                    {"certificateTypes.moces", "medarbejdercertifikat"},
                    {"certificateTypes.voces", "virksomhedscertifikat"},
                    {"certificateTypes.foces", "funktionscertifikat"},
                    {"certificateTypes.unknown", "ukendt"}
                };

        /// <summary>
        /// Translates the supplied error code to a descriptive message to be shown to the end-user.
        /// </summary>
        /// <param name="result">Error code from the applet.</param>
        /// <returns>Descriptive message.</returns>
        public static string GetErrorText(string result)
        {
            return Metadata.Get("/Metadata/GmCoreErrorCodes/DKLicense/"+result+".Text").DefaultIfNullOrWhiteSpace(result); 
        }

        /// <summary>
        /// Translates the supplied error code to a descriptive message to be logged.
        /// </summary>
        /// <param name="result">result Error code from the applet.</param>
        /// <returns>Descriptive message.</returns>
        public static string GetTechnicalDescription(string result)
        {
            return Metadata.Get("/Metadata/GmCoreErrorCodes/DKLicense/" + result + ".Description").DefaultIfNullOrWhiteSpace(result);
        }

        public static bool IsError(string signature)
        {
            if (signature.Length > 100)
                return false;
            return string.IsNullOrEmpty(Metadata.Get("/Metadata/GmCoreErrorCodes/DKLicense/" + signature + ".Description"));
        }
    } 
    public static class DkLicenseClient
    {
        //public static string OperatorSecret = Settings.DKLicenseKey; 
        public static string GmCoreUrl = ConfigurationManager.AppSettings["GmCore.RestHOST"];
        public static string Base64Decode(string s)
        {
            var bytes = Convert.FromBase64String(s);
            return Encoding.UTF8.GetString(bytes);
        }
        public static string GetAPIURL(APIEventType evn, string domainID , string cpr ="",string challenge = "", string postAction = "", string address ="",string formatedBirthdate = "1900-01-01",string userFirstName="",string userLastName = "",long userID= 0)
        {
            string dkApiHost = DkLicenseClient.GmCoreUrl + "/api/dkuser";
            string dkApiUrl = "";
            string OperatorSecret = Settings.DKLicenseKey;
            switch (evn) {
                case APIEventType.VerifyUserLogin:
                    dkApiUrl = string.Format(
                        "{0}/VerifyUserLogin?domainID={1}&secret={2}",
                        dkApiHost,
                        domainID,
                        OperatorSecret
                    );
                    break;
                case APIEventType.GenerateUserLogin:
                    dkApiUrl = string.Format("{0}/GenerateUserLogin?domainID={1}&challenge={2}&postAction={3}&secret={4}",
                        dkApiHost,
                        domainID,
                        challenge,
                        HttpUtility.UrlEncode(postAction),
                        OperatorSecret
                    );
                    break;
                case APIEventType.ValidateCprAndAge:
                    dkApiUrl = string.Format("{0}/ValidateCprAndAge?domainID={1}&cpr={3}&secret={2}",
                        dkApiHost,
                        domainID,
                        OperatorSecret,
                        HttpUtility.HtmlEncode(cpr)
                    );
                    break;
                case APIEventType.ValidateCpr:
                    dkApiUrl = string.Format("{0}/ValidateCpr?domainID={1}&secret={2}&cpr={3}&address={4}&birthDate={5}&userFullName={6}&userID={7}",
                        dkApiHost,
                        domainID,
                        OperatorSecret,
                        HttpUtility.HtmlEncode(cpr),
                        HttpUtility.HtmlEncode(address),
                        HttpUtility.HtmlEncode(formatedBirthdate),
                        HttpUtility.HtmlEncode(userFirstName + " " + userLastName),
                        userID.ToString()
                    );
                    break;
                case APIEventType.CheckIsRofusSelfExcluded:
                    dkApiUrl = string.Format("{0}/CheckIsRofusSelfExcluded?domainID={1}&cpr={3}&secret={2}",
                        dkApiHost,
                        domainID,
                        OperatorSecret,
                        HttpUtility.HtmlEncode(cpr)
                    );
                    break;
                default:
                    break;
            }  
            return dkApiUrl;
        }
        public static string GETFileData(string theURL)
        {

            Uri uri = new Uri(theURL);
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(uri);
            request.Method = "GET";
            request.ContentType = "application/x-www-form-urlencoded";
            request.AllowAutoRedirect = false;
            request.Timeout = 5000;
            request.ServicePoint.ConnectionLimit = int.MaxValue;
            request.KeepAlive = false;
            string retext = "";
            try
            {
                using (var response = (HttpWebResponse)request.GetResponse())
                {
                    using (var readStream = new StreamReader(response.GetResponseStream(), Encoding.UTF8))
                    {
                        retext = readStream.ReadToEnd();
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                Logger.Information("DK", "GETFileData from {0}: {1}", theURL, retext);
            }
            return retext;
        }

        public static string GetNewParams(Dictionary<string, string> values) {
            string param = "";
            foreach (var item in values) {
                param   += item.Key.ToLower() + "=" +HttpUtility.UrlEncode( item.Value) + "&";
            }
            return param.TrimEnd('&') ;
        } 

        public static VerifyUserLoginResponse POSTFileData(string theURL, Dictionary<string, string> values)
        {
            string retext = "";
            string param = GetNewParams(values);
            Uri uri = new Uri(theURL);
            byte[] btBodys = Encoding.UTF8.GetBytes(param);
            HttpWebRequest webReq = (HttpWebRequest)WebRequest.Create(uri);
            webReq.Method = "POST"; 
            webReq.ContentType = "application/x-www-form-urlencoded";
            webReq.Timeout = 50000;
            webReq.ServicePoint.ConnectionLimit = int.MaxValue;
            webReq.ContentLength = btBodys.Length;
            webReq.KeepAlive = false;
            try
            {
                using (Stream responseStream = webReq.GetRequestStream())
                {
                    responseStream.Write(btBodys, 0, btBodys.Length);
                    responseStream.Close();
                    using (var response = (HttpWebResponse)webReq.GetResponse())
                    {
                        using (var readStream = new StreamReader(response.GetResponseStream(), Encoding.UTF8))
                        {
                            retext = readStream.ReadToEnd();
                        }
                    }
                }
                return JsonConvert.DeserializeObject<VerifyUserLoginResponse>(retext); ;
            }
            catch (Exception ex)
            {
                Logger.Information("DK", "Unexpected response from {0} {1} : {2}", theURL, param , retext);
                Logger.Exception(ex);
            }
            return null;

        }
        public static void UpdateTempAccountStatus(long userID, string cpr, string address, DateTime birthDate, string userFirstName, string userLastName) {
            if (ValidateUserCpr(userID, cpr, address, birthDate, userFirstName, userLastName))
            {
                long roleID = 0;
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserRolesRequest rq = client.SingleRequest<GetUserRolesRequest>( new GetUserRolesRequest()
                    {
                        UserID = userID
                    });
                    List<string> roleNames = rq.RolesByName;
                    List<long> roleIDs = rq.RolesByID;
                    var record = rq.RolesByID;
                    for (int i = 0; i < roleNames.Count; i++)
                    {
                        if (roleNames[i].Equals( Settings.DKLicense.DKTempAccountRole , StringComparison.InvariantCultureIgnoreCase))
                        {
                            roleID = roleIDs[i];
                            break;
                        }
                    }
                    if(roleID != 0)
                    { 
                        RemoveUserRoleRequest rurr = client.SingleRequest<RemoveUserRoleRequest>(new RemoveUserRoleRequest()
                        {
                            UserID = userID,
                            RoleID = roleID
                        });
                    }
                } 
            }
        }


        public static  bool ValidateUserCpr(long userID , string cpr, string address, DateTime birthDate, string userFirstName, string userLastName)
        {
            try
            {
                string domainID = SiteManager.Current.DomainID.ToString();
                string dkKey = Settings.DKLicenseKey;
                string formatedBirthdate =
                    string.Format("{0}-{1}-{2}",
                    birthDate.Year.ToString("00"),
                    birthDate.Month.ToString("00"),
                    birthDate.Day.ToString("00")
                    );
                string dkApiUrl = GetAPIURL(APIEventType.ValidateCpr, domainID, cpr, "", "", address, formatedBirthdate, userFirstName, userLastName, userID); 
                string html = DkLicenseClient.GETFileData(dkApiUrl);
                CprValidationResult result = JsonConvert.DeserializeObject<CprValidationResult>(html);
                return result != null && result.CprValidationStatus == CprValidationStatus.ValidationPassed;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return false;
            }
        }
        public  static ValidateCprAndAgeResponse ValidateAgeAndCpr(string cpr)
        {
            string dkApiUrl = "";
            string html = "";
            try
            {
                string domainID = SiteManager.Current.DomainID.ToString();
                string dkKey = Settings.DKLicenseKey;
                dkApiUrl = GetAPIURL(APIEventType.ValidateCprAndAge, domainID, cpr);
                html = DkLicenseClient.GETFileData(dkApiUrl);
                ValidateCprAndAgeResponse result = JsonConvert.DeserializeObject<ValidateCprAndAgeResponse>(html);
                return result;
            }
            catch (Exception ex)
            {
                Logger.Information("DK", "DKValidateAgeAndCpr From URL: {0} , return: {1}", dkApiUrl, html);
                Logger.Exception(ex);
                return null;
            }
        }

        public static CheckIsRofusSelfExcludedResponse CheckIsRofusSelfExcluded(string cpr)
        {
            string dkApiUrl = "";
            string html = "";
            try
            {
                string domainID = SiteManager.Current.DomainID.ToString();
                string dkKey = Settings.DKLicenseKey;
                dkApiUrl = GetAPIURL(APIEventType.CheckIsRofusSelfExcluded, domainID, cpr);
                html = DkLicenseClient.GETFileData(dkApiUrl);
                CheckIsRofusSelfExcludedResponse result = JsonConvert.DeserializeObject<CheckIsRofusSelfExcludedResponse>(html);
                return result;
            }
            catch (Exception ex)
            {
                Logger.Information("CheckIsRofusSelfExcluded", "CheckIsRofusSelfExcludedResponse From URL: {0},\nreturn:{1}\nException:{2}", dkApiUrl, html, ex.Message);
                return null;
            }
        }


        public static void LinkToExternalDB(long userId, string pid)
        {
            try
            {
                using (DbManager dbManager = new DbManager())
                {
                    ExternalLoginAccessor eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                    eua.Create(CustomProfile.Current.DomainID, userId, (int)ExternalAuthParty.NemID, pid);
                }
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    AddNoteRequest request = new AddNoteRequest()
                    {
                        Note = "This user is registered from NemID",
                        Type = NoteType.User,
                        Importance = ImportanceType.Normal,
                        TypeID = CustomProfile.Current.UserID
                    };
                    client.SingleRequest<AddNoteRequest>(request);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }
}
