<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private List<SelectListItem> GetHoGamingGames()
    {
        var p = new Dictionary<string, object>()
        {
            { "VendorID" , new VendorID[] { VendorID.HoGaming } },
        };
        int total = 0;
        
        List<ceCasinoGameBaseEx> games 
            = CasinoGameAccessor.SearchGames(1, 9999, Constant.SystemDomainID, p, out total, false, false);

        return games.Select(g => new SelectListItem() { Value = g.ID.ToString(), Text = string.Format("{0} - {1} [{2}]", g.ID, g.GameName, g.GameCode) }).ToList();
    }

    private List<SelectListItem> GetGameTypes()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        list.Add(new SelectListItem() { Text = "Baccarat", Value = "baccarat" });
        list.Add(new SelectListItem() { Text = "Blackjack", Value = "blackjack" });
        list.Add(new SelectListItem() { Text = "Roulette", Value = "roulette" });
        list.Add(new SelectListItem() { Text = "Immersive Roulette", Value = "immersive_roulette" });
        list.Add(new SelectListItem() { Text = "Mini Roulette", Value = "mini_roulette" });
        list.Add(new SelectListItem() { Text = "Slingshot", Value = "slingshot" });
        list.Add(new SelectListItem() { Text = "Slots", Value = "slots" });
        list.Add(new SelectListItem() { Text = "Hold'em", Value = "holdem" });
        list.Add(new SelectListItem() { Text = "Tcp", Value = "TCP" });
        return list;
    }

    public List<SelectListItem> GetLiveCasinoGameCategories()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        List<SelectListItem> list = dda.GetAllLiveCasinoCategory().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key }).ToList();       

        return list;
    }

    public Dictionary<string, string> GetClientTypes()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllClientType();
    }
</script>


<style type="text/css">
ul.table-list { list-style-type:none; margin:0px; padding:0px; }
#btnRegHoGaming { float:right; }
</style>

<p>
<label class="label">Game : </label>
<%: Html.DropDownList("gameID", GetHoGamingGames(), new { @class = "ddl", @id = "ddlHoGamingGameID"}) %>
</p>

<p>
    <label class="label">Categoty: <em>*</em></label>
    <%: Html.DropDownList("category", GetLiveCasinoGameCategories(), new { @class = "ddl required", @id = "ddlLiveCasinoCategory" })%>  
</p>

<p>
<label class="label">Client compatibility: </label>
<ul>
<%
    var clientTypes = GetClientTypes();
    foreach (var clientType in clientTypes)
    {
        string controlID = string.Format("btnClientType_{0}", clientType.Key); 
        %>
    <li style="display:inline-block; width:49%">
    <%: Html.CheckBox("clientType", false, new { @id = controlID, @value = clientType.Key })%>
    <label for="<%= controlID.SafeHtmlEncode() %>"><%= clientType.Value.SafeHtmlEncode()%></label>
    </li>
<% } %>
</ul>
<%: Html.Hidden("ClientCompatibility", null,  new { @id = "hClientCompatibility" })%>

<script type="text/javascript">
    $(function () {
        // <%-- ClientCompatibility --%>
        $(':checkbox[name="clientType"]').click(function (e) {
            var $checkedItems = $(':checked[name="clientType"]');
            var clientCompatibility = ',';
            for (var i = 0; i < $checkedItems.length; i++) {
                clientCompatibility = clientCompatibility + $($checkedItems[i]).val() + ',';
            }
            $('#hClientCompatibility').val(clientCompatibility);
        });
    });
</script>
</p>

<p>
<label class="label">Table ID: </label>
<%: Html.TextBox("extraParameter1", string.Empty, new { @id = "txtHoGamingTableID" })%>
</p>

<p>
<label class="label">Limit ID: </label>
<%: Html.TextBox("extraParameter2", string.Empty, new { @id = "txtHoGamingLimitID" })%>
</p>

<p style="position:absolute; bottom:0px; right:0px;width:auto;">
<button id="btnRegHoGaming">Submit</button>
</p>




<script type="text/javascript">

    $(function () {
        $('#btnRegHoGaming').button().click(function (e) {
            e.preventDefault();
            $('#loading').show();
            var url = '<%= this.Url.ActionEx("RegisterTable").SafeJavascriptStringEncode() %>';
            var data = {
                gameID: $('#ddlHoGamingGameID').val(),
                category: $('#ddlLiveCasinoCategory').val(),
                extraParameter1: $('#txtHoGamingTableID').val(),
                extraParameter2: $('#txtHoGamingLimitID').val(),
                ClientCompatibility: $('#hClientCompatibility').val(),
            };
            $.getJSON(url, data, function (json) {
                $('#loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                $('#txtHoGamingTableID').val('');
            });
        });
    });

</script>