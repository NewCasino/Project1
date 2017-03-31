<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script language="C#" type="text/C#" runat="server">
    private SelectListItem [] GetProcessTimeList()
    {
        PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = "Immediately", Value = ProcessTime.Immediately.ToString(), Selected = paymentMethod.ProcessTime == ProcessTime.Immediately });
        list.Add(new SelectListItem() { Text = "Instant", Value = ProcessTime.Instant.ToString(), Selected = paymentMethod.ProcessTime == ProcessTime.Instant });
        list.Add(new SelectListItem() { Text = "15 minutes", Value = ProcessTime.FifteenMinutes.ToString(), Selected = paymentMethod.ProcessTime == ProcessTime.FifteenMinutes });
        list.Add(new SelectListItem() { Text = "3 - 5 days", Value = ProcessTime.ThreeToFiveDays.ToString(), Selected = paymentMethod.ProcessTime == ProcessTime.ThreeToFiveDays });
        list.Add(new SelectListItem() { Text = "Variable", Value = ProcessTime.Variable.ToString(), Selected = paymentMethod.ProcessTime == ProcessTime.Variable });
        return list.ToArray();
    }
</script>

<%
    using( Html.BeginRouteForm( "PaymentMethodMgt", new 
   { @action="SaveProcessTime",
     @paymentMethodName = (this.ViewData["paymentMethod"] as PaymentMethod).UniqueName,
     @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt()
   }, FormMethod.Post, new { @id = "formSaveProcessTime" }))
   { %>

<ui:InputField runat="server" >
    <LabelPart>
        Process Time:
    </LabelPart>
    <ControlPart>
        <table cellpadding="0" cellspacing="0" border="0">
            <tr>
                <td><%: Html.DropDownList( "processTime", GetProcessTimeList()) %></td>
                <td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
                <td><%: Html.Button("Save", new { @id = "btnSaveProcessTime", @type = "submit" })%></td>
            </tr>
        </table>
    </ControlPart>
</ui:InputField>

<% } %>

<script language="javascript" type="text/javascript">
    $('#formSaveProcessTime').initializeForm();

    $('#btnSaveProcessTime').click(function (e) {
        e.preventDefault();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (!json.success) { alert(json.error); }
                $("div.popup-dialog").dialog('destroy');
                $("div.popup-dialog").remove();
                self.tabProperties.refresh();
            }
        };
        if (self.startLoad) self.startLoad();
        $('#formSaveProcessTime').ajaxForm(options);
        $('#formSaveProcessTime').submit();
    });
</script>