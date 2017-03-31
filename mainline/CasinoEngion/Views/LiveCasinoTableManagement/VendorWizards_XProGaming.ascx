<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private List<SelectListItem> Items { get; set; }
    private Dictionary<string, CurrencyExchangeRateRec> Currencies { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        using (GamMatrixClient client = new GamMatrixClient())
        {
            Currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
        }
        
        var p = new Dictionary<string,object>()
        {
            { "VendorID" , new VendorID[] { VendorID.XProGaming } },
        };
        
        
        int total = 0;
        var games = CasinoGameAccessor.SearchGames(1, 9999, Constant.SystemDomainID, p, out total, false, false);

        this.Items = games.Select(g => new SelectListItem() { Value = g.ID.ToString(), Text = string.Format("{0} - {1} [{2}]", g.ID, g.GameName, g.GameCode) }).ToList();
    }

    
</script>


<style type="text/css">
#dlgTableRegistration .ui-widget-content { overflow:auto; }
ul.table-list { list-style-type:none; margin:0px; padding:0px; }
ul.table-list li { display:inline-block; margin-right:15px; }
.currency-label { width:45px; display:inline-block; }
.currency-limit-set { width:50px; text-align:right; }
</style>

<p>
<label class="label">Game : </label>
<%: Html.DropDownList("gameID", this.Items, new { @class = "ddl", @id = "ddlXProGameID"}) %>
</p>

<p>
    <label class="label">Default limit Set ID : </label>
    <%: Html.TextBox("extraParameter1", string.Empty, new { @id = "txtXProExtraParam1" })%>
</p>

<p>
    <label class="label">Limit Set ID Per Currency : </label>
    <ul class="table-list" id="currency-limit-sets">
        <% foreach( var currency in Currencies )
           { %>
        <li>
            <label><span class="currency-label"><%= currency.Key %> = </span>
            <%: Html.TextBox(currency.Key, string.Empty, new { @class = "currency-limit-set", @maxlength = 5 })%>
            </label>
        </li>
        <% } %>
    </ul>
    <%: Html.Hidden("extraParameter2", string.Empty, new { @id = "txtXProExtraParam2" })%>
</p>

<p style="text-align:right">
<button id="btnRegXProGaming">Submit</button>
</p>



<script type="text/javascript">

    $(function () {
        $('input.currency-limit-set').each(function (i, el) {
            $(el).keypress(function (evt) {
                var allowed = true;
                var code = evt.which || evt.keyCode;
                if (code >= 48 && code <= 57) {
                    return;
                }
                else if (code == 0 || code == 8) {
                    return;
                }
                else
                    evt.preventDefault();
            });
            $(el).change(function (evt) {
                var text = $(this).val();
                if (text != null && text.toString().length > 0) {
                    var num = parseInt(text, 10);
                    if (num > 0)
                        $(this).val(num.toString(10));
                    else
                        $(this).val('');
                }
                updateXProExtraParam2();
            });
        });

        function updateXProExtraParam2() {
            var json = {};
            var $textboxes = $('#currency-limit-sets .currency-limit-set');
            $textboxes.each(function (i, el) {
                var limitSetID = $(el).val();
                if (limitSetID != null && limitSetID.length > 0) {
                    json[$(el).prop('name')] = limitSetID;
                }
            });

            $('#txtXProExtraParam2').val(JSON.stringify(json));
        }

        $('#btnRegXProGaming').button().click(function (e) {
            e.preventDefault();

            var p = { gameID: $('#ddlXProGameID').val(), extraParameter1: $('#txtXProExtraParam1').val(), extraParameter2: $('#txtXProExtraParam2').val() };
            if (p.extraParameter1 == null || p.extraParameter1 == '') {
                alert('Default limit set ID is missing!');
                return;
            }

            $('#loading').show();

            var url = '<%= this.Url.ActionEx("RegisterTable").SafeJavascriptStringEncode() %>';
            $.getJSON(url, p, function (json) {
                $('#loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                $('#txtXProExtraParam1').val('');
                $('#currency-limit-sets .currency-limit-set').val('');
                alert('Table is registered successfully.');
            });
        });
    });

</script>