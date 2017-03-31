<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<CE.db.ceLiveCasinoTableBaseEx>" %>

<script language="C#" type="text/C#" runat="server">
    private List<SelectListItem> GetLiveCasinoVendors()
    {
        List<SelectListItem> list = GlobalConstant.AllLiveCasinoVendors.Select(v => new SelectListItem()
        {
            Text = v.ToString(),
            Value = v.ToString()
        }
        ).OrderBy(x => x.Text).ToList();
        
        list.Insert(0, new SelectListItem() { Text = "-- Selector Vendor --", Value = string.Empty, Selected = true });
        
        return list;
    }
</script>

<style type="text/css">
#table-editor-tabs .LeftColumn { width:49%; float:left; }
#table-editor-tabs .RightColumn { width:49%; float:left; }
#table-editor-tabs .Clear { clear:both; }
#table-editor-tabs .ui-tabs-panel { height: 430px; overflow: hidden; }
#vendor-wizards { height:355px; position:relative; }
</style>

<form enctype="multipart/form-data" action="#">


    <div id="table-editor-tabs">
        <ul>
            <li><a href="#tabs-1">Register New Live Casino Table</a></li>
        </ul>
        <div id="tabs-1">
                <p>
                    <label class="label">Vendor: </label>
            
                    <%: Html.DropDownListFor(m => m.VendorID, GetLiveCasinoVendors(), new { @class = "ddl", @id = "ddlLiveCasinoVendor" })%>
                </p>
                <p>
                    <div id="vendor-wizards">
                    </div>
                </p>


        </div>
    </div>


    <p align="right">
        <% if (DomainManager.CurrentDomainID != Constant.SystemDomainID )
       { %>
    <div class="ui-widget">
		<div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
			<p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
			<strong>NOTE!</strong> Editing the table attributes here will override the default settings for this operator.</p>
		</div>
	</div>
    <% } %>

    </p> 


</form>
<script type="text/javascript">
    $(function () {
        $('#table-editor-tabs').tabs();


        $('#ddlLiveCasinoVendor').change(function (e) {
            if ($(this).val() == '') {
                e.preventDefault();
                return;
            }

            $('#vendor-wizards').html('<img src="/images/loading.icon.gif" /> Loading...');
            var url = '<%= this.Url.ActionEx("VendorWizards").SafeJavascriptStringEncode() %>?vendorID=' + $(this).val();
            $('#vendor-wizards').load(url);
        });

    });
    
    
</script>