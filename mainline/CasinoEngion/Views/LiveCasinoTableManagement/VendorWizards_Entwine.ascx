<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private List<SelectListItem> GetEntwineGames()
    {
        var p = new Dictionary<string, object>()
        {
            { "VendorID" , new VendorID[] { VendorID.Entwine } },
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

    private List<SelectListItem> GetGameInterfaces()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        //list.Add(new SelectListItem() { Text = "Small Screen", Value = "smallscreen" });
        //list.Add(new SelectListItem() { Text = "Full Screen", Value = "fullscreen", Selected = true });
        //list.Add(new SelectListItem() { Text = "Special ( Baccarat only )", Value = "special" });
        list.Add(new SelectListItem() { Text = "3D View", Value = "view1" });
        list.Add(new SelectListItem() { Text = "Classic View", Value = "view2" });
        list.Add(new SelectListItem() { Text = "In-line Video", Value = "inlinevideo" });
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
#btnRegEntwine { float:right; }
</style>

<p>
<label class="label">Game : </label>
<%: Html.DropDownList("gameID", GetEntwineGames(), new { @class = "ddl", @id = "ddlEntwineGameID"}) %>
</p>

<p>
<label class="label">Type (gtype): </label>
<%: Html.DropDownList("extraParameter1", GetGameTypes(), new { @class = "ddl", @id = "ddlEntwineType" })%>
</p>

<p>
<label class="label">Interface (gif): </label>
<%: Html.DropDownList("extraParameter2", GetGameInterfaces(), new { @class = "ddl", @id = "ddlEntwineInterface" })%>
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
<label class="label">Table ID (tid): </label>
<%: Html.TextBox("extraParameter3", string.Empty, new { @id = "txtEntwineTableID" })%>
</p>

<p>
<label class="label">Virtual Table ID (vtid): </label>
<%: Html.TextBox("extraParameter4", string.Empty, new { @id = "txtEntwineVTableID" })%>
</p>


<p style="position:absolute; bottom:0px; right:0px;width:auto;">
<button id="btnRegEntwine">Submit</button>
</p>




<script type="text/javascript">

    $(function () {
        $('#btnRegEntwine').button().click(function (e) {
            e.preventDefault();
            $('#loading').show();
            var url = '<%= this.Url.ActionEx("RegisterTable").SafeJavascriptStringEncode() %>';
            var data = {
                gameID: $('#ddlEntwineGameID').val(),
                extraParameter1: $('#ddlEntwineType').val(),
                extraParameter2: $('#ddlEntwineInterface').val(),
                extraParameter3: $('#txtEntwineTableID').val(),
                extraParameter4: $('#txtEntwineVTableID').val(),
                ClientCompatibility: $('#hClientCompatibility').val(),
            };
            $.getJSON(url, data, function (json) {
                $('#loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                $('#txtEntwineTableID').val('');
                $('#txtEntwineVTableID').val('');
            });
        });
    });

</script>