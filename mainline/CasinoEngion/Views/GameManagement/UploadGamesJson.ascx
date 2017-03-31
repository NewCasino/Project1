<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>

<% using (Ajax.BeginForm("UploadGamesJson", "GameManagement", new AjaxOptions { HttpMethod = "POST", InsertionMode = InsertionMode.Replace, UpdateTargetId = "import_result" }, new { enctype = "multipart/form-data", id = "UploadGamesJsonForm" }))
   { %>
    <input type="file" name="file" />
    <input type="checkbox" value="true" id="overrideExistingGames" name="overrideExistingGames" style="margin-left: 15px;" />
    <input type="hidden" value="false" name="overrideExistingGames" />
    <label for="overrideExistingGames">Override Existing Games</label>
    <br/>
    <input type="submit" name="Submit" id="Submit" value="Upload config" style="position: absolute;right: 15px;bottom: 15px;" />
<%} %>

<script type="text/javascript">
$(function () {
    $('#Submit').button().click(function (e) {
        e.preventDefault();

        var options = {
            dataType: 'json',
            success: function (json) {
                $('#loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                alert("SUCCESS");
                $.modal.close();
            }
        };

        $('#loading').show();
        $("#UploadGamesJsonForm").ajaxSubmit(options);
    });
});
</script>
