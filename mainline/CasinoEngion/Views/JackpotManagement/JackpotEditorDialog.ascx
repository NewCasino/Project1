<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<CE.db.ceCasinoJackpotBaseEx>" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Jackpot" %>
<%@ Import Namespace="CasinoEngine.Models" %>
<%@ Import Namespace="Newtonsoft.Json" %>

<script language="C#" type="text/C#" runat="server">
    private ceDomainConfig Domain { get; set; }

    protected override void OnInit(EventArgs e)
    {
        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        this.Domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
        base.OnInit(e);
    }

    private List<SelectListItem> GetVendors()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();

        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        this.Domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
        if (this.Domain != null && DomainManager.CurrentDomainID != Constant.SystemDomainID)
        {
            var allVendors = dda.GetAllVendorID();
            
            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            return cva.GetEnabledVendorList(DomainManager.CurrentDomainID, Constant.SystemDomainID)
                .Select(v => new SelectListItem()
                {
                    Text = allVendors.First(x => x.Key == (VendorID)v.VendorID).Value.ToString(),
                    Value = allVendors.First(x => x.Key == (VendorID)v.VendorID).Key.ToString(),
                    Selected = this.Model.VendorID == (VendorID)v.VendorID
                }).OrderBy(x => x.Text).ToList();
        }
        return dda.GetAllVendorID().Select(v => new SelectListItem()
        {
            Text = v.Value,
            Value = v.Key.ToString(),
            Selected = this.Model.VendorID == v.Key
        }).OrderBy(x => x.Text).ToList();
    }

    private List<SelectListItem> GetCurrencies()
    {
        return GamMatrixClient.GetSupportedCurrencies()
            .Select(c => new SelectListItem()
            {
                Text = c.Name,
                Value = c.ISO4217_Alpha,
                Selected = this.Model != null && this.Model.BaseCurrency == c.ISO4217_Alpha,
            }).ToList();
    }



    private List<SelectListItem> GetNetEntJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.NetEnt };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetNetEntJackpots(Constant.SystemDomainID)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetMicrogamingJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.Microgaming };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetMicrogamingJackpots()
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( £ {1:N0} )", j.Value.Name, j.Value.Amounts["GBP"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetCTXMJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.CTXM };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetCTXMJackpots(Constant.SystemDomainID)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetPlaynGOJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.PlaynGO };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetPlaynGOJackpots(Constant.SystemDomainID)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetIGTJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.IGT };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetIGTJackpots(Constant.SystemDomainID)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetBetSoftJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.BetSoft };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetBetSoftJackpots(this.Domain)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetSheriffJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.Sheriff };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetSheriffJackpots(this.Domain)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<SelectListItem> GetOMIJackpots()
    {
        VendorID[] filteredVendorIDs = { VendorID.OMI };
        List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(DomainManager.CurrentDomainID, filteredVendorIDs);

        return JackpotFeeds.GetOMIJackpots(this.Domain)
            .Where(j => !jackpots.Exists(j2 => j2.MappedJackpotID == j.Value.ID && (this.Model == null || this.Model.MappedJackpotID != j2.MappedJackpotID)))
            .Select(j => new SelectListItem()
            {
                Text = string.Format("{0} ( € {1:N0} )", j.Value.Name, j.Value.Amounts["EUR"]),
                Value = j.Key,
                Selected = this.Model != null && string.Equals(j.Key, this.Model.MappedJackpotID, StringComparison.OrdinalIgnoreCase)
            })
            .OrderBy(j => j.Text)
            .ToList();
    }

    private List<CustomVendorJackpotConfig> _customVendorConfigs { get; set; }

    private string _customErrorConfigText;

    private List<CustomVendorJackpotConfig> GetCustomVendorConfigs()
    {
        if (_customVendorConfigs == null)
        {
            try
            {
                _customVendorConfigs = JsonConvert.DeserializeObject<List<CustomVendorJackpotConfig>>(Model.CustomVendorConfig);

                if (_customVendorConfigs == null)
                {
                    _customVendorConfigs = new List<CustomVendorJackpotConfig>();
                }
            }
            catch (Exception ex)
            {
                _customErrorConfigText = ex.Message;

                _customVendorConfigs = new List<CustomVendorJackpotConfig>();
            }
        }

        return _customVendorConfigs;
    }
</script>

<style type="text/css">
    #ulAssignedGames {
        list-style-type: none;
        padding: 0px;
        margin: 0px;
    }

        #ulAssignedGames li {
            width: 45%;
            display: inline-block;
        }

    .assigned-games-wrapper {
        height: 500px;
        width: 100%;
        border: 1px solid #FFF;
        display: block;
        overflow: auto;
    }

    #btnSaveJackpot {
        float: right;
    }

    #tblJackpotVendorUrls{
        width:100%;
        border-collapse:collapse;
        border:1px solid white;
    }
    #tblJackpotVendorUrls thead{color: #B8EC79;}
    #tblJackpotVendorUrls tr{
        border-bottom:1px solid white;
    }
        #tblJackpotVendorUrls td,#tblJackpotVendorUrls th {
            border-right:1px solid white;
        }

    #lnkLoadCustomJackpots{float:right;}
    #lnkLoadCustomJackpotsValidator{float:left;}
    p {clear:both;}
    .hidden{display:none;}
    .load-custom-jackpots{background-repeat: no-repeat;padding-left: 16px;background-position: 0 1px;}
    .load-custom-jackpots.busy{background-image: url(/images/loading.icon.gif);}
</style>


<form id="formRegisterJackpot" method="post" enctype="application/x-www-form-urlencoded"
    action="<%= this.Url.ActionEx("SaveJackpot").SafeHtmlEncode() %>" style="height: 100%">

    <table cellpadding="0" cellspacing="0" border="0" style="width: 100%; table-layout: fixed;">
        <tr>
            <td valign="top">
                <input type="hidden" id="CustomVendorConfig" name="CustomVendorConfig" value="" />
                <p>
                    <%: Html.HiddenFor(m => m.BaseID)%>
                    <%: Html.HiddenFor(m => m.JackpotID)%>
                    <%: Html.TextBoxFor(m => m.Name, new { @class = "textbox required", @autocomplete = "off", @maxlength = "50", @id = "txtJackpotName" })%>
                </p>
                <p>
                    <label class="label">Vendor: </label>
                    <%: Html.DropDownListFor(m => m.VendorID, GetVendors(), new { @class = "ddl required", @id = "ddlVendor" })%>
                    <%: Html.HiddenFor(m => m.ID)%>
                </p>
                <p id="pMappedJackpotID">
                    <label class="label">Mapping Jackpot (all operators): <em>*</em></label>
                    <%: Html.DropDownList("netentJackpotID", GetNetEntJackpots(), new { @class = "ddl", @id = "ddlNetEntJackpot" })%>
                    <%: Html.DropDownList("microgamingJackpotID", GetMicrogamingJackpots(), new { @class = "ddl", @id = "ddlMicrogamingJackpot" })%>
                    <%: Html.DropDownList("ctxmJackpotID", GetCTXMJackpots(), new { @class = "ddl", @id = "ddlCTXMJackpot" })%>
                    <%: Html.DropDownList("playngoJackpotID", GetPlaynGOJackpots(), new { @class = "ddl", @id = "ddlPlaynGOJackpot" })%>
                    <%: Html.DropDownList("igtJackpotID", GetIGTJackpots(), new { @class = "ddl", @id = "ddlIGTJackpot" })%>
                    <%: Html.DropDownList("betsoftJackpotID", GetBetSoftJackpots(), new { @class = "ddl", @id = "ddlBetSoftJackpot" })%>
                    <%: Html.DropDownList("sheriffJackpotID", GetSheriffJackpots(), new { @class = "ddl", @id = "ddlSheriffJackpot" })%>
                    <%: Html.DropDownList("omiJackpotID", GetOMIJackpots(), new { @class = "ddl", @id = "ddlOMIJackpot" })%>
                    <%: Html.HiddenFor(m => m.MappedJackpotID, new { @id = "hMappedJackpotID" })%>
                </p>
                <div id="customVendorConfigContainer">
                    <fieldset>
                        <legend>Custom Vendor Config</legend>
                        <p>
                            <label class="label">Operator: </label>
                            <select id="ddlNewJackpotOperators"></select>
                        </p>
                        <p>
                            <label class="label">Jackpot Url: <em>*</em></label>
                            <input type="text" id="txtCustomJackpotUrl" class="textbox" />
                            <a id="lnkLoadCustomJackpots" class="load-custom-jackpots" href="javascript:void(0);">Load</a>
                            <label for="ddlNewJackpotOperators" class="hidden lnkLoadCustomJackpotsValidator">This field is required.</label>
                        </p>
                        <p>
                            <label class="label">Mapping Jackpot: <em>*</em></label>
                            <select id="ddlCustomMappingJackpot" style="min-width: 100px;"></select>
                            <label for="ddlCustomMappingJackpot" class="hidden ddlCustomMappingJackpotValidator">This field is required.</label>
                        </p>
                        <p>
                            <input type="button" value="Add" id="btnAddNewJackpotVendorUrl" />
                        </p>
                    </fieldset>
                </div>
            </td>
            <td valign="top">
                <label class="label">Assigned Games: </label>
                <div class="assigned-games-wrapper">
                    <ul id="ulAssignedGames">
                        <%
                            List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(Constant.SystemDomainID)
                                .OrderBy(g => g.ShortName)
                                .ToList();
                            foreach (ceCasinoGameBaseEx game in games)
                            {
                        %>
                        <li vendor="<%= game.VendorID %>">
                            <input type="checkbox" id="btnJackpotGame_<%= game.ID %>" value="<%= game.ID %>" />
                            <label for="btnJackpotGame_<%= game.ID %>"><%= game.ShortName.SafeHtmlEncode() %></label>
                        </li>
                        <%
                            }
                        %>
                    </ul>
                </div>
                <%: Html.HiddenFor( m => m.GameIDs, new { @id = "hGameIDs" }) %>
                <script type="text/javascript">
                    $(function () {
                        initCustomVendorConfigVisibility();

                        var collectGameIDs = function () {
                            var gameIDs = ',';
                            var $checkboxes = $('#ulAssignedGames > li:visible > :checked');
                            for (var i = 0; i < $checkboxes.length; i++) {
                                gameIDs = gameIDs + $($checkboxes[i]).val() + ',';
                            }
                            $('#hGameIDs').val(gameIDs);
                        };

                        var ddlVendorLastSelected = $('#ddlVendor option:selected');

                        $('#ulAssignedGames :input[type="checkbox"]').click(collectGameIDs);
                        $('#ddlVendor').change(function () {
                            var customJackpots = $('#tblJackpotVendorUrls tbody tr');

                            if (customJackpots.length < 1 || confirm('All data in Custom Jackpots Configuration Table will be deleted. Are you sure?')) {
                                $('#ddlCustomMappingJackpot option').remove();
                                customJackpots.remove();

                                initCustomVendorConfigVisibility();

                                setTimeout(collectGameIDs, 500);
                            } else {
                                ddlVendorLastSelected.attr('selected', true);
                            }
                        });

                        $('#ddlVendor').click(function () {
                            ddlVendorLastSelected = $('#ddlVendor option:selected');
                        });

                        // <%-- Initialize the checkbox --%>
                        $('#ulAssignedGames :input[type="checkbox"]').attr('checked', false);
                        var gameIDs = $('#hGameIDs').val().split(',');
                        for (var i = 0; i < gameIDs.length; i++) {
                            if (gameIDs[i].length == 0)
                                continue;
                            $('#ulAssignedGames :input[value="' + gameIDs[i] + '"]').attr('checked', true);
                        }
                    });

                    function initCustomVendorConfigVisibility() {
                        var supportedCustomVendors = ['Microgaming', 'PlaynGO', 'IGT', 'BetSoft'];

                        if (supportedCustomVendors.indexOf($('#ddlVendor').val()) < 0) {
                            $('#tblJackpotVendorUrls').hide();
                            $('#customVendorConfigContainer').hide();
                        } else {
                            $('#tblJackpotVendorUrls').show();
                            $('#customVendorConfigContainer').show();
                        }
                    }
                </script>
                <br />
                <% if(DomainManager.AllowEdit()) { %>
                <button type="submit" id="btnSaveJackpot">Save</button>
                <% } %>
            </td>
        </tr>
    </table>
    <div>
        <div><%= _customErrorConfigText %></div>
        <table id="tblJackpotVendorUrls">
            <thead>
                <tr>
                    <th>Operator</th>
                    <th>Jackpot Url</th>
                    <th>Mapping Jackpot</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                <% foreach (var item in GetCustomVendorConfigs())
                   { %>
                <tr>
                    <td class="tdOperatorId" data-operatorid="<%= item.OperatorId %>">
                        <%= item.OperatorName %>
                    </td>
                    <td>
                        <div style="word-break: break-all;"><%= item.Url %></div>
                    </td>
                    <td data-jackpotid="<%= item.MappedJackpotID %>">
                        <%= item.MappedJackpotText %>
                    </td>
                    <td>
                        <input type="button" value="Delete" class="btnDeleteCustomVendorConfig" />
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <input type="hidden" id="CustomVendorConfig" name="CustomVendorConfig" value="" />
</form>

<script type="text/javascript">
    $(function () {
        var handler = function () {
            var vendor = $('#ddlVendor').val();
            $('#ddlNetEntJackpot').css('display', (vendor == 'NetEnt' ? '' : 'none'));
            $('#ddlMicrogamingJackpot').css('display', (vendor == 'Microgaming' ? '' : 'none'));
            $('#ddlCTXMJackpot').css('display', (vendor == 'CTXM' ? '' : 'none'));
            $('#ddlPlaynGOJackpot').css('display', (vendor == 'PlaynGO' ? '' : 'none'));
            $('#ddlIGTJackpot').css('display', (vendor == 'IGT' ? '' : 'none'));
            $('#ddlBetSoftJackpot').css('display', (vendor == 'BetSoft' ? '' : 'none'));
            $('#ddlSheriffJackpot').css('display', (vendor == 'Sheriff' ? '' : 'none'));
            $('#ddlOMIJackpot').css('display', (vendor == 'OMI' ? '' : 'none'));

            // <%-- adjust the games --%>
            $('#ulAssignedGames li').hide();
            $('#ulAssignedGames li[vendor="' + vendor + '"]').show();
        };

        $('#ddlVendor').change(handler);
        handler();

        initOperators();

        function initOperators() {
            var savedOperatorIds = [];

            $('.tdOperatorId').each(function (index, item) {
                savedOperatorIds.push($(item).attr('data-operatorid'));
            });

            // var selectedOperator = $('#ddlOperator option:selected');

            //if (selectedOperator.val() == "1000") {
                $('#ddlOperator option').each(function (index, item) {
                    if (index > 0 && savedOperatorIds.indexOf($(item).attr('value')) < 0) {
                        $('#ddlNewJackpotOperators').append($(item).clone());
                    }
                });
            /*} else {
                $('#ddlNewJackpotOperators').append(selectedOperator.clone());

                $('#tblJackpotVendorUrls tbody tr').each(function (index, item) {
                    var $item = $(item);

                    if ($item.find('td:first').attr('data-operatorid') != selectedOperator.val()) {
                        $item.hide();
                    }
                });
            }*/

            $('#btnAddNewJackpotVendorUrl').click(function () {
                var selectedOperator = $('#ddlNewJackpotOperators option:selected');
                var operatorName = selectedOperator.text();
                var operatorId = selectedOperator.val();
                var customSelectedOption = $('#ddlCustomMappingJackpot option:selected');
                var url = $('#txtCustomJackpotUrl').val();

                if (url.length == 0) {
                    $('.lnkLoadCustomJackpotsValidator').addClass('error');
                    return;
                } else {
                    $('.lnkLoadCustomJackpotsValidator').removeClass('error');
                }

                if (!customSelectedOption[0] || customSelectedOption.val().length == 0) {
                    $('.ddlCustomMappingJackpotValidator').addClass('error');
                    return;
                } else {
                    $('.ddlCustomMappingJackpotValidator').removeClass('error');
                }

                $('#tblJackpotVendorUrls tbody').append(
                    $('<tr/>').append(
                        $('<td class="tdOperatorId"/>').text(operatorName).attr('data-operatorid', operatorId)
                    ).append(
                        $('<td/>').append(
                            $('<div style="word-break: break-all;"/>').text(url)
                        )
                    ).append(
                        $('<td/>').attr('data-jackpotid', customSelectedOption.val()).text(customSelectedOption.text())
                    ).append(
                        $('<td/>').append(
                            $('<input type="button" value="Delete" class="btnDeleteCustomVendorConfig"/>').click(function () {
                                $('#ddlNewJackpotOperators').append(
                                    $('<option/>').text(operatorName).val(operatorId)
                                );

                                $(this).closest('tr').remove();
                            })
                        )
                    )
                );

                $('#ddlNewJackpotOperators option:selected').remove();
            });

            $('.btnDeleteCustomVendorConfig').click(function () {
                var tr = $(this).closest('tr');
                var tds = tr.find('td');

                $('#ddlNewJackpotOperators').append(
                    $('<option/>').text($(tds[0]).text()).val($(tds[0]).attr('data-operatorid'))
                );

                tr.remove();
            });

            $('#lnkLoadCustomJackpots').click(function () {
                var vendorId = $('#ddlVendor').val();
                var url = $('#txtCustomJackpotUrl').val();

                if (url.length == 0) {
                    return;
                }

                var item = $(this);

                item.addClass('busy');
                $('#ddlCustomMappingJackpot option').remove();

                var jackpotManagementUrl = '<%= this.Url.ActionEx("LoadCustomJackpots").SafeJavascriptStringEncode() %>';

                $.post(jackpotManagementUrl,
                    { vendorId: vendorId, url: url },
                    function (data) {
                        if (data.success) {
                            $('#ddlCustomMappingJackpot option').remove();

                            for (var i = 0; i < data.Data.length; i++) {
                                $('#ddlCustomMappingJackpot').append(
                                    $('<option/>').text(data.Data[i].Text).val(data.Data[i].Value)
                                );
                            }
                        } else {
                            alert('Error');
                        }
                    }, "json")
                    .fail(function () {
                        alert('Error');
                    })
                    .always(function () {
                        item.removeClass('busy');
                    });
            });
        }
    });
</script>

<script type="text/javascript">
    $(function () {
        $("#formRegisterJackpot").validate({
            rules: {
                netentJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'NetEnt') {
                            $('#hMappedJackpotID').val($('#ddlNetEntJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                ctxmJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'CTXM') {
                            $('#hMappedJackpotID').val($('#ddlCTXMJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                microgamingJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'Microgaming') {
                            $('#hMappedJackpotID').val($('#ddlMicrogamingJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                playngoJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'PlaynGO') {
                            $('#hMappedJackpotID').val($('#ddlPlaynGOJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                igtJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'IGT') {
                            $('#hMappedJackpotID').val($('#ddlIGTJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                betsoftJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'BetSoft') {
                            $('#hMappedJackpotID').val($('#ddlBetSoftJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                sheriffJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'Sheriff') {
                            $('#hMappedJackpotID').val($('#ddlSheriffJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                },
                omiJackpotID: {
                    required: function (value) {
                        if ($('#ddlVendor').val() == 'OMI') {
                            $('#hMappedJackpotID').val($('#ddlOMIJackpot').val());
                            return $('#hMappedJackpotID').val().length == 0;
                        }
                        return false;
                    }
                }
            }
        });

        $('#btnSaveJackpot').button({
            icons: {
                primary: "ui-icon-disk"
            }
        }).click(function (e) {
            e.preventDefault();
            if (!$("#formRegisterJackpot").valid()) {
                return;
            }

            var customJackpotConfigs = [];

            $('#tblJackpotVendorUrls tbody tr').each(function (index, item) {
                var tds = $(item).find('td');

                customJackpotConfigs.push(
                    {
                        Url: $('div', tds[1]).text(),
                        OperatorId: parseInt($(tds[0]).attr('data-operatorid')),
                        OperatorName: $(tds[0]).text(),
                        MappedJackpotID: $(tds[2]).attr('data-jackpotid'),
                        MappedJackpotText: $(tds[2]).text()
                    });
            });

            $('#CustomVendorConfig').val(JSON.stringify(customJackpotConfigs));

            $('#loading').show();
            var options = {
                dataType: 'json',
                success: function (json) {
                    $('#loading').hide();
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    $('#btnSearchJackpots').trigger('click');
                    $('#dlgJackpotRegistration').dialog('close');
                }
            };
            $("#formRegisterJackpot").ajaxSubmit(options);
        });
    });
</script>
