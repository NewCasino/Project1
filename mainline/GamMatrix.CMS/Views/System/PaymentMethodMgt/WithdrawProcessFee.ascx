<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<%
    PaymentMethod paymentMethod = this.ViewData["paymentMethod"] as PaymentMethod;
    using( Html.BeginRouteForm( "PaymentMethodMgt", new 
   { @action="SaveWithdrawProcessFee",
     @paymentMethodName = paymentMethod.UniqueName,
     @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt()
   }, FormMethod.Post, new { @id = "formWithdrawSaveProcessFee" }))
   { %>

<ul id="process-fee-type" style="list-style-type:none; padding:0px;">
   <li><input type="radio" name="processFeeType" value="Free" id="btnFree"/>
       <label for="btnFree">Free</label> </li>
   <li><input type="radio" name="processFeeType" value="Percent" id="btnPercent" />
        <label for="btnPercent">Percent</label></li>
   <li><input type="radio" name="processFeeType" value="Fixed" id="btnFixed" />
        <label for="btnFixed">Fixed</label></li>
   <li><input type="radio" name="processFeeType" value="Bank" id="btnBank" />
        <label for="btnBank">Bank withdraw</label></li>
</ul>

<ui:InputField ID="fldPercent" runat="server" Style="display:none">
    <LabelPart>
        Percent:
    </LabelPart>
    <ControlPart>
        <table cellpadding="0" cellspacing="0" border="0">
            <tr>
                <td><%: Html.TextBox("percentage", (this.ViewData["paymentMethod"] as PaymentMethod).DepositProcessFee.Percentage, new { @style = "text-align:right" })%></td>
                <td>%</td>
            </tr>
        </table>
    </ControlPart>
</ui:InputField>

<ui:InputField ID="fldFixed" runat="server" Style="display:none">
    <ControlPart>
        <table cellpadding="0" border="0" cellspacing="1" style="font-size:11px">
        <% var list = GmCore.GamMatrixClient.GetSupportedCurrencies();
            foreach( var item in list)
            {
                var fees =  (this.ViewData["paymentMethod"] as PaymentMethod).WithdrawProcessFee.Currency2FixedFee; %>
                <tr>
                    <td><nobr><%= item.Name.SafeHtmlEncode() %></nobr></td>
                    <td>:</td>
                    <td>
                        <%: Html.TextBox("fixed_" + item.ISO4217_Alpha
                        , fees.ContainsKey(item.ISO4217_Alpha) ? fees[item.ISO4217_Alpha].ToString() : string.Empty
                        , new { @style = "text-align:right" })%> 
                    </td>
                    <td>
                        <%= item.ISO4217_Alpha %>
                    </td>
                </tr>

        <% } %>
        </table>
    </ControlPart>
</ui:InputField>

<ui:InputField ID="fldBank" runat="server">
    <ControlPart>
        <table cellpadding="0" border="0" cellspacing="1" style="font-size:11px">
        <% var list = GmCore.GamMatrixClient.GetSupportedCurrencies();
            foreach( var item in list)
            {
                var fees = (this.ViewData["paymentMethod"] as PaymentMethod).WithdrawProcessFee.Currency2BankFee;
                KeyValuePair<decimal, decimal> fee;
                if (!fees.TryGetValue(item.ISO4217_Alpha, out fee))
                    fee = new KeyValuePair<decimal, decimal>(0, 0); %>
                <tr>
                    <td><nobr><%= item.Name.SafeHtmlEncode() %></nobr></td>
                    <td>&nbsp;</td>
                    <td><nobr>Local:</nobr></td>
                    <td>
                        <%: Html.TextBox("local_" + item.ISO4217_Alpha
                            , fee.Key.ToString() , new { @style="text-align:right" })%> 
                    </td>
                    <td>
                        <%= item.ISO4217_Alpha %>
                    </td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
                    <td><nobr>International:</nobr></td>
                    <td>
                        <%: Html.TextBox("international_" + item.ISO4217_Alpha
                            , fee.Value.ToString() , new { @style = "text-align:right" })%> 
                    </td>
                    <td>
                        <%= item.ISO4217_Alpha %>
                    </td>
                </tr>

        <% } %>
        </table>
    </ControlPart>
</ui:InputField>

<div class="button-contaner">
<%: Html.Button("Save", new { @id = "btnSaveProcessFee", @type = "submit" })%>
</div>
<% } %>

<script language="javascript" type="text/javascript">
    //$('#formWithdrawSaveProcessFee').initializeForm();
    function onTypeChanged() {
        var type = $('#process-fee-type input:checked').val();
        if (type == 'Percent') $('#fldPercent').show(); else $('#fldPercent').hide();
        if (type == 'Fixed') $('#fldFixed').show(); else $('#fldFixed').hide();
        if (type == 'Bank') $('#fldBank').show(); else $('#fldBank').hide();
    }
    $('#process-fee-type input').click(onTypeChanged);

    $('#process-fee-type input[value="<%= (this.ViewData["paymentMethod"] as PaymentMethod).WithdrawProcessFee.ProcessFeeType %>"]').attr('checked', true);
    onTypeChanged();

    $('#btnSaveProcessFee').click(function (e) {
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
        $('#formWithdrawSaveProcessFee').ajaxForm(options);
        $('#formWithdrawSaveProcessFee').submit();
    });
</script>