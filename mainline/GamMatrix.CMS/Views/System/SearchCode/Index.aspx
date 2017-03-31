<%@ Page Title="Search Metadata" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>"%>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/SearchMetadata/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="search-metadata-form-wrapper">

<% using (this.Html.BeginForm("StartSearch", null, new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id = "formSearchCode", @target = "_blank" }))
   { %>

<ui:InputField id="fldFindWhat" runat="server">
    <LabelPart>
    Find what:
    </LabelPart>
    <ControlPart>
        <%: Html.TextBox("content", string.Empty, new { @validator = ClientValidators.Create().Required().MinLength(3) })   %>
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldSearchMode" runat="server">
    <LabelPart>
    Find options:
    </LabelPart>
    <ControlPart>
    <%: Html.CheckBox( "caseSensitive", false, new { @id = "btnCaseSensitive" }) %>
    <label for="btnCaseSensitive">Case sensitive</label>
    <br />
    <%: Html.CheckBox( "matchWholeString", false, new { @id = "btnMatchWholeString" }) %>
    <label for="btnMatchWholeString">Match whole string</label>
    </ControlPart>
</ui:InputField>

<div class="buttons-wrap">
    <button id="btnSearch">Search</button>
</div>

<% } %>
</div>

<script language="javascript" type="text/javascript">
    $(function () {
        $('#formSearchCode').initializeForm();
        $('#btnSearch').button().click(function (e) {
            e.preventDefault();

            if (!$('#formSearchCode').valid())
                return;

            
            $('#formSearchCode').submit();
        });
    });
</script>

</asp:Content>



