<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<script language="C#" type="text/C#" runat="server">
    private SelectListItem [] GetCountryList()
    {
        PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
        cmSite domain = this.ViewData["cmSite"] as cmSite;
        var selectedList = (paymentMethod.SupportedCountries ?? new CountryList()).List;
        var list = CountryManager.GetAllCountries(domain.DistinctName)
            .Where(c => c.InternalID > 0)
            .Select(c => new SelectListItem() { Text = string.Format("{0} - {1}", c.ISO_3166_Alpha2Code, c.EnglishName), Value = c.InternalID.ToString(), Selected = (selectedList != null && selectedList.Exists( d => c.InternalID == d)) })
            .OrderBy(c => c.Text)
            .ToArray();
        return list;
    }

    private bool IsExcluded()
    {
        return ((this.ViewData["paymentMethod"] as PaymentMethod).SupportedCountries ?? new CountryList()).Type == CountryList.FilterType.Exclude;
    }
</script>

<% 
    PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
    cmSite domain = this.ViewData["cmSite"] as cmSite;
    using( Html.BeginRouteForm("PaymentMethodMgt", new
   { @action = "SaveSupportedCountry"
       , @paymentMethodName = paymentMethod.UniqueName
       , @distinctName = domain.DistinctName.DefaultEncrypt()
   }
   , FormMethod.Post
   , new { @id = "formSaveSupportedCountry" }
   ))
   { %>

   <%: Html.RadioButton("filterType", CountryList.FilterType.Exclude, IsExcluded(), new { @id = "Exclude" })%>
   <label for="Exclude">Only the selected country(s) are <strong>NOT</strong> supported for this payment method.</label>
   <br />
   <%: Html.RadioButton("filterType", CountryList.FilterType.Include, !IsExcluded(), new { @id = "Include" })%>
   <label for="Include">Only the selected country(s) are supported for this payment method.</label>
   <hr />

   <%: Html.DropDownList( "list", GetCountryList(), new { @multiple = "multiple", @size = "20", @id = "ddlCountry" }) %>

   <div class="button-contaner">
   <%: Html.Button("Save", new { @id = "btnSaveCountryList", @type = "submit" })%>
   </div>
<% } %>

<script language="javascript" type="text/javascript">
    $('#btnSaveCountryList').click( function (e) {
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
        $('#formSaveSupportedCountry').ajaxForm(options);
        $('#formSaveSupportedCountry').submit();
    });

</script>