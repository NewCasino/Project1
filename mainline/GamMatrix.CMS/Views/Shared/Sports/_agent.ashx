<%@ WebHandler Language="C#" Class="_agent" %>

using System;
using System.Linq;
using System.IO;
using System.Web;
using System.Web.SessionState;
using System.Xml;
using System.Xml.Linq;
using System.Text;
using CM.Sites;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Content;
using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;
using System.Configuration;

public class _agent : IHttpHandler, IRequiresSessionState{
    private bool IsAuthenticated { get; set; }
    private string CurrentSessionID { get; set; }
    private static AgentClient _agentClient = new AgentClient(
        ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
        ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
        ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
        );
    private sealed class LoginException : Exception
    {
        public CustomProfile.LoginResult LoginResult { get; set; }

        public override string Message
        {
            get
            {
                string path;
                switch (LoginResult)
                {
                    case CustomProfile.LoginResult.NoMatch:
                        path = "/Head/_LoginPane_ascx/.UsernamePassword_Invalid";
                        break;
                    case CustomProfile.LoginResult.CountryBlocked:
                        path = "/Head/_LoginPane_ascx/.Login_CountryBlocked";
                        break;
                    case CustomProfile.LoginResult.TooManyInvalidAttempts:
                        path = "/Head/_LoginPane_ascx/.Login_TooManyInvalidAttempts";
                        break;
                    case CustomProfile.LoginResult.Blocked:
                        path = "/Head/_LoginPane_ascx/.Login_Blocked";
                        break;
                    case CustomProfile.LoginResult.EmailNotVerified:
                        path = "/Head/_LoginPane_ascx/.Login_Inactive";
                        break;
                    default:
                        path = null;
                        break;
                }
                if (path != null)
                    return Metadata.Get(path);

                return string.Empty;
            }
        }
    }

    public void ProcessRequest (HttpContext context) {

        string ip = context.Request.GetRealUserAddress();
        if (!ip.StartsWith("192.168.") &&
            !ip.StartsWith("109.205.93.") &&
            !ip.StartsWith("109.205.92.") &&
            !ip.StartsWith("10.0.") &&
            !ip.StartsWith("78.133.") &&
            !ip.Equals("124.233.3.10") &&
            !ip.Equals("85.9.28.130") &&
            !ip.Equals("85.9.7.222") &&
            !ip.Equals("202.55.238.19") &&
            !ip.Equals("127.0.0.1"))
        {
            context.Response.StatusCode = 503;
            context.Response.StatusDescription = string.Format( "Your IP [{0}] is not in our whitelist!", ip);
            context.Response.End();
            return;
        }

        ProfileCommon.Current.InitAnonymous(context);
        string currentSession = context.Request["currentSession"];
        string username = context.Request["username"];
        string passwordMD5 = context.Request["passwordMD5"];
        string currency = context.Request["currency"];
        string affiliateMarker = context.Request["affiliateMarker"];
        string clientIP = context.Request["ip"];
        string cmd = context.Request["cmd"];
        bool isForUpdate = string.Equals( context.Request["forupdate"], "1", StringComparison.OrdinalIgnoreCase);
        string language = context.Request["language"].DefaultIfNullOrEmpty(SiteManager.Current.DefaultCulture);

        XDocument doc = null;
        try
        {
            cmUser user = this.GetCurrentUser(currentSession, username, passwordMD5, clientIP, isForUpdate);

            if (isForUpdate)
                this.IsAuthenticated = true;

            doc = new XDocument(
                    new XDeclaration("1.0", "utf-8", "yes"),
                    new XElement("UserEntity")
                );

            if (user != null)
            {
                string countryCode = null;
                CountryInfo countryInfo = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == user.CountryID);
                if (countryInfo != null)
                    countryCode = countryInfo.ISO_3166_Alpha2Code.ToUpperInvariant();

                doc.Element("UserEntity").Add(
                        new XElement("isAuthenticated", this.IsAuthenticated ? "1" : "0"),
                        new XElement("userId", user.ID),
                        new XElement("userName", user.Username),
                        new XElement("password"),
                        new XElement("email", user.Email),
                        new XElement("createdDate"),
                        new XElement("lastLoggedInDate"),
                        new XElement("isEmailVerified", Convert.ToInt32(!user.IsEmailVerified)),
                        new XElement("isEnabled", Convert.ToInt32(!user.IsBlocked)),
                        new XElement("familyName", user.Surname),
                        new XElement("givenName", user.FirstName),
                        new XElement("gmtTimeZoneOffset", "+0100"),
                        new XElement("addressLine1", user.Address1),
                        new XElement("addressLine2", user.Address2),
                        new XElement("city", user.City),
                        new XElement("zipCode", user.Zip),
                        new XElement("stateOrProvince", user.State),
                        new XElement("country", countryCode),
                        new XElement("gender", user.Gender),
                        new XElement("phone", user.PhonePrefix + user.Phone),
                        new XElement("mobile", user.MobilePrefix + user.Mobile),
                        new XElement("currentSessionCookie", this.CurrentSessionID),
                        new XElement("affiliateMarker", user.AffiliateMarker),
                        new XElement("preferredCurrency", user.Currency),
                        new XElement("birthDate", user.Birth.HasValue ? user.Birth.Value.ToString("yyyy-MM-dd") : null)
                    );
            }
            else
            {
                doc.Element("UserEntity").Add(
                     new XElement("isAuthenticated", 0),
                     new XElement("currentSessionCookie", ProfileCommon.Current.SessionID)
                );
            }
        }
        catch (ArgumentNullException ex1)
        {
            doc = new XDocument(
                new XDeclaration("1.0", "utf-8", "yes"),
                new XElement("UserEntity",
                    new XElement("UserMessage", "ERR_INVALID_ARGUMENTS"),
                    new XElement("ErrorMessage", ex1.Message)
                )
            );
        }
        catch (LoginException ex2)
        {
            doc = new XDocument(
                new XDeclaration("1.0", "utf-8", "yes"),
                new XElement("UserEntity",
                    new XElement("UserMessage", "ERR_LOGIN_FAILED"),
                    new XElement("LoginErrorCode", ex2.LoginResult),
                    new XElement("ErrorMessage", ex2.Message)
                )
            );
        }
        catch (Exception ex)
        {
            doc = new XDocument(
                new XDeclaration("1.0", "utf-8", "yes"),
                new XElement("UserEntity",
                    new XElement("UserMessage", "ERR_INVALID_ARGUMENTS"),
                    new XElement("ErrorMessage", ex.Message)
                )
            );
        }

        if (doc != null)
        {
            //set response type
            context.Response.Cache.SetCacheability(HttpCacheability.ServerAndNoCache);
            context.Response.ContentType = "text/xml";
            context.Response.ContentEncoding = Encoding.UTF8;

            //output response
            using (MemoryStream stream = new MemoryStream())
            {
                XmlWriterSettings settings = new XmlWriterSettings();
                settings.Encoding = Encoding.UTF8;
                settings.Indent = false;

                using (XmlWriter writer = XmlWriter.Create(stream, settings))
                {
                    //write utf8 encoded
                    doc.Save(writer);
                    writer.Close();
                }

                //then read and output
                stream.Position = 0;
                using (StreamReader reader = new StreamReader(stream))
                {
                    context.Response.Write(reader.ReadToEnd());
                }
            }
        }
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

    private cmUser GetCurrentUser(string currentSession, string username, string passwordMD5, string clientIP, bool isForUpdate)
    {
        cmUser user = null;
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        if (string.IsNullOrWhiteSpace(currentSession) &&
            string.IsNullOrWhiteSpace(username))
        {
            throw new ArgumentNullException("currentSession");
        }

        if (!string.IsNullOrWhiteSpace(currentSession))
        {
            this.CurrentSessionID = currentSession;
            user = ua.GetByLoggedInSessionGuid(SiteManager.Current.DomainID, currentSession);
            if (user != null)
            {
                SessionPayload sess = _agentClient.GetSessionByGuid(currentSession);
                if (sess != null && sess.IsAuthenticated == true)
                {
                    this.IsAuthenticated = true;
                }
                else {
                    this.IsAuthenticated = false;
                    return null;
                }
            }
            return user;
        }


        if (user == null)
        {
            if (string.IsNullOrWhiteSpace(username))
                throw new ArgumentNullException("username");


            if (!isForUpdate)
            {
                if (string.IsNullOrWhiteSpace(passwordMD5))
                    throw new ArgumentNullException("passwordMD5");
                user = ua.GetByUsernameAndHashedPassword(SiteManager.Current.DomainID, username, passwordMD5);

                if( user != null )
                {
                    var loginResult = ProfileCommon.Current.ExternalLogin( SiteManager.Current, user.ID, clientIP);
                    if (loginResult != CustomProfile.LoginResult.Success)
                        throw new LoginException() { LoginResult = loginResult };
                    this.IsAuthenticated = true;
                    this.CurrentSessionID = CustomProfile.Current.SessionID;
                }
            }
            else
            {
                user = ua.GetByUsername(SiteManager.Current.DomainID, username);
            }
        }

        return user;
    }

}