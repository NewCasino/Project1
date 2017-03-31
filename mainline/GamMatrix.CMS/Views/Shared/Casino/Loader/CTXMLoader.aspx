<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<Casino.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="Casino" %>
<script language="C#" type="text/C#" runat="server">

    private bool RealMoney { get { return (bool)this.ViewData["realMoney"]; } }

    protected override void OnInit(EventArgs e)
    {
        StringBuilder url = new StringBuilder();
        url.Append(Settings.Casino_CTXMGameLoadBaseUrl);

        // game_code
        url.AppendFormat("&game_code={0}", HttpUtility.UrlEncode(this.Model.ID));
        
        if( RealMoney )
        {
            url.Append("&playmode=real");
            url.AppendFormat("&ticket={0}", HttpUtility.UrlEncode(GameManager.CreateCTXMTicket()));
        }
        else
        {
            url.Append("&playmode=fun");
        }

        // singlegame
        //url.Append("&singlegame=true");

        // disableLogout
        url.Append("&disableLogout=true");

        // lockPlaymode
        url.Append("&lockPlaymode=true");

        // uniformScaling
        url.Append("&uniformScaling=true");

        string lang = MultilingualMgr.GetCurrentCulture().Truncate(2).ToUpper();
        url.AppendFormat("&language={0}", HttpUtility.UrlEncode(lang));

        Response.Redirect(url.ToString());
        
        base.OnInit(e);
    }
    
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

</asp:Content>

