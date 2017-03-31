<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script language="C#" type="text/C#" runat="server">
    private SelectListItem [] GetCurrencyList()
    {
        var selectedList = ((this.ViewData["paymentMethod"] as PaymentMethod).SupportedCurrencies ?? new CurrencyList()).List;
        var list = GmCore.GamMatrixClient.GetSupportedCurrencies()
            .Select(c => new SelectListItem() { Text = string.Format("{0} - {1}", c.ISO4217_Alpha, c.Name), Value = c.ISO4217_Alpha, Selected = (selectedList != null && selectedList.Exists( d => c.ISO4217_Alpha == d)) })
            .ToArray();
        return list;
    }

    private bool IsExcluded()
    {
        return ((this.ViewData["paymentMethod"] as PaymentMethod).SupportedCurrencies ?? new CurrencyList()).Type == CurrencyList.FilterType.Exclude;
    }
</script>

<% 
    PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
    cmSite domain = this.ViewData["cmSite"] as cmSite;
    
    using( Html.BeginRouteForm("PaymentMethodMgt", new
   { @action = "SaveSupportedCurrency"
       , @paymentMethodName = paymentMethod.UniqueName
       , @distinctName = domain.DistinctName.DefaultEncrypt()
   }
   , FormMethod.Post
   , new { @id = "formSaveSupportedCurrency" }
   ))
   { %>

   <%: Html.RadioButton("filterType", CurrencyList.FilterType.Exclude, IsExcluded(), new { @id = "Exclude" })%>
   <label for="Exclude">Only the selected currency(s) are <strong>NOT</strong> supported for this payment method.</label>
   <br />
   <%: Html.RadioButton("filterType", CurrencyList.FilterType.Include, !IsExcluded(), new { @id = "Include" })%>
   <label for="Include">Only the selected currency(s) are supported for this payment method.</label>
   <hr />

   <%: Html.DropDownList("list", GetCurrencyList(), new { @multiple = "multiple", @size = "23", @id = "ddlCurrency" })%>

   <div class="button-contaner">
   <%: Html.Button("Save", new { @id = "btnSaveCurrencyList", @type = "submit" })%>
   </div>
<% } %>

<script language="javascript" type="text/javascript">
    $('#btnSaveCurrencyList').click( function (e) {
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
        $('#formSaveSupportedCurrency').ajaxForm(options);
        $('#formSaveSupportedCurrency').submit();
    });
</script>