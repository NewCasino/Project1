<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<Casino.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="Casino" %>
<script language="C#" type="text/C#" runat="server">
    private bool RealMoney { get { return (bool)this.ViewData["realMoney"]; } }
    
    protected override void OnInit(EventArgs e)
    {
        string lang = "en";
        switch(MultilingualMgr.GetCurrentCulture().Truncate(2).ToLowerInvariant())
        {
            case "es": lang = "es"; break;
            case "de": lang = "de"; break;
            case "it": lang = "it"; break;
            case "fr": lang = "fr"; break;
            default: lang = "en"; break;
        }
        
        string url;

        if (RealMoney)
        {
            url = string.Format(Settings.Casino_MicrogamingRealGameUrl
                , lang
                , HttpUtility.UrlEncode(this.Model.ID)
                , GameManager.CreateMicrogamingToken()
                );
        }
        else
        {
            url = string.Format(Settings.Casino_MicrogamingFunGameUrl
                , lang
                , HttpUtility.UrlEncode(this.Model.ID)
                );
        }
        Response.Redirect(url);
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

</asp:Content>

