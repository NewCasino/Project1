<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>

<script type="text/C#" runat="server">
    private string[] GetComponentLinks()
    {
        string content = this.Model.GetFileContent().Replace("\r\n", "\n");
        string pattern = "Html\\.(RenderPartial|CachedPartial|Partial)\\s*\\(\\s*\\\"(\\S*)\\\"";
        Regex regex = new Regex(pattern, RegexOptions.CultureInvariant);
        MatchCollection matches = regex.Matches(content);
        List<string> urls = new List<string>();
        foreach (Match match in matches)
        {
            urls.Add(match.Groups[2].Value);
        }
        
        return urls.ToArray();
    }

    private string GetPath(string path1, string path2)
    {
        string result = string.Empty;
        if (path2.StartsWith("/"))
        {
            result = path2;
        }
        else if (path2.StartsWith(".."))
        {
            int step = 0;
            string[] segments = path2.Split('/');
            foreach (var item in segments)
            {
                if (item == "..")
                {
                    step++;
                }
            }
            result = BackPath(path1, step);
            for (int i = step; i < segments.Length; i++)
            {
                result += "/" + segments[i];
            }
        }
        else
        {
            result = BackPath(path1, 0) + "/" + path2;
        }
        return result;
    }

    private string BackPath(string path, int step)
    {
        string[] segments = path.Split("/".ToCharArray(), StringSplitOptions.RemoveEmptyEntries);
        string result = "";
        for (int i = 0; i < segments.Length - step - 1; i++)
        {
            result += "/" + segments[i];
        }
        return result;
    }
</script>

<div id="editor-wrapper">



<% if (this.Model.NodeStatus != ContentNode.ContentNodeStatus.Inherited)
{ %>
<ul id="editor-toolbar">
    <li class="icoFullscreen"><a title="Toggle Fullscreen" href="javascript:void(0)">Toggle Fullscreen</a></li>
    <li>|</li>
    <li class="icoSave"><a title="Save" href="javascript:void(0)">Save</a></li>
    <li>|</li>
    <li class="icoReload"><a title="Reload" href="javascript:void(0)">Reload</a></li>
    <li>|</li>
    <li class="icoFileManager"><a title="Insert images..." href="javascript:void(0)">File Manager...</a></li>

    <% if (this.Model.NodeType == ContentNode.ContentNodeType.HtmlSnippet)
       { %>
    <li>|</li>
    <li class="icoMetadata"><a title="Insert metadata..." href="javascript:void(0)">Insert Metadata...</a></li>
    <% } %>

</ul>
<% } %>
<div id="warning-msg-2" style="display:none">
<% Html.RenderPartial("../Warning"); %>
<br />
</div>
<div id="code-editor"></div>
</div>
<div>
    <h3>Widget links:</h3>
    <ul id="widget-links"></ul>
</div>   

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
    function onEditorLoaded() {
        try {
            document.getElementById('ctlFlash').setText($(self.ViewEditor.txtContent).text().replace(/\r/g, "\n"));
        } catch (e) { /*alert(e)*/ }
    }

    function navTo(action) {
        if (parent && parent.onNavTreeClicked)
            parent.onNavTreeClicked(action);
    }

    function TabRawCode(viewEditor) {
        this.viewEditor = viewEditor;

        this.load = function () {
            this.loadFlash($(document.body).height() - 200);
            onEditorLoaded();//For IE

            $("#widget-links").empty();
            var line;
            <% 
            string[] arry = GetComponentLinks();
            for(int i = 0;i < arry.Length;i++){
                
            string path1 = this.Model.RelativePath;
            string path2 = arry[i];
            string url  = GetPath(path1, arry[i]) +".ascx";
            %>
            line = "/ViewEditor/Index/" + '<%=this.Model.ContentTree.DistinctName.DefaultEncrypt()%>' + "/" + '<%=url.DefaultEncrypt()%>';

            $("#widget-links").append("<li><a href=\"javascript:void(0)\" onclick=\"navTo('" + line + "')\">" + '<%=path2%>' + "</a></li>");
            <% } %>

        };

        this.loadFlash = function (height) {
            var readOnlyMode = <%= (this.Model.NodeStatus == ContentNode.ContentNodeStatus.Inherited) ? "true" : "false" %>;

            if( readOnlyMode ){
                $('#warning-msg-2').show();
                $('#warning-msg-2 span.text').text("You need override the common template before you can edit!");
            }

            // initialize with parameters
            var flashvars = {
                parser: '<%= this.Model.NodeType == ContentNode.ContentNodeType.HtmlSnippet ? "custom1" : "aspx" %>',
                readOnly: readOnlyMode,
                preferredFonts: "|Consolas|Courier New|Courier|Fixedsys|Fixedsys Excelsior 3.01|Fixedsys Excelsior 3.00|",
                onload: "onEditorLoaded"
            };

            var params = { menu: "false", /*wmode : "transparent",*/ allowscriptaccess: "always", allowfullscreen: "true" };
            var attributes = { id: "ctlFlash", name: "ctlFlash" };

            swfobject.embedSWF("/js/CodeHighlightEditor.swf?_=<%= DateTime.Now.DayOfYear %>", "code-editor", "100%", height, "11.0.0", "/js/expressInstall.swf", flashvars, params, attributes);
        }

        this.fullscreen = false;
        this.onToggleFullscreen = function () {
            this.fullscreen = !this.fullscreen;
            if (this.fullscreen) {
                $('#editor-wrapper').addClass('fullscreen');
                $(document.body).css('overflow', 'hidden');
                $('#editor-wrapper').append('<div id="code-editor"></div>');
                $('#ctlFlash').remove()
                this.loadFlash($(document.body).height() - 50);
            }
            else {
                $('#editor-wrapper').removeClass('fullscreen');
                $(document.body).css('overflow', 'auto');
                $('#editor-wrapper').append('<div id="code-editor"></div>');
                $('#ctlFlash').remove()
                this.loadFlash($(document.body).height() - 200);
            }
        };

        this.onBtnSaveClick = function () {
            try {
                $(this.viewEditor.txtContent).text(document.getElementById('ctlFlash').getText());
                this.viewEditor.save("$USERNAME$ updates code in raw code view.");
            } catch (e) { alert(e) }
        };

        this.onBtnReloadClick = function () {
            if( window.confirm('You are about to reload, please "OK" to continue.') == true )
                onEditorLoaded();
        };

        this.onBtnFileManagerClick = function(){
            
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
                            document.getElementById('ctlFlash').insertText(self.htmlToInsert)
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
                            document.getElementById('ctlFlash').insertText(self.lastSelectedExpression);
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

        this.init = function () {
            $('#editor-wrapper .icoFullscreen > a').bind('click', this, function (e) { e.data.onToggleFullscreen(); });
            $('#editor-wrapper .icoSave > a').bind('click', this, function (e) { e.data.onBtnSaveClick(); });
            $('#editor-wrapper .icoReload > a').bind('click', this, function (e) { e.data.onBtnReloadClick(); });
            $('#editor-wrapper .icoFileManager > a').bind('click', this, function (e) { e.data.onBtnFileManagerClicked(); });
            $('#editor-wrapper .icoMetadata > a').bind('click', this, function (e) { e.data.onBtnInsertMetadataClicked(); });
        };

        this.init();
    };
    </script>
</ui:ExternalJavascriptControl>
