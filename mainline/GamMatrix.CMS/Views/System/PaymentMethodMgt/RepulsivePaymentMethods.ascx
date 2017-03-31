<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script language="C#" type="text/C#" runat="server">
    private SelectListItem [] GetPaymentMethodList()
    {
        PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
        return PaymentMethodManager.GetPaymentMethods(this.ViewData["cmSite"] as cmSite, false)
            .Select(p => new SelectListItem() 
            { 
                Text = string.Format("{0} ------- ({1})", p.UniqueName, p.VendorID.ToString()),
                Value = p.UniqueName,
                Selected = paymentMethod.RepulsivePaymentMethods.Exists( p2 => p2 == p.UniqueName)
            })
            .ToArray();
    }
</script>

<%
    PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
    using( Html.BeginRouteForm( "PaymentMethodMgt", new
    {
        @action = "SaveRepulsivePaymentMethods",
        @paymentMethodName = paymentMethod.UniqueName,
        @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt()
    }, FormMethod.Post, new { @id = "formSaveRepulsivePaymentMethods" }))
   { %>

<p>If the selected payment method(s) is available on the deposit page, 
then this payment method <strong>[<%= (this.ViewData["paymentMethod"] as PaymentMethod).UniqueName  %>]</strong> will be hidden automatically.
</p>
<%: Html.DropDownList("repulsivePaymentMethods", GetPaymentMethodList(), new { @multiple = "multiple", @size = "20", @id="ddlPaymentMethod" })%>


<div class="button-contaner">
<%: Html.Button("Save", new { @id = "btnSaveRepulsivePaymentMethods", @type = "submit" })%>
</div>


<% } %>

<script language="javascript" type="text/javascript">

    $('#btnSaveRepulsivePaymentMethods').click(function (e) {
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
        $('#formSaveRepulsivePaymentMethods').ajaxForm(options);
        $('#formSaveRepulsivePaymentMethods').submit();
    });
</script>