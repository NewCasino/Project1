<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private object SelectedCountry { get; set; }
    private List<SelectListItem> GetCountryList()
    {
        List<SelectListItem> items = CountryManager.GetAllCountries()
            .Where( c => c.InternalID > 0 )
            .Select( c => new SelectListItem() { Text = c.DisplayName, Value = c.InternalID.ToString(), Selected = c.InternalID == ProfileCommon.Current.AsCustomProfile().UserCountryID })
            .ToList();

        items.Insert(0, new SelectListItem() { Text = this.GetMetadata(".Choose_Country"), Value = "-1" });

        if (Profile.IsAuthenticated)
            SelectedCountry = ProfileCommon.Current.AsCustomProfile().UserCountryID;
        
        return items;
    }

    private bool LockCountryPaymentsFIlterForLoginUsers
    {
        get
        {
            if (Profile.IsAuthenticated)
            {
                return Settings.LockCountryPaymentsFIlterForLoginUsers;
            }
            else
            {
                return false;
            }
        }
    }

    private bool LockCurrencyPaymentsFIlterForLoginUsers
    {
        get
        {
            if (Profile.IsAuthenticated)
            {
                return Settings.LockCurrencyPaymentsFIlterForLoginUsers;
            }
            else
            {
                return false;
            }
        }
    }

    private string SelectedCurrency { get; set; }
    private List<SelectListItem> GetCurrencyList()
    {
        List<SelectListItem> list = GamMatrixClient.GetSupportedCurrencies()
            .FilterForCurrentDomain()
            .Select(c => new SelectListItem { Text = c.GetDisplayName(), Value = c.ISO4217_Alpha })
            .ToList();
        
        if (Profile.IsAuthenticated)
        {
            SelectListItem item = list.FirstOrDefault(i => string.Equals(i.Value, Profile.AsCustomProfile().UserCurrency));
            if (item != null)
            {
                item.Selected = true;
                SelectedCurrency = Profile.AsCustomProfile().UserCurrency;
            }
            else
            {
                ResolveDefaultCurrency(list);
            }
        }
        else
        {
            ResolveDefaultCurrency(list); 
        }
        return list;
    }
    private void ResolveDefaultCurrency(List<SelectListItem> list)
    {
        string defaultCurreny = this.ViewData["DefaultCurreny"] as string;

        if (list.Exists(p => p.Value.Equals(defaultCurreny, StringComparison.OrdinalIgnoreCase)))
        {
            SelectListItem defaultSelectedItem = list.First(p => p.Value.Equals(defaultCurreny, StringComparison.InvariantCultureIgnoreCase));
            defaultSelectedItem.Selected = true;
            SelectedCurrency = defaultSelectedItem.Value;
        }
        else if(list.Count>0)
        {
            list[0].Selected = true;
            SelectedCurrency = list[0].Value;
        }
    } 
</script>

<% if( Profile.IsAuthenticated )
   { %>
<div id="registered-cards-wrapper"></div>
<div id="registered-cards-wrapper-" class="registered-cards-wrapper">
<script id="registered-cards-template" type="text/html">
<ui:Fieldset Legend="<%$ Metadata:value(.Registered_Credit_Cards) %>" runat="server">
    <ul class="CardsLists">
<#
    var d=arguments[0];

    for(var i=0; i < d.length; i++)     
    { 
        var item = d[i];
        if( item.Visible != undefined){
            if( !item.Visible)
                continue;
        }       
#>
    <li>
        <a href="<#= d[i].Url.htmlEncode() #>">
            <#= d[i].DisplayNumber.htmlEncode() #> 
        </a>
        (<#= d[i].ExpiryDate.htmlEncode() #> <#= d[i].CardName #>)
    </li>

<#  }  #>

    </ul>
</ui:Fieldset>
</script>
</div>
<% } %>

<ui:Fieldset runat="server" Legend="<%$ Metadata:value(.Legend_Filter) %>">
<% using (Html.BeginRouteForm("Deposit", new { @action = "PaymentMethodListView" }, FormMethod.Post, new { @id = "formPaymentMethodList" }))
   { %>
   <ui:InputField runat="server" ID="fldCountry">
        <LabelPart><%= this.GetMetadata(".Choose_Country").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
            <%: Html.DropDownList( "ddlcountry", this.GetCountryList(), new Dictionary<string, object>().SetDisabled(LockCountryPaymentsFIlterForLoginUsers) ) %>
        </ControlPart>
   </ui:InputField>

   <ui:InputField runat="server" ID="fldCurrency">
        <LabelPart><%= this.GetMetadata(".Choose_Currency").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
            <%: Html.DropDownList("ddlcurrency", this.GetCurrencyList(), new Dictionary<string, object>().SetDisabled(LockCurrencyPaymentsFIlterForLoginUsers))%>
        </ControlPart>
   </ui:InputField>
   <input type="hidden" id="country" name="country" value="" />
   <input type="hidden" id="currency" name="currency" value="" />
   <div class="button-wrapper">
   <%: Html.Button( this.GetMetadata(".Button_Filter"), new { @type = "submit", @id = "btnFilterPaymentMethods"} ) %>
   </div>
<% } %>
</ui:Fieldset>



<div id="payment-methods-wrapper">
    <% Html.RenderPartial("PaymentMethodList", this.ViewData.Merge(new { @CountryID = SelectedCountry, @Currency = SelectedCurrency })); %>
</div>

<script language="javascript" type="text/javascript">
//<![CDATA[
    $(document).ready(function () {
        $('#formPaymentMethodList').initializeForm();
        $(".PaymentItem[data-resourcekey='APX']").css("display","none");
        $('#btnFilterPaymentMethods').click(function (e) {
            $(this).toggleLoadingSpin(true);
            e.preventDefault();
            $('#country').val($('#ddlcountry').val());
            $('#currency').val($('#ddlcurrency').val());
            var options = {
                type: 'POST',
                dataType: 'html',
                success: function (html) {
                    $('#btnFilterPaymentMethods').toggleLoadingSpin(false);
                    $('#payment-methods-wrapper').html(html);
                    $(document).trigger("_ON_PAYMENT_METHOD_LIST_LOAD_");
                }
            };
            $('#formPaymentMethodList').ajaxForm(options);
            $('#formPaymentMethodList').submit();
        });

<% if( Profile.IsAuthenticated )
   { %>
        var url = '<%= this.Url.RouteUrl( "Deposit", new { @action="GetPayCards", @vendorID=VendorID.PaymentTrust }).SafeJavascriptStringEncode() %>';
        jQuery.getJSON(url, null, function (json) {
            if (!json.success) {
                return;
            }

            if( json.payCards.length > 0 ){
                var wrap = $('#registered-cards-wrapper').hide().html($('#registered-cards-template').parseTemplate(json.payCards));
                if( $('.CardsLists li').length == 0){
                }else{
                    wrap.slideDown();
                }
            }
        });

<% } %>

    });
//]]>
</script>
