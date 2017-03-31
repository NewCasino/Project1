<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%
    string[] paths = Metadata.GetChildrenPaths("/Metadata/LiveDealer/");

    string title, image, slug, name;
    foreach (string path in paths)
    {
        title = this.GetMetadata(path + ".Title");
        image = this.GetMetadata(path + ".Image");
        slug = this.GetMetadata(path + ".Slug").DefaultIfNullOrEmpty("").Trim();
        
        name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
        %>
        <div class="live_casino_game live_dealer_game" data-type="<%= name%>">
            <div class="container">
                <%: Html.H3(title, new { @class="game_name" })%>
                <div class="game_info">
                <%=image.HtmlEncodeSpecialCharactors() %>
                </div>
                <div class="game_button" align="center">
                <%: Html.LinkButton(this.GetMetadata(".PlayNow"), new { @onclick = "return openLivedealer('"+slug+"');", @class = "button_view_table" })%>
                </div>
            </div>
        </div>
        <%
    }
 %>

 <script type="text/javascript">
 function openLivedealer(slug)
    {
    <% if (!Profile.IsAuthenticated)
    { %>
        alert('<%= this.GetMetadata(".Anonymous_Message").SafeJavascriptStringEncode() %>');
        return false;
    <% }%>
        if(slug && slug.length>0)
        {
        window.open('/Casino/Game/Play/'+ slug +'?realMoney=True', 'newWindow', "status=0,toolbar=0,menubar=0,location=0,width=800,height=600");
        }
        else
        {
        
        }
        return false;        
    }
 </script>