<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Controllers.System.RegionLanguageParam>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script language="C#" runat="server" type="text/C#">
    private SelectListItem[] GetCountryList()
    {
        //Language language = this.ViewData["language"] as Language;
        cmSite domain = this.ViewData["cmSite"] as cmSite;
        var list = CountryManager.GetAllCountries(domain.DistinctName)
            .Where(c => c.InternalID > 0)
            .Select(c => new SelectListItem()
            {
                Text = string.Format("{0} - {1}", c.ISO_3166_Alpha2Code, c.EnglishName),
                Value = c.InternalID.ToString(),
                Selected = false
            })
            .OrderBy(c => c.Text)
            .ToArray();
        return list;
    }
</script>

<div id="language-links">
    <ul>
        <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
        <li>|</li>
        <li>
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                            @action = "Dialog",
                            @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                            @relativePath = "/.config/languages.setting".DefaultEncrypt(),
                            @searchPattner = "",
                            } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
        </li>
    </ul>
</div>

<hr class="seperator" />

<table id="table-language" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-language">Language</th>
            <th class="col-displayName">Display name</th>
            <th class="col-countries">Countries</th>
            <th class="col-flag">Country flag</th>
            <th class="col-tools"><a href="javascript:void(0)">Add New</a></th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>

<script id="row-template" type="text/html">
    <%
        cmSite domain = this.ViewData["cmSite"] as cmSite;
    %>
    <tr id="<#= arguments[0].guid#>">
        <td valign="middle" align="center" class="col-language">
            <select name="language" class="language-selector"></select>
        </td>
        <td valign="middle" align="center" class="col-displayName">
            <input type="text" class="display-name" value="<#= arguments[0].DisplayName.htmlEncode() #>" />
        </td>
        <td valign="middle" align="center" class="col-country default-countries">
            <%--<a class="country-selector" href="javascript:__showModalDialog('<%= this.Url.RouteUrl( "RegionLanguage", new { @action = "DefaultCountryView", @distinctName = domain.DistinctName.DefaultEncrypt(), @languageCode= "@0", @isExclude="true", @selection="1,2,3,4,5,6,7,8,9,10" }).SafeJavascriptStringEncode() %>')"><#= arguments[0].Countries.htmlEncode() #>--%>
            <a class="default-country-selector" href="javascript:void(0)" isexclude="<#= arguments[0].IsExclude #>" countryids="<#= arguments[0].CountryIds #>"><#= arguments[0].Countries.htmlEncode() #>
            </a>
        </td>
        <td valign="middle" align="center" class="col-flag country-flags">
            <img src="/images/transparent.gif" class="<#= arguments[0].CountryFlagName.htmlEncode() #>" title="<#= arguments[0].CountryFlagName.htmlEncode() #>" />
        </td>
        <td valign="middle" align="center" class="col-tools">
            <a href="javascript:void(0)" target="_self" onclick="self.tabLanguage.onBtnRemoveClick('<#= arguments[0].guid#>')">Remove</a>
        </td>
    </tr>

</script>

<% using (Html.BeginForm("Save"
       , null
       , new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formLanguage" }
    ))
   { %>

<% } %>

<div id="default-country-dialog" class="country-flags" title="Select the country..." style="display: none">
    <%--<%: Html.RadioButton("filterType", CountryList.FilterType.Exclude, false, new { @id = "Exclude" })%>
    <label for="Exclude">Only the selected country(s) are <strong>NOT</strong> supported for this language.</label>
    <br />
    <%: Html.RadioButton("filterType", CountryList.FilterType.Include, true, new { @id = "Include" })%>
    <label for="Include">Only the selected country(s) are supported for this language.</label>
    <hr />--%>
    <%: Html.DropDownList( "list", GetCountryList(), new { @multiple = "multiple", @size = "20", @id = "ddlCountry", @style="width: 100%;" }) %>
</div>


<div id="country-flag-dialog" class="country-flags" title="Select the country flag..." style="display: none">
    <%
        string[] flags = this.ViewData["CountryFlagNames"] as string[];
        foreach (string flag in flags)
        { %>
    <a href="javascript:void(0)">
        <div align="center" onclick="self.tabLanguage.onFlagClick(event)" class="item" title="<%= flag.SafeHtmlEncode() %>">
            <img src="/images/transparent.gif" class="<%= flag.SafeHtmlEncode() %>" />
        </div>
    </a>

    <%  } %>
</div>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true" Enabled="false">
    <script language="javascript" type="text/javascript">
        function TabLanguage(viewEditor) {
            self.tabLanguage = this;
    <% 
        StringBuilder script = new StringBuilder();
        script.Append("this.languages=[");

        foreach (var language in this.Model.Languages)
        {
            script.AppendFormat(CultureInfo.InvariantCulture, "{{LanguageCode:\"{0}\",Name:\"{1}\",NativeName:\"{2}\"}},"
            , ObjectHelper.GetFieldValue(language, "LanguageCode").SafeJavascriptStringEncode()
            , ObjectHelper.GetFieldValue(language, "Name").SafeJavascriptStringEncode()
            , ObjectHelper.GetFieldValue(language, "NativeName").SafeJavascriptStringEncode()
            );
        }

        if (script[script.Length - 1] == ',')
            script.Remove(script.Length - 1, 1);
        script.Append("];");
        Response.Write(script.ToString());
    %>

            this.getLanguagesAction = '<%= Url.RouteUrl( "RegionLanguage", new { @action = "GetLanguages", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';

            this.currentLink = null;

            this.currentImg = null;

            this.onFlagClick = function (evt) {
                var target = $(evt.srcElement || evt.target);
                if (target.attr('nodeName').toLowerCase() == 'img') target = target.parent('div');
                target.parent('a').parent('div').find('div.selected').removeClass('selected');
                target.addClass('selected');
                this.currentFlag = target.attr('title');
            };

            this.onBtnAddNewRowClicked = function () {
                this.addNewRow();
            };

            this.S4 = function () {
                return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
            }

            this.guid = function () {
                return (this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4());
            }

            this.onBtnChooseDefaultCountryClick = function (evt) {
                this.currentLink = $(evt.target);
                self.TabLanguage.currentLink = $(evt.target);
                this.isExclude = this.currentLink.attr("isExclude") == 'true';
                this.countryIds = this.currentLink.attr("countryIds").split(',');
                
                $("#default-country-dialog").find('#Exclude').attr('checked', this.isExclude);
                $("#default-country-dialog").find('#Include').attr('checked', !this.isExclude);

                $("#default-country-dialog").find('#ddlCountry option').attr('selected', false);
                for (var i = 0; i < this.countryIds.length; i++) {
                    $("#default-country-dialog").find('#ddlCountry option[value="' + this.countryIds[i] + '"]').attr('selected', true);
                }
                
                $("#default-country-dialog").find('div.selected').removeClass('selected');
                $("#default-country-dialog").dialog({
                    autoOpen: true,
                    height: 500,
                    width: 700,
                    modal: true,
                    buttons: {
                        OK: function () {
                            var isExclude = $("#default-country-dialog").find('#Exclude').attr('checked');
                            var selected = $("#default-country-dialog").find('#ddlCountry option:selected');
                            
                            var countryIds = '';
                            var countries = '';
                            if (isExclude) {
                                if (selected.length == 0)
                                    countries += "All";
                                else
                                    countries += "Exclude ";
                            }
                            else {
                                if (selected.length == 0)
                                    countries += "None";
                            }
                            
                            for (var i = 0; i < selected.length; i++) {
                                countryIds += $(selected[i]).val() + ',';
                                var country = $(selected[i]).text();
                                country = country.substring(country.indexOf('- ') + 2, country.length);
                                countries += " " + country + " ,";
                            }
                            if (selected.length > 0) {
                                countryIds = countryIds.substring(0, countryIds.length - 1);
                                countries = countries.substring(0, countries.length - 1);
                            }
                            self.TabLanguage.currentLink.attr('isExclude', isExclude);
                            self.TabLanguage.currentLink.attr('countryIds', countryIds);
                            self.TabLanguage.currentLink.html(countries);
                            $(this).dialog('close');
                        },
                        Cancel: function () {
                            $(this).dialog('close');
                        }
                    }
                });
            };

            this.onBtnCountryChange = function (evt) {
                var target = $(evt.target);
                this.currentFlag = target.val();

                if (this.currentFlag.length > 2) {
                    var startIndex = this.currentFlag.indexOf('-') + 1;
                    var trimmedString = this.currentFlag.substring(startIndex, this.currentFlag.length);
                    this.currentFlag = trimmedString;
                }

                self.tabLanguage.currentImg = target.parent().parent().find('.col-flag.country-flags img');
                if (self.tabLanguage.currentFlag != null) {
                    self.tabLanguage.currentImg.attr('class', self.tabLanguage.currentFlag);
                    self.tabLanguage.currentImg.attr('title', self.tabLanguage.currentFlag);
                }
            }

            this.onBtnChooseFlagClick = function (evt) {
                this.currentImg = $(evt.target);
                this.currentFlag = null;

                $("#country-flag-dialog").find('div.selected').removeClass('selected');
                this.currentFlag = null;
                $("#country-flag-dialog").dialog({
                    autoOpen: true,
                    height: 500,
                    width: 700,
                    modal: true,
                    buttons: {
                        OK: function () {
                            if (self.tabLanguage.currentFlag != null) {
                                self.tabLanguage.currentImg.attr('class', self.tabLanguage.currentFlag);
                            }
                            $(this).dialog('close');
                        },
                        Cancel: function () {
                            $(this).dialog('close');
                        }
                    }
                });
            };

            this.onBtnRemoveClick = function ($guid) {
                $('tr[id="' + $guid + '"]').remove();
            };

            this.addNewRow = function (json) {
                if (json == null) json = {};
                json.guid = this.guid();
                if (json.DisplayName == null) json.DisplayName = '';
                if (json.CountryFlagName == null) json.CountryFlagName = "gb";
                //if (json.Countries == null) json.Countries = '<a countryids="" isexclude="" href="javascript:void(0)" class="default-country-selector">None</a>';
                if (json.Countries == null) json.Countries = 'None';
                $('#table-language tbody').append($('#row-template').parseTemplate(json));
                var $select = $('#' + json.guid + ' select.language-selector');
                $select.append($("<option></option>").attr("value", '').text('-- Please select language --').attr('selected', 'selected'));
                for (var i = 0; i < this.languages.length; i++) {
                    $lang = this.languages[i];

                    $select.append($("<option></option>").attr("value", $lang.LanguageCode).text($lang.Name).attr('nativeName', $lang.NativeName));
                }
                if (json.LanguageCode != null)
                    $select.val(json.LanguageCode);

                $select.bind('change', json.guid, function (e) {
                    $('#' + json.guid + ' .col-displayName input').val(
                        $('#' + json.guid + ' .col-language select option:selected').attr('nativeName')
                    );
                });

                $('#' + json.guid + ' .col-country a').bind('click', this, function (e) {
                    e.data.onBtnChooseDefaultCountryClick(e);
                });

                $('#' + json.guid + ' select.language-selector').bind('change', this, function (e) {
                    e.data.onBtnCountryChange(e);
                });

                $('#' + json.guid + ' .col-flag img').bind('click', this, function (e) {
                    e.data.onBtnChooseFlagClick(e);
                });
            };

            this.onLnkSaveClick = function () {
                $('#formLanguage').html('');
                var rows = $('#table-language > tbody > tr');

                var total = 0;
                for (var i = 0; i < rows.length; i++) {
                    var langCode = $(rows[i]).children('td.col-language').children('select').val();
                    if (langCode == '')
                        continue;
                    $('#formLanguage').append('<input type="hidden" name="LanguageCode_' + total + '" value="' + langCode.htmlEncode() + '" />');
                    $('#formLanguage').append('<input type="hidden" name="CountryFlagName_' + total + '" value="' + $(rows[i]).find('.col-flag img').attr('className').htmlEncode() + '" />');
                    $('#formLanguage').append('<input type="hidden" name="DisplayName_' + total + '" value="' + $(rows[i]).find('.col-displayName input').val().htmlEncode() + '" />');
                    $('#formLanguage').append('<input type="hidden" name="IsExclude_' + total + '" value="' + $(rows[i]).find('.col-country a').attr('isExclude').htmlEncode() + '" />');
                    $('#formLanguage').append('<input type="hidden" name="CountryIds_' + total + '" value="' + $(rows[i]).find('.col-country a').attr('countryIds').htmlEncode() + '" />');
                    total++;
                }
                $('#formLanguage').append('<input type="hidden" name="total" value="' + total.toString(10) + '" />');

                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) { alert(json.error); return; }
                    }
                };
                $('#formLanguage').ajaxForm(options);
                $('#formLanguage').submit();
            };

            this.refresh = function () {
                if (self.startLoad) self.startLoad();
                jQuery.getJSON(this.getLanguagesAction, null, function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) { alert(json.error); return; }
                    $('#table-language > tbody').html('');
                    for (var i = 0; i < json.data.length; i++) {
                        self.tabLanguage.addNewRow(json.data[i]);
                    }
                });
            };

            this.init = function () {
                InputFields.initialize($("#formTabGeneric"));

                $('#table-language > thead th.col-tools > a').bind('click', this, function (e) { e.data.onBtnAddNewRowClicked(); });

                $('#language-links a.save').bind('click', this, function (e) { e.data.onLnkSaveClick(); });
                $('#language-links a.refresh').bind('click', this, function (e) { e.data.refresh(); });

                $('#language-links a.history').click(function (e) {
                    var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                    if (wnd) e.preventDefault();
                });

                this.refresh();
            };

            this.init();
        }

        function __showModalDialog(url) {
            $('<div class="popup-dialog"><img src="/images/icon/loading.gif" /></div>').appendTo(document.body).load(url).dialog({
                autoOpen: true,
                height: 'auto',
                minHeight: 50,
                position: [100, 50],
                width: 700,
                modal: true,
                resizable: false,
                close: function (ev, ui) { $("div.popup-dialog").dialog('destroy'); $("div.popup-dialog").remove(); }
            });
        };
    </script>
</ui:ExternalJavascriptControl>
