<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>

<form id="formHead">
        <ui:InputField id="fldPageTemplate" runat="server">
            <LabelPart>
            Page template:
            </LabelPart>
            <ControlPart>
            <%: Html.DropDownList("cmbPageTemplate", new SelectList(this.ViewData["MasterPages"] as IEnumerable, "Value", "Text"), new { @id = "cmbPageTemplate" })%>
            </ControlPart>
        </ui:InputField>

        <ui:InputField id="fldTitle" runat="server">
            <LabelPart>
            Title:
            </LabelPart>
            <ControlPart>
                <table>
                    <tr>
                        <td>
                             <%= Html.TextBox("txtHeadTitle", "", new { @id = "txtHeadTitle", @readonly = "readonly" })%>
                        </td>
                        <td>
                            <img id="btnHeadTitle" src="/images/transparent.gif" class="btn-insert-metadata"/>
                        </td>
                    </tr>
                </table>            
            </ControlPart>
        </ui:InputField>

        <ui:InputField id="fldKeywords" runat="server">
            <LabelPart>
            Keywords:
            </LabelPart>
            <ControlPart>
                <table>
                    <tr>
                        <td>
                            <%= Html.TextBox("txtHeadKeywords", "", new { @id = "txtHeadKeywords", @readonly = "readonly" })%>
                        </td>
                        <td>
                            <img id="btnHeadKeywords" src="/images/transparent.gif" class="btn-insert-metadata"/>
                        </td>
                    </tr>
                </table>                
            </ControlPart>
            <HintPart>
            &lt;meta name="keywords" content="<em>bet, sportsbook, poker</em>" /&gt;
            </HintPart>
        </ui:InputField>

        <ui:InputField id="fldDescription" runat="server">
            <LabelPart>
            Description:
            </LabelPart>
            <ControlPart>
                <table>
                    <tr>
                        <td>
                             <%= Html.TextBox("txtHeadDesc", "", new { @id = "txtHeadDesc", @readonly = "readonly" })%>
                        </td>
                        <td>
                            <img id="btnHeadDesc" src="/images/transparent.gif" class="btn-insert-metadata"/>
                        </td>
                    </tr>
                </table>               
            </ControlPart>
            <HintPart>
            &lt;meta name="description" content="<em>Come and win!</em>" /&gt;
            </HintPart>
        </ui:InputField>

        <ui:InputField id="fldCanonicalUrl" runat="server">
            <LabelPart>
            Canonical Url:
            </LabelPart>
            <ControlPart>
                 <%= Html.TextBox("txtHeadCanonicalUrl", "", new { @id = "txtHeadCanonicalUrl" })%>
            </ControlPart>
            <HintPart>
            &lt;link rel="canonical" href="<em>product.aspx?item=sss</em>" /&gt;
            </HintPart>
        </ui:InputField>

        <ui:InputField id="fldStylesheet" runat="server">
            <LabelPart>
            Stylesheet reference:
            </LabelPart>
            <ControlPart>
            <table><tr>
            <td>
                <%= Html.DropDownList("cmbStylesheet", new SelectListItem[0], new { @size = 5} ) %>
            </td>
            <td valign="top">
                <img id="btnRemoveStylesheet" src="/images/icon/delete.png" />
            </td>
            </tr>
            <tr>
            <td>
                <%= Html.TextBox("txtStylesheet", null, new { @id = "txtStylesheet" })%>
            </td>
            <td>
                <img id="btnAddStylesheet" src="/images/icon/add.png" style="cursor:pointer" />
            </td>
            </tr>
            </table>
            
            </ControlPart>
        </ui:InputField>

        <ui:InputField id="fldScript" runat="server">
            <LabelPart>
            Javascript reference:
            </LabelPart>
            <ControlPart>

            <table><tr>
            <td>
                <%= Html.DropDownList("cmbJavascript", new SelectListItem[0], new { @size = 5} ) %>
            </td>
            <td valign="top">
                <img id="btnRemoveJavascript" src="/images/icon/delete.png"/>
            </td>
            </tr>
            <tr>
            <td>
                <%= Html.TextBox("txtJavascript", null, new { @id = "txtJavascript" })%>
            </td>
            <td>
                <img id="btnAddJavascript" src="/images/icon/add.png" style="cursor:pointer"/>
            </td>
            </tr>
            </table>

            </ControlPart>
        </ui:InputField>

        <ui:InputField id="fldSEOMeta" runat="server">
            <LabelPart>
            &nbsp;
            </LabelPart>
            <ControlPart>
            <div style="width:300px;">
                <table>
                    <tr>
                        <td>
                            <%: Html.CheckBox("NoIndex", false, new { @id="btnNoIndex"}) %>
                            <label for="btnNoIndex">NoIndex</label>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <%: Html.CheckBox("NoFollow", false, new { @id="btnNoFollow"}) %>
                            <label for="NoFollow">NoFollow</label>
                        </td>
                    </tr>
                </table>
            </div>
            </ControlPart>
        </ui:InputField>

        <% if (this.Model.NodeStatus != ContentNode.ContentNodeStatus.Inherited)
           { %>
        <div class="buttons-wrap">
            <ui:Button runat="server" ID="btnSubmit"
            type="button">Save Changes</ui:Button>
        </div>
        <% } %>
</form>


<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
    function TabHead(viewEditor) {
        this.viewEditor = viewEditor;
        this.btnSubmit = '#<%=btnSubmit.ClientID %>';
        this.regex1 = new RegExp("\\<\\%\\@(\\s*)(Master|Page)([^\\%\\\"\\']+(\\%(?!\\>)|(\\\"[^\\\"]*\\\")|(\\'[^\\']*\\'))[^\\%\\\"\\']+)*?\\%\\>", "i");
        this.regex2 = new RegExp("\\<(\\s*)meta(\\s+)name(\\s*)\\=(\\s*)\\\"keywords\\\"(\\s+)([^\\<\\>]+(\\<\\%(.*?)\\%\\>)|[^\\>\\<]*)*?\\>", "i");
        this.regex3 = new RegExp("\\<(\\s*)meta(\\s+)name(\\s*)\\=(\\s*)\\\"description\\\"(\\s+)([^\\<\\>]+(\\<\\%(.*?)\\%\\>)|[^\\>\\<]*)*?\\>", "i");
        this.regex4 = new RegExp("\\<(\\s*)link(\\s+)rel(\\s*)\\=(\\s*)\\\"canonical\\\"(\\s+)([^\\<\\>]+(\\<\\%(.*?)\\%\\>)|[^\\>\\<]*)*?\\>", "i");
        this.regex5 = /\<(\s*)script(\s+)((.|\r|\n)*?)(\<(\s*)\/(\s*)script(\s*)\>)/i;
        this.regex6 = new RegExp("\\<(\\s*)link(\\s+)([^\\<\\>]+(\\<\\%(.*?)\\%\\>)|[^\\>\\<]*)*?\\>", "i");
        this.regex7 = new RegExp("\\<(\\s*)meta(\\s+)name(\\s*)\\=(\\s*)\\\"robots\\\"(\\s+)([^\\<\\>]+(\\<\\%(.*?)\\%\\>)|[^\\>\\<]*)*?\\>", "i");

        this.load = function () {
            $('#txtHeadTitle').val("");
            $('#txtHeadKeywords').val("");
            $('#txtHeadDesc').val("");
            $('#txtHeadCanonicalUrl').val("");

            var $text = $(this.viewEditor.txtContent).text();
            var $ret = this.viewEditor.searchInstructionLine($text);
            if ($ret != null){
                <%-- Read Title MetaKeywords MetaDescription --%>
                var title = this.viewEditor.formatFromMetadataExpression( this.viewEditor.getAttrVal($ret.text, "Title") );
                $('#txtHeadTitle').val(title);

                var metaKeywords = this.viewEditor.formatFromMetadataExpression( this.viewEditor.getAttrVal($ret.text, "MetaKeywords") );
                $('#txtHeadKeywords').val(metaKeywords);

                var metaDescription = this.viewEditor.formatFromMetadataExpression( this.viewEditor.getAttrVal($ret.text, "MetaDescription") );
                $('#txtHeadDesc').val(metaDescription);

                var masterPageFile = this.viewEditor.getAttrVal($ret.text, "PageTemplate");
                if( masterPageFile != null ) {
                    if( $('#cmbPageTemplate > option[value="' + masterPageFile + '"]').length == 0 )
                        $('#cmbPageTemplate').append( '<option value="' + masterPageFile.htmlEncode() + '">' + masterPageFile.htmlEncode() + '</option>' );
                    $('#cmbPageTemplate').val(masterPageFile);
                }                
            }

            var $head = this.viewEditor.searchSection(true);
            if ($head == null) {
                alert("You can only edit in RawCode view because the head can't be located");
                $(this.btnSubmit).hide();
                return false;
            }
            $(this.btnSubmit).show();

            $text = $head.text;

            $('#cmbJavascript').empty();
            $text = $head.text;
            $lastIndex = 0;
            while(true) {
                $ret = this.viewEditor.searchText($text, this.regex5, $lastIndex);
                if ($ret != null) {
                    $lastIndex += $ret.startIndex + $ret.length;
                    $src = this.viewEditor.getAttrVal($ret.text, "src");
                    if ($src.length > 0) {
                        var $opt = $('<option></option>');
                        $opt.text($src).attr('title', $src);
                        $('#cmbJavascript').append($opt);
                    }
                }
                else break;
            }

            $('#cmbStylesheet').empty();
            $text = $head.text;
            $lastIndex = 0;
            while(true) {
                $ret = this.viewEditor.searchText($text, this.regex6, $lastIndex);
                if ($ret != null) {
                    $lastIndex = $ret.startIndex + $ret.length;
                    $rel = this.viewEditor.getAttrVal($ret.text, "rel").toLowerCase();
                    $href = this.viewEditor.getAttrVal($ret.text, "href");
                    switch ($rel) {
                        case "canonical":
                            $('#txtHeadCanonicalUrl').val($href);
                            break;

                        case "stylesheet":
                            {
                                if ($href.length > 0) {
                                    var $opt = $('<option></option>');
                                    $opt.text($href).attr('title', $href);
                                    $('#cmbStylesheet').append($opt);
                                }
                                break;
                            }
                    }
                }
                else break;
            }

            $('#btnNoIndex').attr('checked', false);
            $('#btnNoFollow').attr('checked', false);
            $text = $head.text;
            $lastIndex = 0;
            while (true) {
                $ret = this.viewEditor.searchText($text, this.regex7, $lastIndex);
                if ($ret != null) {
                    $lastIndex = $ret.startIndex + $ret.length;
                    $rel = this.viewEditor.getAttrVal($ret.text, "content").toLowerCase();
                    if ($rel.indexOf('noindex') >= 0) {
                        $('#btnNoIndex').attr('checked', true);
                    }
                    if ($rel.indexOf('nofollow') >= 0) {
                        $('#btnNoFollow').attr('checked', true);
                    }
                }
                else break;
            }

            this.adjustUI();
        };

        this.adjustUI = function () {
            var selected = $("#cmbJavascript > option:selected").length == 1;
            $('#btnRemoveJavascript').attr('src', selected ? "/images/icon/delete.png" : "/images/icon/delete_gray.png")
            .css('cursor', selected ? 'pointer' : 'default');

            selected = $("#cmbStylesheet > option:selected").length == 1;
            $('#btnRemoveStylesheet').attr('src', selected ? "/images/icon/delete.png" : "/images/icon/delete_gray.png")
            .css('cursor', selected ? 'pointer' : 'default');
        };

        this.onBtnSaveClick = function () {
            var $text = $(this.viewEditor.txtContent).text();
            var $ret = this.viewEditor.searchInstructionLine($text);
            if ($ret != null) {
                var $str = $ret.text;
                <%-- Title --%>
                var title = this.viewEditor.formatToMetadataExpression($('#txtHeadTitle').val());
                var $temp = "Title=\"" + title + "\"";
                $str = $str.replace(/\bTitle(\s*)\=(\s*)\"(.*?)\"/ig, $temp);
                if ($str.indexOf('Title') < 0 && $('#txtHeadTitle').val() != "")
                    $str = $str.replace(/(\%\>$)/i, (" " + $temp + " %>"));
                $text = $text.substr(0, $ret.startIndex) + $str + $text.substr($ret.startIndex + $ret.length);

                <%-- PageTemplate --%>
                $ret = this.viewEditor.searchInstructionLine($text);
                $str = $ret.text;
                $temp = "PageTemplate=\"" + $('#cmbPageTemplate').val() + "\"";                
                $str = $str.replace(/\bPageTemplate(\s*)\=(\s*)\"(.*?)\"/ig, $temp);
                if ($str.indexOf('PageTemplate') < 0 && $('#cmbPageTemplate').val() != "")
                    $str = $str.replace(/(\%\>$)/i, (" " + $temp + " %>"));
                $text = $text.substr(0, $ret.startIndex) + $str + $text.substr($ret.startIndex + $ret.length);

                <%-- MetaKeywords --%>
                $ret = this.viewEditor.searchInstructionLine($text);
                $str = $ret.text;
                var metaKeywords = this.viewEditor.formatToMetadataExpression($('#txtHeadKeywords').val());
                $temp = "MetaKeywords=\"" + metaKeywords + "\"";
                $str = $str.replace(/\bMetaKeywords(\s*)\=(\s*)\"(.*?)\"/ig, $temp);
                if ($str.indexOf('MetaKeywords') < 0 && $('#txtHeadKeywords').val() != "")
                    $str = $str.replace(/(\%\>$)/i, (" " + $temp + " %>"));
                $text = $text.substr(0, $ret.startIndex) + $str + $text.substr($ret.startIndex + $ret.length);

                <%-- MetaDescription --%>
                $ret = this.viewEditor.searchInstructionLine($text);
                $str = $ret.text;
                var metaDescription = this.viewEditor.formatToMetadataExpression($('#txtHeadDesc').val());
                $temp = "MetaDescription=\"" + metaDescription + "\"";
                $str = $str.replace(/\bMetaDescription(\s*)\=(\s*)\"(.*?)\"/ig, $temp);
                if ($str.indexOf('MetaDescription') < 0 && $('#txtHeadDesc').val() != "")
                    $str = $str.replace(/(\%\>$)/i, (" " + $temp + " %>"));
                $text = $text.substr(0, $ret.startIndex) + $str + $text.substr($ret.startIndex + $ret.length);
            }
            $(this.viewEditor.txtContent).text($text);

            var $head = this.viewEditor.searchSection(true);
            if ($head == null) {
                alert("Error, can't locate the head part.");
                return;
            }

            $text = $head.text;

            $ret = this.viewEditor.searchText($text, this.regex4, 0);
            $temp = '<link rel="canonical" href="' + $('#txtHeadCanonicalUrl').val().htmlEncode(true) + '" />';
            if ($('#txtHeadCanonicalUrl').val() == "") $temp = "";
            if ($ret != null) {
                $text = $text.substr(0, $ret.startIndex) + $temp + $text.substr($ret.startIndex + $ret.length);
            }
            else if ($('#txtHeadCanonicalUrl').val().length > 0) {
                $text = $text + $temp;
            }

            $lastIndex = 0;
            for (; ; ) {
                $ret = this.viewEditor.searchText($text, this.regex5, $lastIndex);
                if ($ret != null) {
                    $lastIndex = $ret.startIndex + $ret.length;
                    $src = this.viewEditor.getAttrVal($ret.text, "src");
                    if ($src.length > 0) {
                        $text = $text.substr(0, $ret.startIndex) + $text.substr($ret.startIndex + $ret.length);
                        $lastIndex = 0;
                    }
                }
                else break;
            }

            $lastIndex = 0;
            for (; ; ) {
                $ret = this.viewEditor.searchText($text, this.regex6, $lastIndex);
                if ($ret != null) {
                    $lastIndex = $ret.startIndex + $ret.length;
                    $rel = this.viewEditor.getAttrVal($ret.text, "rel").toLowerCase();
                    $href = this.viewEditor.getAttrVal($ret.text, "href");
                    if ($rel == "stylesheet" && $href.length > 0) {
                        $text = $text.substr(0, $ret.startIndex) + $text.substr($ret.startIndex + $ret.length);
                        $lastIndex = 0;
                    }
                }
                else break;
            }

            var $temp = "";
            var $opts = $("#cmbJavascript > option");
            for (var i = 0; i < $opts.length; i++) {
                $temp += '<' + 'script language="javascript" type="text/javascript" src="';
                $temp += $($opts[i]).text().htmlEncode(true);
                $temp += "\"></" + "script>";
            }
            

            $opts = $("#cmbStylesheet > option");
            for (var i = 0; i < $opts.length; i++) {
                $temp += '<link rel="stylesheet" type="text/css" href="' + $($opts[i]).text().htmlEncode(true) + '" />';
            }
            $text = $text + $temp;

            $ret = this.viewEditor.searchText($text, this.regex7, 0);
            $tempcontent = '';
            if ($('#btnNoIndex').attr('checked') && $('#btnNoFollow').attr('checked')) {
                $tempcontent = 'noindex, nofollow';
            } else if ($('#btnNoIndex').attr('checked')) {
                $tempcontent = 'noindex';
            } else if ($('#btnNoFollow').attr('checked')) {
                $tempcontent = 'nofollow';
            }
            if ($tempcontent.length > 0) {
                $temp = '<meta name="robots" content="' + $tempcontent + '" />';
            } else {
                $temp = '';
            }
            if ($ret != null) {
                $text = $text.substr(0, $ret.startIndex) + $temp + $text.substr($ret.startIndex + $ret.length);
            }
            else if ($temp.length > 0) {
                $text = $text + $temp;
            }

            var $code = $(this.viewEditor.txtContent).text();
            $code = $code.substr(0, $head.startIndex) + $text + $code.substr($head.startIndex + $head.length);
            $(this.viewEditor.txtContent).text($code);

            <%-- Save change --%>
            this.viewEditor.save("$USERNAME$ updates the head.");
        };

        this.openMetadataSelectorDlg = function(textbox){
            self.selectedTextbox = textbox;
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
                            self.selectedTextbox.val(self.lastSelectedExpression);
                        }
                        $(this).dialog('close');
                    },
                    Cancel: function () {
                        $(this).dialog('close');
                    }
                }
            });
            var url = '<%= Url.RouteUrl( "MetadataEditor", new { @action="MetadataSelector", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?output-type=value';
            $('#ifmMetadataDlg').attr( 'src', url);
        };

        this.init = function () {
            InputFields.initialize($("#formHead"));
            $("#cmbJavascript").bind('change', this, function (e) { e.data.adjustUI(); });
            $('#btnRemoveJavascript').bind('click', this, function (e) { $("#cmbJavascript > option:selected").remove(); e.data.adjustUI(); });
            $("#cmbStylesheet").bind('change', this, function (e) { e.data.adjustUI(); });
            $('#btnRemoveStylesheet').bind('click', this, function (e) { $("#cmbStylesheet > option:selected").remove(); e.data.adjustUI(); });

            $('#btnAddStylesheet').bind('click', this, function (e) {
                var t = $('#txtStylesheet').val();
                if (t.length > 0) {
                    var $opt = $('<option></option>');
                    $opt.text(t).attr('title', t);
                    $("#cmbStylesheet").append($opt);
                    $('#txtStylesheet').val("");
                }
            });

            $('#btnAddJavascript').bind('click', this, function (e) {

                var t = $('#txtJavascript').val();
                if (t.length > 0) {
                    var $opt = $('<option></option>');
                    $opt.text(t).attr('title', t);
                    $("#cmbJavascript").append($opt);
                    $('#txtJavascript').val("");
                }
            });

            $(this.btnSubmit).bind('click', this, function (e) {
                e.preventDefault();
                e.data.onBtnSaveClick();
            });

            $('#btnHeadTitle').bind('click', this, function(e) {
                e.data.openMetadataSelectorDlg($('#txtHeadTitle'));
                }
            );

            $('#btnHeadKeywords').bind('click', this, function(e) {
                e.data.openMetadataSelectorDlg($('#txtHeadKeywords'));
                }
            );

            $('#btnHeadDesc').bind('click', this, function(e) {
                e.data.openMetadataSelectorDlg($('#txtHeadDesc'));
                }
            );
        };

        this.init();
    };
    </script>
</ui:ExternalJavascriptControl>
