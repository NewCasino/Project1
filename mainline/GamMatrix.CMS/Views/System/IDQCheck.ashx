<%@ WebHandler Language="C#" Class="_IDQCheck" %>

using System;
using System.IO;
using System.Text;
using System.Data;
using System.Linq;
using System.Collections;
using System.Web;
using System.Data.OleDb;
using System.Collections.Generic;
using GamMatrix.CMS.Integration.OAuth;
using GmCore;
using GamMatrixAPI;
using CM.db;
using CM.db.Accessor;
using BLToolkit.Data;
using System.Threading.Tasks;

public static class UserAccessorExtension
{
    public static List<cmUser> GetUsersByUserIds(this UserAccessor userAccessor, List<int> userIds)
    {
        if (userIds == null || userIds.Count == 0)
            return new List<cmUser>();

        using (DbManager db = new DbManager())
        {
            List<IDbDataParameter> param = new List<IDbDataParameter>();

            StringBuilder sql = new StringBuilder();
            sql.Append("SELECT * FROM cmUser WHERE ID in (");
            int index = 0;
            foreach (int userId in userIds)
            {
                string p = string.Format("@UserId{0}", index);
                index++;
                param.Add(new System.Data.SqlClient.SqlParameter(p, userId));
                sql.AppendFormat("{0},", p);
            }
            sql.Remove(sql.Length - 1, 1);
            sql.Append(")");
            db.SetCommand(sql.ToString(), param.ToArray());
            return db.ExecuteList<cmUser>();
        }
    }
}

public class _IDQCheck : IHttpHandler
{
	private HttpContext context;

    private List<string> successList = new List<string>();
    private List<string> errorList = new List<string>();
    private List<cmUser> users = new List<cmUser>();
    
    
    
    public void ProcessRequest(HttpContext context)
	{
        this.context = context;
        ProfileCommon.Current.Init(context);
        
        bool result = false;
        string message = string.Empty;
        try
        {
            if (context.Request.Files.Count > 0)
            {
                var file = context.Request.Files[0];
                string directory = context.Server.MapPath(string.Format("~/IDQCheckLog/{0}", DateTime.Now.ToString("yyyyMMdd")));
                if (!Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                string filename = string.Format("{0}/{1}_{2}", directory, Guid.NewGuid().ToString("N").Truncate(6), file.FileName);
                file.SaveAs(filename);

                List<int> userIds = new List<int>();
                using (StreamReader reader = new StreamReader(file.InputStream))
                {
                    string content = reader.ReadLine();
                    int position = -1;
                    int fields_length = 0;
                    if (!string.IsNullOrEmpty(content))
                    {
                        string[] fields = content.Split(new char[] { ',' });
                        fields_length = fields.Length;
                        for (int i = 0; i < fields.Length; i++)
                        {
                            if (string.Equals("UserID", fields[i], StringComparison.InvariantCultureIgnoreCase))
                            {
                                position = i;
                                break;
                            }
                        }
                    }

                    content = reader.ReadLine();
                    while(!string.IsNullOrEmpty((content = reader.ReadLine())) && !content.ToLowerInvariant().Contains("total"))
                    {
                        try
                        {
                            var user = content.Split(new char[] { ',' });
                            if (user.Length >= fields_length)
                            {
                                userIds.Add(int.Parse(user[position]));
                            }
                        }
                        catch
                        {
                            errorList.Add(string.Format("can't read userid from this line: {0}.", content));
                        }
                    }
                }

                if (userIds.Count > 0)
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    users = ua.GetUsersByUserIds(userIds);
                    List<int> errorUserIds = userIds.Except(users.Select(f=>f.ID)).ToList<int>();

                    foreach (var userid in errorUserIds)
                    {
                        errorList.Add(string.Format("can't find the userid {0} from our database.", userid));
                    }
                }
                
                if (users.Count > 0)
                {
                    List<Task> tasks = new List<Task>();
                    foreach(var user in users)
                    {
                        tasks.Add(Task.Factory.StartNew(() =>
                        {
                            UpdateTempAccountStatus(user);
                        }));
                    }
                    
                    Task.WaitAll(tasks.ToArray());
                }

                StringBuilder sb = new StringBuilder();
                sb.AppendLine(string.Format(@"the user ""{0}"" updated IDQ check status at {1}.", ProfileCommon.Current.UserName, DateTime.Now.ToString("yyy-MM-dd hh:mm:ss")));
                sb.AppendLine(string.Format("Success count: {0}", successList.Count));
                sb.AppendLine("Failure of user list below:");
                foreach (var error in errorList)
                {
                    sb.AppendLine(error);
                }
                sb.AppendLine("").AppendLine("");

                using (StreamWriter writer = new StreamWriter(new FileStream(string.Format("{0}/log.txt", directory), FileMode.Append)))
                {
                    writer.Write(sb.ToString());
                };
                
                result = true;
                message = string.Format(@"all data you uploaded has been dealt with, more detail please see <a href='/IDQCheckLog/{0}/log.txt' target='_blank'>the log file</a>.", DateTime.Now.ToString("yyyyMMdd"));
            }
            else
            {
                message = "please upload a file.";
            }
        }
        catch (Exception e)
        {
            message = e.Message;
        }

        context.Response.ContentType = "application/json;charset=utf-8";
        context.Response.Clear();
        context.Response.Write(string.Format(@"{{""success"": {0}, ""message"" : ""{1}""}}", result.ToString().ToLowerInvariant(), message));
        context.Response.Flush();
        context.Response.End();
	}

    public static bool ValidateUserCpr(cmUser user)
    {
        try
        {
            string domainID = user.DomainID.ToString();
            string dkKey = Settings.DKLicenseKey;
            string formatedBirthdate =
                string.Format("{0}-{1}-{2}",
                user.Birth.Value.Year.ToString("00"),
                user.Birth.Value.Month.ToString("00"),
                user.Birth.Value.Day.ToString("00")
                );

            SiteAccessor siteAccessor = BLToolkit.DataAccess.DataAccessor.CreateInstance<SiteAccessor>();
            cmSite site = siteAccessor.GetByDomainID(user.DomainID).FirstOrDefault();

            string dkApiUrl = string.Format("{0}/ValidateCpr?domainID={1}&secret={2}&cpr={3}&address={4}&birthDate={5}&userFullName={6}&userID={7}",
                        DkLicenseClient.GmCoreUrl + "/api/dkuser",
                        user.DomainID,
                        CM.Content.Metadata.Get(site, "Metadata/Settings/DKLicense.DKLicenseKey", "en", true, true),
                        HttpUtility.HtmlEncode(user.PersonalID),
                        HttpUtility.HtmlEncode(user.Address1),
                        HttpUtility.HtmlEncode(formatedBirthdate),
                        HttpUtility.HtmlEncode(user.FirstName + " " + user.Surname),
                        user.ID.ToString()
                    );
            string html = DkLicenseClient.GETFileData(dkApiUrl);
            CprValidationResult result = Newtonsoft.Json.JsonConvert.DeserializeObject<CprValidationResult>(html);
            return result != null && result.CprValidationStatus == CprValidationStatus.ValidationPassed;
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
            return false;
        }
    }
    
    public void UpdateTempAccountStatus(cmUser user)
    {
        if (ValidateUserCpr(user))
        {
            long roleID = 0;
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRolesRequest rq = client.SingleRequest<GetUserRolesRequest>(new GetUserRolesRequest()
                {
                    UserID = user.ID
                });
                List<string> roleNames = rq.RolesByName;
                List<long> roleIDs = rq.RolesByID;
                var record = rq.RolesByID;
                for (int i = 0; i < roleNames.Count; i++)
                {
                    if (roleNames[i].Equals(Settings.DKLicense.DKTempAccountRole, StringComparison.InvariantCultureIgnoreCase))
                    {
                        roleID = roleIDs[i];
                        break;
                    }
                }
                RemoveUserRoleRequest rurr = client.SingleRequest<RemoveUserRoleRequest>(new RemoveUserRoleRequest()
                {
                    UserID = user.ID,
                    RoleID = roleID
                });

                successList.Add(string.Format("{0}, ", user.ID));
            }
        }
        else
        {
            errorList.Add(string.Format("validate cpr failure for the userid {0}", user.ID));
        }
    }

	public bool IsReusable 
	{
        get { return false; }
    }
}