<%@ Page Title="Advanced Editor" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script language="javascript" type="text/javascript" src="/js/tinymce/jquery.tinymce.js"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/MetadataEditor/AdvancedEditor.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="file-manager-dialog" title="File manager" style="display:none">
<iframe frameborder="0" id="ifmFileManager" name="ifmFileManager" src="about:blank"></iframe>
</div>


<div id="metadata-selector-modal" title="Select metadata entry..." style="display:none">
<iframe frameborder="0" id="ifmMetadataDlg" name="ifmMetadataDlg" src="about:blank"></iframe>
</div>


<div id="translation-wrap">
<div class="language-nav country-flags">
<br /><br />
<div class="language-item first-language-item">
    <span><img src="/images/transparent.gif" />&nbsp;Default</span>
    <textarea name="default_value_<%= (this.ViewData["EntryName"] as string).SafeHtmlEncode() %>" style="display:none"><%= (this.ViewData["Default"] as string).SafeHtmlEncode() %></textarea>
</div>

<% LanguageInfo[] languages = this.ViewData["Languages"] as LanguageInfo[];
   foreach (LanguageInfo language in languages)
   { %>
<div class="language-item">
    <span><img src="/images/transparent.gif" class="<%= language.CountryFlagName.SafeHtmlEncode() %>" />&nbsp;<%= language.DisplayName.SafeHtmlEncode() %></span>
    <textarea name="translation_<%= language.LanguageCode.SafeHtmlEncode()%>_<%= (this.ViewData["EntryName"] as string).SafeHtmlEncode() %>" style="display:none"><%= (this.ViewData[language.LanguageCode] as string).SafeHtmlEncode()%></textarea>
</div>
<% } %>

</div>
<% using (Html.BeginForm("SaveAll"
       , null
       , new { @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formAdvancedEditor" }
    ))
   { %>
        

    <div class="translation-editor-container" align="right">
        <textarea id="translation-editor" readonly="readonly"></textarea>
    </div>

<% } %>
</div>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function MetadataDialog() {
    self.metadataDlialog = this;
    this.init = function () {
        $('#translation-wrap .language-item').bind('click', this, function (e) {
            $(this).siblings().removeClass('selected');
            $(this).addClass('selected');
            $('#translation-editor').tinymce().setContent($(this).children('textarea').text());
            $('#translation-editor').attr( 'name', $(this).children('textarea').attr('name') );
        });

        $('#translation-editor').tinymce({
		    <%--  Location of TinyMCE script --%>
		    script_url : '/js/tinymce/tiny_mce.js',

		    <%-- General options --%>
		    theme : "advanced",
		    plugins : "pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,advlist",

		    <%-- Theme options --%>
		    theme_advanced_buttons1 : "save,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,styleselect,formatselect,fontselect,fontsizeselect",
		    theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,|,insertdate,inserttime,preview,|,forecolor,backcolor",
		    theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,iespell,media,advhr,|,print,|,ltr,rtl",
		    theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,pagebreak,|,code,fullscreen,metadata,filemanager",
		    theme_advanced_toolbar_location : "top",
		    theme_advanced_toolbar_align : "left",
		    theme_advanced_statusbar_location : "bottom",
            relative_urls : false,
            convert_urls : false,
			
            verify_html : false,
            forced_root_block : false,
            theme_advanced_resizing : false,

            setup : function(ed) {
                ed.onInit.add(function(ed) {
                    $('.language-nav .first-language-item').addClass('selected');
                    $('#translation-editor').tinymce().setContent($('.language-nav .first-language-item textarea').text());
                    $('#translation-editor').attr( 'name', $('.language-nav .first-language-item textarea').attr('name') );
                });

                ed.onBeforeExecCommand.add(function(ed, cmd, ui, val, o) {
                    if( cmd == "mceSave" ){
                        o.terminate = true;
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
                            }
                        };
                        $('#formAdvancedEditor').ajaxForm(options);
                        $('#formAdvancedEditor').submit();
                    }
                });

                ed.onChange.add(function(ed, l) {
                    $('.language-nav .language-item textarea[name="' + $('#translation-editor').attr('name') + '"]').text(l.content);         
                });

                ed.addButton('metadata', {
                    title : 'Insert metadata...',
                    image : '/js/tinymce/metadata.png',
                    onclick : function() {
                        self.metadataDlialog.onBtnInsertMetadataClicked();
                    }
                });

                ed.addButton('filemanager', {
                    title : 'File manager',
                    image : '/js/tinymce/filemanager.png',
                    onclick : function() {
                        self.metadataDlialog.onBtnFileManagerClicked();
                    }
                });
            }
            
	    });
    };

    this.onBtnFileManagerClicked = function(){
        $('#ifmFileManager').attr( 'src', 'about:blank');
        $("#file-manager-dialog").dialog({
            height: 500,
            width: '90%',
            draggable: false,
            resizable: false,
            modal: true,
            buttons: {
                OK: function () {
                    if( self.htmlToInsert != null && self.htmlToInsert != "" ){
                        $('#translation-editor').tinymce().focus();
                        $('#translation-editor').tinymce().execCommand('mceReplaceContent',false,self.htmlToInsert);
                        //$('#translation-editor').tinymce().selection.setContent(self.htmlToInsert);
                    }
                    $(this).dialog('close');
                },
                Cancel: function () {
                    $(this).dialog('close');
                }
            }
        });
        var url = '<%= Url.RouteUrl( "FileManager", new { @action="Index", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
        $('#ifmFileManager').attr( 'src', url);
    };

    this.onBtnInsertMetadataClicked = function(){
        self.lastSelectedExpression = null;
        $('#ifmMetadataDlg').attr( 'src', 'about:blank');
        $("#metadata-selector-modal").dialog({
            height: 500,
            width: '90%',
            draggable: false,
            resizable: false,
            modal: true,
            buttons: {
                OK: function () {
                    if( self.lastSelectedExpression != null ){
                        $('#translation-editor').tinymce().focus();
                        $('#translation-editor').tinymce().execCommand('mceReplaceContent',false,self.lastSelectedExpression.htmlEncode());
                        //$('#translation-editor').tinymce().selection.setContent(self.lastSelectedExpression.htmlEncode());
                    }
                    $(this).dialog('close');
                },
                Cancel: function () {
                    $(this).dialog('close');
                }
            }
        });
        var url = '<%= Url.RouteUrl( "MetadataEditor", new { @action="MetadataSelector", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
        $('#ifmMetadataDlg').attr( 'src', url);
    };

    this.init();
}

$(document).ready(function () { new MetadataDialog(); });
</script>
</ui:ExternalJavascriptControl>

</asp:Content>

