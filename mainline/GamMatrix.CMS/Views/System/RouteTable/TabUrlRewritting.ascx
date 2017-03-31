<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="CM.db" %>

<div id="url-rewritting-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li> 
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li>
    <li>
        <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/url_rewrite.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </li>
</ul>
</div>

<hr class="seperator" />

<table id="table-rewritting" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-rewritting-url">Url</th>
            <th class="col-symbol"></th>
            <th class="col-rewritting-dest">Destination</th>
            <th class="col-tools"><a href="javascript:void(0)">Add New</a></th>
        </tr>
    </thead>
    <tbody>   
        

    </tbody>
</table>


<script id="rewrite-row-template" type="text/html">
<tr id="<#= arguments[0].guid#>">
    <td valign="middle" align="center" class="col-rewritting-url">
        <input type="text" class="rewritting-url" value="<#= arguments[0].Key.htmlEncode() #>" />
    </td>
    <td valign="middle" align="center" class="col-symbol">
        &gt;&gt;&gt;
    </td>
    <td valign="middle" align="center" class="col-rewritting-dest">
        <input type="text" class="rewritting-dest" value="<#= arguments[0].Value.htmlEncode() #>" />
    </td>
    <td valign="middle" align="center" class="col-tools">
        <a href="javascript:void(0)" target="_self" onclick="self.tabUrlRewritting.onBtnRemoveClick('<#= arguments[0].guid#>')">Remove</a>
    </td>
</tr>
</script>

<% using (Html.BeginForm( "SaveUrlRewriteRules"
       , null
       , new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formUrlRewritting"}
    ) ) { %>

<% } %>



<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script type="text/javascript">
function TabUrlRewritting(viewEditor) {
    self.tabUrlRewritting = this;

    this.getRulesAction = '<%= Url.RouteUrl( "RouteTable", new { @action = "GetUrlRewriteRules", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';

    

    this.onBtnAddNewRowClicked = function () {
        this.addNewRow();
    };

    this.S4 = function() {
       return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
    }
    this.guid = function() {
       return (this.S4()+this.S4()+this.S4()+this.S4()+this.S4()+this.S4()+this.S4()+this.S4());
    }


    this.onBtnRemoveClick = function($guid){    
        $('tr[id="' + $guid + '"]').remove();
    };
    this.addNewRow = function (json) {
        if (json == null) json = {};
        json.guid = this.guid();
        if (json.Key == null) json.Key = '';
        if (json.Value == null) json.Value = '';
        $('#table-rewritting tbody').append($('#rewrite-row-template').parseTemplate(json));
    };

    this.onLnkSaveClick = function () {
        $('#formUrlRewritting').html('');
        var rows = $('#table-rewritting > tbody > tr');

        var total = 0;
        for (var i = 0; i < rows.length; i++) {
            var url = $('input.rewritting-url', rows[i]).val();
            var dest = $('input.rewritting-dest', rows[i]).val();
            if (url == '' || dest == '')
                continue;
            $('#formUrlRewritting').append('<input type="hidden" name="Key_' + total + '" value="' + url.htmlEncode() + '" />');
            $('#formUrlRewritting').append('<input type="hidden" name="Value_' + total + '" value="' + dest.htmlEncode() + '" />');
            total++;
        }
        $('#formUrlRewritting').append('<input type="hidden" name="total" value="' + total.toString(10) + '" />');

        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (self.stopLoad) self.stopLoad();
                if (!json.success) { alert(json.error); return; }
                self.tabUrlRewritting.refresh();
            }
        };
        $('#formUrlRewritting').ajaxForm(options);
        $('#formUrlRewritting').submit();
    };

    this.refresh = function(){
        if( self.startLoad ) self.startLoad();
        jQuery.getJSON(this.getRulesAction, null, function (json) {
            if( self.stopLoad ) self.stopLoad();
            if (!json.success) { alert(json.error); return; }
            $('#table-rewritting > tbody').html('');
            for( var i = 0; i < json.data.length; i++){
                self.tabUrlRewritting.addNewRow(json.data[i]);
            }
        });
    };

    this.init = function () {
        InputFields.initialize($("#formTabGeneric"));

        $('#table-rewritting > thead th.col-tools > a').bind('click', this, function (e) { e.data.onBtnAddNewRowClicked(); });

        $('#url-rewritting-links a.save').bind( 'click', this, function(e){ e.data.onLnkSaveClick(); } );
        $('#url-rewritting-links a.refresh').bind('click', this, function (e) { e.data.refresh(); });

        $('#url-rewritting-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });

        this.refresh();
    };

    this.init();
}
</script>
</ui:ExternalJavascriptControl>
