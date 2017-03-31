<%@ Page Title="Search Metadata" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>"%>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>

<script language="C#" type="text/C#" runat="server">
    private SelectList GetLanguages()
    {
        var languages = MultilingualMgr.GetSupporttedLanguages(this.Model)
            .Select( l => new KeyValuePair<string, string>( l.LanguageCode, string.Format( "{0} - [{1}]", l.DisplayName, l.LanguageCode)) )
            .ToList();
        
        languages.Insert( 0, new KeyValuePair<string,string>( string.Empty, "Default"));

        return new SelectList(languages, "Key", "Value", string.Empty);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/SearchMetadata/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="search-metadata-form-wrapper">

<% using (this.Html.BeginForm("StartSearch", null, new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id = "formSearchMetadata", @target = "_blank" }))
   { %>

<ui:InputField id="fldFindWhat" runat="server">
    <LabelPart>
    Find what:
    </LabelPart>
    <ControlPart>
        <%: Html.TextBox("content", string.Empty, new { @validator = ClientValidators.Create().Required().MinLength(3) })   %>
    </ControlPart>
</ui:InputField>


<ui:InputField id="fldLanguage" runat="server">
    <LabelPart>
    Look in language:
    </LabelPart>
    <ControlPart>
        <%: Html.DropDownList( "language", GetLanguages() ) %>
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
        $('#formSearchMetadata').initializeForm();
        $('#btnSearch').button().click(function (e) {
            e.preventDefault();

            if (!$('#formSearchMetadata').valid())
                return;

            
            $('#formSearchMetadata').submit();
        });
    });
</script>

</asp:Content>



