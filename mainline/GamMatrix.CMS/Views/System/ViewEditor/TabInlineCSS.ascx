<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>

<script runat="server" type="text/C#">
    private string GetInlineCssUrl
    {
        get
        {
            ContentNode metadataNode = this.ViewData["MetadataNode"] as ContentNode;
            return this.Url.RouteUrl("MetadataEditor"
                , new { @action = "GetEntryValue", distinctName = metadataNode.ContentTree.DistinctName.DefaultEncrypt(), @id = "InlineCSS", @path = metadataNode.RelativePath.DefaultEncrypt() }
                );
        }
    }

    private string SaveInlineCssUrl
    {
        get
        {
            ContentNode metadataNode = this.ViewData["MetadataNode"] as ContentNode;
            return this.Url.RouteUrl("MetadataEditor"
                , new { @action = "SaveAll", distinctName = metadataNode.ContentTree.DistinctName.DefaultEncrypt(), @path = metadataNode.RelativePath.DefaultEncrypt() }
                );
        }
    }

    private string ViewHistoryUrl
    {
        get
        {
            ContentNode metadataNode = this.ViewData["MetadataNode"] as ContentNode;
            return this.Url.RouteUrl("HistoryViewer"
                , new { @action = "Dialog", @distinctName = metadataNode.ContentTree.DistinctName.DefaultEncrypt(), @relativePath = metadataNode.RelativePath.DefaultEncrypt(), @searchPattner = "/.InlineCSS" })
                ;
        }
    }
</script>

<div id="css-editor-wrapper">
<ul id="css-editor-toolbar">
    <li class="icoSave"><a title="Save" href="javascript:void(0)">Save</a></li>
    <li>|</li>
    <li class="icoReload"><a title="Reload" href="javascript:void(0)">Reload</a></li>
    <li>|</li>
    <li class="icoFileManager"><a title="File Manager" href="javascript:void(0)">File Manager</a></li>
    <li>|</li>
    <li class="icoViewHistory"><a title="View History" href="javascript:void(0)">View History</a></li>
</ul>
<div id="css-editor"></div>
</div>   

<form id="formSaveInlineCSS" action="<%= SaveInlineCssUrl.SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">
    <input type="hidden" name="default_value_InlineCSS" />
</form>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script type="text/javascript">
    function onCssEditorLoaded() {
        if (self.startLoad) self.startLoad();
        var url = '<%= this.GetInlineCssUrl.SafeJavascriptStringEncode() %>';
        $.getJSON(url, function (json) {
            if (self.stopLoad) self.stopLoad();
            if (!json.success) {
                alert(json.error);
                return;
            }
            try {
                document.getElementById('ctlCssFlash').setText(json.data.Default);
            } catch (e) { /*alert(e)*/ }
        });
        
    }

    function TabInlineCSS(viewEditor) {
        this.viewEditor = viewEditor;

        this.load = function () {
            this.loadFlash($(document.body).height() - 200);
            onCssEditorLoaded();//For IE
        };

        this.loadFlash = function (height) {
            // initialize with parameters
            var flashvars = {
                parser: "css",
                readOnly: false,
                preferredFonts: "|Consolas|Courier New|Courier|Fixedsys|Fixedsys Excelsior 3.01|Fixedsys Excelsior 3.00|",
                onload: "onCssEditorLoaded"
            };

            var params = { menu: "false", wmode : "transparent", allowscriptaccess: "always" };
            var attributes = { id: "ctlCssFlash", name: "ctlCssFlash" };

            swfobject.embedSWF("/js/CodeHighlightEditor.swf?Now=" + (new Date()).toGMTString(), "css-editor", "100%", height, "10.0.0", "/js/expressInstall.swf", flashvars, params, attributes);
        }


        this.onBtnSaveClick = function () {
            try {
                if (self.startLoad) self.startLoad();
                $('#formSaveInlineCSS :hidden').val(document.getElementById('ctlCssFlash').getText());
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
                $('#formSaveInlineCSS').ajaxForm(options);
                $('#formSaveInlineCSS').submit();
            } catch (e) { alert(e) }
        };

        this.onBtnReloadClick = function () {
            if (window.confirm('You are about to reload, please "OK" to continue.') == true) {
                onCssEditorLoaded();
            }
        };

        this.init = function () {
            $('#css-editor-wrapper .icoSave > a').bind('click', this, function (e) { e.data.onBtnSaveClick(); });
            $('#css-editor-wrapper .icoReload > a').bind('click', this, function (e) { e.data.onBtnReloadClick(); });


            $('#css-editor-wrapper .icoViewHistory > a').bind('click', this, function (e) {
                var url = '<%= ViewHistoryUrl.SafeJavascriptStringEncode() %>';
                window.open(url);
            });


            $('#css-editor-wrapper .icoFileManager > a').bind('click', this, function (e) {
                $('#ifmFileManager').attr('src', 'about:blank');
                $("#file-manager-dialog").dialog({
                    height: 500,
                    width: '90%',
                    draggable: false,
                    resizable: false,
                    modal: true,
                    buttons: {
                        Close: function () {
                            $(this).dialog('close');
                        }
                    }
                });
                var url = '<%= Url.RouteUrl( "FileManager", new { @action="Index", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
                $('#ifmFileManager').attr('src', url);
            });
        };

        this.init();
    };
    </script>
</ui:ExternalJavascriptControl>
