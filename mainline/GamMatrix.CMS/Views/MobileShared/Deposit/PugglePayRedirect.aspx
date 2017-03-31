<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
    <div class="UserBox DepositBox CenterBox">
	    <div class="BoxContent"><!-- 1. Element where the form is inserted. -->
            <div id="pugglepay-authorize" class="CenterBox"></div>

            <!-- 2. PugglePay JavaScript. -->
            <script src="<%=this.Model.RequestFields["pugglepay_api_url"] %>"></script>

            <!-- 3. Define callback and call authorize. -->
            <script type="text/javascript">
                function redirectToReceipt() {
                    var success = false;
                    var url = '<%= this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = this.ViewData["PaymentMethodName"], @sid = this.Model.Record.Sid }).SafeJavascriptStringEncode() %>';
                    try { if (self.opener !== null && self.opener.redirectToReceiptPage(url)) { success = true; } } catch (e) { }
                    if (!success)
                        try { if (self.parent !== null && self.parent != self && self.parent.redirectToReceiptPage(url)) { success = true; } } catch (e) { }
                }

                var onSuccess = function () {
                    $('#formSuccess').submit();
                    return;

                    var options = {
                        dataType: "json",
                        type: 'POST',
                        success: function (json) {
                            redirectToReceipt();
                        },
                        error: function (xhr, textStatus, errorThrown) {
                            //showDepositError(errorThrown);
                            redirectToReceipt();
                        }
                    };
                    $('#formSuccess').ajaxForm(options);
                    $('#formSuccess').submit();
                };
                PugglePay.authorize("<%=this.Model.RequestFields["authorization_id"]%>", onSuccess);
            </script>

            <!-- 4. Form used for posting on authorization success. -->
            <form id="formSuccess" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "PugglePayPostback", @paymentMethodName = this.ViewData["PaymentMethodName"], @sid = this.Model.Record.Sid, @authorizationID = this.Model.RequestFields["authorization_id"] }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
                
            </form>
        </div>
    </div>
</asp:content>

