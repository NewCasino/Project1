<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<Type>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>

<script type="text/C#" runat="server">
    private static List<SelectListItem> s_Countries;

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        if (s_Countries == null)
        {
            LocationAccessor la = LocationAccessor.CreateInstance<LocationAccessor>();
            s_Countries = la.GetCountries().Select(c => new SelectListItem() { Text = c.Value, Value = c.Key }).ToList();
            s_Countries.Insert(0, new SelectListItem() { Selected = true, Text = "< Country >", Value = string.Empty });
        }
    }

    private string FormClientID { get; set; }
    protected override void OnInit(EventArgs e)
    {
        this.FormClientID = Guid.NewGuid().ToString("N").Truncate(5);
        base.OnInit(e);
    }

    
    private Dictionary<ConfigAttribute, ceDomainConfigItem> GetRows()
    {
        StringBuilder html = new StringBuilder();
        return IConfigBase.DirectReadAll(DomainManager.CurrentDomainID, this.Model);
    }
</script>



<h3 id="<%= this.Model.Name %>"><a href="#"><%= this.Model.Name %></a></h3>
<div>
    <form id="formSaveCfg_<%= this.FormClientID %>" target="_blank" method="post" enctype="application/x-www-form-urlencoded"
        action="<%= this.Url.ActionEx("SaveDomainConfig", new { @typeName = this.Model.FullName } ).SafeHtmlEncode() %>">
        <table border="0" cellspacing="0" cellpadding="5" style="width:100%">

            <% foreach( var item in GetRows() )
               { 
                   string countrySpecificCfgFieldName = string.Format( "{0}_CountrySpecificCfg", item.Value.ItemName);
                   %>
            <tr>
                <td style="width:30%"><%= item.Key.Comments.SafeHtmlEncode() %> : </td>
                <td>
                    <%: Html.TextBox(item.Value.ItemName
                        , item.Value.ItemValue
                        , new { @autocomplete="off", @class="textbox", @style="width:100%", @maxlength = item.Key.MaxLength }
                        ) %>
                    <% if( item.Key.AllowCountrySpecificValue )
                       { %>
                        <%: Html.Hidden(countrySpecificCfgFieldName, item.Value.CountrySpecificCfg, new { @class = "country_specific_cfg_hidden" })%>
                    <% } %>
                </td>
            </tr>

                <% if( item.Key.AllowCountrySpecificValue )
                   { %>

                <tr data-for="<%: countrySpecificCfgFieldName %>">
                    <td style="text-align:right">
                        <%: Html.DropDownList( "country", s_Countries, new { @style = "width:140px", @class = "country_selection" })%> =
                    </td>
                    <td>
                        <%: Html.TextBox(item.Value.ItemName + Guid.NewGuid().ToString("N")
                        , string.Empty
                        , new { @autocomplete="off", @class="textbox country_specific_cfg", @style="width:100%", @maxlength = item.Key.MaxLength }
                        ) %>
                    </td>
                </tr>
                <tr class="section-seperator">
                    <td colspan="2"><hr /></td>
                </tr>
                <% } %>

            <% } %>
        
        </table>
        <p>
            <% if(DomainManager.AllowEdit()) { %>
            <button style="float:right" id="btnSaveVendors_<%= this.FormClientID %>">Save</button>
            <% } %>
        </p>
<script type="text/javascript">
    $(function () {
        var $btn = $('#btnSaveVendors_<%= this.FormClientID %>');
        var $form = $('#formSaveCfg_<%= this.FormClientID %>');
        $form.validate();
        $btn.button({
            icons: {
                primary: "ui-icon-disk"
            }
        }).click(function (e) {
            e.preventDefault();

            var options = {
                dataType: 'json',
                success: function (json) {
                    $('#loading').hide();
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                }
            };
            $('#loading').show();
            $form.ajaxSubmit(options);
        });

        var $ddls = $('select.country_selection', $form);
        $ddls.each(function (i, ddl) {
            var $ddl = $(ddl);
            $ddl.change(function (e) {
                var $row = $(this).parent().parent().eq(0);

                // if value is selected
                if ($(this).val() != '') {
                    // if this is the last row in this section
                    if ($row.next('tr').hasClass('section-seperator')) {
                        var $newRow = $row.clone(true).insertAfter($row);

                        $('input', $row).focus();
                    }
                }
                updateCountrySpecificCfg($row.data('for'));
            });
        });

        var $textbox = $('input.country_specific_cfg', $form);
        $textbox.change(function () {
            var $row = $(this).parent().parent().eq(0);
            updateCountrySpecificCfg($row.data('for'));
        });

        function updateCountrySpecificCfg(fieldName) {
            var $rows = $('tr[data-for="' + fieldName + '"]', $form);
            var data = {};
            $rows.each(function (i, el) {
                var $select = $('select', el);
                var $input = $('input', el);
                if ($select.val() != '' && $input.val() != '') {
                    data[$select.val()] = $input.val();
                }
            });
            $('input[name="' + fieldName + '"]').val(JSON.stringify(data));
        }

        var $hiddens = $('input.country_specific_cfg_hidden', $form);
        $hiddens.each(function (i, el) {
            var $hidden = $(el);
            if ($hidden.val().length > 0) {
                var $row = $('tr[data-for="' + $hidden.prop('name') + '"]', $form);
                var data = JSON.parse($hidden.val());
                if (data != null) {
                    for (var country in data) {
                        var $newRow = $row.clone(true).insertBefore($row);
                        $('select', $newRow).val(country);
                        $('input', $newRow).val(data[country]);
                    }
                }
            }
        });

    });
</script>

    </form>
    

</div>

