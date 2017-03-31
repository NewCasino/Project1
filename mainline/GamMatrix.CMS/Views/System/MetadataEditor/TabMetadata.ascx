<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="CM.Content" %>

<script language="C#" type="text/C#" runat="server">
    private SelectList GetLanguages()
    {
        return new SelectList(SiteManager.GetSiteByDistinctName(this.Model.ContentTree.DistinctName).GetSupporttedLanguages()
            , "LanguageCode"
            , "DisplayName"
            , this.ViewData["Language"]
            );
    }

    private bool IsCMSSystemAdminUser
    {
        get
        {
            return Profile.IsInRole("CMS System Admin") || Profile.IsInRole("CMS Admin");
        }
    }

    private bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }

    private bool AllowToControl { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        AllowToControl = true;
        if (!IsCMSSystemAdminUser)
        {
            if (this.Model.RelativePath.StartsWith("/Metadata/Settings/Registration", StringComparison.OrdinalIgnoreCase)
             || this.Model.RelativePath.StartsWith("/Metadata/Settings/QuickRegistration", StringComparison.OrdinalIgnoreCase)
			 || (this.Model.RelativePath.StartsWith("/Metadata/Footer", StringComparison.OrdinalIgnoreCase) && Settings.Site_IsUnWhitelabel)
             || (this.Model.RelativePath.StartsWith("/Metadata/TermsConditions", StringComparison.OrdinalIgnoreCase) && Settings.Site_IsUnWhitelabel))
            {
                AllowToControl = false;
            }
        }
    }
</script>

<% using (Html.BeginRouteForm( "MetadataEditor"
       , new { @action="SaveAll", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formMetadata"}
    ) ) { %>

            
<div id="metadata-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <%if (AllowToControl) { %>
    <li>|</li> 
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li> 
    <li><a href="javascript:void(0)" target="_self" class="create">Create...</a></li>
    <%} %>
</ul>
</div>

<hr class="seperator" />

<table id="metadata-table" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th>Name</th>
            <th>Default value</th>
            <th>Translation&nbsp;
            <%: Html.DropDownList( "currenLang" , GetLanguages() , new { @id= "cmbLanguage"} ) %></th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>

<% } %>

<div id="metadata-modal" style="display:none">
<iframe frameborder="0" id="ifmDialog" name="ifmDialog" src="about:blank"></iframe>
</div>

<script id="metadata-row-template" type="text/html">
<#
var d=arguments[0];
if( d.length == 0 ){
#>

<#   }  #>

<#
    var focusedKey = '<%= (this.ViewData["Key"] as string).SafeJavascriptStringEncode() %>';
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

<tr id="<#= item.Name.htmlEncode() #>" status="<#= item.Status.htmlEncode() #>" class="<#= (focusedKey == item.Name) ? 'focus' : '' #>">
    <td class="col-name" valign="top" align="left">
        <span title="<#= item.EntryPath.htmlEncode() #>" class="<#= item.Status.htmlEncode() #>"><#= item.Name.htmlEncode() #></span><br />
        <%if(AllowToControl){%>
        <a href="javascript:void(0)" target="_self" class="icoHtml">Advanced editor</a><br />
        <a href="<%= Url.RouteUrl( "HistoryViewer", new { @action = "Dialog", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeHtmlEncode() %>&searchPattner=%2f.<#= item.Name.htmlEncode() #>%25" target="_blank" class="icoHistory">View history</a><br />
        <%} %>
        <a href="<%= Url.RouteUrl( "MetadataEditor", new { @action = "Preview", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeHtmlEncode() %>?id=<#= item.Name.htmlEncode() #>" target="_blank" class="icoPreview">Preview</a><br />
        <# if( item.Status != 'inherited' ) { #>
        <a href="javascript:void(0)" target="_self" class="icoDelete">Delete</a><br />   
        <# } #>
    </td>
    <td class="col-value" valign="top" align="center">
        <textarea name="default_value_<#= item.Name.htmlEncode() #>"><#= item.Default.htmlEncode() #></textarea>
    </td>
    <td class="col-translation" valign="top" align="center">
        <textarea></textarea>
    </td>
</tr>
<#   }  #>
</script>

<div id="metadata-modal-dialog" title="Create a New Entry..." style="display:none">
    <% using (Html.BeginRouteForm("MetadataEditor"
       , new { @action = "CreateEntry", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formCreateEntry"} ) )
       { %>
        <ui:InputField id="fldEntryName" runat="server">
            <LabelPart>
            Name:
            </LabelPart>
            <ControlPart>
            <%: Html.TextBox( "entryName"
                , ""
                , new { @id="txtEntryName", @validator = ClientValidators.Create().Required() } 
                ) %>
            </ControlPart>
        </ui:InputField>
        
        <div class="buttons-wrap">
            <%: Html.Button("Create", new { @id = "btnCreateEntry" })  %>
        </div>
    <% } %>
</div>



<ui:ExternalJavascriptControl runat="server">
<script language="javascript" type="text/javascript">
function TabMetadata() {
    self.tabMetadata = this;
    this.getAllEntriesAction = '<%= this.Url.RouteUrl( "MetadataEditor", new { @action = "GetAllEntries", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
    this.dialogAction = '<%= this.Url.RouteUrl( "MetadataEditor", new { @action = "AdvancedEditor", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
    this.getSpecialLanguageEntriesAction = '<%= this.Url.RouteUrl( "MetadataEditor", new { @action = "GetSpecialLanguageEntries", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?lang=';
    this.deleteAction = '<%= this.Url.RouteUrl( "MetadataEditor", new { @action = "Delete", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?id=';

    this.currentSelected = null;
    this.onRowSelected = function (row) {
        if (this.currentSelected != null) {
            if (this.currentSelected.get(0) == row.get(0))
                return;
            this.currentSelected.removeClass('selected');
            this.currentSelected.find('textarea').animate({
                height: this.originalHeight
            }, 1000);
        }
        this.currentSelected = row;
        row.addClass('selected');

        if (this.originalHeight == null)
            this.originalHeight = row.find('textarea').height();
        row.find('textarea').animate({
            height: "150px"
        }, 1000);
    };

    this.loadSpecialLanguage = function () {
        $('#cmbLanguage').attr('disabled', 'disabled');
        $('#metadata-table > tbody > tr .col-translation textarea').attr('disabled', 'disabled');
        jQuery.getJSON(this.getSpecialLanguageEntriesAction + $('#cmbLanguage').val(), null, function (data) {
            $('#cmbLanguage').attr('disabled', null);
            if (!data.success) { alert(data.error); return; }
            var rows = $('#metadata-table > tbody > tr');
            for (var i = 0; i < rows.length; i++) {
                var tran = data.data[$(rows[i]).attr('id')];
                $(rows[i]).find('.col-translation textarea').val((tran != null) ? tran : "").attr('disabled', null).attr('name', 'translation_' + $('#cmbLanguage').val() + '_' + $(rows[i]).attr('id'));
            }
        });
    };

    this.onLnkEditHtmlClicked = function ($id) {
        $('#ifmDialog').attr('src', 'about:blank');
        $("#metadata-modal").dialog({
            height: 600,
            width: '90%',
            draggable: false,
            resizable: false,
            modal: true,
            title: '<%= this.Model.RelativePath.SafeJavascriptStringEncode() %>.' + $id,
            close: (function (id) {
                return function () {
                    var getEntryValueAction = '<%= Url.RouteUrl( "MetadataEditor", new { @action = "GetEntryValue", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?id=' + id;
                    $('#metadata-table > tbody > tr[id="' + id + '"] textarea').attr('disabled', 'disabled');
                    jQuery.getJSON(getEntryValueAction, null, function (data) {
                        if (!data.success) { alert(data.error); return; }
                        $('#metadata-table tr[id="' + id + '"] textarea').attr('disabled', null);
                        $('#metadata-table tr[id="' + id + '"] .col-value textarea').val(data.data['Default']);
                        $('#metadata-table tr[id="' + id + '"] .col-translation textarea').val(data.data[$('#cmbLanguage').val()]);
                    });
                };
            })($id)
        });

        var url = this.dialogAction + '?id=' + $id;
        $('#ifmDialog').attr('src', url);
    };

    this.onLnkViewHistoryClicked = function ($id) {
        window.open(this.viewHistoryAction + $id + '%25'
        , '_blank'
        , 'fullscreen=yes,location=no,menubar=no,resizable=1,scrollbars=0,status=0,titlebar=1,toolbar=0'
        );
    };

    this.onLnkDeleteClicked = function ($id) {
        var msg = 'You are going to remove the entry [' + $id + '].\n\n';
        if ($('#metadata-table > tbody > tr[id="' + $id + '"]').attr('status') == 'overrode') {
            msg += 'NOTE, you are trying to remove an overridden entry and after deleted, the inherited entry will still be exist(you need click "Refresh").\n\n';
        }
        msg += 'Press "OK" to continue.';

        if (window.confirm(msg) != true)
            return;
        jQuery.getJSON(this.deleteAction + $id, null, function (data) {
            if (!data.success) { alert(data.error); return; }
            $('#metadata-table > tbody > tr[id="' + data.name + '"]').remove();
        });
    };


    this.onLnkSaveClicked = function () {
        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (self.stopLoad) self.stopLoad();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                $('#txtEntryName').val('');
            }
        };
        $('#formMetadata').ajaxForm(options);
        $('#formMetadata').submit();
    };

    this.refresh = function () {
        this.currentSelected = null;
        $('#metadata-table > tbody').html('<tr><td colspan="3"><img src="/images/icon/loading.gif" /></td></tr>');
        jQuery.getJSON(this.getAllEntriesAction, null, function (data) {
            if (!data.success) { alert(data.error); return; }

            $('#metadata-table > tbody').html($('#metadata-row-template').parseTemplate(data.entries));

            if ($('#metadata-table > tbody tr').length > 1)
                $('#metadata-table > tbody tr.focus').detach().insertBefore($('#metadata-table > tbody tr:first'));

            $('#metadata-table > tbody > tr')
                .mouseover(function () { $(this).addClass('hover'); })
                .mouseleave(function () { $(this).removeClass('hover'); });
            $('#metadata-table > tbody > tr textarea').bind('focus', function (e) {
                self.tabMetadata.onRowSelected($(this).parent('td').parent('tr'));
            });
            $('#metadata-table > tbody > tr a.icoHtml').bind('click', function (e) {
                self.tabMetadata.onLnkEditHtmlClicked($(this).parent('td').parent('tr').attr('id'));
            });

            $('#metadata-table > tbody > tr a.icoDelete').bind('click', function (e) {
                self.tabMetadata.onLnkDeleteClicked($(this).parent('td').parent('tr').attr('id'));
            });

            self.tabMetadata.loadSpecialLanguage();
        });
    };

    this.onBtnCreateEntryClick = function () {
        if ($("#formCreateEntry").valid()) {
            if (self.startLoad) self.startLoad();
            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    self.tabMetadata.refresh();
                }
            };
            $('#formCreateEntry').ajaxForm(options);
            $('#formCreateEntry').submit();
        }
    };

    this.init = function () {
        this.refresh();
        $('#cmbLanguage').bind('change', this, function (e) { e.data.loadSpecialLanguage(); });
        $('#metadata-links a.refresh').bind('click', this, function (e) { e.data.refresh(); });
        $('#metadata-links a.save').bind('click', this, function (e) { e.data.onLnkSaveClicked(); });
        $('#metadata-links a.create').bind('click', this, function (e) {
            $("#metadata-modal-dialog").dialog({
                height: 100,
                width: 410,
                draggable: false,
                resizable: false,
                modal: true
            });
        });

        $('#txtEntryName').keypress(function (e) {
            if (e.which >= 65 && e.which <= 90)
                return;
            if (e.which >= 97 && e.which <= 122)
                return;
            if (e.which >= 48 && e.which <= 57)
                return;
            if (e.which == 95 || e.which == 45 || e.which == 8 || e.which == 127 || e.which == 0)
                return;
            e.preventDefault();
        }
        );

        $('#txtEntryName').change(function (e) {
            var str = $('#txtEntryName').val();
            $('#txtEntryName').val(str.replace(/[^\w\_\-]/g, ""));
        }
        );

        InputFields.initialize($("#formCreateEntry"));

        $('#btnCreateEntry').bind('click', this, function (e) { e.preventDefault(); e.data.onBtnCreateEntryClick(); });
    };

    this.init();
};
</script>
</ui:ExternalJavascriptControl>