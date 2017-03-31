<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
protected override void OnInit(EventArgs e)
{
    base.OnInit(e);

    // http://integration-ext-04.zoneplaytest.com/?platform=external&external_system=playadjara&token=$TOKEN$&mode=$MODE$&lang=$LANG$
    string url = Settings.BuzzSports_Url;
    url = url.Replace("$LANG$", MultilingualMgr.GetCurrentCulture());
    if (Profile.IsAuthenticated)
    {
        BuzzSportsGetSessionRequest request = new BuzzSportsGetSessionRequest()
        {
            UserID = Profile.UserID
        };
        GamMatrixClient client = new GamMatrixClient();
        request = client.SingleRequest<BuzzSportsGetSessionRequest>(request);
        url = url.Replace("$TOKEN$", HttpUtility.UrlEncode(request.Token) );
        url = url.Replace("$MODE$", "");
    }
    else
    {
        url = url.Replace("$TOKEN$", "1");
        url = url.Replace("$MODE$", "demo");
    }

    StringBuilder sb = new StringBuilder();
    foreach (string key in Request.QueryString.AllKeys)
    {
        sb.AppendFormat(CultureInfo.InvariantCulture, "&{0}={1}", HttpUtility.UrlEncode(key), HttpUtility.UrlEncode(Request.QueryString[key]));
    }
    url += sb.ToString();

    Response.Redirect(url);    
}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

</asp:Content>

