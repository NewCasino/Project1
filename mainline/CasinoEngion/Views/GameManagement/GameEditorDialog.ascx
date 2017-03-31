<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.Extensions" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private bool ShowThumbnail { get; set; }
    private bool ShowScalableThumbnail { get; set; }

    private int ScalableThumbnailWidth { get; set; }
    private int ScalableThumbnailHeight { get; set; }

    private List<ceCasinoGame> GameOverrides { get; set; }
    private List<ceDomainConfigEx> Domains { get; set; }
    
    protected override void OnInit(EventArgs e)
    {
        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        ceDomainConfigEx domain = dca.GetByDomainID(DomainManager.CurrentDomainID);

        ScalableThumbnailWidth = domain.ScalableThumbnailWidth == 0 ? 376 : domain.ScalableThumbnailWidth;
        ScalableThumbnailHeight = domain.ScalableThumbnailHeight == 0 ? 250 : domain.ScalableThumbnailHeight;
        
        if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
        {
            ShowThumbnail = true;
            ShowScalableThumbnail = true;
        }
        else
        {
            ShowThumbnail = !domain.EnableScalableThumbnail;
            ShowScalableThumbnail = domain.EnableScalableThumbnail;
        }

        GameOverrides = CasinoGameAccessor.GetGameOverrides(this.Model.ID);
        Domains = dca.GetAll(CurrentUserSession.ShowInactiveDomains ? ActiveStatus.InActive : ActiveStatus.Active);
        base.OnInit(e);
    }

    private List<SelectListItem> GetInvoicingGroup()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllInvoicingGroup().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key.ToString() }).OrderBy(x => x.Text).ToList();
    }

    private List<SelectListItem> GetReportCategory()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllReportCategory().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key.ToString() }).OrderBy(x => x.Text).ToList();
    }

    private List<SelectListItem> GetLicenseList()
    {
        Array values = Enum.GetValues(typeof(LicenseType));
        List<SelectListItem> list = new List<SelectListItem>();
        foreach (object value in values)
        {
            list.Add( new SelectListItem()
            {
                Text = Enum.GetName(typeof(LicenseType), value),
                Value = value.ToString(),
            });
        }

        return list;
    }

    private List<SelectListItem> GetVendors()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        
        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        var domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
        if (domain != null && domain.DomainID != Constant.SystemDomainID )
        {
            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            return cva.GetEnabledVendorList(DomainManager.CurrentDomainID, Constant.SystemDomainID)
                .Select(v => new SelectListItem()
                {
                    Text = ((VendorID)v.VendorID).ToString(),
                    Value = ((VendorID)v.VendorID).ToString(),
                    Selected = (int)this.Model.VendorID == v.VendorID
                }).OrderBy(x => x.Text).ToList();
        }
        return dda.GetAllVendorID().Select(v => new SelectListItem()
        {
            Text = v.Value,
            Value = v.Key.ToString(),
            Selected = this.Model.VendorID == v.Key
        }).OrderBy(x => x.Text).ToList();
    }

    private List<SelectListItem> GetOriginalVendors()
    {
        VendorID[] vendors = new VendorID[] { 
            VendorID.NetEnt, VendorID.Microgaming, VendorID.CTXM, VendorID.IGT, VendorID.GreenTube,
            VendorID.NYXGaming, VendorID.BetSoft, VendorID.Sheriff, VendorID.OMI, VendorID.XProGaming,
            VendorID.EvolutionGaming, VendorID.BallyGaming, VendorID.Aristocrats, VendorID.Cryptologic, 
            VendorID.ELK, VendorID.iGaming2Go, VendorID.NextGen, VendorID.Williams
        };
        
        var selectVendors = vendors.Select(v => new SelectListItem()
                {
                    Text = v.ToString(),
                    Value = v.ToString(),
                    Selected = this.Model.OriginalVendorID == v
                }).OrderBy(x => x.Text).ToList();
        
        selectVendors.Insert(0, new SelectListItem
        {
            Text = VendorID.Unknown.ToString(),
            Value = VendorID.Unknown.ToString(),
            Selected = this.Model.OriginalVendorID == VendorID.Unknown
        });

        return selectVendors;
    }

    private List<SelectListItem> GetContentProviders()
    {
        List<ceContentProviderBase> list = ContentProviderAccessor.GetAll(DomainManager.CurrentDomainID, Constant.SystemDomainID);

        return list.Select(p => new SelectListItem()
        {
            Text = p.Name,
            Value = p.ID.ToString(),
            Selected = this.Model.ContentProviderID == p.ID
        }).OrderBy(x => x.Text).ToList();
    }

    public Dictionary<string, string> GetGameCategories()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllGameCategory();
    }

    public Dictionary<string, string> GetClientTypes()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        return dda.GetAllClientType();
    }


    private List<SelectListItem> GetCountries()
    {
        LocationAccessor la = LocationAccessor.CreateInstance<LocationAccessor>();
        return la.GetCountries().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key }).ToList();
    }

    private List<SelectListItem> GetSpinLines()
    {
        List<int> list = this.Model.GetSpinLines();
        if (list != null && list.Count > 0)
        {
            return list.Select(i => new SelectListItem() { Text = i.ToString(), Value = i.ToString() }).ToList();
        }
        return new List<SelectListItem>();
    }

    private List<SelectListItem> GetSpinCoins()
    {
        List<int> list = this.Model.GetSpinCoins();
        if (list != null && list.Count > 0)
        {
            return list.Select(i => new SelectListItem() { Text = i.ToString(), Value = i.ToString() }).ToList();
        }
        return new List<SelectListItem>();
    }
    
    private List<SelectListItem> GetSpinDenominations()
    {
        List<float> list = this.Model.GetSpinDenominations();
        if (list != null && list.Count > 0)
        {
            return list.Select(i => new SelectListItem() { Text = i.ToString(), Value = i.ToString() }).ToList();
        }
        return new List<SelectListItem>();
    }

    private string GetBackgroundImage()
    {
        if (string.IsNullOrEmpty(this.Model.BackgroundImage))
            return "//cdn.everymatrix.com/images/placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , this.Model.BackgroundImage
            );
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

    private string GetLogoImage()
    {
        if (string.IsNullOrEmpty(this.Model.Logo))
            return "//cdn.everymatrix.com/images/logo_placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , this.Model.Logo
            );
    }

    private string GetIconImage()
    {
        if (string.IsNullOrEmpty(this.Model.Icon))
            return "//cdn.everymatrix.com/images/logo_placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , string.Format( this.Model.Icon, 114)
            );
    }

    private string GetScalableThumbnailImage()
    {
        if (string.IsNullOrEmpty(this.Model.ScalableThumbnail))
            return "//cdn.everymatrix.com/images/placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , this.Model.ScalableThumbnailPath
            );
    }
    private List<SelectListItem> GetCurrencyList()
    {
        List<SelectListItem> list = GamMatrixClient.GetSupportedCurrencies().Select(c => new SelectListItem() { Text = string.Format("{0} - {1}", c.ISO4217_Alpha, c.Name), Value = c.ISO4217_Alpha }).ToList();

        //SelectListItem selected = list.FirstOrDefault(i => i.Value == this.Model.Limit.BaseCurrency);
        //if (selected != null)
            //selected.Selected = true;

        return list;
    }
</script>

<style type="text/css">
#ddlRestrictedTerritories { width:100%; height:100%; }
.ul-languages { margin:0px; padding:0px; list-style-type:none; }
.ul-languages li { display:inline-block; width:100px; }
#pExtraParam1 { display:none; }
#pExtraParam2 { display:none; }
#dlgRestrictedTerritories ul { list-style-type:none; margin:0px; padding:0px; }
#dlgRestrictedTerritories li { list-style-type:none; margin:0px; }
#dlgRestrictedTerritories li.Checked { background-color:Yellow; }
#dlgRestrictedTerritories li.Checked label { color:red; font-weight:bold; }

table.format-table tbody td { height:30px; }
table.format-table .col-1 select { margin-right:15px; }
table.format-table input { width:70px; text-align:right; margin:0px 5px; }

#game-editor-tabs .LeftColumn { width:49%; float:left; }
#game-editor-tabs .RightColumn { width:49%; float:left; }
#game-editor-tabs .Clear { clear:both; }
#game-editor-tabs .ui-tabs-panel { height: 520px; overflow: auto; }

.date-inputbox{text-align:center;width: 80px;background: #acacac;}

#btnRevertDeleteGame { float: left;margin-right: 25px;}
</style>


<form id="formRegisterGame" target="ifmRegisterGame" method="post" enctype="multipart/form-data"
    action="<%= this.Url.ActionEx("SaveGame").SafeHtmlEncode() %>">

    <div id="game-editor-tabs">
        <ul>
            <li><a href="#tabs-1">Basic</a></li>
            <li><a href="#tabs-2">Advanced</a></li>
            <li><a href="#tabs-3">Assets</a></li>
            <li><a href="#tabs-4">Restricted Territories</a></li>
            <li><a href="#tabs-5">Languages</a></li>
            <%if(!string.IsNullOrEmpty(this.Model.GameID)){
                  if (DomainManager.CurrentDomainID == Constant.SystemDomainID && GameOverrides.Count > 0)
                  { %>
                    <li><a href="#tabs-6"><%= GameOverrides.Count %> Overrides</a></li>
            <%    }
              } %>
        </ul>
        <div id="tabs-1">
            <%-------------------------
                Tab - Basic - Start
             ---------------------------%>
             <div class="LeftColumn">
                <p>
                    <label class="label">Vendor: <em>*</em></label>
            
                    <%: Html.DropDownListFor(m => m.VendorID, GetVendors(), new { @class = "ddl", @id = "ddlVendor" })%>
                    <%: Html.HiddenFor(m => m.ID)%>
                </p>
                 <p>
                    <label class="label">Content Provider: <em>*</em></label>
                    <%: Html.DropDownListFor(m => m.ContentProviderID, GetContentProviders(), new { @class = "ddl required", @id = "ddlContentProviderID" })%>
                </p>
                <p>
                    <label class="label">Vendor Game ID: <em>*</em></label>

                    <%: Html.TextBox("inputGameID", this.Model.GameID, new { @id = "txtInputGameID", @class = "textbox" })%>
                    <%: Html.HiddenFor(m => m.GameID, new { @autocomplete = "off", @maxlength = "30", @id = "txtGameID" })%>
                </p>                
                <% CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                   Dictionary<VendorID, string> vendors = cva.GetLanguagesDictionary(DomainManager.CurrentDomainID);
                   foreach (var item in vendors)
                   {%>
                 <input type="hidden" name="Languages_<%= ((VendorID)item.Key).ToString() %>" id="Languages_<%= ((VendorID)item.Key).ToString() %>" 
                                value="<%= item.Value.SafeHtmlEncode() %>" />
                 <%  } %>
                <script type="text/javascript">
                    $(function () {
                        $('#ddlVendor').change(function (e) {
                            var vendor = $(this).val();
                            $('#txtInputGameID').show();
                            $('#pGameLaunchIdentifying').hide();
                            $('#pGetActiveTablesCode').hide();
                            $('#pExternalGameName').hide();
                            $('#pDefaultCoin').hide();
                            var vendorLanguages = document.getElementById("Languages_"+vendor).value;
                            
                            if (vendorLanguages == '') {
                                $('#btnLanguage_all').attr('checked', true);
                                $('ul.ul-languages :checkbox[value!="All"]').attr('checked', false).parent('li').hide();
                            } else {
                                $('ul.ul-languages :checkbox').attr('checked', false);
                                var languages = vendorLanguages.split(',');
                                for (var i = 0; i < languages.length; i++) {
                                    $('ul.ul-languages :checkbox[value="' + languages[i] + '"]').attr('checked', true);
                                }
                                $('ul.ul-languages :checkbox[value!="All"]').parent('li').show();
                            }

                            switch(vendor)
                            {
                                case 'Microgaming':
                                case 'PlaynGO':
                                case 'Sheriff':
                                case 'TTG':
                                case 'OMI':
                                case 'EvolutionGaming':
                                case 'Ezugi':
                                case 'GoldenRace':
                                {
                                    $('#pExternalGameName').show();
                                    break;
                                }
                                case 'ISoftBet':
                                {
                                    $('#pExternalGameName').show();
                                    $('#pDefaultCoin').show();
                                    break;
                                }
                                case 'Vivo':
                                {
                                    $('#pGetActiveTablesCode').show();
                                    $('#pGameLaunchIdentifying').show();
                                    $('#pExternalGameName').show();
                                    break;
                                }
                                case 'WorldMatch':
                                {
                                    $('#pGameLaunchIdentifying .label').text("Configuration ID:");
                                    $('#pGameLaunchIdentifying').show();

                                    $('#pGetActiveTablesCode .label').text("Licensee ID:");
                                    $('#pGetActiveTablesCode').show();
                                    break;
                                }
                                default:
                                {
                                    break;
                                }
                            }
                        }).trigger('change');

                        <% 
                        if( string.IsNullOrWhiteSpace(this.Model.GameID) )
                        { %>
                            setTimeout( function() { $('#ddlVendor').trigger('change'); }, 500);
                        <% } %>
                    });
                    
                </script>

                <p id="pExternalGameName">
                    <label class="label">Game Code: </label>
                    <%: Html.TextBoxFor(m => m.GameCode, new { @class = "textbox required", @autocomplete = "off", @maxlength = "50", @id = "txtGameCode" })%>
                </p>

                <p id="pGameLaunchIdentifying">
                    <label class="label">Launch Identifying: </label>
                    <%: Html.TextBoxFor(m => m.ExtraParameter1, new { @class = "textbox required", @autocomplete = "off", @maxlength = "50", @id = "txtExtraParameter1" })%>
                </p>
                <p id="pGetActiveTablesCode">
                    <label class="label">Code For Get Tables: </label>
                    <%: Html.TextBoxFor(m => m.ExtraParameter2, new { @class = "textbox required", @autocomplete = "off", @maxlength = "50", @id = "txtExtraParameter2" })%>
                </p>

                <p>
                    <label class="label">Name: <em>*</em></label>
                    <%: Html.TextBoxFor(m => m.GameName, new { @class = "textbox required", @autocomplete = "off", @maxlength = "50", @id = "txtGameName" })%>
                </p>
                <p>
                    <label class="label">Short name: <em>*</em></label>
                    <%: Html.TextBoxFor(m => m.ShortName, new { @class = "textbox required", @autocomplete = "off", @maxlength = "50", @id = "txtGameShortName" })%>
                </p>
                <p>
                    <label class="label" title="only accept alphanumeric charactor plus '_' and '-' .">Slug: </label>
                    <%: Html.TextBoxFor(m => m.Slug, new { @class = "textbox", @autocomplete = "off", @maxlength = "200", @id = "txtSlug", @title = "only accept alphanumeric charactor plus '_' and '-' ." })%>
                </p>
                <script type="text/javascript">
                    $(function () {
                        var fun = function () {
                            var slug = $('#txtSlug').val();
                            var regex = /[^a-z_\-\d]/gi;
                            slug = slug.replace(regex, '-');
                            $('#txtSlug').val(slug.toLowerCase());
                        };
                        $('#txtSlug').change(fun).blur(fun).click(fun);

                        $('#txtSlug').keypress(function (e) {
                            if ((e.which >= 48 && e.which <= 57) ||
                                (e.which >= 97 && e.which <= 122) ||
                                e.which == 95 || e.which == 45 ||
                                e.which == 8 || e.which == 0) {
                            }
                            else {
                                e.preventDefault();
                            }
                        });
                    });
                </script>

                <p>
                    <div class="label">
                        <span>Description (plain text) :</span>
                        <% if (this.Model.ID > 0)
                           { %>
                        <button type="button" class="translation-description" data-url="<%= this.Url.ActionEx("EditGameTranslation", new { @id = this.Model.ID, @propertyName = "description" }).SafeHtmlEncode() %>"">...</button>
                        <% } %>
                    </div>
                    <%: Html.TextAreaFor(m => m.Description, new { @class = "textarea", @style="width:300px; height:100px;",  @autocomplete = "off", @maxlength = "1024", @id = "txtGameDesc" })%>
                    <script type="text/javascript">
                        $(function () {
                            $('.translation-description').click(function (e){
                                e.preventDefault();
                                var url = $(this).data('url');
                                window.open(url, "gameinformation", "menubar=false,location=false,resizable=yes,scrollbars=yes,status=yes");
                            });
                        });
                    </script>
                </p>
             </div>
             <div class="RightColumn">
                
                <%-----------------------
                    >>> CATEGORIES
                 -----------------------%>
                <label class="label">Category : </label>
                <ul>
                <%
                    var categories = GetGameCategories();
                    foreach (var category in categories)
                    {
                        string controlID = string.Format("btnGameCategory_{0}", category.Key); 
                        %>
                    <li style="display:inline-block; width:49%">
                    <%: Html.CheckBox("gameCategory", false, new { @id = controlID, @value = category.Key })%>
                    <label for="<%= controlID.SafeHtmlEncode() %>"><%= category.Value.SafeHtmlEncode()%></label>
                    </li>
                <% } %>
                </ul>
                <%: Html.HiddenFor(m => m.GameCategories, new { @id = "hGameCategories" })%>
                <script type="text/javascript">
                    $(function () {
                        // <%-- game category --%>
                        $('#formRegisterGame :checkbox[name="gameCategory"]').click(function (e) {
                            var $checkedItems = $('#formRegisterGame :checked[name="gameCategory"]');
                            var gameCategories = ',';
                            for (var i = 0; i < $checkedItems.length; i++) {
                                gameCategories = gameCategories + $($checkedItems[i]).val() + ',';
                            }
                            $('#hGameCategories').val(gameCategories);
                        });
                        var $items = $('#formRegisterGame :checkbox[name="gameCategory"]');
                        for (var i = 0; i < $items.length; i++) {
                            var $item = $($items[i]);
                            var strToFind = ',' + $item.val() + ',';
                            if ($('#hGameCategories').val().indexOf(strToFind) >= 0)
                                $item.attr('checked', true);
                        }
                    });
                </script>

                <%-----------------------
                    >>> ClientCompatibility 
                 -----------------------%>
                <label class="label">Client compatibility : </label>
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
                <%: Html.HiddenFor(m => m.ClientCompatibility, new { @id = "hClientCompatibility" })%>

                <%-----------------------
                    >>> Options 
                 -----------------------%>
                <label class="label"> Options :</label>
                <ul>
                    <li style="display:inline-block; width:49%">
                        <%= Html.CheckBoxFor(m => m.FunMode, new { @id = "funMode" })%>
                        <label for="funMode">Enable Fun Mode</label>
                    </li>
                    <li style="display:inline-block; width:49%">
                        <%= Html.CheckBoxFor(m => m.AnonymousFunMode, new { @id = "anonymousFunMode" })%>
                        <label for="anonymousFunMode">Anonymous Fun Mode</label>
                    </li>
                    <li style="display:inline-block; width:49%">
                        <%= Html.CheckBoxFor(m => m.RealMode, new { @id = "realMode" })%>
                        <label for="realMode">Enable Real Mode</label>
                    </li>
                    <li style="display:inline-block; width:98%">
                        <%= Html.CheckBoxFor(m => m.NewGame, new { @id = "newGame" })%>
                        <label for="newGame">Is New Game</label>
                        <div class="newGameDatePicker" style="<%= this.Model.NewGame ? "display:inline;" : "display:none;" %>">
                            <span>&nbsp;till</span> <input class="date-inputbox" type="text" id="newGameExpirationDate" name="newGameExpirationDate" value="<%=this.Model.NewGameExpirationDate.ToShortDateString() %>" />
                        </div>
                    </li>
                    <li style="display:inline-block; width:98%">
                        <%= Html.CheckBoxFor(m => m.ExcludeFromBonuses, new { @id = "excludeFromBonuses" })%>                        
                        <label for="excludeFromBonuses">Exclude from Bonuses</label>
                        <%if (CurrentUserSession.UserDomainID == Constant.SystemDomainID) { %>
                        (<%= Html.CheckBoxFor(m => m.ExcludeFromBonuses_EditableByOperator, new { @id = "excludeFromBonuses_EditableByOperator" })%>
                        <label for="excludeFromBonuses_EditableByOperator">Editable by Operator</label>)
                        <%} %>
                    </li>
                </ul>
                <script type="text/javascript">
                    $(function () {
                        // <%-- ClientCompatibility --%>
                        $('#formRegisterGame :checkbox[name="clientType"]').click(function (e) {
                            var $checkedItems = $('#formRegisterGame :checked[name="clientType"]');
                            var clientCompatibility = ',';
                            for (var i = 0; i < $checkedItems.length; i++) {
                                clientCompatibility = clientCompatibility + $($checkedItems[i]).val() + ',';
                            }
                            $('#hClientCompatibility').val(clientCompatibility);
                        });
                        var $items = $('#formRegisterGame :checkbox[name="clientType"]');
                        for (var i = 0; i < $items.length; i++) {
                            var $item = $($items[i]);
                            var strToFind = ',' + $item.val() + ',';
                            if ($('#hClientCompatibility').val().indexOf(strToFind) >= 0)
                                $item.attr('checked', true);
                        }

                    });
                </script>

                <p>
                    <label class="label" style="display:inline-block; width:150px;">FPP :</label>
                    <%: Html.TextBoxFor(m => m.FPP, new { @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:50px" })%>
                    %
                </p>
                <p>
                    <label class="label" style="display:inline-block; width:150px;">Bonus Contribution :</label>
                    <%: Html.TextBoxFor(m => m.BonusContribution, new { @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:50px" })%>
                    %
                </p>
                <p>
                    <label class="label" style="display:inline-block; width:150px;">Popularity Coefficient :</label>
                    <%: Html.TextBoxFor(m => m.PopularityCoefficient, new { @id = "popularityCoefficient", @class = "textbox required number", @autocomplete = "off", @maxlength = "8", @style = "text-align:right; width:50px" })%>
                </p>
                <%-----------------------
                    >>> Width & Height
                 -----------------------%>
                <p style="display:inline-block; width:49%;">
                    <label class="label" style="display:inline">Width :</label>
                    <%: Html.TextBoxFor(m => m.Width, new { @id="txtWidth", @class = "textbox required digits", @autocomplete = "off", @maxlength = "5", @style = "text-align:right; width:40px" })%>
                    px
                </p>
                <p style="display:inline-block; width:49%;">
                    <label class="label" style="display:inline">Height :</label>
                    <%: Html.TextBoxFor(m => m.Height, new { @id = "txtHeight", @class = "textbox required digits", @autocomplete = "off", @maxlength = "5", @style = "text-align:right; width:40px" })%>
                    px
                </p>
                <p id="pDefaultCoin" style="display:none;">
                    <label class="label" style="display:inline-block; width:90px;">Default Coin :</label>
                    <%: Html.TextBoxFor(m => m.DefaultCoin, new { @id = "defaultCoin", @class = "textbox required number", @autocomplete = "off", @maxlength = "8", @style = "text-align:right; width:50px" })%>
                </p>
             </div>
             <div class="Clear">
             </div>
            

            
            <%-------------------------
                Tab - Basic - End
             ---------------------------%>
        </div>
        <div id="tabs-2">
            <%-------------------------
                Tab - Advanced - Start
             ---------------------------%>
            <div class="LeftColumn">
                <p>
                    <label class="label">Original Vendor: </label>
                    <%: Html.DropDownListFor(m => m.OriginalVendorID, GetOriginalVendors(), new { @class = "ddl", @id = "ddlOriginalVendorID" })%>
                </p>                
                <p>
                    <label class="label">License: <em>*</em></label>
                    <%: Html.DropDownListFor(m => m.License, GetLicenseList(), new { @class = "ddl", @id = "ddlLisenceType" })%>
                </p>
                <p>
                    <label class="label">Invoicing Group: <em>*</em></label>
                    <%: Html.DropDownListFor(m => m.InvoicingGroup, GetInvoicingGroup(), new { @class = "ddl", @id = "ddlInvoicingGroup" })%>
                </p>
                <p>
                    <label class="label">Reporting Category: <em>*</em></label>
                    <%: Html.DropDownListFor(m => m.ReportCategory, GetReportCategory(), new { @class = "ddl", @id = "ddlReportingCategory" })%>
                </p>

                <p>
                    <label class="label" style="display:inline-block; width:150px;">Third Party Fee :</label>
                    <%: Html.TextBoxFor(m => m.ThirdPartyFee, new { @id = "thirdPartyFee", @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:50px" })%>
                    %
                </p>  
                
                <p>
                    <label class="label" style="display:inline-block; width:150px;">Jackpot Contribution :</label>
                    <%: Html.TextBoxFor(m => m.JackpotContribution, new { @id = "jackpotContribution", @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:50px" })%>
                    %
                </p>                
                <p>
                    <label class="label" style="display:inline-block; width:150px;">Theoretical Payout :</label>
                    <%: Html.TextBoxFor(m => m.TheoreticalPayOut, new { @id = "theoreticalPayout", @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:50px" })%>
                    %
                </p>
                <p>
                    <label class="label">Jackpot :</label>
                    <%: Html.RadioButtonFor(m => m.JackpotType, CE.db.JackpotType.None, new { @id = "btnJackpotType_None" }) %>
                    <label for="btnJackpotType_None">None</label>
                    <%: Html.RadioButtonFor(m => m.JackpotType, CE.db.JackpotType.Local, new { @id = "btnJackpotType_Local" }) %>
                    <label for="btnJackpotType_Local">Local</label>
                    <%: Html.RadioButtonFor(m => m.JackpotType, CE.db.JackpotType.Global, new { @id = "btnJackpotType_Global" }) %>
                    <label for="btnJackpotType_Global">Global</label>
                </p>      

                <p>
                <div class="tags_section">
                    <label class="label">Tags :</label>
                    <div class="tags">
                    </div>
                    <%: Html.HiddenFor(m => m.Tags, new { @class = "textarea hTags", @autocomplete = "off", @id = "hTags" })%>
                    <%: Html.TextBox("newTag", string.Empty, new { @id = "txtTag", @class = "textbox", @autocomplete = "on", @maxlength = "20", @style = "width:150px" })%>
                </div>
                </p> 
                <script type="text/html" id="tag-template">
                    <# var d=arguments[0]; #>
                    <span class="tag" title="<#= d.htmlEncode() #>"><#= d.htmlEncode() #><a href="javascript:void(0)"><span onclick="removeTag(this)"></span></a></span>
                </script>
                <script type="text/javascript">                    

                    $(function () {
                        $('#txtTag').keypress(function (e) {
                            if (e.keyCode == 13) {
                                e.preventDefault();                                
                                creatTag($(this), true);
                            }
                        });

                        <% 
                            string[] tags = this.Model.Tags.DefaultIfNullOrEmpty(string.Empty).Split(',');
                            foreach (string tag in tags)
                            {
                                if (string.IsNullOrWhiteSpace(tag))
                                    continue; %>
                               var $c_tags = $('#txtTag').parents('.tags_section').find('div.tags');
                               $($('#tag-template').parseTemplate('<%= tag.SafeJavascriptStringEncode() %>')).appendTo($c_tags);
                               <%
                            }
                        %>
                    });
                </script>
            </div>
            <div class="RightColumn">
                <p>
                    <label class="label">Free Spin Bonus</label>
                    <input type="checkbox" value="true" name="SupportFreeSpinBonus" id="supportFreeSpinBonus"<%= this.Model.SupportFreeSpinBonus ? @" checked=""checked"" ": "" %> <%= CurrentUserSession.IsSuperUser ? "" : @" onclick=""return false"" " %> >
                    <label for="supportFreeSpinBonus" >Support Free Spin Bonus</label>
                </p>
                
                <script type="text/javascript">
                    $(function () {

                        function onSupportFreeSpinBonusChanged()
                        {
                            $('#divFreeSpinBonusAsset').hide();

                            if ($('#ddlVendor').val() == 'PlaynGO') {
                                if ($('#supportFreeSpinBonus').attr('checked')) {
                                    $('#divFreeSpinBonusAsset').show();
                                }
                            }
                        }

                        $('#supportFreeSpinBonus').change(function () {
                            <% if (CurrentUserSession.IsSuperUser) { %>
                            onSupportFreeSpinBonusChanged();
                            <% } %>
                            
                        });

                        onSupportFreeSpinBonusChanged();
                    });
                </script>

                <div id="divFreeSpinBonusAsset" style="display:none; padding:0; margin:0; border:0;">
                <%if (CurrentUserSession.IsSuperUser) { %>
                <p>
                <label class="label">Lines :</label>
                <%: Html.TextBoxFor(m => m.SpinLines, new { @id = "spinLines", @class = "textbox", @autocomplete = "off" })%>
                </p>

                <p>
                <label class="label">Coins :</label>
                <%: Html.TextBoxFor(m => m.SpinCoins, new { @id = "spinCoins", @class = "textbox", @autocomplete = "off" })%>
                </p>

                <p>
                <div class="tags_section">
                <label class="label">Denominations (EUR) :</label>
                <div class="tags"></div>
                <%: Html.HiddenFor(m => m.SpinDenominations, new { @class = "textarea hTags", @autocomplete = "off", @id = "hDenoes" })%>
                <%: Html.TextBox("newDeno", string.Empty, new { @id = "txtSpinDenomination", @class = "textbox", @autocomplete = "off" })%>
                </div>
                </p>
                <script type="text/javascript">
                    $(function () {
                        $('#txtSpinDenomination').keypress(function (e) {
                            if (e.keyCode == 13) {
                                e.preventDefault();

                                var regex = new RegExp("^[\\d]+(\\.[\\d]{1,2})?$", "g");
                                
                                $this = $(this);
                                if (regex.test($this.val()))
                                    creatTag($this);
                                else
                                    alert('please enter correct denomination');
                            }
                        });

                        <% 
                            string[] spinDenominations = this.Model.SpinDenominations.DefaultIfNullOrEmpty(string.Empty).Split(',');
                            foreach (string deno in spinDenominations)
                            {
                                if (string.IsNullOrWhiteSpace(deno))
                                    continue; %>
                        var $c_tags = $('#txtSpinDenomination').parents('.tags_section').find('div.tags');
                        $($('#tag-template').parseTemplate('<%= deno.SafeJavascriptStringEncode() %>')).appendTo($c_tags);
                        <%
                            }
                        %>
                    });
                </script>

                <script type="text/javascript">

                    $(function () {

                        $('#spinLines').blur(function () {
                            var $el = $('#ddlFreeSpinBonus_DefaultLine');
                            var _dr = $el.val();

                            $el.find('option').remove();

                            var _ds = CovertScopeStringToArray($('#spinLines').val());
                            if (_ds != null) {
                                for (var _d in _ds) {
                                    $('<option value="' + _ds[_d] + '">' + _ds[_d] + '</option>').appendTo($el);
                                }
                            }
                            $el.val(_dr);
                        });

                        $('#spinCoins').blur(function () {
                            var $el = $('#ddlFreeSpinBonus_DefaultCoin');
                            var _dr = $el.val();

                            $el.find('option').remove();

                            var _ds = CovertScopeStringToArray($('#spinCoins').val());
                            if (_ds != null) {
                                for (var _d in _ds) {
                                    $('<option value="' + _ds[_d] + '">' + _ds[_d] + '</option>').appendTo($el);
                                }
                            }
                            $el.val(_dr);
                        });

                        $(document).bind('OnTagChanged', function () {
                            var str = $('#hDenoes').val();
                            
                            if (str != null && str.trim() != '')
                            {
                                var range = new Array();
                                var strs = str.split(',');
                                for (var i = 0; i < strs.length; i++) {
                                    if (strs[i].trim() != '') {
                                        range.push(parseFloat(strs[i]));
                                    }
                                }
                                if (range.length > 0)
                                    range.sort(NumAscSort);

                                var $el = $('#ddlFreeSpinBonus_DefaultDenomination');
                                var _dr = $el.val();

                                $el.find('option').remove();

                                if (range != null) {
                                    for (var _d in range) {
                                        $('<option value="' + range[_d] + '">' + range[_d] + '</option>').appendTo($el);
                                    }
                                }
                                $el.val(_dr);
                            }
                        });
                        

                        function NumAscSort(a, b) {
                            return a - b;
                        }

                        function CovertScopeStringToArray(str) {

                            if (str == null || str.trim() == '')
                                return null;

                            var regFigure = /^[\d]{1,5}$/;
                            var regRange = /^([\d]{1,5})-([\d]{1,5})$/;

                            var range = new Array();

                            var strs = str.split(',');
                            for (var i = 0; i < strs.length; i++) {
                                if (strs[i].trim() != '') {
                                    if (regFigure.test(strs[i]))
                                        range.push(parseInt(strs[i]));
                                    else if (regRange.test(strs[i])) {
                                        var min = parseInt(RegExp.$1);
                                        var max = parseInt(RegExp.$2);

                                        if (min <= max) {
                                            for (var j = min; j <= max; j++) {
                                                range.push(j);
                                            }
                                        }
                                    }
                                }
                            }

                            if (range.length > 0)
                                range.sort(NumAscSort);

                            return range;
                        }
                    });
                    </script>
                <%} %>

                <p>
                <label class="label">Default Line :</label>
                    <%: Html.DropDownListFor(m => m.FreeSpinBonus_DefaultLine, GetSpinLines(), null, new { @class = "ddl", @id = "ddlFreeSpinBonus_DefaultLine" })%>
                </p>

                <p>
                <label class="label">Default Coin :</label>
                    <%: Html.DropDownListFor(m => m.FreeSpinBonus_DefaultCoin, GetSpinCoins(), new { @class = "ddl", @id = "ddlFreeSpinBonus_DefaultCoin" })%>
                </p>

                <p>
                <label class="label">Default Denomination (EUR) :</label>
                    <%: Html.DropDownListFor(m => m.FreeSpinBonus_DefaultDenomination, GetSpinDenominations(), new { @class = "ddl", @id = "ddlFreeSpinBonus_DefaultDenomination" })%>
                </p>
                    
                </div>
            </div>
            <div class="RightColumn">
            <p>
                <label class="label">Bet Limit</label>
                <input type="checkbox" value="true" name="SupportBetLimit" id="supportBetLimit">
                <label for="supportBetLimit" >Support Bet Limit</label>
                <script type="text/javascript">
                    $('#supportBetLimit').change(function (e) {
                        if ($(this).attr('checked') == "checked") {
                            $('#limit-amount').show();
                            $('#currency-limit-table').show();
                        }
                        else {
                            $('#limit-amount').hide();
                            $('#currency-limit-table').hide();
                        }

                    }).trigger('change');   

                </script>
            </p>

            <p id="limit-amount" style="display:none">
                <table cellpadding="0" cellspacing="0" border="0" class="format-table" id="currency-limit-table" style="display:none">
                    <tbody>
                        <% 
                            CurrencyData [] currencies = GamMatrixClient.GetSupportedCurrencies();
                            foreach (CurrencyData currency in currencies)
                            {
                                CasinoGameLimitAmount limitAmount;
                                if (!this.Model.LimitAmounts.TryGetValue(currency.ISO4217_Alpha, out limitAmount))
                                    limitAmount = new CasinoGameLimitAmount();
                                  %>
                        <tr data-currency="<%= currency.ISO4217_Alpha %>">
                            <td class="col-1">
                                <%= string.Format( "{0} - {1}", currency.ISO4217_Alpha, currency.Name.SafeHtmlEncode()).SafeHtmlEncode() %>
                            </td>
                            <td class="col-2">
                                <%: Html.TextBox("minAmount_" + currency.ISO4217_Alpha, limitAmount.MinAmount.ToString("F2"), new { @class = "textbox number min", @maxlength = "8" })%>
                            </td>
                            <td>
                                &#8804; X &#8804;
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
            <div class="RightColumn">
                <p>
                    <label class="label">Age Limit</label>
                    <p>
                        <%= Html.CheckBoxFor(m => m.AgeLimit, new {@id = "ageLimit"})%>
                        <label for="ageLimit">Game has content not allowed till 21</label>                                            
                    </p>
                </p>
            </div>
            <div class="RightColumn">
                <p>
                    <label class="label">Html5 game</label>
                    <p>
                        <%= Html.CheckBoxFor(m => m.LaunchGameInHtml5, new {@id = "launchGameInHtml5"})%>
                        <label for="launchGameInHtml5">Launch game in HTML5 mode</label>                                            
                    </p>
                </p>
            </div>
            <div class="RightColumn">
                <p>
                    <label class="label">Launch urls</label>
                    <p>
                        <label for="txtGameLaunchUrl" >Game launch url</label>
                        <br>
                        <%: Html.TextBoxFor(m => m.GameLaunchUrl, new { @class = "textbox", @autocomplete = "off", @maxlength = "512", @id = "txtGameLaunchUrl" })%>
                    </p>
                        <br>
                    <p>
                        <label for="txtMobileGameLaunchUrl" >Mobile game launch url</label>
                        <br>
                        <%: Html.TextBoxFor(m => m.MobileGameLaunchUrl, new { @class = "textbox", @autocomplete = "off", @maxlength = "512", @id = "txtMobileGameLaunchUrl" })%>
                    </p>
                </p>
            </div>
            <div class="Clear"></div>
            <%-------------------------
                Tab - Advanced - End
             ---------------------------%>
        </div>
        <div id="tabs-3">
            <%-------------------------
                Tab - Assets - Start
             ---------------------------%>
             <div class="LeftColumn">
                <p>
                    <label class="label">Logo (120px X 120px) :</label>
                    <a href="<%= GetLogoImage().SafeHtmlEncode() %>" target="_blank">
                        <img src="<%= GetLogoImage().SafeHtmlEncode() %>" style="width:120px; min-height:120px; border:solid 1px #666;" />
                    </a>
                    <br />

                    <input type="file" name="logoFile" style="width:240px" />
                </p>

                <% if (this.ShowThumbnail)
                   { %>
                <p>
                    <label class="label">Thumbnail (120px X 70px) :</label>
                    <a href="<%= GetThumbnailImage().SafeHtmlEncode() %>" target="_blank">
                        <img style="width:120px; height:70px; border:solid 1px #666;" src="<%= GetThumbnailImage().SafeHtmlEncode() %>" />
                    </a>
                    <br />

                    <input type="file" name="thumbnailFile" style="width:240px" />
                </p>  
                <% } %>

                <p>
                    <label class="label">Icon (114px X 114px, for mobile) :</label>
                    <a href="<%= GetIconImage().SafeHtmlEncode() %>" target="_blank">
                        <img style="max-width:114px; max-height:114px; border:0px;" src="<%= GetIconImage().SafeHtmlEncode() %>" />
                    </a>
                    <br />
                    
                    <input type="file" name="iconFile" style="width:240px" />
                </p>
             </div>
             <div class="RightColumn">
                <% if (this.ShowScalableThumbnail)
                   { %>
                <p>
                    <label class="label">Scalable Thumbnail ( <%= ScalableThumbnailWidth %>px X <%= ScalableThumbnailHeight %>px ) :</label>    
                    <a href="<%= GetScalableThumbnailImage().SafeHtmlEncode() %>" target="_blank">
                        <img style="max-width:360px; max-height:300px; border:0px;" src="<%=GetScalableThumbnailImage().SafeHtmlEncode() %>" />
                    </a>
                    <br />               
                    <input type="file" name="scalableThumbnailFile" style="width:240px" />
                </p>
                <% } %>

                <p>
                    <label class="label">Background :</label>
                    <a href="<%= GetBackgroundImage().SafeHtmlEncode() %>" target="_blank">
                        <img style="max-width:360px; max-height:300px; border:0px;" src="<%= GetBackgroundImage().SafeHtmlEncode() %>" />
                    </a>
                    <br />
                    
                    <input type="file" name="backgroundImageFile" style="width:240px" />
                </p>
             </div>
             <div class="Clear"></div>
            <%-------------------------
                Tab - Assets - End
             ---------------------------%>

        </div>
        <div id="tabs-4">
            <%-------------------------
                Tab - Restricted Territories - Start
             ---------------------------%>
            <div id="dlgRestrictedTerritories" title="Restricted Territories">
            <ul>
            <%
                List<SelectListItem> list = GetCountries();
                foreach ( SelectListItem item in list )
                {
                    string controlID = string.Format( "btnRestrictedTerritory_{0}", item.Value);
                    %>
                    <li>
                        <%: Html.CheckBox( "countries", item.Selected, new { @id=controlID, @value=item.Value } ) %>
                        <label for="<%:controlID %>"><%= item.Text.SafeHtmlEncode() %></label>
                    </li>
                    <%    
                }
            %>
            </ul>
            <p>
                <%: Html.HiddenFor(m => m.RestrictedTerritories, new { @id = "hGameRestrictedTerritories" })%>
            </p>
            <script type="text/javascript">
                $(function () {
                    function refreshCheckboxStatus() {
                        var strCodes = '';
                        $('#dlgRestrictedTerritories li.Checked').removeClass('Checked');
                        var checkboxes = $('#dlgRestrictedTerritories :checkbox:checked');
                        for (var i = 0; i < checkboxes.length; i++) {
                            var id = checkboxes.eq(i).attr('id');
                            $('#dlgRestrictedTerritories label[for="' + id + '"]').parent('li').addClass('Checked');
                            strCodes += ',' + checkboxes.eq(i).val();
                            $('#hGameRestrictedTerritories').val(strCodes);
                        }
                        if(checkboxes.length==0)
                            $('#hGameRestrictedTerritories').val(' ');
                    }

                    $('#dlgRestrictedTerritories :checkbox').click(function (e) {
                        setTimeout(refreshCheckboxStatus, 0);
                    });

                    $('#dlgRestrictedTerritories :checkbox:checked').attr('checked', false);
                    var strCodes = $('#hGameRestrictedTerritories').val().split(',');
                    for (var i = 0; i < strCodes.length; i++) {
                        $('#dlgRestrictedTerritories :checkbox[value="' + strCodes[i] + '"]').attr('checked', true);
                    }
                    setTimeout(refreshCheckboxStatus, 0);
                });
            </script>
            <%-------------------------
                Tab - Restricted Territories - End
             ---------------------------%>
            </div>
        </div>

        <div id="tabs-5">
            <%-------------------------
                Tab - Language - Start
             ---------------------------%>
            <label class="label">Available Languages : </label>
            <input id="btnLanguagesType_Default" type="radio" value="Default" name="LanguagesType"  checked="checked">
            <label for="btnLanguagesType_Default">Default</label>
            <input id="btnLanguagesType_Customize" type="radio" value="Customize" name="LanguagesType">
            <label for="btnLanguagesType_Customize">Customize</label>
                <script type="text/javascript">
                    $(function () {
                        $('#btnLanguagesType_Default').click(function (e) {
                            $('#btnLanguagesType_Default').attr('checked','checked');
                            $('#btnLanguagesType_Customize').removeAttr("checked");
                            var vendorId = $('#ddlVendor').val();
                            var vendorLanguages = document.getElementById("Languages_"+vendorId).value;
                            var languages = vendorLanguages.split(',');
                            $('ul.ul-languages :checkbox[value!="All"]').attr('checked', false).parent('li').show();
                            $('ul.ul-languages :checkbox').attr('checked', false);
                            for (var i = 0; i < languages.length; i++) {
                                $('ul.ul-languages :checkbox[value="' + languages[i] + '"]').attr('checked', true);
                            }
                            $('ul.ul-languages :checkbox').attr('disabled',true);
                            $('#hGameAvailableLanguages').val('');
                        });
                        $('#btnLanguagesType_Customize').click(function (e) {
                            $('#btnLanguagesType_Customize').attr('checked','checked');
                            $('#btnLanguagesType_Default').removeAttr("checked");
                            $('ul.ul-languages :checkbox').attr('disabled',false);
                            var gameLanguages = $('#hGameAvailableLanguages').val();
                            if (gameLanguages == '') {
                                $('#btnLanguage_all').attr('checked', true);
                                $('#hGameAvailableLanguages').val('All');
                                $('ul.ul-languages :checkbox[value!="All"]').attr('checked', false).parent('li').hide();

                            }
                        });
                    });
                    
                </script>
            <ul class="ul-languages">
                <li>
                    <input type="checkbox" id="btnLanguage_all" value="All"/>
                    <label for="btnLanguage_all"><strong>All</strong></label>
                </li>
                <li>
                    <input type="checkbox" id="btnLanguage_en" value="en"/>
                    <label for="btnLanguage_en">English</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_sq" value="sq"/>
                    <label for="btnLanguage_sq">Albanian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_bg" value="bg"/>
                    <label for="btnLanguage_bg">Bulgarian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_cs" value="cs"/>
                    <label for="btnLanguage_cs">Czech</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_da" value="da"/>
                    <label for="btnLanguage_da">Danish</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_nl" value="nl"/>
                    <label for="btnLanguage_nl">Dutch</label>
                </li>
                <li>
                    <input type="checkbox" id="btnLanguage_et" value="et"/>
                    <label for="btnLanguage_et">Estonian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_fi" value="fi"/>
                    <label for="btnLanguage_fi">Finnish</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_fr" value="fr"/>
                    <label for="btnLanguage_fr">French</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_de" value="de"/>
                    <label for="btnLanguage_de">German</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_el" value="el"/>
                    <label for="btnLanguage_el">Greek</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_he" value="he"/>
                    <label for="btnLanguage_he">Hebrew</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_hu" value="hu"/>
                    <label for="btnLanguage_hu">Hungarian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_it" value="it"/>
                    <label for="btnLanguage_it">Italian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_jp" value="jp"/>
                    <label for="btnLanguage_jp">Japanese</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_ko" value="ko"/>
                    <label for="btnLanguage_ko">Korean</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_no" value="no"/>
                    <label for="btnLanguage_no">Norwegian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_pl" value="pl"/>
                    <label for="btnLanguage_pl">Polish</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_pt" value="pt"/>
                    <label for="btnLanguage_pt">Portuguese</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_ro" value="ro"/>
                    <label for="btnLanguage_ro">Romanian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_ru" value="ru"/>
                    <label for="btnLanguage_ru">Russian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_sr" value="sr"/>
                    <label for="btnLanguage_sr">Serbian</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_es" value="es"/>
                    <label for="btnLanguage_es">Spanish</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_sv" value="sv"/>
                    <label for="btnLanguage_sv">Swedish</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_tr" value="tr"/>
                    <label for="btnLanguage_tr">Turkish</label>
                </li>
				<li>
                    <input type="checkbox" id="btnLanguage_uk" value="uk"/>
                    <label for="btnLanguage_uk">Ukrainian</label>
                </li>
                <li>
                    <input type="checkbox" id="btnLanguage_zhcn" value="zh-cn"/>
                    <label for="btnLanguage_zhcn">Chinese (Simplified)</label>
                </li>
                <li>
                    <input type="checkbox" id="btnLanguage_zhtw" value="zh-tw"/>
                    <label for="btnLanguage_zhtw">Chinese (Traditional)</label>
                </li>
            </ul>
            <%: Html.HiddenFor(m => m.Languages, new { @id = "hGameAvailableLanguages" })%>
            <script type="text/javascript">
                var vendorId = $('#ddlVendor').val();
                var vendorLanguages = document.getElementById("Languages_"+vendorId).value;
                var gameLanguages = $('#hGameAvailableLanguages').val();
                var currentLanguages = gameLanguages;
                if (gameLanguages == '') {
                    currentLanguages = vendorLanguages;
                }
                <% if( string.IsNullOrEmpty(this.Model.GameID) ) { %>
                  currentLanguages = vendorLanguages;
                <%}%>
                if (currentLanguages == '') {
                    $('#btnLanguage_all').attr('checked', true);
                }
                else {
                    $('ul.ul-languages :checkbox').attr('checked', false);
                    var languages = currentLanguages.split(',');
                    for (var i = 0; i < languages.length; i++) {
                        $('ul.ul-languages :checkbox[value="' + languages[i] + '"]').attr('checked', true);
                    }
                }

                $('ul.ul-languages :checkbox[value!=""]').click(function (e) {
                    var languages = '';
                    var checkboxes = $('ul.ul-languages :checked[value!=""]');
                    for (var i = 0; i < checkboxes.length; i++) {
                        if (i > 0)
                            languages += ',';
                        languages += checkboxes.eq(i).val();
                    }
                    $('#hGameAvailableLanguages').val(languages);
                });

                $('ul.ul-languages :checkbox[value="All"]').change(function (e) {
                    if ($(this).attr('checked') == "checked") {
                        $('#hGameAvailableLanguages').val('All');
                        $('ul.ul-languages :checkbox[value!="All"]').attr('checked', false).parent('li').hide();
                    }
                    else {
                        $('ul.ul-languages :checkbox[value!="All"]').parent('li').show();
                    }

                }).trigger('change');   
            </script>
            <%-------------------------
                Tab - Language - End
             ---------------------------%>
        </div>
        <%if(!string.IsNullOrEmpty(this.Model.GameID)){
            if (DomainManager.CurrentDomainID == Constant.SystemDomainID && GameOverrides.Count > 0)
            { %>
            <div id="tabs-6">
                <%-------------------------
                    Tab - Overrides - Start
                 ---------------------------%>
                <label class="label">Game Overrides : </label>
                <div class="div-overrides">
                <% foreach (var gameOverride in GameOverrides)
                   {
                       if(Domains.Exists(d => d.DomainID == gameOverride.DomainID))
                       {
                       var gameOverrideDomain = Domains.Single(d => d.DomainID == gameOverride.DomainID);
                       var _url = string.Format("<label for='btnOverrideGame'><strong>{0}</strong>: </label><a class='btnOverrideGame' target='_self' href='/GameManagement/{1}/GameEditorDialog?id={2}'>{3}{4}{5}</a><br/>",
                           gameOverrideDomain.Name,
                           gameOverride.DomainID,
                           gameOverride.CasinoGameBaseID,
                           gameOverride.GameName,
                           gameOverride.OpVisible.GetValueOrDefault(false) ? "" : " - <strong>Invisible</strong>",
                           gameOverride.Enabled ? "" : " <strong>Disabled</strong>");
                           %>
                    
                        <%= _url %>
                <%      }
                
                    } %>
                </div>
                <%-------------------------
                    Tab - Overrides - End
                 ---------------------------%>
            </div>
        <%    }
           } %>
    </div>


    <p align="right">
    <% if(DomainManager.AllowEdit()) { %>
    <% if (!string.IsNullOrWhiteSpace(this.Model.GameID))
       { %>
        <button type="button" id="btnRevertDeleteGame"><%: DomainManager.CurrentDomainID != Constant.SystemDomainID ? "To Defaults" : "Delete" %></button>
           <% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
           { %>
            <div class="ui-widget" style="width:475px; float:left;">
		        <div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
			        <p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
			        <strong>NOTE!</strong> Editing game attributes here will override defaults for this operator.</p>
		        </div>
	        </div>
        <% } %>
      <% } %>
    <% } %>

        <div style="float:right">
        <button type="reset" id="btnResetForm">Reset</button>
        <% if(DomainManager.AllowEdit()) { %>
        <button type="submit" id="btnSaveGame">Save</button>
        <% } %>
        </div>
    </p> 


    
</form>
<form id="formRevertDeleteGame" enctype="multipart/form-data" method="post" action="<%= this.Url.ActionEx("RevertOrDeleteGame").SafeHtmlEncode() %>">
    <%: Html.HiddenFor(m => m.ID)%>
</form>
<iframe id="ifmRegisterGame" name="ifmRegisterGame" style="display:none"></iframe>

<script type="text/javascript">
    function removeTag(el) {
        var $el = $(el);
        var $c = $el.parents('.tags_section');
        $el.parents('span.tag').remove();
        syncTags($c);        
    }

    function syncTags($c) {
        var tags = ',';
        var $tags = $c.find('div.tags span.tag');
        for (var i = 0; i < $tags.length; i++) {
            tags = tags + $tags[i].title + ',';
        }
        $c.find('.hTags').val(tags);
        $(document).trigger('OnTagChanged');
    }

    function creatTag($el, replaceSpecialChar)
    {
        var $c = $el.parents('.tags_section');

        var newTag = $el.val();
        if (newTag == null)
            return;
        newTag = newTag.trim();
        if (replaceSpecialChar) {
            var regex = new RegExp("[^\\w]", "g");
            newTag = newTag.replace(regex, "-");
        }
        if (newTag.length > 0) {
            $($('#tag-template').parseTemplate(newTag.toLowerCase())).appendTo($c.find('div.tags'));
            $el.val('');
            syncTags($c);
        }
    }

    $(function(){
        $('#game-editor-tabs').tabs();


        var a = $('#popularityCoefficient').val();
        $('#popularityCoefficient').val( a.replace('.00', '') );

        <% if( !string.IsNullOrEmpty(this.Model.LimitationXml) )
        { %>
        $('#supportBetLimit').attr('checked','checked');
          $('#limit-amount').show();
          $('#currency-limit-table').show();
        <%  }else {%>
        $('#supportBetLimit').removeAttr("checked");
          $('#limit-amount').hide();
          $('#currency-limit-table').hide();
       <%}%>
    });
    setTimeout(function () {
        $("#formRegisterGame").validate({
            validateHidden: true,
            rules: {
                inputGameID: {
                    required: function (value) {
                        $('#txtGameID').val($('#txtInputGameID').val());
                        return $('#txtGameID').val().length == 0;
                    }
                }
            }
        });
        $('#btnSaveGame').button({
            icons: {
                primary: "ui-icon-disk"
            }
        }).click(function (e) {
            if (!$("#formRegisterGame").valid()) {
                e.preventDefault();
                return;
            }
            var $trs = $('#currency-limit-table tr[data-currency]');
            for (var i = 0; i < $trs.length; i++) {
                var $tr = $trs.eq(i);
                var currency = $tr.data('currency');
                var min = parseInt($('input.min', $tr).val(), 10);
                var max = parseInt($('input.max', $tr).val(), 10);
                if (min > max) {
                    alert('The min limitation of ' + currency + ' is greater than its max limitation');
                    $('input.min', $tr).focus();
                    return false;
                }
            }
            //$('#loading').show();
        });

        $('#btnResetForm').button({
            icons: {
                primary: "ui-icon-refresh"
            }
        });

        // <%-- do not allow to modify vendor --%>
        <% if( !string.IsNullOrEmpty(this.Model.GameID) )
            { %>
            $('#ddlVendor').attr('disabled',true);
        <%   } %>
        <% if( !string.IsNullOrEmpty(this.Model.Languages) )
            { %>
        $('#btnLanguagesType_Customize').attr('checked','checked');
        $('#btnLanguagesType_Default').removeAttr("checked");
        $('ul.ul-languages :checkbox').attr('disabled',false);

        
        <%   } else { %>
        $('#btnLanguagesType_Default').attr('checked','checked');
        $('#btnLanguagesType_Customize').removeAttr("checked");
        var vendorId = $('#ddlVendor').val();
        var vendorLanguages = document.getElementById("Languages_"+vendorId).value;
        var languages = currentLanguages.split(',');
        $('ul.ul-languages :checkbox').attr('checked', false);
        for (var i = 0; i < languages.length; i++) {
            $('ul.ul-languages :checkbox[value="' + languages[i] + '"]').attr('checked', true);
        }
        $('ul.ul-languages :checkbox').attr('disabled',true);
        $('#hGameAvailableLanguages').val('');
        <% }%>
         
        // <%-- if this is a special operator --%>
        <%if(!string.IsNullOrEmpty(this.Model.GameID)){ 
            if( DomainManager.CurrentDomainID != Constant.SystemDomainID)
            { %>
            $('#ddlOriginalVendorID').attr('disabled',true);
            $('#ddlVendor').attr('disabled',true);
            $('#ddlCTXMGames').attr('disabled',true);
            $('#ddlBetSoftGames').attr('disabled',true);
            $('#txtInputGameID').attr('disabled',true);
            $('#txtGameCode').attr('disabled',true);
            $('#ddlReportingCategory').attr('disabled',true);
            $('#ddlInvoicingGroup').attr('disabled',true);
            $('#jackpotGame').attr('disabled',true);
            $('#jackpotContribution').attr('disabled',true);
            $('#theoreticalPayout').attr('disabled',true);
            $('#thirdPartyFee').attr('disabled',true);
            $('#txtSlug').attr('disabled',true);
            //$('#game-editor-tabs').tabs( "remove", 4);
            //$('#dlgRestrictedTerritories :checkbox').attr('disabled', true);
            $('#txtWidth').attr('disabled',true);
            $('#txtHeight').attr('disabled',true);
            <%} 
            if (CurrentUserSession.UserDomainID != Constant.SystemDomainID){ %>
            $('#anonymousFunMode').attr('disabled',true);
            $('#funMode').attr('disabled',true);
            $('#realMode').attr('disabled',true);
            $('#ddlLisenceType').attr('disabled',true);
            $(':checkbox[id^="btnClientType_"]').attr('disabled', true);
                <%if (!this.Model.ExcludeFromBonuses_EditableByOperator) { %>
        $('#excludeFromBonuses').attr('disabled', true);
                <%}
            }
        } %>
    }, 0);

    self.onGameSaved = function (success, error, isExist) {
        $('#loading').hide();
        if (!success)
            alert(error);
        else {
            if (isExist) {
                if (window.confirm("The operation has been completed successfully!\n Do you want to refresh the list?") == true)
                    $('#btnFilter').trigger('click');
                $.modal.close();
            }
            else {
                if (window.confirm("Do you want to continue registering new game?") == true){
                    var url = '<%= this.Url.ActionEx("GameEditorDialog").SafeJavascriptStringEncode() %>';
                    $('#dlgGameRegistration').html('<img src="/images/loading.icon.gif" />').load(url);
                }
                else{
                    $('#btnFilter').trigger('click');
                    $.modal.close();
                }
            }
        }
    };


    function getDateString(date) {
        return date.getMonth() + 1 + "/" + date.getDate() + "/" + date.getFullYear();
    }

    $('#newGame').click(function() {
        $('.newGameDatePicker').toggle(this.checked);
        var _d = new Date();
        if (this.checked) {
            _d.setDate(_d.getDate() + <%: ViewData["newStatusCasinoGameExpirationDays"] %>);
        } else {
            _d.setDate(_d.getDate() - 1);
        }
        $('#newGameExpirationDate').val(getDateString(_d));
    });

    $('#newGameExpirationDate').attr("readonly", "readonly").datepicker({ minDate: 'today', showOn: "button", });
    
    $('#btnRevertDeleteGame').button().click(function (e) {
        e.preventDefault();

        var options = {
            dataType: 'json',
            success: function (json) {
                $('#loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                $(document).trigger('GAME_CHANGED');
                $.modal.close();
            }
        };

        if (!confirm('<%: (DomainManager.CurrentDomainID != Constant.SystemDomainID)
            ? "Are you sure you want to lose all changes and revert to defaults?"
            : "This action cannot be reverted! Are you sure you want to delete this game?"%>')) {return;}

        $('#loading').show();
        $("#formRevertDeleteGame").ajaxSubmit(options);
    });

    $('#tabs-6 .div-overrides a.btnOverrideGame').click(function (e) {
        e.preventDefault();

        $('#dlgGameRegistration').html('<img src="/images/loading.icon.gif" /> Downloading data from third parties...');

        var url = $(this).attr('href');
        $('#dlgGameRegistration').load(url);
    });
</script>