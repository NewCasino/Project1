<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>


<table id="revision-table" class="console-content-table" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th>ID</th>
            <th colspan="2"><ui:Button runat="server" ID="btnCompare" type="button">Compare</ui:Button></th>
            <th>Time</th>
            <th>Comments</th>
            <th>Operator</th>
            <th>&nbsp;</th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>



<script id="row-template" type="text/html">
<#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

<tr revision="<#= item.ID #>">
    <td align="center" class="col-1"><#= item.ID #></td>
    <td align="center" class="col-2"><input type="radio" name="compare_from" class="<#= item.ViewCss #>" /></td>
    <td align="center" class="col-3"><input type="radio" name="compare_to" class="<#= item.ViewCss #>" /></td>
    <td align="center" class="col-4"><#= item.Ins #></td>
    <td class="col-5"><#= item.Comments.htmlEncode() #></td>
    <td align="center" class="col-6"><#= item.Username.htmlEncode() #></td>
    <td align="center" class="col-7">
            <a href="javascript:void(0)" target="_self" class="icoView <#= item.ViewCss #>">View</a>
            <% if (this.Model.NodeStatus != ContentNode.ContentNodeStatus.Inherited)
    { %>
            <span class="<#= item.SeperatorCss #>">|</span>
            <a href="javascript:void(0)" target="_self" class="icoRollback <#= item.RollbackCss #>">Rollback</a>
    <% } %>

            <% if( this.Model.NodeStatus == CM.Content.ContentNode.ContentNodeStatus.Overrode ) { %>
            <br />
            <a href="javascript:void(0)" target="_self" class="icoCompare <#= item.ViewCss #>">Compare with template</a>
            <% } %>
            <% if( this.Model.RelativePath.ToLowerInvariant().Contains("countries.setting") ) { %>
            <span class="block">|</span>
            <a href="javascript:void(0)" target="_self" class="showChanges <#= item.ViewCss #>">Changes</a>
            <% } %>
    </td>
</tr>
<#   }  #>
</script>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function TabHistory(viewEditor) {
    self.tabHistory = this;
    this.viewEditor = viewEditor;
    this.btnCompare = '#<%= btnCompare.ClientID %>';
    this.getRevisionsAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="GetRevisions", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt(), @searchPattner = this.ViewData["HistorySearchPattner"] }).SafeJavascriptStringEncode() %>';
    this.codeViewAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="CodeView" }).SafeJavascriptStringEncode()%>?revisionID=';
    this.rollbackAction = '<%= Url.RouteUrl( "HistoryViewer", new{ @action="Rollback" }).SafeJavascriptStringEncode()%>?revisionID=';
    this.compareRevisionsAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="CompareRevisions" }).SafeJavascriptStringEncode()%>';
    this.compareWithTemplateAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="CompareWithTemplate", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>&revisionID=';
    this.showChangesAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="showChanges" }).SafeJavascriptStringEncode()%>';

    this.onResponse = function (data) {
        if (self.stopLoad)
            self.stopLoad();

        if (!data.success) {
            alert(data.error);
            return;
        }

        $('#revision-table > tbody').html($('#row-template').parseTemplate(data.revisions));

        $('#revision-table > tbody a.icoView').bind('click', this, function (e) { self.tabHistory.onLnkViewClick($(this).parent('td').parent('tr').attr('revision')); });

        $('#revision-table > tbody a.icoRollback').bind('click', this, function (e) { self.tabHistory.onLnkRollbackClick($(this).parent('td').parent('tr').attr('revision')); });

        $('#revision-table > tbody a.icoCompare').bind('click', this, function (e) { self.tabHistory.onLnkCompareWithTemplateClick($(this).parent('td').parent('tr').attr('revision')); });

        $('#revision-table > tbody a.showChanges').bind('click', this, function (e) {
            var recentRevisonId = $(this).parent('td').parent('tr').attr('revision');
            var prevRevisonId = $(this).parent('td').parent('tr').next("tr").attr('revision');
            if (prevRevisonId == undefined) {
                alert("sorry, can't find the previous revision");
                return;
            }
            window.open((self.tabHistory.showChangesAction + "?srcRevID=" + recentRevisonId + "&destRevID=" + prevRevisonId)
            , '_blank'
            , 'fullscreen=yes,location=no,menubar=no,resizable=1,scrollbars=1,status=0,titlebar=1,toolbar=0'
            );
        });

        return;
        $('#revision-table > tbody').find('input[type=radio][data-viewable=0]').hide();

        $('#revision-table > tbody').find('a[data-viewable=0]').hide();

        $('#revision-table > tbody').find('a[data-rollbackable=0]').hide();

        $('#revision-table > tbody').find('span[data-seperator=00]').hide();

        $('#revision-table > tbody').find('br[data-newline=00]').hide();
    };

    this.onLnkViewClick = function (id) {
        window.open(this.codeViewAction + id
        , '_blank'
        , 'fullscreen=yes,location=no,menubar=no,resizable=1,scrollbars=1,status=0,titlebar=1,toolbar=0'
        );
    };

    this.onLnkRollbackClick = function (id) {
        if (window.confirm('You are about to roll the changes back to this revision. \nPlease "OK" to continue.') != true)
            return;
        if (self.startLoad)
            self.startLoad();
        jQuery.getJSON(this.rollbackAction + id, null, function (data) {
            if (self.stopLoad)
                self.stopLoad();
            if (!data.success) alert(data.error);
            else {
                alert('The operation is completed successfully.\nPlease "OK" to reload this page.');
                self.location = self.location;
            }
        });
    };

    this.onLnkCompareWithTemplateClick = function (id) {
        window.open(this.compareWithTemplateAction + id
        , '_blank'
        , 'fullscreen=yes,location=no,menubar=no,resizable=0,scrollbars=0,status=0,titlebar=1,toolbar=0'
        );
    };

    this.load = function () {
        $('#revision-table > tbody').html("");
        if (self.startLoad)
            self.startLoad();

        jQuery.getJSON(this.getRevisionsAction, null, self.tabHistory.onResponse);
    };

    this.onBtnCompareClick = function () {
        var src = $('#revision-table td.col-2 input:checked').parent('td').parent('tr');
        var dest = $('#revision-table td.col-3 input:checked').parent('td').parent('tr');

        if( src.length == 0 || dest.length == 0 ){
            alert("Please choose two revisions to compare.");
            return;
        }

        var srcRevID = src.attr('revision');
        var destRevID = dest.attr('revision');

        window.open( (this.compareRevisionsAction + "?srcRevID=" + srcRevID + "&destRevID=" + destRevID)
            , '_blank'
            , 'fullscreen=yes,location=no,menubar=no,resizable=1,scrollbars=1,status=0,titlebar=1,toolbar=0'
            );
    };

    this.init = function () {
        $(this.btnCompare).bind('click', this, function (e) { e.data.onBtnCompareClick(); });
    };

    this.init();
}
</script>
</ui:ExternalJavascriptControl>