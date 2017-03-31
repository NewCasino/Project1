<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<script type="text/C#" runat="server">
    private PaymentMethod paymentMethod;    
    protected override void OnInit(EventArgs e)
    {
        paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
        base.OnInit(e);
    }
</script>
<%
    paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;    
    using( Html.BeginRouteForm( "PaymentMethodMgt", new
    {
        @action = "SaveSupportWithdraw",
        @paymentMethodName = paymentMethod.UniqueName,
        @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt()
    }, FormMethod.Post, new { @id = "formSaveWithdrawSupport" }))
   { %>
<div style="font-weight: bold;">Support Withdraw:</div>
<ul id="withdraw-support" style="list-style-type:none; padding:0px;">
   <li>
        <input type="radio" value="True" name="supportWithdraw" id="btnTrue" />
        <label for="btnTrue">Yes</label>
   </li>
   <li>
        <input type="radio" value="False" name="supportWithdraw" id="btnFalse" />
        <label for="btnFalse">No</label>
   </li>
</ul>

<div class="button-contaner">
<%: Html.Button("Save", new { @id = "btnSaveWithdrawSupport", @type = "submit" })%>
</div>

<% } %>

<script language="javascript" type="text/javascript">
    $(function () {
        $("#btn<%= paymentMethod.SupportWithdraw%>").attr("checked","checked");
        $('#formSaveWithdrawSupport').initializeForm();

        $('#btnSaveWithdrawSupport').click(function (e) {
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
            $('#formSaveWithdrawSupport').ajaxForm(options);
            $('#formSaveWithdrawSupport').submit();
        });
    });
</script>