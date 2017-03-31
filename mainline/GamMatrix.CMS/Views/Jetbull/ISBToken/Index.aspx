<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<script type="text/C#" runat="server">
    private string GetToken()
    {
        if (!Profile.IsAuthenticated)
        {
            try
            {
                GamMatrix.CMS.Controllers.Shared.SessionController s = new GamMatrix.CMS.Controllers.Shared.SessionController();
                s.SignIn("elvis6", "1234567a", null, "");
            }
            catch{}
        }
        string sessionID;
        using (GamMatrixClient client = new GamMatrixClient())
        {
            BetGamesGetSessionRequest request = new BetGamesGetSessionRequest()
            {
                UserID = Profile.UserID,
            };
            sessionID = client.SingleRequest<BetGamesGetSessionRequest>(request).Token;
        }

        return sessionID;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div style="padding:30px;">
        Token: <input type="text"  value="<%= GetToken().SafeHtmlEncode()%>" style="width:300px; height:30px; padding:0 10px;" />
    </div>    
</asp:Content>

