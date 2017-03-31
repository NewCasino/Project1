<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.MetadataNode>" %>

<% using (Html.BeginForm("SaveProperties"
       , null
       , new { @distinctName = this.Model.ContentNode.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.ContentNode.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formProperties" }
    ))
   { %>

<ui:InputField ID="fldValidFrom" runat="server">
    <labelpart>
    Valid From:
    </labelpart>
    <controlpart>
        <input type="text" id="txtValidFrom" name="validFrom" readonly="readonly" value="<%= this.Model.ValidFrom.HasValue ? this.Model.ValidFrom.Value.ToString("yyyy-MM-dd HH:mm:ss") : string.Empty %>"/>
        <%= Html.Button("Remove", new { @id = "btnRemoveValidFrom"})  %>
    </controlpart>
</ui:InputField>

<ui:InputField ID="fldExpiryTime" runat="server">
    <labelpart>
    Expiry Time:
    </labelpart>
    <controlpart>
        <input type="text" id="txtExpiryTime" name="expiryTime" readonly="readonly" value="<%= this.Model.ExpiryTime.HasValue ? this.Model.ExpiryTime.Value.ToString("yyyy-MM-dd HH:mm:ss") : string.Empty %>"/>
        <%= Html.Button("Remove", new { @id = "btnRemoveExpiryTime"})  %>
    </controlpart>
</ui:InputField>

<ui:InputField id="fldVisibility" runat="server">
    <LabelPart>
    Visibility:
    </LabelPart>
    <ControlPart>
    <%: Html.CheckBox( "isUKLicense", this.Model.AvailableForUKLicense, new { @id = "btnIsUKLicense" }) %>
    <label for="btnIsUKLicense">UK License</label>
    <br />
    <%: Html.CheckBox( "notUKLicense", this.Model.AvailableForNonUKLicense, new { @id = "btnNotUKLicense" }) %>
    <label for="btnNotUKLicense">Non UK License</label>
    </ControlPart>
</ui:InputField>

<div class="buttons-wrap">
    <%= Html.Button("Save", new { @id = "btnSubmit"})  %>
    
</div>

<% } %>


<ui:ExternalJavascriptControl ID="ExternalJavascriptControl1" runat="server">
    <script language="javascript" type="text/javascript">
        function TabProperties() {

            this.onBtnSaveClick = function () {
        <% if (this.Model.ContentNode.NodeStatus == ContentNode.ContentNodeStatus.Inherited)
           { %>
                if (window.confirm('This page is inherited from common template, you are about to override it for modification.\n\nPress "OK" to continue.') != true)
                    return;
        <% } %>

                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success)
                            alert(json.error);
                    }
                };
                $('#formProperties').ajaxForm(options);
                $('#formProperties').submit();
            };

            this.init = function () {
                $('#txtValidFrom').datetimepicker({
                    ampm: false,
                    dateFormat: 'yy-mm-dd',
                    showAnim: '',
                    showSecond: false,
                    timeFormat: 'hh:mm:ss',
                    hour: 0,
                    minute: 0,
                    second: 0
                });
                $('#txtExpiryTime').datetimepicker({
                    ampm: false,
                    dateFormat: 'yy-mm-dd',
                    showAnim: '',
                    showSecond: false,
                    timeFormat: 'hh:mm:ss',
                    hour: 23,
                    minute: 59,
                    second: 59
                });

                InputFields.initialize($("#formProperties"));

                $('#btnSubmit').bind('click', this, function (e) {
                    e.preventDefault();
                    e.data.onBtnSaveClick();
                });

                $('#btnRemoveValidFrom').bind('click', this, function (e) {
                    e.preventDefault();

                    $('#txtValidFrom').val('');
                });

                $('#btnRemoveExpiryTime').bind('click', this, function (e) {
                    e.preventDefault();

                    $('#txtExpiryTime').val('');
                });
            };

            this.init();
        };
    </script>
</ui:ExternalJavascriptControl>
