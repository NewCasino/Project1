<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>


<fieldset>
    <legend class="hidden">
		<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
	</legend>
    <ul class="FormList">
        <%------------------------------------------
            MinClaimPoints
            -------------------------------------------%>
	    <li class="FormItem" id="fldMinClaimPoints" runat="server">
		    <label class="FormLabel" for="minClaimPoints"><%= this.GetMetadata(".MinClaimPoints_Label").SafeHtmlEncode()%></label>
            <%: Html.TextBox("minClaimPoints", "99999", new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "txtMinClaimPoints" },
                { "readonly", "readonly" },                    
            }) %>
		    <span class="FormStatus">Status</span>
		    <span class="FormHelp"></span>
	    </li>

        <%------------------------------------------
            Points
            -------------------------------------------%>
	    <li class="FormItem" id="fldPoints" runat="server">
		    <label class="FormLabel" for="points"><%= this.GetMetadata(".Points_Label").SafeHtmlEncode()%></label>
            <%: Html.TextBox("points", null, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "txtCasinoFPP" },
                { "readonly", "readonly" },                    
            }) %>
		    <span class="FormStatus">Status</span>
		    <span class="FormHelp"></span>
	    </li>

        <div class="AccountButtonContainer">
			<button class="Button AccountButton" type="button" id="btnClaimCasinoFPP">
				<strong class="ButtonText"><%= this.GetMetadata(".Button_Claim").SafeHtmlEncode()%></strong>
			</button>
		</div>


        <a target="_blank" href="/Casino/FPP/LearnMore" class="InfoLink" title="<%= this.GetMetadata(".Link_About_Title").SafeHtmlEncode() %>">
            <span class="InfoIcon">?</span>
            <%= this.GetMetadata(".Link_About").SafeHtmlEncode()%>
        </a>

    </ul>
</fieldset>

<script type="text/javascript">
    $(function () {
        var _points = 0;
        var _convertionMinClaimPoints = 0;
        var _convertionCurrency, _convertionPoints, _convertionAmount, _convertionType;

        function RefreshCasinoFPP()
        {
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
                    $('#txtMinClaimPoints').val(json.convertionMinClaimPoints);
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
        }

        function ClaimCasinoFPP()
        {
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
                        });
                    }
                }
            }
        }

        RefreshCasinoFPP();

        $('#btnClaimCasinoFPP').click(function (e) {
            e.preventDefault();

            ClaimCasinoFPP();
        });
    });
</script>
