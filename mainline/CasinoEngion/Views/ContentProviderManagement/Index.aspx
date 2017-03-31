<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" Inherits="System.Web.Mvc.ViewPage<List<CE.db.ceContentProviderBase>>" %>

<asp:Content ContentPlaceHolderID="phMain" runat="server">
 
 <style type="text/css">
     #table-content-providers td
     {
         height: 60px;
     }
.input_box { background-color:transparent; border:none; width:40px; text-align:right; color:White; }
.indicator { background-color:transparent; border:none; width:20px; text-align:right; color:White; }
.focused_input_box { background-color:White !important; color:Black; }
.header-buttons, .footer-buttons { float:right; margin:2px 10px 0px 0px; } 
#dlgRestrictedTerritories ul { list-style-type:none; margin:0px; padding:0px; }
#dlgRestrictedTerritories li { list-style-type:none; margin:0px; }
#dlgRestrictedTerritories li.Checked { background-color:Yellow; }
#dlgRestrictedTerritories li.Checked label { color:red; font-weight:bold; }
 </style>

<div id="table-vendors-wrapper" class="styledTable" style="max-width:750px">
    <div class="table-header ui-toolbar ui-widget-header ui-corner-tl ui-corner-tr ui-helper-clearfix">
        <div class="header-buttons">
            <%if ( DomainManager.CurrentDomainID == Constant.SystemDomainID && 
                  CurrentUserSession.UserDomainID == Constant.SystemDomainID) { %>
            <% if(DomainManager.AllowEdit()) { %>
            <button type="submit" id="btnAdd">Add</button>
            <% } %>
            <%} %>
        </div>
    </div>


    <div id="providerListHolder" style="background-color:#000000;"></div>

    <div class="table-footer ui-toolbar ui-widget-header ui-corner-bl ui-corner-br ui-helper-clearfix">
        <div class="footer-buttons">
        <% if(DomainManager.AllowEdit()) { %>
        <button type="button" id="btnEnableSelectedProviders">Enable Selected...</button>
        <button type="button" id="btnDisableSelectedProviders">Disable Selected...</button>
        <% } %>
        </div>
    </div>

    <form id="formEnableProviders" style="display:none" target="_self" action="<%= this.Url.ActionEx("Enable").SafeHtmlEncode() %>" method="post"></form>
</div>

<div id="dlgAdd" style="display:none" title="Restricted Territories"></div>

<script type="text/javascript">

    function editProvider(id)
    {
        $('#dlgAdd').html('<img src="/images/loading.icon.gif" /> Downloading data from third parties...').modal({
            minWidth: 680,
            minHeight: 300,
            dataCss: { padding: "0px" }
        });

        var url = '<%= this.Url.ActionEx("ProviderEditorDialog").SafeJavascriptStringEncode() %>';
        if (id)
            url += '?id='+id;
        $('#dlgAdd').load(url);
    }

    function loadProviderList()
    {
        $('#loading').show();
        var url = '<%= this.Url.ActionEx("ProviderList").SafeJavascriptStringEncode() %>?_t='+(new Date()).getTime();
        $('#providerListHolder').html('<img src="/images/loading.icon.gif" /> Downloading data from third parties...').load(url, function () {
            $('#loading').hide();
        });
    }

    $(function () {
        loadProviderList();

        $('#btnAdd').button({
            icons: {
                primary: "ui-icon-plusthick"
            }
        }).click(function (e) {
            e.preventDefault();

            editProvider();
        });

        function enableProviders(enable) {
            $('#formEnableProviders').empty();
            var $inputs = $('#table-content-providers input.select_provider:checked');
            if ($inputs.length == 0) {
                alert('Please select at least one content provider!');
                return;
            }
            $inputs.clone().appendTo($('#formEnableProviders')).attr('name', 'providerIDs');

            var options = {
                dataType: 'json',
                data: { enable: enable },
                success: function (json) {
                    $('#loading').hide();
                    if (!json.success)
                        alert(json.error);
                    $(document).trigger('CONTENT_PROVIDER_CHANGED');
                }
            };
            $('#loading').show();
            $("#formEnableProviders").ajaxSubmit(options);
        }

        $('#btnEnableSelectedProviders').button().click(function () { enableProviders(true); });
        $('#btnDisableSelectedProviders').button().click(function () { enableProviders(false); });
    });

    $(document).on('CONTENT_PROVIDER_CHANGED', function () { loadProviderList(); });
</script>

</asp:Content>
