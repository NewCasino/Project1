<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<style></style>
<%
    using (Html.BeginRouteForm("PaymentMethodMgt", new
    {
        @action = "SaveSimultaneousDepositLimit",
        @paymentMethodName = (this.ViewData["paymentMethod"] as PaymentMethod).UniqueName,
        @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt()
    }, FormMethod.Post, new { @id = "formSaveSimultaneousDepositLimit" }))
    { %>
<ul style="list-style-type:none; padding:1px 0; margin:0;">
    <li><b>Simultaneous Deposit Limit:</b></li>
    <li style="padding:8px 0">
        <%: Html.TextBox("simultaneousDepositLimit", (this.ViewData["paymentMethod"] as PaymentMethod).SimultaneousDepositLimit, new { @style = "text-align:right", @onkeyup="this.value=this.value.replace(/\\D/g,'')", @maxlength = 2 })%>
        <span> (0 means unlimited)</span>
    </li>
    <li style="text-align: right;"><%: Html.Button("Save", new { @id = "btnSaveSimultaneousDepositLimit", @type = "submit" })%></li>
</ul>    

<%
    } %>
<script type="text/javascript">
    $('#formSaveSimultaneousDepositLimit').initializeForm();

    $('#btnSaveSimultaneousDepositLimit').click(function (e) {
        e.preventDefault();
        if ($('#simultaneousDepositLimit').val().trim() == '')
            return;

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
        $('#formSaveSimultaneousDepositLimit').ajaxForm(options);
        $('#formSaveSimultaneousDepositLimit').submit();
    });
</script>