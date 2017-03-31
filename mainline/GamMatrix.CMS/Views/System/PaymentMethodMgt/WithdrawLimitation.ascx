<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Dictionary< string, Range>>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>




<div class="ui-widget">
	<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all"> 
		<p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-info"></span>
		The textboxes below can be left empty if no limitation;
        If the limitation is only given in <strong>EUR</strong>, the missing limitations of other currencies will be converted from <strong>EUR</strong> limitation.
        </p>
	</div>
</div>
<br />
<%
    using( Html.BeginRouteForm( "PaymentMethodMgt", new 
   { @action="SaveWithdrawLimitation",
     @paymentMethodName = (this.ViewData["paymentMethod"] as PaymentMethod).UniqueName,
     @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt()
   }, FormMethod.Post, new { @id = "formSaveWithdrawLimitation" }))
   { %>

<ui:Fieldset runat="server" Legend="Withdraw Limitation">
    <table border="0" cellspacing="0" cellpadding="0" width="100%">
    <% var list = GmCore.GamMatrixClient.GetSupportedCurrencies();
        foreach( var item in list)
        {
            Range range;
            this.Model.TryGetValue(item.ISO4217_Alpha, out range);
            %>

                <tr>
                    <td><%= item.ISO4217_Alpha.SafeHtmlEncode() %>(<%= item.Name.SafeHtmlEncode() %>)</td>
            	    <td><%: Html.TextBox(string.Format("withdrawLimitMin_{0}", item.ISO4217_Alpha)
                     , (range != null && range.MinAmount > 0.00M) ? range.MinAmount.ToString("N2") : string.Empty
                     , new { @maxlength = 10, @class = "textbox" }
                     )%></td>
                     <td>
                     &lt;= x &lt;=
                     </td>
                     <td>
                     <%: Html.TextBox( string.Format("withdrawLimitMax_{0}", item.ISO4217_Alpha)
                     , (range != null && range.MaxAmount > 0.00M) ? range.MaxAmount.ToString("N2") : string.Empty
                     , new { @maxlength = 10, @class = "textbox" }
                     )%>
                     </td>
                </tr>
            
    <%   }%>
    </table>
</ui:Fieldset>

<div class="button-contaner">
<%: Html.Button("Save", new { @id = "btnSaveWithdrawLimitation", @type = "submit" })%>
</div>

<% } %>

<script type="text/javascript">
    $('#formSaveWithdrawLimitation').initializeForm();

    $('#btnSaveWithdrawLimitation').click( function (e) {
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
        $('#formSaveWithdrawLimitation').ajaxForm(options);
        $('#formSaveWithdrawLimitation').submit();
    });
</script>