<%@ Page Title="View Editor" Language="C#" MasterPageFile="~/Views/System/Content.master"
    Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>" %>

<script language="C#" type="text/C#" runat="server">
    private bool HasPermission()
    {
        if (Profile.IsInRole("CMS System Admin"))
            return true;

        if (this.Model.NodeStatus == ContentNode.ContentNodeStatus.Overrode ||
            this.Model.NodeStatus == ContentNode.ContentNodeStatus.Normal)
            return true;

        List<string> allowedFiles = new List<string>()
        {
            "/Bingo/BingoMaster.master",
            "/RootMasterBodyPlus.ascx",
            "/DefaultMaster.master",
            "/ProfileMaster.master",
            "/Register/Advertisement.ascx",
            "/PageNotFound/Index.aspx",
            "/Home/Index.aspx",
            "/AboutUs/Index.aspx",
            "/GlobalCode.htm",
        };

        return allowedFiles.Exists(f => string.Equals(f, this.Model.RelativePath.Trim(), StringComparison.OrdinalIgnoreCase));
    }

    private bool ShowRawCode
    {
        get
        {
            if (this.Model.NodeType == ContentNode.ContentNodeType.StaticContent ||
                this.Model.NodeType == ContentNode.ContentNodeType.HtmlSnippet)
            {
                return true;
            }

            return Profile.IsInRole("CMS System Admin");
        }
    }

    private bool ShowHead
    {
        get
        {
            return this.Model.NodeType != CM.Content.ContentNode.ContentNodeType.PartialView &&
                this.Model.NodeType != CM.Content.ContentNode.ContentNodeType.StaticContent &&
                this.Model.NodeType != CM.Content.ContentNode.ContentNodeType.HtmlSnippet;
        }
    }

    private bool ShowBody
    {
        get
        {
            return this.Model.NodeType != CM.Content.ContentNode.ContentNodeType.StaticContent &&
                this.Model.NodeType != CM.Content.ContentNode.ContentNodeType.HtmlSnippet;
        }
    }

    private bool ShowInlineCSS
    {
        get
        {
            return this.ViewData["MetadataNode"] != null &&
                this.Model.NodeType != CM.Content.ContentNode.ContentNodeType.HtmlSnippet;
        }
    }
    
    private bool ShowOverridesList
    {
        get
        {
            return this.ViewData["MetadataNode"] != null
                   && this.Model.NodeStatus == ContentNode.ContentNodeStatus.Normal;
        }
    }
</script>
<asp:Content ContentPlaceHolderID="cphHead" runat="Server">
    <script type="text/javascript" src="/js/swfobject.js"></script>
    <script type="text/javascript" src="/js/tinymce/jquery.tinymce.js"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.template.js") %>"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/editor.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/ViewEditor/Index.css") %>" />
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" runat="Server">
    <div id="metadata-selector-modal" title="Insert metadata..." style="display: none">
        <iframe frameborder="0" id="ifmMetadataDlg" name="ifmMetadataDlg" src="about:blank">
        </iframe>
    </div>

    <div id="file-manager-dialog" title="File manager" style="display:none">
        <iframe frameborder="0" id="ifmFileManager" name="ifmFileManager" src="about:blank"></iframe>
    </div>


    <% using (Html.BeginForm("Save"
        , null
        , new { distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), path = this.Model.RealPhysicalPath.DefaultEncrypt(), relativePath = this.Model.RelativePath.DefaultEncrypt() }
        , FormMethod.Post
        , new { @id = "formSaveContent" }))
       { %>
    <textarea id="txtContent" name="content" style="display: none"><%= this.Model.GetFileContent().Replace("\r\n", "\n").SafeHtmlEncode() %></textarea>
    <input type="hidden" id="txtComments" name="comments" value="" />
    <% } %>
    <div style="padding: 10px;">
        <div id="vuedt-tabs">
            <ul>
                <% if (HasPermission())
                   { %>
                <li><a href="#tabs-1">
                    <%= this.Model.NodeType.ToString().SafeHtmlEncode() %>
                    [ <em>
                        <%= this.Model.DisplayName.SafeHtmlEncode() %></em> ]</a></li>
                <li <%= this.ShowHead ? "" : "style=\"display:none\"" %>>
                    <a href="#tabs-2">Head</a></li>
                <li <%= this.ShowBody ? "" : "style=\"display:none\"" %>>
                    <a href="#tabs-3">Body</a></li>
                <li <%= this.ShowRawCode ? "" : "style=\"display:none\"" %>>
                    <a href="#tabs-4">Raw Code</a></li>
                <li><a href="#tabs-5">Change History</a></li>
                    <% if( this.ShowOverridesList )
                       { %>
                        <li><a href="#tabs-8">Overrides List</a></li>
                    <% } %>
                <% } %>

                <% if (this.ViewData["MetadataNode"] != null)
                   { %>
                <li><a href="#tabs-6">Internal Metadata</a></li>
                <% } %>

                <% if( this.ShowInlineCSS )
                   { %>
                <li><a href="#tabs-7">Inline CSS</a></li>
                <% } %>
            </ul>
            <% // verify permission
                if (HasPermission())
                { %>
            <div id="tabs-1" data-idx="1">
                <% Html.RenderPartial("TabGeneric", this.Model); %>
            </div>
            <div id="tabs-2" data-idx="2">
                <% Html.RenderPartial("TabHead", this.Model); %>
            </div>
            <div id="tabs-3" data-idx="3">
                <% Html.RenderPartial("TabBody", this.Model); %>
            </div>
            <% 
               if (this.ShowRawCode)
               {
            %>
            <div id="tabs-4" data-idx="4">
                <% Html.RenderPartial("TabRawCode", this.Model); %>
            </div>
            <% } %>
            <div id="tabs-5"  data-idx="5">
                <% Html.RenderPartial("../HistoryViewer/Index", this.Model); %>
            </div>
            <% if (this.ShowOverridesList)
              { %> 
             <div id="tabs-8" data-idx="8">
                <% Html.RenderPartial("../HistoryViewer/OverridesList", this.Model); %>
             </div>
            <% } %>  
            <% } // Has Permission %>

            <% if (this.ViewData["MetadataNode"] != null)
               { %>
            <div id="tabs-6" data-idx="6">
                <% Html.RenderPartial("../MetadataEditor/TabMetadata", this.ViewData["MetadataNode"] as CM.Content.ContentNode); %>
            </div>
            <% } %>
            
            
            <% if( this.ShowInlineCSS )
              { %> 
             <div id="tabs-7" data-idx="7">
                <% Html.RenderPartial("TabInlineCss", this.Model); %>
             </div>
            <% } %>


            
        </div>
    </div>
    <ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
        <script type="text/javascript">
            function ViewEditor() {
                self.ViewEditor = this;

                this.txtContent = '#txtContent';

                this.searchInstructionLine = function ($str) {
                    var $regex = /\<\%\@(\s*)(Master|Page|Control)(\s+)/i;
                    var $start = this.searchText($str, $regex, 0);
                    if ($start == null) return null;
                    var $lastIndex = $start.startIndex + $start.length;
                    var c = 1;
                    while (true) {
                        var $ret = this.searchText($str, /((\<\%)|(\%\>))/i, $lastIndex);
                        if ($ret == null) return null;
                        $lastIndex = $ret.startIndex + 1;
                        if ($ret.text == '<' + '%') {
                            c++;
                            continue;
                        }

                        c--;
                        if (c == 0)
                            return { startIndex: $start.startIndex, length: ($ret.startIndex + $ret.length) - $start.startIndex, text: $str.substr($start.startIndex, ($ret.startIndex + $ret.length) - $start.startIndex) };
                    }
                };

                this.searchText = function ($str, $regex, $startIndex) {
                    var $newStr = $str.substr($startIndex);
                    var $index = $newStr.search($regex);
                    if ($index >= 0) {
                        $newStr = $newStr.substr($index);
                        var matchs = $regex.exec($newStr);
                        if (matchs == null || matchs.length == 0)
                            return null;
                        return { startIndex: ($startIndex + $index), length: matchs[0].length, text: matchs[0] };
                    }
                    return null;
                };

                this.getAttrVal = function ($str, $name) {
                    var $regex = new RegExp("\\b" + $name + "(\\s*)\\=(\\s*)\"", "i");
                    var $ret = this.searchText($str, $regex, 0);
                    if ($ret != null) {
                        $str = $str.substr($ret.startIndex + $ret.length);
                        $temp = $str.substr(0, $str.indexOf('"'));
                        while ($temp.indexOf('<' + '%') >= 0 && $temp.indexOf('%' + '>') < 0) {
                            $temp = $str.substr(0, $str.indexOf('"', $temp.length + 1));
                        }
                        return $temp;
                    }
                    return "";
                };

                this.searchSection = function (searchHead) {
                    var $str = $(this.txtContent).text();
                    var $regex = /\<(\s*)asp\:Content\s((.|\r|\n)*?)\<(\s*)\/(\s*)asp\:Content(\s*)\>/i;
                    var $lastIndex = 0;
                    var $sections = [];
                    while (true) {
                        var $ret = this.searchText($str, $regex, $lastIndex);
                        if ($ret != null) {
                            $sections.push($ret);
                            $lastIndex = $ret.startIndex + $ret.length;
                        }
                        else {
                            break;
                        }
                    }
                    if ($sections.length == 0)
                        return null;

                    for (var i = 0; i < $sections.length; i++) {
                        var $attr = $sections[i].text.substr(0, $sections[i].text.indexOf('>') + 1);
                        var $id = this.getAttrVal($attr, "ContentPlaceHolderID");
                        if ((searchHead && $id.toLowerCase() == "cphhead") ||
                    (!searchHead && $id.toLowerCase() == "cphmain")) {
                            $regex = /^(\<(\s*)asp\:Content\s([^\>]*)>)/i;
                            var matchs = $regex.exec($sections[i].text);
                            $sections[i].startIndex = $sections[i].startIndex + matchs[0].length;
                            $sections[i].length = $sections[i].length - matchs[0].length;

                            $regex = /(\<(\s*)\/(\s*)asp\:Content(\s*)>)$/i;
                            matchs = $regex.exec($sections[i].text);
                            $sections[i].length = $sections[i].length - matchs[0].length;

                            $sections[i].text = $str.substr($sections[i].startIndex, $sections[i].length);
                            return $sections[i];
                        }
                    }

                    return null;
                };

                this.onTabSelect = function (index) {
                    switch (index) {
                        case 2: this.tabHead.load(); break;
                        case 3: this.tabBody.load(); break;
                        case 4: this.tabRawCode.load(); break;
                        case 5: this.tabHistory.load(); break;
                        case 7: this.tabInlineCSS.load(); break;
                        case 8: this.tabOverrides.load(); break;
                    };
                };

                this.formatFromMetadataExpression = function (str) {
                    return str.replace(/\<\%\$(\s*)Metadata(\s*)\:(\s*)value(\s*)\((\s*)[\w\.\/\-_]+(\s*)\)(\s*)\%\>/g
            , function ($1) {
                if ($1 != null) {
                    $1 = $1.toString().replace(/^(\<\%\$(\s*)Metadata(\s*)\:(\s*)value(\s*)\((\s*))/i, "");
                    $1 = $1.replace(/((\s*)\)(\s*)\%\>)$/i, "");
                    return '[Metadata:value(' + $1 + ')]';
                }
                return $1;
            }
            );
                };

                this.formatToMetadataExpression = function (str) {
                    return str.replace(/\[(\s*)Metadata(\s*)\:(\s*)((value)|(htmlencode)|(scriptencode))(\s*)\((\s*)([\w\-\._\/]+)(\s*)\)(\s*)\]/ig
                , function ($1) {
                    if ($1 != null) {
                        $1 = $1.toString().replace(/^(\[(\s*)Metadata(\s*)\:(\s*)((value)|(htmlencode)|(scriptencode))(\s*)\()/i, "");
                        $1 = $1.replace(/((\s*)\)(\s*)\])$/i, "");
                        return '<' + '%$ Metadata:value(' + $1 + ')%' + '>';
                    }
                    return $1;
                }
            );
                };

                this.transformFromUBBCode = function (str) {
                    return str.replace(/\[(\s*)Metadata(\s*)\:(\s*)((value)|(htmlencode)|(scriptencode))(\s*)\((\s*)([\w\-\._\/]+)(\s*)\)(\s*)\]/ig
                , function ($1) {
                    if ($1 != null) {
                        $1 = $1.toString().replace(/^(\[(\s*)Metadata(\s*)\:(\s*))/i, "");
                        $1 = $1.replace(/((\s*)\)(\s*)\])$/i, "");
                        var array = $1.split('(');
                        var outputType = array[0].trim();
                        var path = array[1].trim();
                        var replaced = '<%= "<%= this.GetMetadata(\"".SafeJavascriptStringEncode() %>' + path + '")';
                        switch (outputType.toLowerCase()) {
                            case "htmlencode": return replaced + '.SafeHtmlEncode() %' + '>';
                            case "scriptencode": return replaced + '.SafeJavascriptStringEncode() %' + '>';
                            default: return replaced + ' %' + '>';
                        }
                    }
                    return $1;
                }
            );
                };

                this.transformToUBBCode = function (str) {
                    return str.replace(/\<\%\=(\s*)this\.GetMetadata\(\"[^\"]+\"\)(.*?)\%\>/g
            , function ($1) {
                if ($1 != null) {
                    $1 = $1.toString().replace(/^(\<\%\=(\s*)this\.GetMetadata\(\")/i, "");
                    $1 = $1.replace(/((\s*)\%\>)$/i, "");
                    var array = $1.split('"');
                    var outputType = array[1].trim();
                    var path = array[0].trim();
                    var replaced = '[Metadata:';
                    if (outputType.indexOf('.SafeHtmlEncode()') > 0)
                        replaced += 'htmlencode(';
                    else if (outputType.indexOf('.SafeJavascriptStringEncode()') > 0)
                        replaced += 'scriptencode(';
                    else
                        replaced += 'value(';
                    return replaced + path + ')]';
                }
                return $1;
            }
            );
                };

                // init
                this.init = function () {
                    try {
                        try { this.tabInlineCSS = new TabInlineCSS(this); } catch (e) { }
                        try { this.tabRawCode = new TabRawCode(this); } catch (e) { }
                        this.tabGeneric = new TabGeneric(this);
                        this.tabHead = new TabHead(this);
                        this.tabBody = new TabBody(this);
                        
                        this.tabHistory = new TabHistory(this);
                        try{this.tabOverrides = new TabOverrides(this);}catch(e){}
                    } catch (e) { console.info(e); }

                    try { this.tabMetadata = new TabMetadata(this); } catch (e) { }
                    $("#vuedt-tabs").tabs();
                    $('#vuedt-tabs').bind('tabsselect', this, function (event, ui) {
                        event.data.onTabSelect(parseInt($(ui.panel).data('idx'), 10));
                    });
                };

                this.save = function ($comments) {
                    if (self.startLoad) self.startLoad();
                    $('#txtComments').val($comments);

                    var options = {
                        type: 'POST',
                        dataType: 'json',
                        success: function (json) { if (self.stopLoad) self.stopLoad(); }
                    };
                    $('#formSaveContent').ajaxForm(options);
                    $('#formSaveContent').submit();
                };

                this.init();
            }
            new ViewEditor();
        </script>
    </ui:ExternalJavascriptControl>
</asp:Content>
