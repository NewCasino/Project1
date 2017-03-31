<%@ Page Language="C#" PageTemplate="/ProfileMaster.master"  Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.AvailableBonusData>>"  Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="OddsMatrix" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        if (Settings.IsBetConstructWalletEnabled)
        {
            fsBonusList.Visible = true;
            fsBetConstructWalletDisabled.Visible = false;
        }
        else
        {
            fsBonusList.Visible = false;
            fsBetConstructWalletDisabled.Visible = true;
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
        <ui:Fieldset ID="fsBonusList" runat="server" Legend="<%$ Metadata:value(.Sports_Bonus) %>">
        <% 
            List<AvailableBonusData> bonuses = this.Model;
            if (bonuses.Count == 0)
            {
                %>
                <%: Html.InformationMessage( this.GetMetadata(".No_Bonus") ) %>
                <%
            }
            else
            {
                foreach (AvailableBonusData bonus in bonuses)
                {%>
            <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">    
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_Type").SafeHtmlEncode() %></td>
                    <td class="value"><%= bonus.Type.SafeHtmlEncode() %></td>
                </tr>

                <% if (bonus.BonusID != "0")
                   { %>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_ID").SafeHtmlEncode()%></td>
                    <td class="value"><%= bonus.BonusID.SafeHtmlEncode()%></td>
                </tr>
                <% } %>

                <%if ( !string.IsNullOrWhiteSpace(bonus.Name) ) 
                  {%>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_Name").SafeHtmlEncode()%></td>
                    <td class="value"><%= bonus.Name.SafeHtmlEncode()%></td>
                </tr>
                <% } %>

                <%if (bonus.Amount > 0.00m) { %>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_Amount").SafeHtmlEncode() %></td>
                    <td class="value"><%= string.Format("{0} {1:N2}", bonus.Currency, bonus.Amount).SafeHtmlEncode()  %></td>
                </tr>
                <%} %>

                <%if (bonus.Percentage > 0.00m) { %>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_Percentage").SafeHtmlEncode() %></td>
                    <td class="value"><%= bonus.Percentage %></td>
                </tr>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_PercentageMaxAmount").SafeHtmlEncode() %></td>
                    <td class="value"><%= bonus.PercentageMaxAmount %></td>
                </tr>
                <%} %>
                
                <%if (bonus.IsMinDepositRequirement) { %>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Bonus_MinDepositAmount").SafeHtmlEncode() %></td>
                    <td class="value"><%= string.Format("{0} {1:N2}", bonus.MinDepositCurrency, bonus.MinDepositAmount).SafeHtmlEncode()  %></td>
                </tr>
                <%} %>    

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

                <%if (bonus.WagerRequirementCoefficient > 0.00m)
                  { %>
                <tr>
                    <td class="name"><%= this.GetMetadata(".Wager_Requirement").SafeHtmlEncode()%></td>
                    <td class="value"><%= bonus.WagerRequirementCoefficient  %></td>
                </tr>
                <% } %>    
            </table>
            <br /><br />
        <%      }
            } %>

<%------------------------------------
    CasinoWallet - BetConstruct Bonus
 ------------------------------------%>
<%
    var gammingAccounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID);
    if( gammingAccounts.Exists( a => a.Record.VendorID == VendorID.CasinoWallet ) )
    {
        
        // Apply bonus code
        using (Html.BeginRouteForm("AvailableBonus", new { @action = "ApplyBetConstructBonusCode" }, FormMethod.Post, new { @id = "formApplyBetConstructBonusCode" }))
        {  %>
                <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
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


            <%: Html.Button( this.GetMetadata(".Button_Submit"), new { @type = "submit", @id="btnApplyBetConstructBonus" }) %>
            <script type="text/javascript">
                $(function () {
                    $('#formApplyBetConstructBonusCode').initializeForm();

                    $('#btnApplyBetConstructBonus').click(function (e) {
                        e.preventDefault();

                        if (!$('#formApplyBetConstructBonusCode').valid())
                            return;
                        $('#btnApplyBetConstructBonus').toggleLoadingSpin(true);
                        var options = {
                            dataType: "json",
                            type: 'POST',
                            success: function (json) {
                                $('#btnApplyBetConstructBonus').toggleLoadingSpin(false);
                                if (!json.success) {
                                    alert(json.error);
                                    return;
                                }
                                alert('<%= this.GetMetadata(".Bonus_Code_Applied").SafeJavascriptStringEncode() %>');
                                self.location = self.location.toString().replace(/(\#.*)$/, '');
                            },
                            error: function (xhr, textStatus, errorThrown) {
                                $('#btnApplyBetConstructBonus').toggleLoadingSpin(false);
                            }
                        };
                        $('#formApplyBetConstructBonusCode').ajaxForm(options);
                        $('#formApplyBetConstructBonusCode').submit();
                    });
                });
            </script>

<%      } // using end
   } // if end%>
        </ui:Fieldset>

        <ui:Fieldset ID="fsBetConstructWalletDisabled" Legend="<%$ Metadata:value(.Sports_Bonus) %>" runat="server">
            <%= Html.CachedPartial("BetConstructWalletDisabled") %>
        </ui:Fieldset>
    </ui:Panel>
</div>

</asp:Content>

