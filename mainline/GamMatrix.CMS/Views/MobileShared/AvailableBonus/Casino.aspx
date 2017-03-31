<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.BonusData>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script language="C#" type="text/C#" runat="server">
    private bool HasCasinoWallet { get; set; }
    protected override void OnInit(EventArgs e)
    {
        try
        {
            HasCasinoWallet = GamMatrixClient.GetUserGammingAccounts(Profile.UserID).Exists(a => a.Record.ActiveStatus == ActiveStatus.Active && a.Record.VendorID == VendorID.CasinoWallet);
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
        }
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox BonusContainnerBox">
<h2 class="SubHeader"><a href="#" class="SHToggle ToggleButton"> <span class="ToggleArrow">−</span> <span class="SHText"><%=this.GetMetadata(".Casino_Bonus").SafeHtmlEncode()%></span> </a></h2>
<div class="BoxContent ToggleContent">

<% 
    List<BonusData> bonuses = this.Model;
    if (bonuses.Count == 0)
    {
        %>
   <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".No_Bonus")) { IsHtml = true });%>

        <%
    }
    else
    {
        foreach (BonusData bonus in bonuses)
        {%>
	<div class="MenuList L DetailContainer">
		<ol class="DetailPairs ProfileList">
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_Type").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Type.SafeHtmlEncode()%></span>
				</div>
			</li>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_ID").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.BonusID.SafeHtmlEncode()%></span>
				</div>
			</li>
			<%if (!string.IsNullOrWhiteSpace(bonus.Name))
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_Name").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Name.SafeHtmlEncode()%></span>
				</div>
			</li>
			<% } %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_Amount").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.Currency, bonus.Amount).SafeHtmlEncode()%></span>
				</div>
			</li>
			<% if (!string.IsNullOrWhiteSpace(bonus.WagerRequirementCurrency) )
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Wager_Requirement").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.WagerRequirementCurrency, bonus.WagerRequirementAmount).SafeHtmlEncode()%></span>
				</div>
			</li>
			<% } %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Remaining_Wagering").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0} {1:N2}", bonus.RemainingWagerRequirementCurrency, bonus.RemainingWagerRequirementAmount).SafeHtmlEncode()%></span>
				</div>
			</li>
			<%if (bonus.Created.HasValue)
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_Granted_Date").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0:dd/MM/yyyy}", bonus.Created.Value).SafeHtmlEncode()%></span>
				</div>
			</li>
			<%} %>
			<%if (bonus.ExpiryDate.HasValue)
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Expiry_Date").SafeHtmlEncode()%></span> <span class="DetailValue"><%= string.Format("{0:dd/MM/yyyy}", bonus.ExpiryDate.Value).SafeHtmlEncode()%></span>
				</div>
			</li>
			<% } %>
			<%if (!string.IsNullOrWhiteSpace(bonus.Status))
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_Status").SafeHtmlEncode()%></span> <span class="DetailValue"><%= bonus.Status.SafeHtmlEncode()%></span>
				</div>
			</li>
			<% } %>
			<%if (!string.IsNullOrEmpty(bonus.Url))
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Bonus_Url").SafeHtmlEncode()%></span> <span class="DetailValue"><a target='_blank' href='<%= bonus.Url.SafeHtmlEncode()%>'><%= this.GetMetadata(".Bonus_TC").SafeHtmlEncode()%></a></span>
				</div>
			</li>
			<% } %>
			<%if (bonus.ConfiscateAllFundsOnExpiration.HasValue)
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Confiscate_All_Funds_On_Expiration").SafeHtmlEncode()%></span> <span class="DetailValue"><%= (bonus.ConfiscateAllFundsOnExpiration.Value ? this.GetMetadata(".YES") : this.GetMetadata(".NO")).SafeHtmlEncode()%></span>
				</div>
			</li>
			<% } %>
			<%if (bonus.ConfiscateAllFundsOnForfeiture.HasValue)
			{ %>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".Confiscate_All_Funds_On_Forfeiture").SafeHtmlEncode()%></span> <span class="DetailValue"><%= (bonus.ConfiscateAllFundsOnForfeiture.Value ? this.GetMetadata(".YES") : this.GetMetadata(".NO")).SafeHtmlEncode()%></span>
				</div>
			</li>
			<% } %>
		</ol>
	</div>

        <%if (bonus.VendorID == VendorID.CasinoWallet && bonus.ConfiscateAllFundsOnForfeiture.HasValue)
          { %>
            <% using( Html.BeginRouteForm( "AvailableBonus", new { @action="ForfeitCasinoBonus"},FormMethod.Post, new { @id="formForfeitCasinoBonus" + bonus.ID }) )
                { %>
            
            <%: Html.Hidden( "bonusID", bonus.ID) %>     
			<button id="btnForfeitCasinoBonus<%=bonus.ID %>" class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Forfeit").SafeHtmlEncode()%></strong>
			</button> 
            <% } %>
            <script type="text/javascript">
                $(function () {
                    $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click( function(e){
                        e.preventDefault();
                        var confiscateAll = <%= bonus.ConfiscateAllFundsOnForfeiture.Value.ToString().ToLowerInvariant() %>;
                        var ret = false;
                        if( confiscateAll )
                            ret = window.confirm( '<%= this.GetMetadata(".Confiscate_All_Warning").SafeJavascriptStringEncode() %>' );
                        else
                            ret = window.confirm( '<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>' );

                        if(ret){
                            $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').attr("disabled","disabled");
                            var options = {
                                dataType: "json",
                                type: 'POST',
                                url: $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').attr('action'),
                                data: {__RequestVerificationToken: $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %> input[name=__RequestVerificationToken]').val(),
                                    "bonusID":$('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').find("#bonusID").val()},
                                success: function (json) {
                                    $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
                                    if( !json.success ){
                                        alert(json.error);
                                    }else{
                                        self.location = self.location.toString().replace(/(\#.*)$/, '');
                                    }
                                },
                                error: function (xhr, textStatus, errorThrown) {
                                    $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
                                }
                            };
                            $.ajax(options);
                        }
                    });
                });
            </script>
        <% } %>

        <%-- Forfeit Classic NetEnt Bonus --%>
        <%if (bonus.VendorID == VendorID.NetEnt )
          { %>
            <% using (Html.BeginRouteForm("AvailableBonus", new { @action = "ForfeitNetEntBonus" }, FormMethod.Post, new { @id = "formForfeitNetEntBonus" + bonus.ID }))
                { %>
            
            <%: Html.Hidden( "bonusID", bonus.ID) %>                
			<button id="btnForfeitNetEntBonus<%= bonus.ID%>" class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Forfeit").SafeHtmlEncode()%></strong>
			</button>
            <% } %>

            <script type="text/javascript">
                $(function () {
                    $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click(function (e) {
                        e.preventDefault();
                        var ret = window.confirm('<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>');

                        if (ret) {
                            $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').attr("disabled", "disabled");
                            var options = {
                                dataType: "json",
                                type: 'POST',
                                url: $('#formForfeitNetEntBonus<%=bonus.ID.SafeJavascriptStringEncode() %>').attr('action'),
                                data: { __RequestVerificationToken: $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %> input[name=__RequestVerificationToken]').val(),
                                    "bonusID": $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').find("#bonusID").val() },
                                success: function (json) {
                                    $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
                                    if (!json.success) {
                                        alert(json.error);
                                    } else {
                                        self.location = self.location.toString().replace(/(\#.*)$/, '');
                                    }
                                },
                                error: function (xhr, textStatus, errorThrown) {
                                    $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').removeAttr("disabled");
                                }
                            };
                            $.ajax(options);
                        }
                    });

                });
            </script>
        <% } %>
	<%}
  
    } %>


    <%------------------------------------
    CasinoWallet - Bonus
 ------------------------------------%>
<%
    var gammingAccounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID);
    if( gammingAccounts.Exists( a => a.Record.VendorID == VendorID.CasinoWallet ) )
    {
        
        // Apply bonus code
        using( Html.BeginRouteForm( "AvailableBonus", new { @action = "ApplyCasinoBonusCode" }, FormMethod.Post, new { @id = "formApplyCasinoBonusCode" }) )
        {  %>
            
            <hr />
            <%: Html.H5( this.GetMetadata(".Enter_Bonus_Code") )  %>

            <ul class="FormList">
            <li class="FormItem" id="fldFirstName" runat="server">
				<label class="FormLabel" for="bonusCode"><%= this.GetMetadata(".Bonus_Code").SafeHtmlEncode()%></label>
                <%: Html.TextBox("bonusCode", "", new Dictionary<string, object>()  
                { 
                    { "class", "FormInput" },
                    { "id", "bonusCode" },
                    { "maxlength", "50" },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Bonus_Code_Empty")) }
                }) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
            </ul>
            <button id="btnApplyCasinoBonus" class="Button AccountButton" type="submit">
				<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit").SafeHtmlEncode()%></strong>
			</button>
            
            <script type="text/javascript">
                $(function () {
                    $('#formApplyCasinoBonusCode').initializeForm();

                    $('#btnApplyCasinoBonus').click(function (e) {
                        e.preventDefault();

                        if (!$('#formApplyCasinoBonusCode').valid())
                            return;
                        $('#btnApplyCasinoBonus').attr("disabled", "disabled");
                        var options = {
                            dataType: "json",
                            type: 'POST',
                            url: $('#formApplyCasinoBonusCode').attr('action'),
                            data: {  __RequestVerificationToken: $('#formApplyCasinoBonusCode input[name=__RequestVerificationToken]').val(),
                                "bonusCode": $("#bonusCode").val() },
                            success: function (json) {
                                $('#btnApplyCasinoBonus').removeAttr("disabled");
                                if (!json.success) {
                                    alert(json.error);
                                    return;
                                }
                                alert('<%= this.GetMetadata(".Bonus_Code_Applied").SafeJavascriptStringEncode() %>');
                                self.location = self.location.toString().replace(/(\#.*)$/, '');
                            },
                            error: function (xhr, textStatus, errorThrown) {
                                $('#btnApplyCasinoBonus').removeAttr("disabled");
                            }
                        };
                        $.ajax(options);
                    });
                });
            </script>

<%      } // using end
   } // if end%>
</div>
</div>

<%if (HasCasinoWallet && false) { %><%-- Claiming FPP not available for mobile --%>
<div class="UserBox BonusContainnerBox" id="CasinoFppContainer">
<h2 class="SubHeader"><a href="#" class="SHToggle ToggleButton"> <span class="ToggleArrow">−</span> <span class="SHText"><%=this.GetMetadata(".CasinoWallet_FPP").SafeHtmlEncode()%></span> </a></h2>
<div class="BoxContent ToggleContent">
<%------------------------------------
    Casino - FPP
 ------------------------------------%>

<br />
   <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Casino_FPP_Notes"))
	  { 
		  IsHtml = true,
		  ComponentId = "casinoFppInformation"
	  }); %>
   <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, string.Empty)
	  { 
		  IsHtml = true,
		  ComponentId = "casinoFppNote" 
	  }); %>

        <ul class="FormList">
        <li class="FormItem" runat="server">
			<label class="FormLabel" for="fppMinClaimPoints"><%= this.GetMetadata(".Casino_FPP_Min_Claim_Points").SafeHtmlEncode()%></label>
            <%: Html.TextBox("fppMinClaimPoints", "", new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "fppMinClaimPoints" },
                { "readonly", "readonly" }
            }) %>
			<span class="FormStatus">Status</span>
			<span class="FormHelp"></span>
		</li>

        <li class="FormItem" runat="server">
			<label class="FormLabel" for="fldCasinoFPPPoints"><%= this.GetMetadata(".Casino_FPP_Points").SafeHtmlEncode()%></label>
            <%: Html.TextBox("fldCasinoFPPPoints", "", new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "fldCasinoFPPPoints" },
                { "readonly", "readonly" }
            }) %>
			<span class="FormStatus">Status</span>
			<span class="FormHelp"></span>
		</li>        
        </ul>

			<button id="btnClaimCasinoFPP" class="Button AccountButton" type="button">
				<strong class="ButtonText"><%= this.GetMetadata(".Button_Claim").SafeHtmlEncode()%></strong>
			</button>        



<script type="text/javascript">
    var _points = 0;
    var _convertionMinClaimPoints = 0;
    var _convertionCurrency, _convertionPoints, _convertionAmount, _convertionType;

    function initFppData() {
        $('#fppMinClaimPoints').val('<%=this.GetMetadata(".Loading").SafeJavascriptStringEncode() %>');
        $('#fldCasinoFPPPoints').val('<%=this.GetMetadata(".Loading").SafeJavascriptStringEncode() %>');

        var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "GetFrequentPlayerPoints" }).SafeJavascriptStringEncode() %>?_t='+new Date().getTime();
        $.getJSON(url, function (json) {
            if (json.success) {
                $("#CasinoFppContainer").show();
                _points = json.points;
                _convertionMinClaimPoints = json.convertionMinClaimPoints;
                _convertionCurrency = json.convertionCurrency;
                _convertionPoints = json.convertionPoints;
                _convertionAmount = json.convertionAmount;
                _convertionType = json.convertionType;

                var informationHtml = $("#casinoFppInformation").find(".StatusMessage").html();
                informationHtml = informationHtml.replace(/\{0\}/ig, _convertionPoints.toString(10));
                informationHtml = informationHtml.replace(/\{1\}/ig, _convertionCurrency.toString(10));
                informationHtml = informationHtml.replace(/\{2\}/ig, _convertionAmount.toString(10));
                $("#casinoFppInformation").find(".StatusMessage").html(informationHtml);

                bindFppData();
            }
            else {
                $("#CasinoFppContainer").hide();
                $('#fppMinClaimPoints').val(0);
                $('#fldCasinoFPPPoints').val(0);
            }
        });
    }

    function bindFppData() {                
        $('#fppMinClaimPoints').val(_convertionMinClaimPoints);
        $('#fldCasinoFPPPoints').val(_points);
        if (_points > _convertionMinClaimPoints)
            $('#btnClaimCasinoFPP').attr('disabled', false).removeClass('Inactive');
        else
            $('#btnClaimCasinoFPP').attr('disabled', true).addClass('Inactive');
    }

    $(function () {
        $('#btnClaimCasinoFPP').attr('disabled', false);
        $("#casinoFppNote").hide();

        initFppData();

        $('#btnClaimCasinoFPP').click(function (e) {
            e.preventDefault();
            if (_points > 0) {
                if (_points < _convertionMinClaimPoints) {
                    var msg = '<%= this.GetMetadata(".Points_Not_Enough").SafeJavascriptStringEncode() %>';
                    msg = msg.replace(/(\x7B\x30\x7D)/mg, _points.toString(10));
                    msg = msg.replace(/(\x7B\x31\x7D)/mg, _convertionMinClaimPoints.toString(10));
                    //alert(msg);
                    $("#casinoFppNote").removeClass("SucessStatus").addClass("ErrorStatus").show();
                    $("#casinoFppNote").find(".StatusMessage").html(msg);
                }
                else {
                    $(this).attr('disabled', true);
                    $('#fppMinClaimPoints').val('<%=this.GetMetadata(".Claiming").SafeJavascriptStringEncode() %>');
                    $('#fldCasinoFPPPoints').val('<%=this.GetMetadata(".Claiming").SafeJavascriptStringEncode() %>');

                    var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "ClaimFrequentPlayerPoints" }).SafeJavascriptStringEncode() %>?_t=' + new Date().getTime();
                    $.getJSON(url, function (json) {
                        $('#btnClaimCasinoFPP').attr('disabled', false);
                        if (!json.success) {
                            bindFppData();
                            alert(json.error);
                            return;
                        }
                        _points = json.remainder;
                        _convertionMinClaimPoints = json.convertionMinClaimPoints;
                        _convertionCurrency = json.convertionCurrency;
                        _convertionPoints = json.convertionPoints;
                        _convertionAmount = json.convertionAmount;
                        _convertionType = json.convertionType;

                        bindFppData();

                        var msg = '<%= this.GetMetadata(".Claim_Done").SafeJavascriptStringEncode() %>';
                        msg = msg.replace(/(\x7B\x30\x7D)/mg, json.converted.toString(10));
                        msg = msg.replace(/(\x7B\x31\x7D)/mg, json.rewardCurrency);
                        msg = msg.replace(/(\x7B\x32\x7D)/mg, json.rewardAmount);
                        msg = msg.replace(/(\x7B\x33\x7D)/mg, json.remainder);
                        //alert(msg);
                        $("#casinoFppNote").removeClass("ErrorStatus").addClass("SucessStatus").show();
                        $("#casinoFppNote").find(".StatusMessage").html(msg);
                    });
                }
            }
        });
    });
</script>


</div>
</div>
<%} %>

<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
    CMS.mobile360.views.ToggleContent.createFor('.BonusContainnerBox');
</script>

</asp:Content>

