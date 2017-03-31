<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<CE.db.ceLiveCasinoTableBaseEx>" %>
<%@ Import Namespace="System.Collections.ObjectModel" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.Extensions" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private List<SelectListItem> GetVendor()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.Model.VendorID.ToString(), Value = this.Model.VendorID.ToString() });
        return list;
    }

    public List<SelectListItem> GetLiveCasinoGameCategories()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        List<SelectListItem> list = dda.GetAllLiveCasinoCategory().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key }).OrderBy(x => x.Text).ToList();

        SelectListItem selected = list.FirstOrDefault(i => string.Equals(i.Value, this.Model.Category, StringComparison.InvariantCultureIgnoreCase));
        if (selected != null)
            selected.Selected = true;

        return list;
    }

    private string GetThumbnailImage()
    {
        if (string.IsNullOrEmpty(this.Model.Thumbnail))
            return "//cdn.everymatrix.com/images/placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , this.Model.Thumbnail
            );
    }

    private List<SelectListItem> GetGameTypes()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        list.Add(new SelectListItem() { Text = "Baccarat", Value = "baccarat" });
        list.Add(new SelectListItem() { Text = "Blackjack", Value = "blackjack" });
        list.Add(new SelectListItem() { Text = "Roulette", Value = "roulette" });
        list.Add(new SelectListItem() { Text = "Mini Roulette", Value = "mini_roulette" });
        list.Add(new SelectListItem() { Text = "Immersive Roulette", Value = "immersive_roulette" });
        list.Add(new SelectListItem() { Text = "Slingshot", Value = "slingshot" });
        list.Add(new SelectListItem() { Text = "Slots", Value = "slots" });
        list.Add(new SelectListItem() { Text = "Hold'em", Value = "holdem" });
        list.Add(new SelectListItem() { Text = "Tcp", Value = "TCP" });

        list = list.OrderBy(x => x.Text).ToList();

        SelectListItem selected = list.FirstOrDefault(i => string.Equals(i.Value, this.Model.ExtraParameter1, StringComparison.InvariantCultureIgnoreCase));
        if (selected != null)
            selected.Selected = true;
        return list;
    }

    private List<SelectListItem> GetGameInterfaces()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        //list.Add(new SelectListItem() { Text = "Small Screen", Value = "smallscreen" });
        //list.Add(new SelectListItem() { Text = "Full Screen", Value = "fullscreen" });
        //list.Add(new SelectListItem() { Text = "Special ( Baccarat only )", Value = "special" });
        list.Add(new SelectListItem() { Text = "3D View", Value = "view1" });
        list.Add(new SelectListItem() { Text = "Classic View", Value = "view2" });
        list.Add(new SelectListItem() { Text = "In-line Video", Value = "inlinevideo" });
        list.Add(new SelectListItem() { Text = "High-definition", Value = "hd1" });

        SelectListItem selected = list.FirstOrDefault(i => string.Equals(i.Value, this.Model.ExtraParameter2, StringComparison.InvariantCultureIgnoreCase));
        if (selected != null)
            selected.Selected = true;
        return list;
    }

    private List<SelectListItem> GetTimeZones()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        Regex regex = new Regex(@"^(?<name>[^\;]+)\;([^\;]+\;)([^\(]*\()(?<offset>[^\)]+)", RegexOptions.Compiled | RegexOptions.ECMAScript);
        ReadOnlyCollection<TimeZoneInfo> timeZones = TimeZoneInfo.GetSystemTimeZones();
        foreach (TimeZoneInfo timeZone in timeZones)
        {
            Match m = regex.Match(timeZone.ToSerializedString());
            if (m.Success)
            {
                list.Add(new SelectListItem()
                {
                    Text = string.Format("{0} {1}", m.Groups["offset"].Value, m.Groups["name"].Value),
                    Value = timeZone.StandardName
                });
            }
        }


        list.Insert(0, new SelectListItem() { Text = "24/7", Value = string.Empty });

        return list;
    }

    private List<SelectListItem> GetLimitationTypes()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        list.Add(new SelectListItem() { Text = "None", Value = LiveCasinoTableLimitType.None.ToString() });
        list.Add(new SelectListItem() { Text = "Same min/max for all currencies", Value = LiveCasinoTableLimitType.SameForAllCurrency.ToString() });
        list.Add(new SelectListItem() { Text = "Specific for each currency", Value = LiveCasinoTableLimitType.SpecificForEachCurrency.ToString() });
        list.Add(new SelectListItem() { Text = "Auto convert basing on currency rate", Value = LiveCasinoTableLimitType.AutoConvertBasingOnCurrencyRate.ToString() });

        SelectListItem selected = list.FirstOrDefault(i => i.Value == this.Model.Limit.Type.ToString());
        if (selected != null)
            selected.Selected = true;

        return list;
    }

    private List<SelectListItem> GetCurrencyList()
    {
        List<SelectListItem> list = GamMatrixClient.GetSupportedCurrencies().Select(c => new SelectListItem() { Text = string.Format("{0} - {1}", c.ISO4217_Alpha, c.Name), Value = c.ISO4217_Alpha }).ToList();

        SelectListItem selected = list.FirstOrDefault(i => i.Value == this.Model.Limit.BaseCurrency);
        if (selected != null)
            selected.Selected = true;

        return list;
    }

    private List<SelectListItem> GetStartOpenHours()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        for (int h = 0; h < 24; h++)
        {
            for (int m = 0; m < 60; m += 5)
            {
                int minutes = h * 60 + m;
                list.Add(new SelectListItem() { Text = string.Format("{0:D2}:{1:D2}", h, m), Value = minutes.ToString(), Selected = this.Model.OpenHoursStart == minutes });
            }
        }

        return list;
    }

    private List<SelectListItem> GetEndOpenHours()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        for (int h = 0; h < 24; h++)
        {
            for (int m = 0; m < 60; m += 5)
            {
                int minutes = h * 60 + m;
                list.Add(new SelectListItem() { Text = string.Format("{0:D2}:{1:D2}", h, m), Value = minutes.ToString(), Selected = this.Model.OpenHoursEnd == minutes });
            }
        }

        return list;
    }

    public Dictionary<string, string> GetClientTypes()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllClientType();
    }

    private List<SelectListItem> GetDealerGenderList()
    {
        var valuesList = Enum.GetValues(typeof(DealerGender)).OfType<DealerGender>();
        List<SelectListItem> list = new List<SelectListItem>();
        foreach (var val in valuesList)
        {
            list.Add(new SelectListItem() { Text = val.GetDescription(), Value = val.ToString() });
        }
        return list;
    }

    private List<SelectListItem> GetDealerOriginList()
    {
        var valuesList = Enum.GetValues(typeof(DealerOrigin)).OfType<DealerOrigin>();
        List<SelectListItem> list = new List<SelectListItem>();
        foreach (var val in valuesList)
        {
            list.Add(new SelectListItem() { Text = val.GetDescription(), Value = val.ToString() });
        }
        return list;
    }


    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        switch (this.Model.VendorID)
        {
            case VendorID.NetEnt:
                {
                    pNetEntTableID.Visible = true;
                    break;
                };

            case VendorID.Microgaming:
                {
                    break;
                };

            case VendorID.XProGaming:
                {
                    pDefaultLimitSetID.Visible = true;
                    pLimitSetIDPerCurrency.Visible = true;
                    break;
                };

            case VendorID.EvolutionGaming:
                {
                    pClientCompatibility.Visible = true;

                    pEvolutionType.Visible = true;
                    pEvolutionInterface.Visible = true;
                    pEvolutionTableID.Visible = true;
                    pEvolutionVTableID.Visible = true;
                    break;
                };
            
            case VendorID.Ezugi:
                pClientCompatibility.Visible = true;
                pEzugiTableID.Visible = true;
                pLaunchUrl.Visible = true;
                break;
            
            case VendorID.Vivo:
                pClientCompatibility.Visible = true;

                pVivoTableID.Visible = true;
                pVivoLimitID.Visible = true;
                break;
            
            case VendorID.Tombala:
            case VendorID.BetGames:
                pClientCompatibility.Visible = true;
                break;
            
            case VendorID.LuckyStreak:
                pLuckyStreakLimitID.Visible = true;
                pClientCompatibility.Visible = true;
                break;
                
            case VendorID.ViG:
                pExtraLaunchParams.Visible = true;
                break;
            
            default:
                pClientCompatibility.Visible = true;
                pExtraLaunchParams.Visible = true;
                break;

        }
    }
</script>

<style type="text/css">
    #table-editor-tabs .ui-tabs-panel {
        height: 490px;
        overflow: auto;
    }

    table.format-table tbody td {
        height: 30px;
    }

    table.format-table .col-1 select {
        margin-right: 15px;
    }

    table.format-table input {
        width: 70px;
        text-align: right;
        margin: 0px 5px;
    }

    ul.table-list {
        list-style-type: none;
        margin: 0px;
        padding: 0px;
    }

        ul.table-list li {
            display: inline-block;
            margin-right: 15px;
        }

    .currency-label {
        width: 45px;
        display: inline-block;
    }

    .currency-limit-set {
        width: 50px;
        text-align: right;
    }

    .date-inputbox {
        text-align: center;
        width: 80px;
        background: #acacac;
    }

    .newTableDatePicker {
        display: inline;
    }

    .selectedOptionText {
        font-weight: bold;
    }

    #btnRevertToDefaultsLiveCasinoTable {
        float: left;
        margin-right: 10px;
    }

    .propertyOverrideWarningMessage {
        float: left;
    }

        .propertyOverrideWarningMessage p {
            margin: 5px 0;
        }

    #btnSubmitLiveCasinoTable {
        float: right;
    }
</style>

<form id="formRegisterTable" enctype="multipart/form-data" method="post" action="<%= this.Url.ActionEx("SaveTable").SafeHtmlEncode() %>">

    <div id="table-editor-tabs">
        <ul>
            <li><a href="#tabs-1">Basic</a></li>
            <li><a href="#tabs-2">Assets</a></li>
            <li><a href="#tabs-3">Advanced</a></li>
        </ul>
        <div id="tabs-1">
            <p>
                <label class="label">Vendor: </label>

                <%: Html.DropDownListFor(m => m.VendorID, GetVendor(), new { @class = "ddl", @id = "ddlLiveCasinoVendor", @disabled = "disabled" })%>
                <%: Html.HiddenFor(m => m.ID)%>
            </p>

            <p>
                <label class="label">Table Name : <em>*</em></label>

                <%: Html.TextBoxFor(m => m.TableName, new { @id = "txtTableName", @class = "textbox required" })%>
            </p>

            <p>
                <label class="label">Category: <em>*</em></label>

                <%: Html.DropDownListFor(m => m.Category, GetLiveCasinoGameCategories(), new { @class = "ddl required", @id = "ddlLiveCasinoCategory" })%>
            </p>

            <p runat="server" id="pLaunchUrl" visible="false">
                <label class="label">Table studio url : </label>
                <%: Html.TextBoxFor(m => m.TableStudioUrl, new { @id = "txtTableStudioUrl", @class = "textbox" })%>
            </p>

            <p runat="server" id="pClientCompatibility" visible="false">
                <label class="label">Client compatibility: </label>
                <ul>
                    <%
                        var clientTypes = GetClientTypes();
                        foreach (var clientType in clientTypes)
                        {
                            string controlID = string.Format("btnClientType_{0}", clientType.Key); 
                    %>
                    <li style="display: inline-block; width: 49%">
                        <%: Html.CheckBox("clientType", false, new { @id = controlID, @value = clientType.Key })%>
                        <label for="<%= controlID.SafeHtmlEncode() %>"><%= clientType.Value.SafeHtmlEncode()%></label>
                    </li>
                    <% } %>
                </ul>
                <%: Html.HiddenFor(m=>m.ClientCompatibility, new { @id = "hClientCompatibility" })%>
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
                            var $items = $(':checkbox[name="clientType"]');
                            for (var i = 0; i < $items.length; i++) {
                                var $item = $($items[i]);
                                var strToFind = ',' + $item.val() + ',';
                                if ($('#hClientCompatibility').val().indexOf(strToFind) >= 0)
                                    $item.attr('checked', true);
                            }

                        });
                </script>
            </p>
            <p runat="server" id="pExtraLaunchParams" visible="false">
                <label class="label">Extra launch params: </label>
                <%: Html.TextAreaFor(m => m.LaunchParams, new { @id = "txtLaunchParams", @class = "textbox" })%>
            </p>

            <%: Html.HiddenFor(m => m.ExtraParameter1, new { @id = "txtExtraParam1", @class = "textbox" })%>
            <%: Html.HiddenFor(m => m.ExtraParameter2, new { @id = "txtExtraParam2", @class = "textbox" })%>
            <%: Html.HiddenFor(m => m.ExtraParameter3, new { @id = "txtExtraParam3", @class = "textbox" })%>
            <%: Html.HiddenFor(m => m.ExtraParameter4, new { @id = "txtExtraParam4", @class = "textbox" })%>          

            <%-- P1 --%>
            <p runat="server" id="pNetEntTableID" visible="false">
                <label class="label">Table ID: <em>*</em></label>
                <input type="text" readonly="readonly" class="textbox" id="txtNetEntTableID" value="<%=this.Model.ExtraParameter1.SafeHtmlEncode() %>" />
            </p>

            <%-- P1 --%>
            <p runat="server" id="pDefaultLimitSetID" visible="false">
                <label class="label">Default Limit Set ID: <em>*</em></label>
                <input type="text" class="textbox" id="txtXProGamingLimitSetID" value="<%=this.Model.ExtraParameter1.SafeHtmlEncode() %>" />
                <script type="text/javascript">
                    $(function () {
                        $('#txtXProGamingLimitSetID').keypress(function (evt) {
                            var allowed = true;
                            var code = evt.which || evt.keyCode;
                            if (code >= 48 && code <= 57) {
                                return;
                            }
                            else if (code == 0 || code == 8) {
                                return;
                            }
                            else
                                evt.preventDefault();
                        }).change(function (evt) {
                            var text = $(this).val();
                            if (text != null && text.toString().length > 0) {
                                var num = parseInt(text, 10);
                                if (num > 0)
                                    $(this).val(num.toString(10));
                                else
                                    $(this).val('');
                            }
                            $('#txtExtraParam1').val($(this).val());
                        });
                    });
                </script>
            </p>



            <%-- P1 --%>
            <p runat="server" id="pEvolutionType" visible="false">
                <label class="label">Type (gtype): <em>*</em></label>
                <%: Html.DropDownList("evolutionType", GetGameTypes(), new { @class = "ddl", @id = "ddlEvolutionType" })%>
            </p>

            <%-- P2 --%>
            <p runat="server" id="pLimitSetIDPerCurrency" visible="false">
                <label class="label">Limit Set ID per Currency: </label>
                <ul class="table-list" id="currency-limit-sets">
                    <% foreach (var currency in GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID))
                       { %>
                    <li>
                        <label>
                            <span class="currency-label"><%= currency.Key %> = </span>
                            <%: Html.TextBox(currency.Key, string.Empty, new { @class = "currency-limit-set", @maxlength = 5 })%>
                        </label>
                    </li>
                    <% } %>
                </ul>
                <script type="text/javascript">
                    $(function () {
                        var json = null;
                        var extraParam2 = $('#txtExtraParam2').val();
                        if (extraParam2 != null && extraParam2.length > 0) {
                            json = JSON.parse(extraParam2);
                        }
                        if (json == null)
                            json = {};

                        $('input.currency-limit-set').each(function (i, el) {
                            var val = json[$(el).prop('name')];
                            $(el).val(val);

                            $(el).keypress(function (evt) {
                                var allowed = true;
                                var code = evt.which || evt.keyCode;
                                if (code >= 48 && code <= 57) {
                                    return;
                                }
                                else if (code == 0 || code == 8) {
                                    return;
                                }
                                else
                                    evt.preventDefault();
                            });
                            $(el).change(function (evt) {
                                var text = $(this).val();
                                if (text != null && text.toString().length > 0) {
                                    var num = parseInt(text, 10);
                                    if (num > 0)
                                        $(this).val(num.toString(10));
                                    else
                                        $(this).val('');
                                }
                                updateXProExtraParam2();
                            });
                        });

                        function updateXProExtraParam2() {
                            var json = {};
                            var $textboxes = $('#currency-limit-sets .currency-limit-set');
                            $textboxes.each(function (i, el) {
                                var limitSetID = $(el).val();
                                if (limitSetID != null && limitSetID.length > 0) {
                                    json[$(el).prop('name')] = limitSetID;
                                }
                            });

                            $('#txtExtraParam2').val(JSON.stringify(json));
                        }
                    });
                </script>
            </p>

            <%-- P2 --%>
            <p runat="server" id="pEvolutionInterface" visible="false">
                <label class="label">Interface (gif): <em>*</em></label>
                <%: Html.DropDownList("evolutionInterface", GetGameInterfaces(), new { @class = "ddl", @id = "ddlEvolutionInterface" })%>
            </p>

            <%-- P3 --%>
            <p runat="server" id="pEvolutionTableID" visible="false">
                <label class="label">Table ID (tid): <em>*</em></label>
                <input type="text" class="textbox" id="txtEvolutionTableID" value="<%=this.Model.ExtraParameter3.SafeHtmlEncode() %>" />
            </p>

            <%-- P4 --%>
            <p runat="server" id="pEvolutionVTableID" visible="false">
                <label class="label">Virtual Table ID (vtid): </label>
                <input type="text" class="textbox" id="txtEvolutionVTableID" value="<%=this.Model.ExtraParameter4.SafeHtmlEncode() %>" />
            </p>

            <%-- P1 --%>
            <p runat="server" id="pEzugiTableID" visible="false">
                <label class="label">Table ID: <em>*</em></label>
                <input type="text" class="textbox" id="txtEzugiTableID" value="<%=this.Model.ExtraParameter1.SafeHtmlEncode() %>" />
            </p>


            <%-- P1 --%>
            <p runat="server" id="pVivoTableID" visible="false">
                <label class="label">Table ID: <em>*</em></label>
                <input type="text" class="textbox" id="txtVivoTableID" value="<%=this.Model.ExtraParameter1.SafeHtmlEncode() %>" />
            </p>

            <%-- P2 --%>
            <p runat="server" id="pVivoLimitID" visible="false">
                <label class="label">Limit ID: <em>*</em></label>
                <input type="text" class="textbox" id="txtVivoLimitID" value="<%=this.Model.ExtraParameter2.SafeHtmlEncode() %>" />
            </p>
            
            <%-- P2 --%>
            <p runat="server" id="pLuckyStreakLimitID" visible="false">
                <label class="label">Limit ID: <em>*</em></label>
                <input type="text" class="textbox" id="txtLuckyStreakLimitID" value="<%=this.Model.ExtraParameter2.SafeHtmlEncode() %>" />
            </p>                                  

            <p>
                <label class="label">Options :</label>
                <ul>
                    <li style="display: inline-block; width: 49%">
                        <%= Html.CheckBox("vipTable", this.Model.VIPTable,new { @id = "vipTable" })%>
                        <label for="vipTable">Is VIP Table</label>
                    </li>
                    <li style="display: inline-block; width: 49%">
                        <%= Html.CheckBox("turkishTable", this.Model.TurkishTable,new { @id = "turkishTable" })%>
                        <label for="turkishTable">Is Turkish Table</label>
                    </li>
                    <li style="display: inline-block; width: 49%">
                        <%= Html.CheckBox("newTable", this.Model.NewTable,new { @id = "newTable" })%>
                        <label for="newTable">Is New Table</label>
                        <div class="newTableDatePicker" style="<%= this.Model.NewTable ? "display:inline;": "display:none;" %>">
                            <span>&nbsp;till</span>
                            <input class="date-inputbox" type="text" id="newTableExpirationDate" name="newTableExpirationDate" value="<%= this.Model.NewTable ? this.Model.NewTableExpirationDate.ToShortDateString() : DateTime.Now.Date.AddDays(-1).ToShortDateString() %>" />
                        </div>
                    </li>
                    <li style="display: inline-block; width: 49%">
                        <% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                           { %>
                        <%= Html.CheckBox("betBehindAvailableDisabled", this.Model.BetBehindAvailable,new { @disabled = "disabled"})%>
                        <% }
                           else
                           { %>
                        <%= Html.CheckBox("betBehindAvailable", this.Model.BetBehindAvailable,new { @id = "betBehindAvailable" })%>
                        <% } %>
                        <label for="betBehindAvailable">Is Bet Behind Available</label>
                    </li>
                    <li style="display: inline-block; width: 49%">
                        <%= Html.CheckBox("excludeFromRandomLaunch", this.Model.ExcludeFromRandomLaunch,new { @id = "excludeFromRandomLaunch" })%>
                        <label for="excludeFromRandomLaunch">Exclude from Random Launch Selected List</label>
                    </li>
                    <li style="display: inline-block; width: 49%">
                        <% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                           { %>
                        <%= Html.CheckBox("seatsUnlimitedDisabled", this.Model.SeatsUnlimited,new { @disabled = "disabled"}) %>
                        <% }
                           else
                           { %>
                        <%= Html.CheckBox("seatsUnlimited", this.Model.SeatsUnlimited,new { @id = "seatsUnlimited" })%>
                        <% } %>
                        <label for="seatsUnlimited">Is Seats Unlimited</label>
                    </li>
                    <li style="display: inline-block; width: 49%">
                        <span>Dealer Gender:</span>
                        <%  if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                            {
                                var selectedItem = GetDealerGenderList().FirstOrDefault(g => g.Value == Model.DealerGender.ToString());
                                if (selectedItem != null)
                                { %>
                        <span class="selectedOptionText"><%= selectedItem.Text %></span>
                        <%  } %>
                        <%  }
                            else
                            { %>
                        <ul style="display: inline-block; width: 100%">
                            <%  foreach (var item in GetDealerGenderList())
                                { %>
                            <li style="display: inline-block;">
                                <%= Html.RadioButtonFor(model => Model.DealerGender, item.Value, new { id = "checkDGender" + item.Value })%>
                                <label for="<%: "checkDGender" + item.Value %>"><%: item.Text %></label>
                            </li>
                            <%  } %>
                        </ul>
                        <%  } %>
                    </li>
                    <li style="display: inline-block; width: 49%"></li>
                    <li style="display: inline-block; width: 49%">
                        <span>Dealer Origin:</span>
                        <%  if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                            {
                                var selectedItem = GetDealerOriginList().FirstOrDefault(g => g.Value == Model.DealerOrigin.ToString());
                                if (selectedItem != null)
                                { %>
                        <span class="selectedOptionText"><%= selectedItem.Text %></span>
                        <%  } %>
                        <%  }
                            else
                            { %>
                        <ul style="display: inline-block; width: 100%">
                            <%  foreach (var item in GetDealerOriginList())
                                { %>
                            <li style="display: inline-block;">
                                <%= Html.RadioButtonFor(model => Model.DealerOrigin, item.Value, new { id = "checkDOrigin" + item.Value})%>
                                <label for="<%: "checkDOrigin" + item.Value %>"><%: item.Text %></label>
                            </li>
                            <%  } %>
                        </ul>
                        <%  } %>
                    </li>
                </ul>
            </p>

        </div>

        <div id="tabs-2">

            <p>
                <label class="label">Thumbnail (294px X 160px):</label>
                <a href="<%= GetThumbnailImage().SafeHtmlEncode() %>" target="_blank">
                    <img style="border: solid 1px #666;" src="<%= GetThumbnailImage().SafeHtmlEncode() %>" />
                </a>
                <br />

                <input type="file" name="thumbnailFile" style="width: 440px" />
            </p>


        </div>

        <div id="tabs-3">
            <p>
                <label class="label">Opening Time :</label>
                <table cellpadding="0" cellspacing="0" border="0" class="format-table">
                    <tbody>
                        <tr>
                            <td class="col-1">
                                <%: Html.DropDownListFor(m => m.OpenHoursTimeZone, GetTimeZones(), new { @class = "ddl", @id = "ddlOpenHoursTimeZone" })%>
                            </td>
                            <td class="col-2">
                                <%: Html.DropDownListFor(m => m.OpenHoursStart, GetStartOpenHours(), new { @class = "ddl", @id = "ddlOpenHoursStart", @style="width:70px;" })%>
                            </td>
                            <td>&#160;&#160;-&#160;&#160;
                            </td>
                            <td class="col-3">
                                <%: Html.DropDownListFor(m => m.OpenHoursEnd, GetEndOpenHours(), new { @class = "ddl", @id = "ddlOpenHoursEnd", @style = "width:70px;" })%>
                            </td>
                        </tr>
                    </tbody>
                </table>


            </p>
            <hr />
            <p>
                <label class="label">Limitation Type :</label>
                <%: Html.DropDownList("limitType", GetLimitationTypes(), new { @class = "ddl", @id = "ddlLimitType" })%>
            </p>
            <p id="limit-amount" style="display: none">
                <label class="label">Limitation Amount :</label>
                <table cellpadding="0" cellspacing="0" border="0" class="format-table" id="base-limit-table" style="display: none">
                    <tbody>
                        <tr>
                            <td class="col-1">
                                <%: Html.DropDownList("baseCurrency", GetCurrencyList(), new { @class = "ddl", @id = "ddlBaseCurrency" })%>
                            </td>
                            <td class="col-2">
                                <%: Html.TextBox("baseCurrencyMinAmount", this.Model.Limit.BaseLimit.MinAmount.ToString("F2"), new { @id = "txtBaseCurrencyMinAmount", @class = "textbox number", @maxlength = "8" })%>
                            </td>
                            <td>&#8804; X &#8804;
                            </td>
                            <td class="col-3">
                                <%: Html.TextBox("baseCurrencyMaxAmount", this.Model.Limit.BaseLimit.MaxAmount.ToString("F2"), new { @id = "txtBaseCurrencyMaxAmount", @class = "textbox number", @maxlength = "8" })%>
                            </td>
                        </tr>
                    </tbody>
                </table>

                <table cellpadding="0" cellspacing="0" border="0" class="format-table" id="currency-limit-table" style="display: none">
                    <tbody>
                        <% 
                            CurrencyData[] currencies = GamMatrixClient.GetSupportedCurrencies();
                            foreach (CurrencyData currency in currencies)
                            {
                                LimitAmount limitAmount;
                                if (!this.Model.Limit.CurrencyLimits.TryGetValue(currency.ISO4217_Alpha, out limitAmount))
                                    limitAmount = new LimitAmount();
                        %>
                        <tr data-currency="<%= currency.ISO4217_Alpha %>">
                            <td class="col-1">
                                <%= string.Format( "{0} - {1}", currency.ISO4217_Alpha, currency.Name.SafeHtmlEncode()).SafeHtmlEncode() %>
                            </td>
                            <td class="col-2">
                                <%: Html.TextBox("minAmount_" + currency.ISO4217_Alpha, limitAmount.MinAmount.ToString("F2"), new { @class = "textbox number min", @maxlength = "8" })%>
                            </td>
                            <td>&#8804; X &#8804;
                            </td>
                            <td class="col-3">
                                <%: Html.TextBox("maxAmount_" + currency.ISO4217_Alpha, limitAmount.MaxAmount.ToString("F2"), new { @class = "textbox number max", @maxlength = "8" })%>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </p>

        </div>
    </div>


    <p align="right">
        <% if(DomainManager.AllowEdit()) { %>
        <% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
           { %>
        <button type="button" id="btnRevertToDefaultsLiveCasinoTable">To Defaults</button>
        <div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all propertyOverrideWarningMessage">
            <p>
                <span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
                <strong>NOTE!</strong> Editing the table attributes here will override the default settings for this operator.
            </p>
        </div>
        <% } %>

        <button type="button" id="btnSubmitLiveCasinoTable">Submit</button>
      <% } %>
    </p>


</form>
<form id="formRevertTable" enctype="multipart/form-data" method="post" action="<%= this.Url.ActionEx("RevertToDefaultTable").SafeHtmlEncode() %>">
    <%: Html.HiddenFor(m => m.ID)%>
</form>
<script type="text/javascript">
    $(function () {
        $('#table-editor-tabs').tabs();

        var syncToExtraParameter1 = function () {
            $('#txtExtraParam1').val($(this).val());
        };
        var syncToExtraParameter2 = function () {
            $('#txtExtraParam2').val($(this).val());
        };
        var syncToExtraParameter3 = function () {
            $('#txtExtraParam3').val($(this).val());
        };
        var syncToExtraParameter4 = function () {
            $('#txtExtraParam4').val($(this).val());
        };     
        $('#txtLimitSetID').change(syncToExtraParameter1).keyup(syncToExtraParameter1).blur(syncToExtraParameter1);
        //$('#txtNetEntTableID').change(syncToExtraParameter1).keyup(syncToExtraParameter1).blur(syncToExtraParameter1);
        $('#ddlEvolutionType').change(syncToExtraParameter1);
        $('#ddlEvolutionInterface').change(syncToExtraParameter2);
        $('#txtEvolutionTableID').change(syncToExtraParameter3).keyup(syncToExtraParameter3).blur(syncToExtraParameter3);
        $('#txtEvolutionVTableID').change(syncToExtraParameter4).keyup(syncToExtraParameter4).blur(syncToExtraParameter4);

        $('#txtEzugiTableID').change(syncToExtraParameter1).keyup(syncToExtraParameter1).blur(syncToExtraParameter1);

        $('#txtVivoTableID').change(syncToExtraParameter1).keyup(syncToExtraParameter1).blur(syncToExtraParameter1);
        $('#txtVivoLimitID').change(syncToExtraParameter2).keyup(syncToExtraParameter2).blur(syncToExtraParameter2);

        $('#txtLuckyStreakLimitID').change(syncToExtraParameter2).keyup(syncToExtraParameter2).blur(syncToExtraParameter2);            

        $('#btnSubmitLiveCasinoTable').button().click(function (e) {
            e.preventDefault();

            if (!$("#formRegisterTable").valid())
                return;

            var t = $('#ddlLimitType').val();
            if (t == 'SameForAllCurrency' ||
                t == 'AutoConvertBasingOnCurrencyRate') {
                var min = parseInt($('#txtBaseCurrencyMinAmount').val(), 10);
                var max = parseInt($('#txtBaseCurrencyMaxAmount').val(), 10);
                if (max <= min) {
                    alert('Error, min amount is not less than max amount!');
                    $('#txtBaseCurrencyMaxAmount').focus();
                    return;
                }
            } else if (t == 'SpecificForEachCurrency') {
                var $trs = $('#currency-limit-table tr[data-currency]');
                for (var i = 0; i < $trs.length; i++) {
                    var $tr = $trs.eq(i);
                    var currency = $tr.data('currency');
                    var min = parseInt($('input.min', $tr).val(), 10);
                    var max = parseInt($('input.max', $tr).val(), 10);
                    if (min > max) {
                        alert('The min limitation of ' + currency + ' is greater than its max limitation');
                        $('input.min', $tr).focus();
                        return;
                    }
                }
            }

            var options = {
                dataType: 'json',
                success: function (json) {
                    $('#loading').hide();
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    $(document).trigger('LIVE_CASINO_TABLE_CHANGED');
                    $.modal.close();
                }
            };
            $('#loading').show();
            $("#formRegisterTable").ajaxSubmit(options);
        });


        $("#formRegisterTable").validate();


        $('#ddlOpenHoursTimeZone').change(function () {
            $('#ddlOpenHoursStart').attr('disabled', $(this).val() == '');
            $('#ddlOpenHoursEnd').attr('disabled', $(this).val() == '');

            <% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
               { %>
            $('#ddlOpenHoursTimeZone').attr('disabled', 'disabled');
            $('#ddlOpenHoursStart').attr('disabled', 'disabled');
            $('#ddlOpenHoursEnd').attr('disabled', 'disabled');
            <%}%>
        }).change();        

        $('input.number').keypress(function (e) {
            if (e.which >= 48 && e.which <= 57) {
            }
            else if (e.which == 0 || e.which == 8 || e.which == 46) {
            }
            else
                e.preventDefault();
        });
        $('input.number').change(function (e) {
            $(this).val($(this).val().replace(/[^\d\.]/g, ''));
        });

        $('#ddlLimitType').change(function () {
            switch ($(this).val()) {
                case 'None':
                    $('#limit-amount').hide();
                    break;

                case 'SameForAllCurrency':
                    $('#limit-amount').show();
                    $('#base-limit-table').show();
                    $('#currency-limit-table').hide();
                    break;

                case 'SpecificForEachCurrency':
                    $('#limit-amount').show();
                    $('#base-limit-table').hide();
                    $('#currency-limit-table').show();
                    break;

                case 'AutoConvertBasingOnCurrencyRate':
                    $('#limit-amount').show();
                    $('#base-limit-table').show();
                    $('#currency-limit-table').hide();
                    break;
            }
        }).change();


        function getDateString(date) {
            return date.getMonth() + 1 + "/" + date.getDate() + "/" + date.getFullYear();
        }

        $('#newTable').click(function() {
            $('.newTableDatePicker').toggle(this.checked);
            var _d = new Date();
            if (this.checked) {
                _d.setDate(_d.getDate() + <%: ViewData["newStatusLiveCasinoGameExpirationDays"] %>);
        } else {
            _d.setDate(_d.getDate() - 1);
        }
            $('#newTableExpirationDate').val(getDateString(_d));
        });

        $('#newTableExpirationDate').attr("readonly", "readonly").datepicker({ minDate: 'today', showOn: "button", });

        $('#btnRevertToDefaultsLiveCasinoTable').button().click(function (e) {
            e.preventDefault();

            var options = {
                dataType: 'json',
                success: function (json) {
                    $('#loading').hide();
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    $(document).trigger('LIVE_CASINO_TABLE_CHANGED');
                    $.modal.close();
                }
            };
            
            if (!confirm('Are you sure you want to loose all changes and revert to defaults?')) {return;}

            $('#loading').show();
            $("#formRevertTable").ajaxSubmit(options);
        });
    });
</script>
