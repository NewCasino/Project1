<%@ Page Title="File Manager" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/swfobject.js") %>"></script>  
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/FileManager/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="file-manager-wrapper">
    <div class="left">
        <div class="list-wrapper"></div>

        <div id="links-wrapper">
        <ul id="file-dlg-links">
            <li><a title="Refresh" class="refresh" href="javascript:void(0)">Refresh</a></li>
            <li>|</li>
            <li><a title="Delete" class="delete" href="javascript:void(0)">Delete</a></li>
            <li>|</li>
            <li><a title="Create" class="create" href="javascript:void(0)">Create</a></li>
        </ul>
        </div>   

    </div>

    <div class="right">
        <div id="file-path-indicator">&nbsp;&nbsp;&nbsp;<span id="spFilePath"></span></div>
        <div id="file-preview"></div>
        <div id="uploader"></div>
    </div>
</div>


<script id="children-template" type="text/html">
<div class="type-parent-dir">
    <table cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="checkbox" align="center" valign="middle"><input type="checkbox" /></td>
            <td class="text" align="left" valign="middle">
                <div class="name"><a href="javascript:void(0)" target="_self">Move up a folder...</a></div>
            </td>
        </tr>
    </table>
</div>

<% using (Html.BeginRouteForm("FileManager"
       , new { @action = "Delete", @distinctName = (this.ViewData["DistinctName"] as string).DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formDelete" }))
   { %>
<#
var d=arguments[0];
for(var i=0; i < d.length; i++)     
{      
    var item = d[i]; 
#>

<div class="item type-<#= item.FileType.htmlEncode() #>">
    <table cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="checkbox" align="center" valign="middle"><input type="checkbox" name="path" value="<#= item.Path.htmlEncode() #>" /></td>
            <td class="text" align="left" valign="middle">
                <div class="name"><a href="javascript:void(0)" target="_self" fullpath="<#= item.FullPath.htmlEncode() #>" path="<#= item.Path.htmlEncode() #>" title="<#= item.FileName.htmlEncode() #>"><#= item.FileName.htmlEncode() #></a></div>
            </td>
        </tr>
    </table>
</div>

<# } #>

<% } %>
</script>

<% using (Html.BeginRouteForm("FileManager"
       , new { @action = "PrepareUpload", @distinctName = (this.ViewData["DistinctName"] as string).DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formPrepareUpload" }))
   { %>
   <input type="hidden" name="filename" />
   <input type="hidden" name="size" />
   <input type="hidden" name="path" />
<% } %>

<% using (Html.BeginRouteForm("FileManager"
       , new { @action = "CreateDir", @distinctName = (this.ViewData["DistinctName"] as string).DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formCreateDir" }))
   { %>
   <input type="hidden" name="dirname" />
   <input type="hidden" name="path" />
<% } %>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function FileManager() {
    $.ajaxSetup({ cache: false });

    self.fileManager = this;
    this.getChildrenAction = '<%= this.Url.RouteUrl( "FileManager", new { @action = "GetChildren", @distinctName = (this.ViewData["DistinctName"] as string).DefaultEncrypt() }).SafeJavascriptStringEncode() %>?path=';
    

    this.onBtnDeleteClick = function(){
        if( window.confirm( 'You are about to delete the selected items.\n\nClick "OK" to continue.' ) != true )
            return;

        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (data) {
                if (self.stopLoad) self.stopLoad();
                if (!data.success) { alert(data.error); return; }
                self.fileManager.refresh();
            }
        };
        $('#formDelete').ajaxForm(options);
        $('#formDelete').submit();   
    };

    this.onBtnCreateClick = function(){
        var dirName = window.prompt("Please enter the name of the new directory name below.");
        if( dirName == null || dirName == '' )
            return;

        $('#formCreateDir :input[name="path"]').val(this.currentPath);
        $('#formCreateDir :input[name="dirname"]').val(dirName);
        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (data) {
                if (self.stopLoad) self.stopLoad();
                if (!data.success) { alert(data.error); return; }
                self.fileManager.refresh();
            }
        };
        $('#formCreateDir').ajaxForm(options);
        $('#formCreateDir').submit();   
    };

    this.currentPath = "";
    this.refresh = function (path) {
        if (path != null)
            this.currentPath = path;
        $('#file-manager-wrapper div.list-wrapper').html('<img src="/images/icon/loading.gif" />');
        jQuery.getJSON(this.getChildrenAction + this.currentPath, null, function (data) {
            $('#file-manager-wrapper div.list-wrapper').html('');
            if (!data.success) { alert(data.error); return; }
            $('#file-manager-wrapper div.list-wrapper').html($('#children-template').parseTemplate(data.children));

            $('div.list-wrapper div.type-parent-dir a').css('display', (data.isRootDir ? 'none' : ''));

            $('div.list-wrapper div.type-parent-dir :input[type="checkbox"]').bind('click', function (e) {
                $('div.list-wrapper div.item :input[type="checkbox"]').attr('checked', $(this).attr('checked'));
            });

            $('div.list-wrapper div.type-0-dir a').bind('click', function (e) {
                self.fileManager.refresh($(this).attr('path'));
            });

            $('div.list-wrapper div.item a').bind('click', data.parentPath, function (e) {
                $('#spFilePath').text($(this).attr('fullpath'));
            });


            $('div.list-wrapper div.type-parent-dir a').bind('click', data.parentPath, function (e) {
                self.fileManager.refresh(e.data);
            });

            $('div.list-wrapper div.type-image a').bind('click', data.parentPath, function (e) {
                $('#file-preview').html('<img style="margin:5px;" border="0" src="' + $(this).attr('fullpath').htmlEncode() + '" />');
                parent.htmlToInsert = '<img border="" atl="" src="' + $(this).attr('fullpath').htmlEncode() + '" />';
            });

            $('div.list-wrapper div.type-txt a, div.list-wrapper div.type-xml a, div.list-wrapper div.type-html a').bind('click', data.parentPath, function (e) {
                $('#file-preview').html('<iframe style="width:100%; height:100%;" frameborder="0" src="' + $(this).attr('fullpath').htmlEncode() + '" />');
            });

            $('div.list-wrapper div.type-zip a').bind('click', data.parentPath, function (e) {
                $('#file-preview').html('');
            });

            $('div.list-wrapper div.type-flash a').bind('click', data.parentPath, function (e) {
                var html = '<object width="100%" height="100%" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://fpdownload.adobe.com/pub/shockwave/cabs/flash/swflash.cab#version=10,1,0,0"><param name="menu" value="false"/><param name="loop" value="false"/><param name="scale" value="noscale"/><param name="allowFullScreen" value="true"/><param name="allowScriptAccess" value="always"/><param name="movie" value="' + $(this).attr('fullpath').htmlEncode() + '"/><param name="quality" value="high"/><embed width="100%" height="100%" loop="false" scale="noscale" allowFullScreen="true" allowScriptAccess="always" src="' + $(this).attr('fullpath').htmlEncode() + '" quality="high" type="application/x-shockwave-flash" pluginspage="https://www.adobe.com/go/flashplayer/"></embed></object>';
                $('#file-preview').html(html);
                parent.htmlToInsert = html;
            });
        });
    };


    <%-- the method is called from flash to prepare the uploading --%>
    this.prepareUpload = function (filename, size) {
        if (self.startLoad) self.startLoad();

        $('#formPrepareUpload :input[name="filename"]').val(filename);
        $('#formPrepareUpload :input[name="size"]').val(size);
        $('#formPrepareUpload :input[name="path"]').val(self.fileManager.currentPath);

        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (data) {
                if (self.stopLoad) self.stopLoad();
                if (!data.success) { alert(data.error); return; }

                <%-- invoke the flash method to start upload --%>
                try{
                    document.getElementById('ctlFileUploader').startUpload(data.key);
                }
                catch(e){ alert(e); }
            }
        };
        $('#formPrepareUpload').ajaxForm(options);
        $('#formPrepareUpload').submit();     
    };

    this.init = function () {
        var image = new Image();
        try{
        image.src = '<%= this.Url.RouteUrl( "FileManager", new { @action = "PartialUpload" }).SafeJavascriptStringEncode() %>';
        }
        catch(e){}
        var flashvars = {
            cmSession: '<%= Profile.AsCustomProfile().SessionID.SafeJavascriptStringEncode() %>',
            PartialUploadUrl: image.src
        };
        var params = {
            menu: "false",
            wmode: "transparent",
            allowScriptAccess: "always",
            allowNetworking: "all"
        };
        var attributes = {
            id: "ctlFileUploader",
            name: "ctlFileUploader"
        };

        swfobject.embedSWF("/js/FileUploader.swf?_=2", "uploader", "100%", "70", "10.0.0", "/js/expressInstall.swf", flashvars, params, attributes);

        this.refresh();

        $('#file-dlg-links a.refresh').bind( 'click', this, function(e){
            e.data.refresh();
        });

        $('#file-dlg-links a.delete').bind( 'click', this, function(e){
            e.data.onBtnDeleteClick();
        });

        $('#file-dlg-links a.create').bind( 'click', this, function(e){
            e.data.onBtnCreateClick();
        });

        self.prepareUpload = this.prepareUpload;
    };

    this.init();
}
$(document).ready(function () { new FileManager(); });
</script>
</ui:ExternalJavascriptControl>



</asp:Content>



