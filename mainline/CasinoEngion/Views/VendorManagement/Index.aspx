<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" Inherits="System.Web.Mvc.ViewPage<dynamic>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Collections.ObjectModel" %>

<script type="text/C#" language="C#" runat="Server">
    private List<SelectListItem> GetCountries()
    {
        LocationAccessor la = LocationAccessor.CreateInstance<LocationAccessor>();
        return la.GetCountries().Select( c => new SelectListItem() { Text = c.Value, Value = c.Key }).ToList();
    }
    private List<SelectListItem> GetLanguages()
    {
        ReadOnlyDictionary<string, Language> allLanguages = Language.All;
        return allLanguages.Select(c => new SelectListItem() { Text = c.Value.Name, Value = c.Key }).ToList();
    }
    private List<SelectListItem> GetCurrencies()
    {
        CurrencyData[] supportedCurrencies = GamMatrixClient.GetSupportedCurrencies();
        return supportedCurrencies.Select(c => new SelectListItem() { Text = c.Name, Value = c.Code }).ToList();
    }
</script>

<asp:Content ContentPlaceHolderID="phMain" runat="server">
 
 <style type="text/css">
.input_box { background-color:transparent; border:none; width:40px; text-align:right; color:White; }
.indicator { background-color:transparent; border:none; width:20px; text-align:right; color:White; }
.focused_input_box { background-color:White !important; color:Black; }
.footer-buttons { float:right; margin:1px 10px 0px 0px; } 
#dlgRestrictedTerritories ul { list-style-type:none; margin:0px; padding:0px; }
#dlgRestrictedTerritories li { list-style-type:none; margin:0px; }
#dlgRestrictedTerritories li.Checked { background-color:Yellow; }
#dlgRestrictedTerritories li.Checked label { color:red; font-weight:bold; }
#dlgLanguages ul { list-style-type:none; margin:0px; padding:0px; }
#dlgLanguages li { list-style-type:none; margin:0px; }
#dlgLanguages li.Checked { background-color:Yellow; }
#dlgLanguages li.Checked label { color:red; font-weight:bold; }
#dlgCurrencies ul { list-style-type:none; margin:0px; padding:0px; }
#dlgCurrencies li { list-style-type:none; margin:0px; }
#dlgCurrencies li.Checked { background-color:Yellow; }
#dlgCurrencies li.Checked label { color:red; font-weight:bold; }
 </style>

<% if (DomainManager.CurrentDomainID == Constant.SystemDomainID ) { %>
<div class="ui-widget" style="max-width:550px">
	<div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
		<p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
		<strong>NOTE!</strong> The configuration below is only default setting for new operators. Modifying the settings here does not impact any operators immediately until you save the configuration in a specific operator.</p>
	</div>
</div>
<% } else if( !CurrentUserSession.IsSuperUser ) { %>
<div class="ui-widget" style="max-width:550px">
	<div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
		<p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
		<strong>NOTE!</strong> You are only allowed to view the configuration below. If you have any query, please contact Casino Product Manager.</p>
	</div>
</div>
<% } %>

<form id="formSaveVendorSettings" method="post" enctype="application/x-www-form-urlencoded" target="_blank"
action="<%= this.Url.ActionEx("Save").SafeHtmlEncode() %>" >

<div id="table-vendors-wrapper" class="styledTable" style="max-width:750px">
    <div class="table-header ui-toolbar ui-widget-header ui-corner-tl ui-corner-tr ui-helper-clearfix"></div>

    <table id="table-vendors" cellpadding="0" cellspacing="0">
        <thead>
            <tr>
                <th class="ui-state-default">Vendor</th>
                <th class="ui-state-default">Bonus deduction</th>
                <th class="ui-state-default">Restricted Territories</th>
                <th class="ui-state-default">GmGaming API</th>
                <th class="ui-state-default">Logging</th>
                <th class="ui-state-default">Languages</th>
                <th class="ui-state-default">Currencies</th>
            </tr>
        </thead>
        <tbody>
            <% 
                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                List<ceCasinoVendor> vendors = cva.GetEnabledVendorList(DomainManager.CurrentDomainID, Constant.SystemDomainID).OrderBy(x => Enum.GetName(typeof(VendorID), x.VendorID)).ToList();
                int index = 0;
                foreach (ceCasinoVendor vendor in vendors)
                {  %>
                    <tr class="<%= ((index++) % 2 == 0) ? "odd" : "even" %>">
                        <td align="center"><%= Enum.GetName( typeof(VendorID), vendor.VendorID).SafeHtmlEncode() %></td>
                        <td align="right"><input class="input_box" name="BonusDeduction_<%= vendor.VendorID %>" value="<%= string.Format( "{0:N2}", vendor.BonusDeduction) %>" /> %</td>
                        <td align="right" style="cursor:pointer" class="RestrictedTerritories">
                            <input type="hidden" name="RestrictedTerritories_<%= (int)vendor.VendorID %>" 
                                value="<%= vendor.RestrictedTerritories.SafeHtmlEncode() %>" />
                            <input type="text" class="indicator" readonly="readonly" name="RestrictedTerritoriesCount_<%= (int)vendor.VendorID %>" 
                                value="<%= vendor.RestrictedTerritories.DefaultIfNullOrEmpty(string.Empty).Split(',').Where( a => a.Length > 0).Count() %>" />
                            Territory(s)
                        </td>
                        <td align="center">
                            <input type="checkbox" class="select_game" name="EnableGmGamingAPI_<%= vendor.VendorID %>" value="<%= vendor.VendorID %>" <%=vendor.EnableGmGamingAPI ? @" checked=""checked"" " : "" %> />
                        </td>
                        <td align="center">
                            <input type="checkbox" class="select_game" name="EnableLogging_<%= vendor.VendorID %>" value="<%= vendor.VendorID %>" <%=vendor.EnableLogging ? @" checked=""checked"" " : "" %> />
                        </td>
                        <td align="right" style="cursor:pointer" class="Languages">
                            <input type="hidden" name="Languages_<%= (int)vendor.VendorID %>" 
                                value="<%= vendor.Languages.SafeHtmlEncode() %>" />
                            <input type="text" class="indicator" readonly="readonly" name="LanguageCount_<%= (int)vendor.VendorID %>"
                                value="<%= vendor.Languages.DefaultIfNullOrEmpty(string.Empty).Split(',').Where( a => a.Length > 0).Count() %>" />
                            Language(s)
                        </td>
                        <td align="right" style="cursor:pointer" class="Currencies">
                            <input type="hidden" name="Currencies_<%= (int)vendor.VendorID %>" 
                                value="<%= vendor.Currencies.SafeHtmlEncode() %>" />
                            <input type="text" class="indicator" readonly="readonly" name="CurrenciesCount_<%= (int)vendor.VendorID %>"
                                value="<%= vendor.Currencies.DefaultIfNullOrEmpty(string.Empty).Split(',').Where( a => a.Length > 0).Count() %>" />
                            Currency(s)
                        </td>
                    </tr>
            <%  } %>
            
           
        </tbody>
        <tfoot>
        </tfoot>
    </table>

    <div class="table-footer ui-toolbar ui-widget-header ui-corner-bl ui-corner-br ui-helper-clearfix">
        <div class="footer-buttons">
            <% if (CurrentUserSession.IsSuperUser && DomainManager.AllowEdit())
               { %>
            <button type="submit" id="btnSaveVendorSettings">Save</button>
            <% }
               else
               {%>
            <script type="text/javascript">
                $(function () {
                    $('#table-vendors input.input_box').attr('disabled', true);
                    $('#dlgRestrictedTerritories :checkbox').attr('disabled', true);
                    $('#dlgLanguages :checkbox').attr('disabled', true);
                    $('#dlgCurrencies :checkbox').attr('disabled', true);
                });
            </script>
            <% } %>
        </div>
    </div>
</div>

</form>

<div id="dlgRestrictedTerritories" style="display:none" title="Restricted Territories">
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
</div>
<div id="dlgLanguages" style="display:none" title="Languages">
<ul>
<%
    List<SelectListItem> languagesList = GetLanguages();
    foreach (SelectListItem item in languagesList)
    {
        string controlID = string.Format("btnLanguage_{0}", item.Value);
        %>
        <li>
            <%: Html.CheckBox( "languages", item.Selected, new { @id=controlID, @value=item.Value } ) %>
            <label for="<%:controlID %>"><%= item.Text.SafeHtmlEncode() %></label>
        </li>
        <%    
    }
%>
</ul>
</div>
<div id="dlgCurrencies" style="display:none" title="Currencies">
<ul>
<%
    List<SelectListItem> currenciesList = GetCurrencies();
    foreach (SelectListItem item in currenciesList)
    {
        string controlID = string.Format("btnCurrency_{0}", item.Value);
        %>
        <li>
            <%: Html.CheckBox( "currencies", item.Selected, new { @id=controlID, @value=item.Value } ) %>
            <label for="<%:controlID %>"><%= item.Text.SafeHtmlEncode() %></label>
        </li>
        <%    
    }
%>
</ul>
</div>

<script type="text/javascript">
    $(function () {
        $('input.input_box')
        .bind('focus', function () { $(this).addClass('focused_input_box'); })
        .bind('blur', function () { $(this).removeClass('focused_input_box'); })
        .attr('autocomplete', 'off');

        $('#btnSaveVendorSettings').button({
            icons: {
                primary: "ui-icon-disk"
            }
        }).click(function (e) {
            e.preventDefault();
            var options = {
                dataType: 'json',
                success: function (json) {
                    $('#loading').hide();
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                }
            };
            $('#loading').show();
            $("#formSaveVendorSettings").ajaxSubmit(options);
        });

        function refreshCheckboxStatus() {
            $('#dlgRestrictedTerritories li.Checked').removeClass('Checked');
            var checkboxes = $('#dlgRestrictedTerritories :checkbox:checked');
            for (var i = 0; i < checkboxes.length; i++) {
                var id = checkboxes.eq(i).attr('id');
                $('#dlgRestrictedTerritories label[for="' + id + '"]').parent('li').addClass('Checked');
            }
        }

        $('#dlgRestrictedTerritories :checkbox').click(function (e) {
            setTimeout(refreshCheckboxStatus, 0);
        });

        $('#table-vendors tbody tr td.RestrictedTerritories').click(function (e) {
            e.preventDefault();
            $('#dlgRestrictedTerritories :checkbox:checked').attr('checked', false);
            var strCodes = $('input:hidden', $(this)).val().split(',');
            for (var i = 0; i < strCodes.length; i++) {
                $('#dlgRestrictedTerritories :checkbox[value="' + strCodes[i] + '"]').attr('checked', true);
            }
            setTimeout(refreshCheckboxStatus, 0);

            $('#dlgRestrictedTerritories').data('td', $(this));
            $('#dlgRestrictedTerritories').dialog({
                width: 700,
                height: $(document.body).height() - 50,
                modal: true,
                resizable: false,
                buttons: {
                    Ok: function () {
                        onDialogButtonOkClick();
                        $(this).dialog("close");
                    },
                    Cancel: function () {
                        $(this).dialog("close");
                    }
                }
            });
        });

        function refreshLanguagesCheckboxStatus() {
            $('#dlgLanguages li.Checked').removeClass('Checked');
            var checkboxesLanguages = $('#dlgLanguages :checkbox:checked');
            for (var i = 0; i < checkboxesLanguages.length; i++) {
                var id = checkboxesLanguages.eq(i).attr('id');
                $('#dlgLanguages label[for="' + id + '"]').parent('li').addClass('Checked');
            }
        }

        $('#dlgLanguages :checkbox').click(function (e) {
            setTimeout(refreshLanguagesCheckboxStatus, 0);
        });

        $('#table-vendors tbody tr td.Languages').click(function (e) {
            e.preventDefault();
            $('#dlgLanguages :checkbox:checked').attr('checked', false);
            var strCodesLanguages = $('input:hidden', $(this)).val().split(',');
            for (var i = 0; i < strCodesLanguages.length; i++) {
                $('#dlgLanguages :checkbox[value="' + strCodesLanguages[i] + '"]').attr('checked', true);
            }
            setTimeout(refreshLanguagesCheckboxStatus, 0);

            $('#dlgLanguages').data('td', $(this));
            $('#dlgLanguages').dialog({
                width: 700,
                height: $(document.body).height() - 50,
                modal: true,
                resizable: false,
                buttons: {
                    Ok: function () {
                        onLanguagesDialogButtonOkClick();
                        $(this).dialog("close");
                    },
                    Cancel: function () {
                        $(this).dialog("close");
                    }
                }
            });
        });

        function onLanguagesDialogButtonOkClick() {
            var strCodesLanguages = '';
            var optionsLanguages = $('#dlgLanguages :checkbox:checked');
            for (var i = 0; i < optionsLanguages.length; i++) {
                if (strCodesLanguages.length > 0)
                    strCodesLanguages += ',';
                strCodesLanguages += $(optionsLanguages[i]).val();
            }
            var $tdLanguages = $('#dlgLanguages').data('td');
            $('input.indicator', $tdLanguages).val(optionsLanguages.length);
            $('input:hidden', $tdLanguages).val(strCodesLanguages);
        }
        function onDialogButtonOkClick() {
            var strCodes = '';
            var options = $('#dlgRestrictedTerritories :checkbox:checked');
            for (var i = 0; i < options.length; i++) {
                if (strCodes.length > 0)
                    strCodes += ',';
                strCodes += $(options[i]).val();
            }
            var $td = $('#dlgRestrictedTerritories').data('td');
            $('input.indicator', $td).val(options.length);
            $('input:hidden', $td).val(strCodes);
        }

        function refreshCurrenciesCheckboxStatus() {
            $('#dlgCurrencies li.Checked').removeClass('Checked');
            var checkboxesCurrencies = $('#dlgCurrencies :checkbox:checked');
            for (var i = 0; i < checkboxesCurrencies.length; i++) {
                var id = checkboxesCurrencies.eq(i).attr('id');
                $('#dlgCurrencies label[for="' + id + '"]').parent('li').addClass('Checked');
            }
        }

        $('#dlgCurrencies :checkbox').click(function (e) {
            setTimeout(refreshCurrenciesCheckboxStatus, 0);
        });

        $('#table-vendors tbody tr td.Currencies').click(function (e) {
            e.preventDefault();
            $('#dlgCurrencies :checkbox:checked').attr('checked', false);
            var strCodesCurrencies = $('input:hidden', $(this)).val().split(',');
            for (var i = 0; i < strCodesCurrencies.length; i++) {
                $('#dlgCurrencies :checkbox[value="' + strCodesCurrencies[i] + '"]').attr('checked', true);
            }
            setTimeout(refreshCurrenciesCheckboxStatus, 0);

            $('#dlgCurrencies').data('td', $(this));
            $('#dlgCurrencies').dialog({
                width: 700,
                height: $(document.body).height() - 50,
                modal: true,
                resizable: false,
                buttons: {
                    Ok: function () {
                        onCurrenciesDialogButtonOkClick();
                        $(this).dialog("close");
                    },
                    Cancel: function () {
                        $(this).dialog("close");
                    }
                }
            });
        });

        function onCurrenciesDialogButtonOkClick() {
            var strCodesCurrencies = '';
            var optionsCurrencies = $('#dlgCurrencies :checkbox:checked');
            for (var i = 0; i < optionsCurrencies.length; i++) {
                if (strCodesCurrencies.length > 0)
                    strCodesCurrencies += ',';
                strCodesCurrencies += $(optionsCurrencies[i]).val();
            }
            var $tdCurrencies = $('#dlgCurrencies').data('td');
            $('input.indicator', $tdCurrencies).val(optionsCurrencies.length);
            $('input:hidden', $tdCurrencies).val(strCodesCurrencies);
        }

    });

    
</script>

</asp:Content>
