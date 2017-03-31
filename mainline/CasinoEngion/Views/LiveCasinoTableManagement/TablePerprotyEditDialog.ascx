<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<script type="text/C#" runat="server">
    private List<SelectListItem> GetAvailableProperties()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        list.Add(new SelectListItem() { Text = "Availability", Value = "Enabled", Selected = true });
        list.Add(new SelectListItem() { Text = "VIP Table", Value = "VIPTable" });
        list.Add(new SelectListItem() { Text = "New Table", Value = "NewTable" });
        list.Add(new SelectListItem() { Text = "Turkish Table", Value = "TurkishTable" });

        if (CurrentUserSession.IsSystemUser)
        {
            list.Add(new SelectListItem() { Text = "Operator-Visible", Value = "OpVisible" });            
        }        

        return list;
    }
</script>

<style type="text/css">
    .propertyItem{ display:none;}
    .col_label{ width:100px; text-align:right; vertical-align:top; padding-right:10px;}
</style>
<div id="edit_selected_tables">
<table cellpadding="0" cellspacing="3" border="0" style="width:100%; table-layout:fixed;">
    <tr>
    <td class="col_label">
    <label class="label">Property:</label>
    </td>
    <td>
    <%: Html.DropDownList("roperties", GetAvailableProperties(), new { @id = "ddlProperties", @class = "ddl" })%>
    </td>
    </tr>
    <tr>
    <td class="col_label">
    <label class="label">Set value to:</label>
    </td>
    <td>
        <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID) { %>
        <div class="propertyItem" id="propertyOpVisible">
        <form action="">
        <input type="checkbox" id="OpVisible" name="OpVisible" style=" float:left; margin: 4px 4px 4px 0;" /><label for="OpVisible" style=" display:block;">Operator Visible</label>
        </form>
        </div>
        <% } %>

        <div class="propertyItem" id="propertyEnabled">
        <form action="">
        <input type="checkbox" id="gameEnabled" name="gameEnabled" style=" float:left; margin: 4px 4px 4px 0;" /><label for="gameEnabled" style=" display:block;">Enabled</label>
        </form>
        </div>

        <div class="propertyItem" id="propertyVIPTable">
        <form action="">
        <input type="checkbox" id="VIPTable" name="VIPTable" style=" float:left; margin: 4px 4px 4px 0;" /><label for="VIPTable" style=" display:block;">VIP Table</label>
        </form>
        </div>

        <div class="propertyItem" id="propertyNewTable">
        <form action="">
        <input type="checkbox" id="NewTable" name="NewTable" style=" float:left; margin: 4px 4px 4px 0;" /><label for="NewTable" style=" display:block;">New Table</label>
        </form>
        </div>

        <div class="propertyItem" id="propertyTurkishTable">
        <form action="">
        <input type="checkbox" id="TurkishTable" name="TurkishTable" style=" float:left; margin: 4px 4px 4px 0;" /><label for="TurkishTable" style=" display:block;">Turkish Table</label>
        </form>
        </div>

    </td>
    </tr>
    <tr>
    <td colspan="2">
        <br />
        <button id="submitPropertyEdit" type="button">Submit</button>
        
        <form target="_blank" enctype="application/x-www-form-urlencoded" id="formPropertyEdit" action="<%= this.Url.ActionEx("UpdateProperty" ).SafeHtmlEncode() %>" method="post">
            <input type="hidden" name="ids" value="" />
            <input type="hidden" name="property" value="" />
            <input type="hidden" name="value" value="" />
            <input type="hidden" name="editType" value="" />
        </form>
    </td>
    </tr>
</table>
</div>


<script type="text/javascript">
    $(function () {
        $("#edit_selected_tables").find("#ddlProperties").change(function () {
            $(".propertyItem").hide();
            var property = $("#edit_selected_tables #ddlProperties").val();
            var propertyItem = $("#property" + property);
            propertyItem.show();
            propertyItem.find("form").validate({ validateHidden: true });
            if (property == "Tags")
                syncTags();
        }).trigger("change");

        $("#submitPropertyEdit").button().click(function () {
            var $this = $(this);

            var property = $("#edit_selected_tables #ddlProperties").val();

            var _form = $("#property" + property).find("form");
            if (!_form.valid()) {
                e.preventDefault();
                return false;
            }

            $this.attr('disabled', true);
            var value = null;
            switch (property) {
                case "Enabled":
                    value = $("#edit_selected_tables #gameEnabled").attr("checked") == "checked";
                    break;
                case "OpVisible":
                    value = $("#edit_selected_tables #OpVisible").attr("checked") == "checked" ? true : false;
                    break;
                case "VIPTable":
                    value = $("#edit_selected_tables #VIPTable").attr("checked") == "checked" ? true : false;
                    break;
                case "NewTable":
                    value = $("#edit_selected_tables #NewTable").attr("checked") == "checked" ? true : false;
                    break;
                case "TurkishTable":
                    value = $("#edit_selected_tables #TurkishTable").attr("checked") == "checked" ? true : false;
                    break;
                default:
                    property = null;
                    break;
            }

            Post($this, property, value);

            return false;
        });

        $("#backToDefault").button().click(function (evt) {
            evt.preventDefault();
            var $this = $(this);
            $this.attr('disabled', true);
            var property = $("#edit_selected_tables #ddlProperties").val();
            if (property != null && property.trim() != "") {
                if (window.confirm("Are you sure you want to set the value to default setting?")) {
                    Post($this, property, null, true);
                }
            }
            $this.attr('disabled', false);
        });

        function Post(evtSource, property, value, setToDefault) {
            if (property != null && (value != null || setToDefault != null)) {
                if (selected_game_ids != null && selected_game_ids.length != 0) {
                    var fun = (function (btn) {
                        return function () {
                            btn.attr('disabled', false);
                            var json = arguments[0];
                            if (!json.success) {
                                btn.attr('checked', !btn.is(':checked'));
                                alert(json.error);
                            }
                            else {
                                if (window.confirm("The operation has been completed successfully!\n Do you want to refresh the list?") == true)
                                    $('#btnFilter').trigger('click');
                                $('#dlgEditTableProperty').dialog('close');
                            }
                        };
                    })(evtSource);

                    var options = { dataType: 'json', success: fun };
                    $('#formPropertyEdit input[name="ids"]').val(selected_game_ids);
                    $('#formPropertyEdit input[name="property"]').val(property);

                    if (value != null)
                        $('#formPropertyEdit input[name="value"]').val(value);

                    if (setToDefault != null)
                        $('#formPropertyEdit input[name="setToDefault"]').val("true");
                    else
                        $('#formPropertyEdit input[name="setToDefault"]').val("false");

                    if (property == "Tags") {
                        $('#formPropertyEdit input[name="editType"]').val($("#tagsEditType").val());
                    }
                    else
                        $('#formPropertyEdit input[name="editType"]').val("");
                    $("#formPropertyEdit").ajaxSubmit(options);
                }
            }
            else { evtSource.attr('disabled', false); alert('Error, invalid value!'); }
        }
    });
</script>
