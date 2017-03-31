<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        scriptCashRewards.Visible = Profile.IsAuthenticated;
        base.OnPreRender(e);
    }

    private string GetAboutLink()
    {
        return this.ViewData["AboutUrl"] as string;
    }
</script>

<div class="Box CashRewards">
	<h2 class="BoxTitle CashRewardsTitle">
		<span class="TitleIcon">&sect;</span>
		<strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %></strong>
	</h2>

    <div class="InputContainer">
	    <label class="hidden" for="cashNumber"></label>
	    <input type="text" id="txtCasinoFPP" value="0" class="cashNumber" readonly="readonly" />
	    <button type="button" id="btnRefreshCasinoFPP" name="calculate" class="Button" disabled="disabled">
		    <span class="ir">Refresh</span>
	    </button>
    </div>
    <div class="InputLowerContainer">
	    <button type="button" id="btnClaimCasinoFPP" name="claim" class="Button Inactive ButtonClaim" disabled="disabled">
		    <%= this.GetMetadata(".Button_Claim").SafeHtmlEncode() %>
	    </button>
    </div>

    <% if (GetAboutLink() != null)
       { %>

    <a target="_blank" href="<%= GetAboutLink().SafeHtmlEncode() %>" class="InfoLink" title="<%= this.GetMetadata(".Link_About_Title").SafeHtmlEncode() %>">
        <span class="InfoIcon">?</span>
        <%= this.GetMetadata(".Link_About").SafeHtmlEncode()%>
    </a>

    <% } %>

</div>



<ui:MinifiedJavascriptControl ID="scriptCashRewards" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    $(function () {
        $('#btnClaimCasinoFPP').attr('disabled', false);
        $('#btnRefreshCasinoFPP').attr('disabled', false);

        var _points = 0;
        var _convertionMinClaimPoints = 0;
        var _convertionCurrency, _convertionPoints, _convertionAmount, _convertionType;
        $('#btnRefreshCasinoFPP').click(function (e) {
            e.preventDefault();
            $('#txtCasinoFPP').val('<%=this.GetMetadata(".Loading").SafeJavascriptStringEncode() %>');
            var url = '/Casino/Lobby/GetFrequentPlayerPoints';
            $.getJSON(url, function (json) {
                if (json.success) {
                    _points = json.points;
                    _convertionMinClaimPoints = json.convertionMinClaimPoints;
                    _convertionCurrency = json.convertionCurrency;
                    _convertionPoints = json.convertionPoints;
                    _convertionAmount = json.convertionAmount;
                    _convertionType = json.convertionType;
                    $('#txtCasinoFPP').val(json.points);
                    if (_points > 0.00)
                        $('#btnClaimCasinoFPP').attr('disabled', false).removeClass('Inactive');
                    else
                        $('#btnClaimCasinoFPP').attr('disabled', true).addClass('Inactive');
                }
                else {
                    $('#txtCasinoFPP').val('N / A');
                }
            });
        }).trigger('click');

        $('#btnClaimCasinoFPP').click(function (e) {
            e.preventDefault();
            if (_points > 0) {
                if (_points < _convertionMinClaimPoints) {
                    var msg = '<%= this.GetMetadata(".Points_Not_Enough").SafeJavascriptStringEncode() %>';
                    msg = msg.replace(/(\x7B\x30\x7D)/mg, _points.toString(10));
                    msg = msg.replace(/(\x7B\x31\x7D)/mg, _convertionMinClaimPoints.toString(10));
                    alert(msg);
                }
                else {
                    var msg = '<%= this.GetMetadata(".Claim_Confirmation").SafeJavascriptStringEncode() %>';
                    msg = msg.replace(/(\x7B\x30\x7D)/mg, _points.toString(10));
                    msg = msg.replace(/(\x7B\x31\x7D)/mg, _convertionMinClaimPoints.toString(10));
                    msg = msg.replace(/(\x7B\x32\x7D)/mg, _convertionPoints.toString(10));
                    msg = msg.replace(/(\x7B\x33\x7D)/mg, _convertionCurrency.toString(10));
                    msg = msg.replace(/(\x7B\x34\x7D)/mg, _convertionAmount.toString(10));
                    if (window.confirm(msg) == true) {
                        $(this).attr('disabled', true);
                        $('#txtCasinoFPP').val('<%=this.GetMetadata(".Claiming").SafeJavascriptStringEncode() %>');
                        var url = '/Casino/Lobby/ClaimFrequentPlayerPoints';
                        $.getJSON(url, function (json) {
                            $('#btnClaimCasinoFPP').attr('disabled', false);
                            if (!json.success) {
                                $('#txtCasinoFPP').val('N / A');
                                alert(json.error);
                                return;
                            }
                            _points = json.remainder;
                            _convertionMinClaimPoints = json.convertionMinClaimPoints;
                            _convertionCurrency = json.convertionCurrency;
                            _convertionPoints = json.convertionPoints;
                            _convertionAmount = json.convertionAmount;
                            _convertionType = json.convertionType;

                            $('#btnRefreshCasinoFPP').trigger('click');
                            var msg = '<%= this.GetMetadata(".Claim_Done").SafeJavascriptStringEncode() %>';
                            msg = msg.replace(/(\x7B\x30\x7D)/mg, json.converted.toString(10));
                            msg = msg.replace(/(\x7B\x31\x7D)/mg, json.rewardCurrency);
                            msg = msg.replace(/(\x7B\x32\x7D)/mg, json.rewardAmount);
                            msg = msg.replace(/(\x7B\x33\x7D)/mg, json.remainder);
                            alert(msg);

                            $(window).load(function () {
                                $(document).trigger("BALANCE_UPDATED");
                            });
                        });
                    }
                }
            }
        });
    });
</script>
</ui:MinifiedJavascriptControl>