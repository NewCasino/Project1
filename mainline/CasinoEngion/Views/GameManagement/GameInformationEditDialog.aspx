<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/DialogDefault.Master" Inherits="System.Web.Mvc.ViewPage<CE.db.ceCasinoGameBaseEx>" %>

<asp:Content ID="Content1" ContentPlaceHolderID="phMain" runat="server">
    <script type="text/javascript" src="<%= Url.Content("~/js/Markdown.Converter.js") %>"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/Markdown.Sanitizer.js") %>"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/Markdown.Editor.js") %>"></script>
    <style type="text/css" media="all">
        html { overflow-y: hidden; }

        .content-wrapper { background-color: #FFFFFF; margin: 0 auto; overflow: hidden; /*width: 99%; */ border: 1px solid #e9e9e9; }

        .preview { float: right; margin-right: 5px; }
        .preview input { vertical-align: middle; }
        .preview label { vertical-align: middle; }
        .wmd-toolbar { border-bottom: 1px solid rgba(0, 0, 0, 0.25); }
        .wmd-button-row { position: relative; margin: 10px 5px 5px 5px; padding: 0; height: 20px; width: 400px; }
        .wmd-spacer { width: 1px; height: 20px; margin-left: 14px; position: absolute; background-color: Silver; display: inline-block; list-style: none; }
        .wmd-button { width: 20px; height: 20px; padding-left: 2px; padding-right: 3px; position: absolute; display: inline-block; list-style: none; cursor: pointer; }
        .wmd-button > span { background-image: url(/images/wmd_buttons.png); background-repeat: no-repeat; background-position: 0 0; width: 20px; height: 20px; display: inline-block; }

        .wmd-input { height: 300px; width: 100%; background-color: #ededed; border: 0; outline: medium none; overflow-x: auto; overflow-y: scroll; margin: 0; padding: 0; }

        .wmd-preview { background-color: #ededed; color: #000000; border: 1px dotted #ccc; height: 300px; width: 100%; overflow-x: auto; overflow-y: scroll; }
        .wmd-spacer1 { left: 50px; }
        .wmd-spacer2 { left: 175px; }
        .wmd-spacer3 { left: 300px; }

        .wmd-prompt-background { background-color: Black; }
        .wmd-prompt-dialog { border: 1px solid #999999; background-color: #F5F5F5; }
        .wmd-prompt-dialog > div { font-size: 0.8em; font-family: arial, helvetica, sans-serif; }
        .wmd-prompt-dialog > form > input[type="text"] { border: 1px solid #999999; color: black; }
        .wmd-prompt-dialog > form > input[type="button"] { border: 1px solid #888888; font-family: trebuchet MS, helvetica, sans-serif; font-size: 0.8em; font-weight: bold; }

        .menubar { border-top: 1px solid rgba(0, 0, 0, 0.25); border-bottom: 1px solid rgba(0, 0, 0, 0.25); background-color: #ffffff; color: #000000; overflow: hidden; }
        .menubar .buttons { float: right; margin-top: 5px; margin-bottom: 5px; margin-right: 2px; }
        .menubar .languages { float: left; vertical-align: top; margin-top: 5px; margin-left: 2px; margin-bottom: 5px; background: none repeat scroll 0 0 rgba(0, 0, 0, 0); border: 0; color: #333333; }
        .menubar .languages button { border: 0; background-color: #FFFFFF; cursor: pointer; border-top: 1px solid rgba(0, 0, 0, 0.25); border-bottom: 1px solid rgba(0, 0, 0, 0.25); float: left; height: 30px; margin: 0; }
        .menubar .languages .first { border-left: 1px solid rgba(0, 0, 0, 0.25); -ms-border-radius: 3px 0 0 3px; border-radius: 3px 0 0 3px; }

        .menubar .languages .last { border-right: 1px solid rgba(0, 0, 0, 0.25); -ms-border-radius: 0 3px 3px 0; border-radius: 0 3px 3px 0; }

        .menubar .languages .selected { background-color: #c6c6c6; }
        .menubar .languages .status-none { color: #666 !important; }
        .menubar .languages .status-normal { color: #338 !important; font-weight: bold; }
        .menubar .languages .status-inherit { color: #383 !important; font-weight: bold; }

        .clear { clear: both; }
        .ui-add-dialog .fields { margin-top: 5px; }
        .ui-add-dialog .fields .name { float: left; width: 150px; height: 30px; min-height: 30px; }
        .ui-add-dialog .fields .value { float: left; height: 30px; min-height: 30px; }
        .ui-add-dialog .buttons { padding-top: 10px; }
        .ui-add-dialog .buttons button { float: right; }
    </style>

    <form id="formSaveGameInformation" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
        action="<%= this.Url.ActionEx("SaveGameInformation").SafeHtmlEncode() %>">
        <%: Html.HiddenFor(m => m.ID) %>
        <%: Html.HiddenFor(m => m.VendorID) %>
        <%: Html.HiddenFor(m => m.GameCode) %>
        <%: Html.Hidden("language") %>
        <div class="content-wrapper" id="content-wrapper">
            <div id="wmd-button-bar" class="wmd-toolbar">
                <div class="preview">
                    <input type="checkbox" id="cbPreview" checked="checked" />
                    <label for="cbPreview">Preview</label>
                </div>
            </div>

            <textarea class="wmd-input" id="wmd-input" name="translation"></textarea>

            <div id="menubar" class="menubar">
                <div class="buttons">
                    <button id="btnRemoveTranslation" style="display: none;">Remove Translation</button>
                    <% if(DomainManager.AllowEdit()) { %>
                    <button id="btnSaveGameInforamtion">Save</button>
                    <% } %>
                </div>
                <div class="languages">
                </div>
            </div>

            <div id="wmd-preview" class="wmd-preview"></div>


        </div>
    </form>
    <form id="formDeleteGameInformation" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
        action="<%= this.Url.ActionEx("DeleteGameInformation").SafeHtmlEncode() %>">
        <%: Html.HiddenFor(m => m.ID) %>
        <%: Html.HiddenFor(m => m.VendorID) %>
        <%: Html.HiddenFor(m => m.GameCode) %>
        <%: Html.Hidden("language") %>
    </form>

    <div id="dlgAddLink" title="Add link" style="display: none" class="ui-add-dialog">
        <p>
            Link URL:<br />
            <input type="text" id="linkUrl" name="linkUrl" style="width: 370px;" />
        </p>
        <div class="buttons clear">
            <button id="btnAddLink">Add link</button>
        </div>
    </div>

    <div id="dlgAddImage" title="Add Image" style="display: none" class="ui-add-dialog">
        <form id="formAddImage" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
            action="<%= this.Url.ActionEx("AddImage").SafeHtmlEncode() %>">
            <div class="fields">
                <div class="name">
                    <input type="radio" value="computer" name="from" id="computer" />
                    <label for="computer">From my computer</label>
                </div>
                <div class="value">
                    <input type="file" id="imageFile" name="imageFile" style="width: 200px; display: none;" />
                </div>
            </div>
            <div class="fields clear">
                <div class="name">
                    <input type="radio" value="web" name="from" id="web" />
                    <label for="web">From the web</label>
                </div>
                <div class="value">
                    <input type="text" id="imageUrl" name="imageUrl" style="width: 200px; display: none;" />
                </div>
            </div>
            <div class="buttons clear">
                <button id="btnAddImage">Add picture</button>
            </div>
        </form>
    </div>


    <script type="text/javascript">
        (function () {
            var mgr = null;

            $('#cbPreview').click(function () {
                if ($(this).prop('checked')) {
                    $('#wmd-preview').show();
                } else {
                    $('#wmd-preview').hide();
                }
                onWindowResized();
            });

            $('#btnRemoveTranslation').button({
                icons: {
                    //primary: 'ui-icon-disk'
                }
            }).click(function (e) {
                e.preventDefault();

                if (mgr != null)
                    mgr.remove();
            });

            $('#btnSaveGameInforamtion').button({
                icons: {
                    primary: 'ui-icon-disk'
                }
            }).click(function (e) {
                e.preventDefault();

                if (mgr != null)
                    mgr.save();
            });

            $('#btnAddLink').button({
                icons: {
                    //primary: 'ui-icon-check'
                }
            }).click(function (e) {
                e.preventDefault();
                if (mgr != null)
                    mgr.addLink();
            });

            $('#dlgAddImage input[type=radio]').on('click', function () {
                if ($('#dlgAddImage #computer').prop('checked')) {
                    $('#dlgAddImage #imageFile').show();
                    $('#dlgAddImage #imageUrl').hide();
                } else {
                    $('#dlgAddImage #imageFile').hide();
                    $('#dlgAddImage #imageUrl').show();
                }
            });

            $('#btnAddImage').button({
                icons: {
                    //primary: 'ui-icon-check'
                }
            }).click(function (e) {
                e.preventDefault();
                if (mgr != null)
                    mgr.addImage();
            });

            function TranslationMgr(json) {
                var self = this;
                self.items = json;
                self.editor = null;
                self.container = $('#menubar .languages');
                self.addLinkCallback = null;
                self.addImageCallback = null;
                self.busy = false;

                self.update = function (data) {
                    self.items = JSON.parse(data);
                    var selectedIndex = $('button.selected', self.container).attr('index');
                    self.updateItems();
                    self.switchTo(selectedIndex);
                };

                self.updateItems = function () {
                    $(self.container).html('');
                    for (var i = 0; i < self.items.length; i++) {
                        var item = self.items[i];
                        var $button = $('<button></button>');
                        $button.attr('index', i);
                        $button.html(item["code"].toUpperCase());
                        $button.addClass('status-' + item["status"]);
                        if (i == 0)
                            $button.addClass('first');
                        if (i == self.items.length - 1)
                            $button.addClass('last');

                        $button.on('click', function (e) {
                            e.preventDefault();
                            self.switchTo($(this).attr('index'));
                        });

                        $button.appendTo(self.container);
                    }
                };

                self.initialize = function (editor) {
                    self.editor = editor;
                    self.updateItems();
                    self.switchTo(0);
                };

                self.switchTo = function (index) {
                    var $selected = $('button.selected', self.container);
                    var $target = $('button[index=' + index + ']', self.container);
                    if ($target.hasClass('selected'))
                        return;

                    if ($selected.length > 0) {
                        if ($('#wmd-input').val() != self.items[$selected.attr('index')]['content']) {
                            var msg = 'You have unsaved change. \nSwitching to [' + self.items[$target.attr('index')]['name'] + '] language will lost them. \n\nClicking "OK" will discard the change.\nAre you sure to continue?';
                            if (!window.confirm(msg))
                                return;
                        }

                        $selected.removeClass('selected');
                        $selected.html(self.items[$selected.attr('index')]['code'].toUpperCase());
                    }

                    $target.addClass('selected');
                    $target.html(self.items[$target.attr('index')]['name']);

                    if (self.items[$target.attr('index')]['code'] != '>' && self.items[$target.attr('index')]['status'] == 'normal')
                        $('#btnRemoveTranslation').show();
                    else
                        $('#btnRemoveTranslation').hide();

                    $('#wmd-input').val(self.items[$target.attr('index')]['content']);
                    self.editor.clearUndolist();
                    self.editor.refreshPreview();
                };

                self.save = function () {
                    var content = $('#wmd-input').val();
                    if (content == null || content.replace(/(^\s+|\s+$)/g, '') == '') {
                        if (!window.confirm("The content is empty, are you sure to save it?"))
                            return;
                    }

                    var selectedIndex = $('button.selected', self.container).attr('index');
                    $('#formSaveGameInformation input[name=language]').val(self.items[selectedIndex]['code']);
                    var options = {
                        dataType: 'json',
                        success: function (result) {
                            $('#loading').hide();
                            if (!result.success) {
                                alert(result.error);
                                return;
                            }
                            self.update(result.data);
                        }
                    };
                    $('#loading').show();
                    $('#formSaveGameInformation').ajaxSubmit(options);
                };

                self.remove = function () {
                    var selectedIndex = $('button.selected', self.container).attr('index');

                    if (!window.confirm('You are going to remove the [' + self.items[selectedIndex]['name'] + '] translation. \n\nNote, if the translation was inherited from parent template, it will be restored to the inherited version.')) {
                        return;
                    }

                    $('#formDeleteGameInformation input[name=language]').val(self.items[selectedIndex]['code']);
                    var options = {
                        dataType: 'json',
                        success: function (result) {
                            $('#loading').hide();
                            if (!result.success) {
                                alert(result.error);
                                return;
                            }
                            self.update(result.data);
                        }
                    };
                    $('#loading').show();
                    $('#formDeleteGameInformation').ajaxSubmit(options);
                };

                self.addLinkDialog = function (callback) {
                    self.addLinkCallback = callback;

                    $('#dlgAddLink #linkUrl').val('http://');

                    $('#dlgAddLink').dialog({
                        modal: true,
                        resizable: false,
                        width: '400px',
                        height: 'auto'
                    });
                    return true;
                };

                self.addLink = function () {
                    var callback = self.addLinkCallback;
                    if (callback == null)
                        return;

                    if (!self.checkLinkUrl())
                        return;

                    if (callback)
                        callback($('#dlgAddLink #linkUrl').val());
                    $('#dlgAddLink').dialog('close');
                    self.addLinkCallback = null;
                };

                self.addImageDialog = function (callback) {
                    self.addImageCallback = callback;

                    $('#dlgAddImage #computer').prop('checked', true);
                    $('#dlgAddImage #web').prop('checked', false);
                    $('#dlgAddImage #imageFile').show();
                    $('#dlgAddImage #imageFile').val('');
                    $('#dlgAddImage #imageUrl').hide();
                    $('#dlgAddImage #imageUrl').val('http://');

                    $('#dlgAddImage').dialog({
                        modal: true,
                        resizable: false,
                        width: '400px',
                        height: 'auto'
                    });
                    return true;
                };

                self.addImage = function () {
                    var callback = self.addImageCallback;
                    if (callback == null)
                        return;

                    if ($('#dlgAddImage #computer').prop('checked')) {
                        if (!self.checkImageFile())
                            return;

                        var options = {
                            dataType: 'json',
                            success: function (result) {
                                $('#loading').hide();
                                if (!result.success) {
                                    alert(result.error);
                                    return;
                                }
                                if (callback)
                                    callback(result.link);
                                $('#dlgAddImage').dialog('close');
                                self.addImageCallback = null;
                            }
                        };
                        $('#loading').show();
                        $('#formAddImage').ajaxSubmit(options);
                    } else {
                        if (!self.checkImageUrl())
                            return;

                        if (callback)
                            callback($('#dlgAddImage #imageUrl').val());
                        $('#dlgAddImage').dialog('close');
                        self.addImageCallback = null;
                    }
                };

                self.checkLinkUrl = function () {
                    var file = $('#dlgAddImage #linkUrl').val();
                    if (file == '') {
                        alert('Please enter the link url you want to add.');
                        return false;
                    }
                    return true;
                };

                self.checkImageFile = function () {
                    var file = $('#dlgAddImage #imageFile').val();
                    if (file == '') {
                        alert('Please select the file you want to add.');
                        return false;
                    }

                    var extension = file.split('.').pop();
                    if (extension)
                        extension = extension.toLowerCase();
                    if (extension != 'png'
                        && extension != 'jpg'
                        && extension != 'gif'
                        && extension != 'jpeg') {
                        alert('[' + file + '] is not a valid image file!');
                        return false;
                    }
                    return true;
                };

                self.checkImageUrl = function () {
                    var file = $('#dlgAddImage #imageUrl').val();
                    if (file == '') {
                        alert('Please enter the image url you want to add.');
                        return false;
                    }
                    return true;
                };

                self.ajaxConverter = function (text, callback) {
                    if (self.busy)
                        return;

                    self.busy = true;
                    $.ajax({
                        type: 'POST',
                        url: '<%= this.Url.ActionEx("Transfer").SafeHtmlEncode() %>',
                        data: { text: text },
                        success: function (result) {
                            self.busy = false;
                            callback(result.html);
                        },
                        error: function () {
                            self.busy = false;
                        }
                    });
                };
            }

            function onWindowInit() {
                var h = $(document.body).height();
                h = h - $('#wmd-button-bar').outerHeight(true);
                h = h - $('#menubar').outerHeight(true);
                h = h - 2;
                if (h >= 602) {
                    $('#wmd-preview').show();
                    $('#cbPreview').prop('checked', true);
                } else {
                    $('#wmd-preview').hide();
                    $('#cbPreview').prop('checked', false);
                }
            }

            function onWindowResized() {
                var h = $(document.body).height();
                h = h - $('#wmd-button-bar').outerHeight(true);
                h = h - $('#menubar').outerHeight(true);
                h = h - 2;
                if ($('#cbPreview').prop('checked')) {
                    $('#wmd-input').height(h / 2);
                    $('#wmd-preview').height(h / 2);
                } else {
                    $('#wmd-input').height(h);
                }
            }

            onWindowInit();
            onWindowResized();
            $(window).on('resize', onWindowResized);

            var converter1 = Markdown.getSanitizingConverter();

            converter1.hooks.chain("preConversion", function (text) {
                return text.replace(/</g, '&lt;').replace(/>/g, '&gt;');
            });

            mgr = new TranslationMgr(<%=this.ViewData["MetadataGameInformations"]%>);

            var editor1 = new Markdown.Editor(converter1);

            editor1.hooks.set("insertLinkDialog", mgr.addLinkDialog);
            editor1.hooks.set("insertImageDialog", mgr.addImageDialog);
            editor1.hooks.set("ajaxConverter", mgr.ajaxConverter);

            editor1.run();

            mgr.initialize(editor1);
        })();
    </script>


</asp:Content>
