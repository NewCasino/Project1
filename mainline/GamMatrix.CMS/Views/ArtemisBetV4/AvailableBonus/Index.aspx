<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.GetUserBonusDetailsRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private NetEntFPPClaimRec NetEntFPPClaimRec { get; set; }

    protected override void OnInit(EventArgs e)
    {
        try
        {
            var account =  GamMatrixClient.GetUserGammingAccounts(Profile.UserID).FirstOrDefault( a => a.Record.VendorID == VendorID.NetEnt);
            if( account != null )
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    NetEntGetClaimFPPDetailsRequest request = new NetEntGetClaimFPPDetailsRequest()
                    {
                        AccountID = account.ID,
                    };
                    request = client.SingleRequest<NetEntGetClaimFPPDetailsRequest>(request);

                    NetEntFPPClaimRec = request.ClaimRec;
                }
            }
        }
        catch(Exception ex)
        {
            Logger.Exception(ex);
        }
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="available-bonus-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnAvailableBonus">

<ui:Fieldset runat="server" Legend="<%$ Metadata:value(.Casino_Bonus) %>">
<% 
    List<BonusData> bonuses = this.Model.Data.Where(b => b.VendorID == VendorID.NetEnt || b.VendorID == VendorID.CasinoWallet ).ToList();
    if (bonuses.Count == 0)
    {
        %>
        <%: Html.InformationMessage( this.GetMetadata(".No_Bonus") ) %>
        <%
    }
    else
    {
        foreach (BonusData bonus in bonuses)
        {%>


    <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">    
        <tr>
            <td class="name"><%= this.GetMetadata(".Bonus_Type").SafeHtmlEncode() %></td>
            <td class="value"><%= bonus.Type.SafeHtmlEncode() %></td>
        </tr>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bonus_Code").SafeHtmlEncode()%></td>
            <td class="value"><%= bonus.BonusID.SafeHtmlEncode()%></td>
        </tr>

        <%if ( !string.IsNullOrWhiteSpace(bonus.Name) ) 
          {%>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bonus_Name").SafeHtmlEncode()%></td>
            <td class="value"><%= bonus.Name.SafeHtmlEncode()%></td>
        </tr>
        <% } %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bonus_Amount").SafeHtmlEncode() %></td>
            <td class="value"><%= string.Format("{0} {1:N2}", bonus.Currency, bonus.Amount).SafeHtmlEncode()  %></td>
        </tr>

        <%if (!string.IsNullOrWhiteSpace(bonus.WagerRequirementCurrency) )
          { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Wager_Requirement").SafeHtmlEncode()%></td>
            <td class="value"><%= string.Format("{0} {1:N2}", bonus.WagerRequirementCurrency, bonus.WagerRequirementAmount).SafeHtmlEncode()  %></td>
        </tr>
        <% } %>

        <tr>
            <td class="name"><%= this.GetMetadata(".Remaining_Wagering").SafeHtmlEncode()%></td>
            <td class="value"><%= string.Format("{0} {1:N2}", bonus.RemainingWagerRequirementCurrency, bonus.RemainingWagerRequirementAmount).SafeHtmlEncode()  %></td>
        </tr>

        <%if (bonus.Created.HasValue)
          { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bonus_Granted_Date").SafeHtmlEncode()%></td>
            <td class="value"><%= string.Format("{0:dd/MM/yyyy}", bonus.Created.Value).SafeHtmlEncode()%></td>
        </tr>
        <% } %>

        <%if (bonus.ExpiryDate.HasValue)
          { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Expiry_Date").SafeHtmlEncode()%></td>
            <td class="value"><%= string.Format("{0:dd/MM/yyyy}", bonus.ExpiryDate.Value).SafeHtmlEncode()%></td>
        </tr>
        <% } %>

        <%if (!string.IsNullOrWhiteSpace(bonus.Status))
          { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bonus_Status").SafeHtmlEncode()%></td>
            <td class="value"><%= bonus.Status.SafeHtmlEncode() %></td>
        </tr>
        <% } %>

        <%if (bonus.ConfiscateAllFundsOnExpiration.HasValue)
          { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Confiscate_All_Funds_On_Expiration").SafeHtmlEncode()%></td>
            <td class="value"><%= (bonus.ConfiscateAllFundsOnExpiration.Value ? this.GetMetadata(".YES") : this.GetMetadata(".NO")).SafeHtmlEncode()%></td>
        </tr>
        <% } %>

        <%if (bonus.ConfiscateAllFundsOnForfeiture.HasValue)
          { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".Confiscate_All_Funds_On_Forfeiture").SafeHtmlEncode()%></td>
            <td class="value"><%= (bonus.ConfiscateAllFundsOnForfeiture.Value ? this.GetMetadata(".YES") : this.GetMetadata(".NO")).SafeHtmlEncode()%></td>
        </tr>
        <% } %>

        <%if (bonus.VendorID == VendorID.CasinoWallet && bonus.ConfiscateAllFundsOnForfeiture.HasValue)
          { %>
        <tr>
            <td class="name"></td>
            <td class="value">
                <% using( Html.BeginRouteForm( "AvailableBonus", new { @action="ForfeitCasinoBonus"},FormMethod.Post, new { @id="formForfeitCasinoBonus" + bonus.ID }) )
                   { %>
                
                <%: Html.Hidden( "bonusID", bonus.ID) %>
                <%: Html.Button( this.GetMetadata(".Forfeit"), new { @type = "submit", @id="btnForfeitCasinoBonus" + bonus.ID }) %>
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
                                $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(true);
                                var options = {
                                    dataType: "json",
                                    type: 'POST',
                                    success: function (json) {
                                        $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                        if( !json.success ){
                                            alert(json.error);
                                        }else{
                                            self.location = self.location.toString().replace(/(\#.*)$/, '');
                                        }
                                    },
                                    error: function (xhr, textStatus, errorThrown) {
                                        $('#btnForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                    }
                                };
                                $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').ajaxForm(options);
                                $('#formForfeitCasinoBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').submit();
                            }
                        });
                        

                    });
                </script>
            </td>
        </tr>
        <% } %>

        <%-- Forfeit Classic NetEnt Bonus --%>
        <%if (bonus.VendorID == VendorID.NetEnt )
          { %>
        <tr>
            <td class="name"></td>
            <td class="value">
                <% using (Html.BeginRouteForm("AvailableBonus", new { @action = "ForfeitNetEntBonus" }, FormMethod.Post, new { @id = "formForfeitNetEntBonus" + bonus.ID }))
                   { %>
                
                <%: Html.Hidden( "bonusID", bonus.ID) %>
                <%: Html.Button(this.GetMetadata(".Forfeit"), new { @type = "submit", @id = "btnForfeitNetEntBonus" + bonus.ID })%>
                <% } %>

                <script type="text/javascript">
                    $(function () {
                        $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').click( function(e){
                            e.preventDefault();
                            var ret = window.confirm( '<%= this.GetMetadata(".Forfeit_Warning").SafeJavascriptStringEncode() %>' );

                            if(ret){
                                $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(true);
                                var options = {
                                    dataType: "json",
                                    type: 'POST',
                                    success: function (json) {
                                        $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                        if( !json.success ){
                                            alert(json.error);
                                        }else{
                                            self.location = self.location.toString().replace(/(\#.*)$/, '');
                                        }
                                    },
                                    error: function (xhr, textStatus, errorThrown) {
                                        $('#btnForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').toggleLoadingSpin(false);
                                    }
                                };
                                $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').ajaxForm(options);
                                $('#formForfeitNetEntBonus<%= bonus.ID.SafeJavascriptStringEncode() %>').submit();
                            }
                        });

                    });
                </script>
            </td>
        </tr>
        <% } %>
        

    </table>
<%      }
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

            <ui:InputField ID="fldBonusCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
            <LabelPart><%= this.GetMetadata(".Bonus_Code").SafeHtmlEncode()%></LabelPart>
            <ControlPart>
                    <%: Html.TextBox( "bonusCode", string.Empty, new 
                    {
                        @maxlength = "50",
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".Bonus_Code_Empty"))
                    })  %>
                </ControlPart>
            </ui:InputField>


            <%: Html.Button( this.GetMetadata(".Button_Submit"), new { @type = "submit", @id="btnApplyCasinoBonus" }) %>
            <script type="text/javascript">
                $(function () {
                    $('#formApplyCasinoBonusCode').initializeForm();

                    $('#btnApplyCasinoBonus').click(function (e) {
                        e.preventDefault();

                        if (!$('#formApplyCasinoBonusCode').valid())
                            return;
                        $('#btnApplyCasinoBonus').toggleLoadingSpin(true);
                        var options = {
                            dataType: "json",
                            type: 'POST',
                            success: function (json) {
                                $('#btnApplyCasinoBonus').toggleLoadingSpin(false);
                                if (!json.success) {
                                    alert(json.error);
                                    return;
                                }
                                alert('<%= this.GetMetadata(".Bonus_Code_Applied").SafeJavascriptStringEncode() %>');
                                self.location = self.location.toString().replace(/(\#.*)$/, '');
                            },
                            error: function (xhr, textStatus, errorThrown) {
                                $('#btnApplyCasinoBonus').toggleLoadingSpin(false);
                            }
                        };
                        $('#formApplyCasinoBonusCode').ajaxForm(options);
                        $('#formApplyCasinoBonusCode').submit();
                    });
                });
            </script>

<%      } // using end
   } // if end%>


</ui:Fieldset>


<%------------------------------------
    NetEnt - FPP
 ------------------------------------%>
<% if (NetEntFPPClaimRec != null)
   { %>

<br />
<ui:Fieldset runat="server" Legend="<%$ Metadata:value(.Casino_FPP) %>">
    <%: Html.InformationMessage( string.Format(this.GetMetadata(".Casino_FPP_Notes")
    , NetEntFPPClaimRec.CfgConvertionPoints
    , NetEntFPPClaimRec.CfgConvertionCurrency
    , NetEntFPPClaimRec.CfgConvertionAmount
    ), true) %>
<%
    using (Html.BeginRouteForm("AvailableBonus", new { @action = "ClaimCasinoFPP" }, FormMethod.Post, new { @id = "formClaimCasinoFPP" }))
    { %>
        
        <ui:InputField ID="InputField1" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Casino_FPP_Min_Claim_Points").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("fppMinClaimPoints", NetEntFPPClaimRec.CfgConvertionMinClaimPoints.ToString("N0"), new 
                {
                    @maxlength = "50",
                    @readonly = "readonly",
                })  %>
            </ControlPart>
        </ui:InputField>

        <ui:InputField ID="fldCasinoFPPPoints" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Casino_FPP_Points").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("fppPoints", NetEntFPPClaimRec.Points.ToString("N0"), new 
                {
                    @maxlength = "50",
                    @readonly = "readonly",
                })  %>
            </ControlPart>
        </ui:InputField>

        <ui:InputField ID="fldCasinoExchangeAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Casino_FPP_Exchange_Amount").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox( "fppExchangeAmount", string.Format("{0} {1:N2}", NetEntFPPClaimRec.RewardCurrency, NetEntFPPClaimRec.RewardAmount), new 
                {
                    @maxlength = "50",
                    @readonly = "readonly",
                })  %>
            </ControlPart>
        </ui:InputField>
        <% if (NetEntFPPClaimRec.Converted > 0)
           {  %>
        <%: Html.Button(this.GetMetadata(".Button_Claim"), new { @type = "submit", @id = "btnClaimCasinoFPP" })%>
        <% } %>
<%  } %>
</ui:Fieldset>
<script type="text/javascript">
    $(function () {
        $('#formClaimCasinoFPP').initializeForm();

        $('#btnClaimCasinoFPP').click(function (e) {
            e.preventDefault();

            $('#btnClaimCasinoFPP').toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnClaimCasinoFPP').toggleLoadingSpin(false);
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    self.location = self.location.toString().replace(/(\#.*)$/, '');
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnClaimCasinoFPP').toggleLoadingSpin(false);
                }
            };
            $('#formClaimCasinoFPP').ajaxForm(options);
            $('#formClaimCasinoFPP').submit();
        });
    });
</script>

<% } %>


</ui:Panel>
</div>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        jQuery('body').addClass('AvailableBonusPage').addClass('ProfilePage');
        jQuery('.inner').addClass('AvailableBonusContent');
   $(function () {
           // console.log('reload bonus');
            setTimeout(function(){
                $(document).trigger("BALANCE_UPDATED");
            },1000);
        });
    </script>
</ui:MinifiedJavascriptControl>
</asp:Content>


