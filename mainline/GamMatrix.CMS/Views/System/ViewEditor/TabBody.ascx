<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>



<div id="warning-msg" style="display:none">
<% Html.RenderPartial("../Warning"); %>
<br />
</div>

<div align="center">
<textarea id="body-editor" rows="30" cols="80" style="width: 100%; height:500px" readonly="readonly"></textarea>
</div>


<script type="text/javascript">
    function TabBody(viewEditor) {
        self.tabBody = this;
        this.viewEditor = viewEditor;
        this.isPartialView = <%= (this.Model.NodeType == CM.Content.ContentNode.ContentNodeType.PartialView).ToString().ToLowerInvariant() %>;

        this.load = function () {
            var readOnlyMode = <%= (this.Model.NodeStatus == ContentNode.ContentNodeStatus.Inherited) ? "true" : "false" %>;
            var $text = $(this.viewEditor.txtContent).text();
            var $body = this.viewEditor.searchSection(false);
            if( $body == null && !this.isPartialView ){
                alert("You can only edit in RawCode view because the body can't be located");
                readOnlyMode = true;
                return;
            }
            else if($body != null)
            {
                $text = $body.text;
            }

            <%--  Replace the placeholder --%>
            $text = $text.replace( /\<(\s*)asp:ContentPlaceHolder\s([^\>]*?)id\=\"cphMain\"([^\>]*)\>(\s|\r|\n)*\<(\s*)\/(\s*)asp\:ContentPlaceHolder(\s*)\>/i, "[PlaceHolder:Main]");

            <%--  Replace metadata --%>
            $text = this.viewEditor.transformToUBBCode($text);

            <%--  Replace partial view --%>
            $text = $text.replace( /\<\%(\s*)Html\.RenderPartial(\s*)\((\s*)\"[^\"]+\"(\s*)\,(\s*)this\.ViewData(\.Merge\((\s*)new(\s*)\{.*?\}(\s*)\))?(\s*)\)(\s*)\;(\s*)\%\>/g, function ($1) {
                $1 = $1.replace( /^(\<\%(\s*)Html\.RenderPartial(\s*)\((\s*))/, '[PartialView:');
                $1 = $1.replace( /((\s*)(\))?(\s*)\)(\s*)\;(\s*)\%\>)$/, ']');
                $1 = $1.replace( /(\s*)\,(\s*)this\.ViewData(\.Merge\((\s*)new)?(\s*)/, ' ');
                return $1;
            }
            );

            <%--  Detect server code --%>
            if( $text.indexOf('<' + '%') >= 0 ){
                $('#warning-msg').show();
                $('#warning-msg span.text').text('Server code is detected, please be careful!');                
            }
            else $('#warning-msg').hide();

            if( readOnlyMode ){
                $('#warning-msg').show();
                $('#warning-msg span.text').text("You need override the common template before you can edit the body!");
                $('#body-editor').hide();
            }

            <%--  Replace server code --%>
            $lastIndex = 0;
            $c = 0;
            while(true) {
                $ret = this.viewEditor.searchText($text, /(\<\%)|(\%\>)/i, $lastIndex);
                if ($ret != null) {
                    $lastIndex = $ret.startIndex + $ret.length;
                    if( $ret.text == '<%= "<%".SafeJavascriptStringEncode() %>' ){
                        $c ++;
                        if( $c == 1 ){
                            $text = $text.substr(0, $ret.startIndex) + '<![CDATA[' + $text.substr($ret.startIndex);
                            $lastIndex += 9;
                        }
                    }
                    else{
                        $c --;
                        if( $c == 0 ){
                            $text = $text.substr(0, $ret.startIndex + $ret.length) + ']]>' + $text.substr($ret.startIndex + $ret.length);
                         }
                    }
                }
                else break;
            }
            try{
                tinyMCE.execCommand('mceRemoveControl', false, 'body-editor');
            }
            catch(e){}
            self.lastContentToLoad = $text;
            //$('#body-editor').text($text);
            $('#body-editor').tinymce({
			    <%--  Location of TinyMCE script --%>
			    script_url : '/js/tinymce/tiny_mce.js',
                readonly : readOnlyMode,

			    <%-- General options --%>
			    theme : "advanced",
			    plugins : "pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,advlist",

			    <%-- Theme options --%>
			    theme_advanced_buttons1 : "save,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect,fontselect,fontsizeselect",
			    theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,cleanup,|,insertdate,inserttime,preview,|,forecolor,backcolor",
			    theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,iespell,advhr,|,print,|,ltr,rtl",
			    theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,pagebreak,|,fullscreen,metadata,filemanager,code",
			    theme_advanced_toolbar_location : "top",
			    theme_advanced_toolbar_align : "left",
			    theme_advanced_statusbar_location : "bottom",
			    theme_advanced_resizing : true,
                relative_urls : false,
                convert_urls : false,
			
                verify_html : false,
                forced_root_block : false,

                setup : function(ed) {
                    // Add a custom button
                    ed.addButton('metadata', {
                        title : 'Insert metadata...',
                        image : '/js/tinymce/metadata.png',
                        onclick : function() {
                            self.tabBody.onBtnInsertMetadataClicked();
                        }
                    });

                    ed.addButton('filemanager', {
                        title : 'File manager',
                        image : '/js/tinymce/filemanager.png',
                        onclick : function() {
                            self.tabBody.onBtnFileManagerClicked();
                        }
                    });

                    ed.onBeforeExecCommand.add(function(ed, cmd, ui, val, o) {
                        if( cmd == "mceSave" ){
                            o.terminate = true;

                            self.tabBody.onBtnSaveClick();
                        }
                    });

                    ed.onInit.add(function(ed) {
                        ed.setContent(self.lastContentToLoad);
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
                            $('#body-editor').tinymce().focus();
                            $('#body-editor').tinymce().execCommand('mceReplaceContent',false,self.htmlToInsert);
                            //$('#body-editor').tinymce().selection.setContent(self.htmlToInsert);
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
                            $('#body-editor').tinymce().focus();
                            $('#body-editor').tinymce().execCommand('mceReplaceContent',false,self.lastSelectedExpression.htmlEncode());
                            //$('#body-editor').tinymce().selection.setContent(self.lastSelectedExpression.htmlEncode());
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

      
        this.onBtnSaveClick = function () {
            
            var code = $('#body-editor').tinymce().getContent();
            
            <%-- Replace back --%>
            code = code.replace( /\[(\s*)PlaceHolder(\s*)\:(\s*)Main(\s*)\]/i, '<%= "<asp:ContentPlaceHolder id=\"cphMain\" runat=\"server\"></asp:ContentPlaceHolder>".SafeJavascriptStringEncode() %>');

            <%-- PartialView --%>
            code = code.replace( /\[(\s*)PartialView(\s*)\:(\s*)\"[^\"]+\"(\s*)(\{(.*?)\})?(\s*)\]/gi, function ($1) {
                $1 = $1.replace( /^(\[(\s*)PartialView(\s*)\:(\s*))/i, '');
                $1 = $1.replace( /((\s*)\])$/i, '');
                $1 = $1.replace( '&lt;', '<').replace( '&gt;', '>').replace( '&amp;', '&');
                $ret = self.tabBody.viewEditor.searchText( $1, /^(\"[^\"]+\")/, 0);
                if( $ret != null ){
                    $temp = $1.substr($ret.length).trim();
                    $1 = '<' + '% Html.RenderPartial( ' + $ret.text + ', this.ViewData';
                    
                    if( $temp.length > 0 && $temp[0] == '{' )
                        $1 += ('.Merge(new ' + $temp + ')');

                    $1 += ('); %' + '>');
                    return $1;
                }
                return '';
            }
            );

            <%-- Server Code --%>
            code = code.replace( /(\u003C\!\[CDATA\[)+\u003C\%/g, '\u003C%');
            code = code.replace( /\%\u003E(\]\]\u003E)+/g, '%\u003E');
            code = this.viewEditor.transformFromUBBCode(code);

            <%-- move <%@  instruction %> to the beginning--%>
            var $ret = this.viewEditor.searchInstructionLine(code);
            if ($ret != null){
                code = $ret.text + code.substr(0, $ret.startIndex) + code.substr($ret.startIndex + $ret.length);
            }
            
            var $text = $(this.viewEditor.txtContent).text();
            var $body = this.viewEditor.searchSection(false);
            if($body != null) {
                $text = $text.substr(0, $body.startIndex) + code + $text.substr($body.startIndex + $body.length);
            }
            else if(this.isPartialView) {
                $text = code;
            }
            else{
                alert("Error! can't locate the body.");
                return;
            }
            $(this.viewEditor.txtContent).text($text);

            <%-- Save change --%>
            this.viewEditor.save("$USERNAME$ updates the body.");
        };

        this.init = function () {
        };

        this.init();
    };
    </script>
