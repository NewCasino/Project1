<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<CasinoEngine.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<script type="text/C#" runat="server">
/*
    protected override void OnInit(EventArgs e)
    {
        Response.Clear();
        Response.ClearHeaders();
        Response.AddHeader("Location", "/Casino/Game/Info/" + this.Model.Slug.DefaultIfNullOrEmpty(this.Model.ID));
        Response.StatusCode = 301;
        Response.Flush();
        Response.End();
        return;
    }
 * */
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<title><%= this.Model.Name.SafeHtmlEncode()%></title>
<meta name="keywords" content="<%= string.Join( ",", this.Model.Tags ).SafeHtmlEncode() %>" />
<meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" /> 
<meta http-equiv="pragma" content="no-cache" /> 
<meta http-equiv="cache-control" content="no-store, must-revalidate" /> 
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" /> 
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="framework" class="Container">

    <div class="Zone Container Intro">
	
        <% Html.RenderPartial("/Casino/Lobby/GameAreaInlineWidget"); %>
    </div>


    <div class="Zone Container SimilarGamesContainer">
		<div class="Main Column">
            
        </div>                        
    </div>

</div>


<script type="text/javascript">
    $(function () {
        var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "SimilarGameSliderWidget", @MaxCount = "20", @gameID = this.Model.ID }).SafeJavascriptStringEncode()%>';
        $('#framework div.SimilarGamesContainer div.Main').load(url);
    });
</script>
</asp:Content>

