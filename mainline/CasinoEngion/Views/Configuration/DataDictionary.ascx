<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<dynamic>" %>


<script type="text/html" language="html" id="data-row-tempalte">

<#
    var d=arguments[0];

    for(var i=0; i < d.length; i++)     
    {        
#>

<tr class="<#= (i%2) ? 'even' : 'odd' #>">
    <td align="center"><#= d[i].DataValue.htmlEncode() #></td>
    <td align="center"><#= d[i].Text.htmlEncode() #></td>
    <td align="center">
        <img src="/images/del.png" alt="Delete" title="Delete" style="cursor:pointer;" itemID="<#= d[i].ID #>" />
    </td>
</tr>

<# } #>
</script>

<% string tableID = string.Format("data-dictionary-{0}", this.ViewData["Type"]);  %>
<h2><%= (this.ViewData["Title"] as string).SafeHtmlEncode() %></h2>
<hr />
<div class="styledTable">
    <table id="<%= tableID.SafeHtmlEncode() %>" class="data-dictionary-list" cellpadding="3" cellspacing="0">
        <thead>
            <tr>
                <th class="ui-state-default">Item Value</th>
                <th class="ui-state-default" colspan="2">Friendly Text</th>
            </tr>
        </thead>
        <tbody>
        </tbody>
        <tfoot>
            <tr>
                <td class="ui-state-default" align="center">
                    
                </td>
                <td class="ui-state-default" align="center">
                    <% using (Html.BeginRouteForm("Configuration", new { @action = "AddDataItem", @type = this.ViewData["Type"] }, FormMethod.Post, new { @class = "formAddDataItem", @onsubmit="return false" }))
                       { %>
                    <input type="text" name="text" class="txtFriendText" />
                    <% } %>
                </td>
                <td class="ui-state-default" align="center">
                    <img src="/images/add.png" class="btnAdd" alt="Add" title="Add" style="cursor:pointer;" />
                </td>
            </tr>
        </tfoot>
    </table>

    <script type="text/javascript">
        $(function () {
            var refreshHandler = function () {
                var url = '<%= this.Url.ActionEx("GetDataItems", new { @type = this.ViewData["Type"] }).SafeJavascriptStringEncode() %>';
                $.getJSON(url, function (json) {
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    $('#<%= tableID %> tbody').empty();
                    $($('#data-row-tempalte').parseTemplate(json.items)).appendTo('#<%= tableID %> tbody');
                    $('#<%= tableID %> tbody img').click(function (e) {
                        if (window.confirm("You are going to delete this data item.\n Click 'OK' to continue.") != true)
                            return;
                        $('#loading').show();
                        var url = '<%= this.Url.ActionEx("RemoveDataItem").SafeJavascriptStringEncode() %>?id=' + $(this).attr('itemID');
                        $.getJSON(url, function (json) {
                            $('#loading').hide();
                            if (!json.success) {
                                alert(json.error);
                                return;
                            }
                            refreshHandler();
                        });
                    });
                });
            };
            refreshHandler();

            $('#<%= tableID %> img.btnAdd').click(function (e) {
                var options = {
                    dataType: 'json',
                    success: function (json) {
                        $('#loading').hide();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        refreshHandler();
                        $('#<%= tableID %> input.txtFriendText').val('');
                    }
                };
                $('#loading').show();
                $('#<%= tableID %> form.formAddDataItem').ajaxSubmit(options);
            });

        });


    </script>
    <br /><br /><br /><br />
</div>




