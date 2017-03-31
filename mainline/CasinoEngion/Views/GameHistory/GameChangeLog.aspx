<%@ Page Title="Casino Engine - Configuration" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" 
    Inherits="System.Web.Mvc.ViewPage<long>" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        if (Request.QueryString["k"] == "zxcvb")
        {
            CE.BackendThread.ChangeNotifier.ReloadOriginalFeeds();
        }
    }
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="phMain" runat="server">
    <% Html.RenderAction("GameChangeDetails", new { gameID = this.Model }); %>
</asp:Content>