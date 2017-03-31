<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Controllers.System.DirectoryMgtParam>" %>
<%@ Import Namespace="CM.Content" %>




<div id="operation-links">
    <ul>
        <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="selectall">Select All</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="unselectall">Unselect All</a></li>
        <%-- 
    <li>|</li>
    <li><a href="javascript:void(0)" target="_self" class="copy">Copy</a></li>
    <li>|</li>
    <li><a href="javascript:void(0)" target="_self" class="cut">Cut</a></li>
    <li>|</li>
    <li><a href="javascript:void(0)" target="_self" onclick="alert('this feature is still under construction')" class="paste">Paste</a></li>
        --%>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="delete">Delete</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="enable">Enable</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="disable">Disable</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="sort">Order...</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="create">Create...</a></li>
    </ul>
</div>


<hr class="seperator" />
<form id="formItems" method="POST" action="#">
    <div id="children-container">
    </div>
</form>

<div id="dialog-modal" title="Create Child" style="display: none">
    <% using (Html.BeginRouteForm("DirectoryMgt"
       , new { @action = "CreateChild", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formCreateChild" }))
       { %>
    <ui:InputField ID="fldType" runat="server" ShowDefaultIndicator="false">
        <labelpart>
            Type:
            </labelpart>
        <controlpart>
            <%: Html.DropDownList( "childType"
                , new SelectList( this.Model.AllowedNodeTypes, "Value", "Key")
                , new { @id = "cmbChildType"}
                ) %>
            </controlpart>
    </ui:InputField>

    <ui:InputField ID="fldName" runat="server" ShowDefaultIndicator="false">
        <labelpart>
            Name:
            </labelpart>
        <controlpart>
            <%: Html.TextBox( "childName"
                , ""
                , new { @id="txtChildName", @validator = ClientValidators.Create().Required() } 
                ) %>
            </controlpart>
    </ui:InputField>

    <div class="copyfield" style="display: none;">
        <%=Html.CheckBox("childCopy", false, new { @id = "cbCopy" })%>
        <label for="cbCopy">Copy from </label>
        <select name="childCopyFrom" id="cmbChildCopyFrom" disabled="disabled"></select>
        <br /><br />
    </div>

    <div class="buttons-wrap">
        <%= Html.Button("Create", new { @id = "btnCreateChild" })  %>
    </div>
    <% } %>
</div>

<div id="order-dialog" title="Metadata Order List" style="display: none" unselectable="on" onselectstart="return false;">
</div>

<% using (Html.BeginRouteForm("DirectoryMgt"
       , new { @action = "SaveMetadataOrderList", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formMetadataOrderList" }))
   { %>
<%: Html.Hidden("list", "", new { id = "hMetadataOrderList"}) %>
<% } %>


<script id="item-template" type="text/html">

    <div class="item">
        <table cellpadding="0" cellspacing="0" border="0">
            <tr class="parent-dir">
                <td>&nbsp;</td>
                <td>
                    <a href="<%= Url.RouteUrl( "DirectoryMgt", new { @action = "GotoParent", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeHtmlEncode() %>" target="_self" class="parent-dir">
                        <span title="Return to parent directory">&nbsp;&nbsp;Move up ..</span>
                    </a>
                </td>
                <td>
                    <img src="/images/transparent.gif" />
                </td>
            </tr>
        </table>
    </div>

    <#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

    <div class="item  <#= (item.IsDisabled == true) ? 'disabled' : 'enabled' #> <#= item.NodeStatus.htmlEncode() #>">
        <table cellpadding="0" cellspacing="0" border="0" class="<#= item.NodeType.htmlEncode() #>">
            <tr class="<#= item.NodeStatus.htmlEncode() #>">
                <td>
                    <input type="checkbox" name="selectedItems" value="<#= item.RelativePath.htmlEncode() #>" /></td>
                <td>
                    <a href="<#= item.ActionUrl.htmlEncode() #>" target="_self">
                        <span title="<#= item.DisplayName.htmlEncode() #>"><#= item.DisplayName.htmlEncode() #></span>
                    </a>
                </td>
                <td>
                    <img src="/images/transparent.gif" />
                </td>
            </tr>
        </table>
    </div>
    <#   }  #>
</script>

<script id="metadata-item-template" type="text/html">
    <#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>
    <div class="item">
        <span><#= item.htmlEncode() #></span>
    </div>
    <#   }  #>
</script>


<ui:ExternalJavascriptControl runat="server">
    <script language="javascript" type="text/javascript">
        function TabChildren() {
            self.tabChildren = this;
            this.getChildrenAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="GetChildren", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
            this.copyAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="Copy", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
            this.cutAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="Cut", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
            this.pasteAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="Paste", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
            this.deleteAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="Delete", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';
            this.enableMetadataAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="EnableMetadata", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @enable = true }).SafeJavascriptStringEncode()  %>';
            this.disableMetadataAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="EnableMetadata", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @enable = false }).SafeJavascriptStringEncode()  %>';
            this.getMetadataOrderListAction = '<%= Url.RouteUrl( "DirectoryMgt", new { @action="GetMetadataOrderList", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode()  %>';

            this.refresh = function () {
                $('#children-container').html('<img src="/images/icon/loading.gif" />');
                $('.copyfield').hide();
                $('#cmbChildCopyFrom').empty();

                jQuery.getJSON(this.getChildrenAction, null, function (data) {
                    $('#children-container').html('');
                    if (!data.success) alert(data.error);
                    else {
                        $('#children-container').html($('#item-template').parseTemplate(data.children));
                        $('#children-container').removeClass();
                        for (var i = 0; i < data.children.length; i++) {
                            if (data.children[i].NodeType != 'metadata')
                                continue;
                            $('#cmbChildCopyFrom').append("<option value='" + data.children[i].RelativePath + "'>" + data.children[i].DisplayName + "</option>")
                        }
                        self.tabChildren.onChildTypeChanged();
                    }
                });
            };

            this.selectAll = function () {
                $('#children-container input[type="checkbox"]').attr('checked', true);
            };

            this.unselectAll = function () {
                $('#children-container input[type="checkbox"]').attr('checked', false);
            };

            this.copy = function () {
                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    url: this.copyAction,
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        alert("The operation has been completed successfully!");
                    }
                };
                $('#formItems').ajaxForm(options);
                $('#formItems').submit();
            };

            this.cut = function () {
                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    url: this.cutAction,
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        alert("The operation has been completed successfully!");
                    }
                };
                $('#formItems').ajaxForm(options);
                $('#formItems').submit();
            };

            this.paste = function (confirmed) {
                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    url: this.pasteAction + "?confirmed=" + ((confirmed == null) ? "false" : confirmed.toString()),
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }

                        if (json.status == "pending") {
                            var msg = "You are going to paste the following " + json.items.length.toString(10) + " items here:\n";
                            for (var i = 0; i < json.items.length; i++) {
                                msg += ("\n" + json.items[i]);
                            }
                            msg += '\n\n Press "OK" to continue.';
                            if (window.confirm(msg) != true)
                                return;

                            self.tabChildren.paste(true);
                            return;
                        }

                    }
                };
                $('#formItems').ajaxForm(options);
                $('#formItems').submit();
            };

            this.remove = function () {
                if (window.confirm('You are going to delete the selected items.\n\nPress "OK" to continue.\n') != true)
                    return;
                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    url: this.deleteAction,
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        self.tabChildren.refresh();
                    }
                };
                $('#formItems').ajaxForm(options);
                $('#formItems').submit();
            };

            this.enableMetadata = function (enable) {
                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    url: (enable ? this.enableMetadataAction : this.disableMetadataAction),
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        self.tabChildren.refresh();
                    }
                };
                $('#formItems').ajaxForm(options);
                $('#formItems').submit();
            };

            this.onBtnCreateChildClick = function () {
                if ($("#formCreateChild").valid()) {
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
                            self.tabChildren.refresh();
                        }
                    };
                    $('#formCreateChild').ajaxForm(options);
                    $('#formCreateChild').submit();
                }
            };

            this.onChildTypeChanged = function () {
                if ($('#cmbChildType').val() == 'Metadata' && $('#cmbChildCopyFrom').find('option').length > 0)
                    $('.copyfield').show();
                else
                    $('.copyfield').hide();
            }

            this.init = function () {
                this.refresh();

                $('#operation-links a.refresh').bind('click', this, function (e) { e.data.refresh(); });
                $('#operation-links a.selectall').bind('click', this, function (e) { e.data.selectAll(); });
                $('#operation-links a.unselectall').bind('click', this, function (e) { e.data.unselectAll(); });
                $('#operation-links a.copy').bind('click', this, function (e) { e.data.copy(); });
                $('#operation-links a.cut').bind('click', this, function (e) { e.data.cut(); });
                $('#operation-links a.paste').bind('click', this, function (e) { e.data.paste(false); });
                $('#operation-links a.delete').bind('click', this, function (e) { e.data.remove(); });
                $('#operation-links a.enable').bind('click', this, function (e) { e.data.enableMetadata(true); });
                $('#operation-links a.disable').bind('click', this, function (e) { e.data.enableMetadata(false); });
                $('#operation-links a.create').bind('click', this, function (e) {
                    $("#dialog-modal").dialog({
                        //height: 180,
                        width: 410,
                        draggable: false,
                        resizable: false,
                        modal: true
                    });
                });
                $('#operation-links a.sort').bind('click', this, function (e) {
                    $("#order-dialog").dialog({
                        height: (document.body.clientHeight - 50),
                        width: 500,
                        draggable: false,
                        resizable: false,
                        modal: true,
                        buttons: {
                            OK: function () {

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
                                $('#formMetadataOrderList').ajaxForm(options);
                                $('#formMetadataOrderList').submit();

                                $(this).dialog('close');
                            },
                            Cancel: function () {
                                $(this).dialog('close');
                            }
                        }
                    });
                    $('#order-dialog').html('<img src="/images/icon/loading.gif" />');

                    jQuery.getJSON(e.data.getMetadataOrderListAction, null, function (data) {
                        $('#order-dialog').html('');
                        if (!data.success) alert(data.error);
                        else {
                            $('#order-dialog').html($('#metadata-item-template').parseTemplate(data.children));
                            new OrderList();
                        }
                    });

                });

                $('#cmbChildType').bind('change', this, function (e) { e.data.onChildTypeChanged(); });
                $('#cbCopy').bind('click', this, function (e) {
                    if ($(this).attr('checked'))
                        $('#cmbChildCopyFrom').removeAttr('disabled');
                    else
                        $('#cmbChildCopyFrom').attr('disabled', 'disabled');
                });
                $('#btnCreateChild').bind('click', this, function (e) { e.preventDefault(); e.data.onBtnCreateChildClick(); });

                $('#operation-links a.enable').mouseover(function (e) {
                    $('#children-container').removeClass().addClass('toEnable');
                });
                $('#operation-links a.disable').mouseover(function (e) {
                    $('#children-container').removeClass().addClass('toDisable');
                });
                $('#operation-links a.delete').mouseover(function (e) {
                    $('#children-container').removeClass().addClass('toDelete');
                });
                $('#children-container').mouseover(function (e) {
                    $('#children-container').removeClass();
                });
                $('#operation-links a.refresh,#operation-links a.selectall,#operation-links a.unselectall,#operation-links a.paste,#operation-links a.create').mouseover(function (e) {
                    $('#children-container').removeClass();
                });

                $('#txtChildName').keypress(function (e) {
                    if (e.which >= 65 && e.which <= 90)
                        return;
                    if (e.which >= 97 && e.which <= 122)
                        return;
                    if (e.which >= 48 && e.which <= 57)
                        return;
                    if (e.which == 95 || e.which == 45 || e.which == 8 || e.which == 127 || e.which == 0)
                        return;
                    e.preventDefault();
                }
                );

                $('#txtChildName').change(function (e) {
                    var str = $('#txtChildName').val();
                    $('#txtChildName').val(str.replace(/[^\w\_\-]/g, ""));
                }
                );

                InputFields.initialize($("#formCreateChild"));
            };

            this.init();

        }

        function OrderList() {
            this.currentItem = null;

            this.onItemMouseDown = function (e, $item) {
                if (this.currentItem != null)
                    return;
                this.currentItem = $item.addClass('drag');

                this.onMouseMove(e);
            };
            this.onItemMouseUp = function () {
                if (this.currentItem != null) {
                    this.currentItem.removeClass('drag');
                    this.currentItem = null;

                    var elements = $('#order-dialog .item');
                    var $list = "";
                    for (var i = 0; i < elements.length; i++) {
                        if ($list.length > 0)
                            $list += ",";

                        $list += $('span', elements[i]).text();
                    }
                    $('#hMetadataOrderList').val($list);
                }
            };
            this.onMouseMove = function (e) {
                this.elements = $('#order-dialog .item');
                if (this.currentItem == null ||
                    this.elements.length == 0) return;
                var height = $(this.elements[0]).height();

                if (e.pageY >= this.currentItem.offset().top &&
                    e.pageY <= (this.currentItem.offset().top + height)) {
                }
                else {
                    var insertBefore = e.pageY < this.currentItem.offset().top;
                    for (var i = 0; i < this.elements.length; i++) {
                        if (e.pageY >= $(this.elements[i]).offset().top &&
                        e.pageY <= ($(this.elements[i]).offset().top + height)) {
                            if (insertBefore)
                                this.currentItem.detach().insertBefore(this.elements[i]);
                            else
                                this.currentItem.detach().insertAfter(this.elements[i]);
                            return;
                        }
                    }
                }
            };

            $('#order-dialog .item').bind('mousedown', this, function (e) { e.data.onItemMouseDown(e, $(this)); });
            $(document.body).bind('mouseup', this, function (e) { e.data.onItemMouseUp(); });
            $(document.body).bind('mousemove', this, function (e) { e.data.onMouseMove(e); });
        }
    </script>
</ui:ExternalJavascriptControl>



