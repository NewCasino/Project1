<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.PageNode>" %>

<% using (Html.BeginForm( "SaveProperties"
       , null
       , new { @distinctName = this.Model.ContentNode.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.ContentNode.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formProperties"}
    ) ) { %>

<ui:InputField id="fldPath" runat="server">
    <LabelPart>
    Path:
    </LabelPart>
    <ControlPart>
    <%: Html.TextBoxFor(t => t.ContentNode.RelativePath, new { @id="txtRelativePath", @readonly = "readonly" }) %>
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldRouteName" runat="server">
    <LabelPart>
    Unique route name:
    </LabelPart>
    <ControlPart>
    <%: Html.TextBoxFor(t => t.RouteName, new { @id="txtRouteName", @readonly = "readonly" }) %>
    </ControlPart>
</ui:InputField>
       
<ui:InputField id="fldController" runat="server">
    <LabelPart>
    Page controller:
    </LabelPart>
    <ControlPart>
    <%= Html.DropDownListFor( r => r.Controller
           , new SelectList(this.ViewData["PageControllers"] as List<KeyValuePair<string, string>>, "Key", "Value")
           , new { @id = "cmbController" }
           ) %>
    </ControlPart>
</ui:InputField>

<div class="buttons-wrap">
    <%= Html.Button("Save", new { @id = "btnSubmit"})  %>
</div>

<% } %>


<ui:ExternalJavascriptControl runat="server">
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
        InputFields.initialize($("#formProperties"));

        $('#btnSubmit').bind('click', this, function (e) { e.preventDefault(); e.data.onBtnSaveClick(); });
    };

    this.init();
};
</script>
</ui:ExternalJavascriptControl>