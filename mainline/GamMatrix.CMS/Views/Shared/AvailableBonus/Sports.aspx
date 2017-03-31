<%@ Page Language="C#" PageTemplate="/ProfileMaster.master"  Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.AvailableBonusData>>"  Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="OddsMatrix" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        if (Settings.IsOMSeamlessWalletEnabled)
        {
            fsBonusList.Visible = true;
            fsOMSeamlessWalletDisabled.Visible = false;
        }
        else
        {
            fsBonusList.Visible = false;
            fsOMSeamlessWalletDisabled.Visible = true;
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

                <%--if ( !string.IsNullOrWhiteSpace(bonus.TermsAndConditions) ) 
                  {%>
                <tr>
                    <td class="name"></td>
                    <td class="value"><a href="<%= bonus.TermsAndConditions.HtmlEncodeSpecialCharactors()%>" target="_blank"><%= this.GetMetadata(".Bonus_TermsConditions").SafeHtmlEncode()%></a></td>
                </tr>
                <% } --%>
            </table>
            <br /><br />
        <%      }
            } %>
        </ui:Fieldset>

        <ui:Fieldset ID="fsOMSeamlessWalletDisabled" Legend="<%$ Metadata:value(.Sports_Bonus) %>" runat="server">
            <%= Html.CachedPartial("OMSeamlessWalletDisabled") %>
        </ui:Fieldset>
    </ui:Panel>
</div>

</asp:Content>

