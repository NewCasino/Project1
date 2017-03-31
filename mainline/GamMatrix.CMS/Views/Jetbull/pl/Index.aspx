<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CM.State" %>

<script language="C#" type="text/C#" runat="server">
    private Dictionary<string, Game> games;
    private cmUser user;

    private bool? _IsCaptchaEnabledForLogin;
    private bool IsCaptchaEnabledForLogin
    {
        get
        {
            if (!_IsCaptchaEnabledForLogin.HasValue)
            {
                _IsCaptchaEnabledForLogin = CM.Content.Metadata.Get("Metadata/Settings/Login.IsCaptchaEnabled").ParseToBool(false);
                _IsCaptchaEnabledForLogin = false;
            }
            return _IsCaptchaEnabledForLogin.Value;
        }
    }

    private string _bonus = string.Empty;
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        games = CasinoEngineClient.GetGames(SiteManager.Current, false);
        using (DbManager dbManager = new DbManager())
        {
            UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
            user = ua.GetByID(115916);



        }
        var client = new GamMatrixClient();
        var request = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(new GetUserAvailableBonusDetailsRequest
        {
            UserID = CustomProfile.Current.UserID
        });
        JavaScriptSerializer jss = new JavaScriptSerializer();
        _bonus = jss.Serialize(request);
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<%= IsCaptchaEnabledForLogin %>
<br/>
<%= user.FailedLoginAttempts%>

<%
    TransSelectParams transSelectParams = new TransSelectParams()
    {
        ByTransTypes = true,
        ParamTransTypes = new List<TransType> { TransType.Deposit, TransType.Vendor2User },
        ByUserID = true,
        ParamUserID = Profile.UserID,
        ByTransStatuses = true,
        ParamTransStatuses = new List<TransStatus>
                    {
                        TransStatus.Success,
                    },
        ByDebitPayableTypes = true,
    };

    transSelectParams.ParamDebitPayableTypes = Enum.GetNames(typeof(PayableType))
                        .Select(t => (PayableType)Enum.Parse(typeof(PayableType), t))
                        .Where(t => t != PayableType.AffiliateFee && t != PayableType.CasinoFPP)
                        .ToList();
    List<TransInfoRec> transInfoRecs = GamMatrixClient.GetTransactions(new TransType[] { TransType.Deposit, TransType.Vendor2User }, new TransStatus[] { TransStatus.Success }, null, 1, 1);

%>
<br />
Count: <%= transInfoRecs.Count%>
<br/>

    UserAvailableBonusDetails: 
    <%=_bonus %>
</asp:content>

