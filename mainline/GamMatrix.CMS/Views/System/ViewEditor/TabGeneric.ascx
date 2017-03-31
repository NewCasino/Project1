<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>

<script runat="server" type="text/C#">
    private bool IsOverridable()
    {
        return this.Model.RelativePath != "/RootMaster.master";
    }
</script>

<% using (Html.BeginForm("ChangeStatus", "ViewEditor"
       , new { @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formTabGeneric" }))
   {  %>
<ui:InputField id="fldPath" runat="server">
    <LabelPart>
    Path:
    </LabelPart>
    <ControlPart>
<%= Html.TextBoxFor(r => r.RelativePath, new { @readOnly = "readOnly" })%>
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldStatus" runat="server">
    <LabelPart>
    Status:
    </LabelPart>
    <ControlPart>
<%= Html.TextBoxFor(r => r.NodeStatus, new { @readOnly = "readOnly" })%>
    </ControlPart>
</ui:InputField>
<% } %>

<%
    if (this.Model.NodeStatus == ContentNode.ContentNodeStatus.Inherited && IsOverridable() )
    using (Html.BeginForm("Override", "ViewEditor"
       , new { @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formOverride" }))
   {  %>
<div class="buttons-wrap">
<button class="ui-button ui-button-text-only ui-widget ui-state-default ui-corner-all">
   <span class="ui-button-text">Click here to override the common template for customization</span>
</button> 
</div>
<% } %>


<%
    if( this.Model.NodeStatus == ContentNode.ContentNodeStatus.Overrode )
    using (Html.BeginForm("Unoverride", "ViewEditor"
       , new { @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formUnoverride" }))
   {  %>
<div class="buttons-wrap">
<button class="ui-button ui-button-text-only ui-widget ui-state-default ui-corner-all">
   <span class="ui-button-text">Click here to restore to use the common template.</span>
</button> 
</div>
<% } %>


<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
    function TabGeneric(viewEditor) {
        this.init = function () {
            InputFields.initialize($("#formTabGeneric"));
        };

        this.init();
    }
</script>
</ui:ExternalJavascriptControl>