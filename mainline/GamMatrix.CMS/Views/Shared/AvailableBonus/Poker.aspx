<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.BonusData>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
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

<ui:Fieldset runat="server" Legend="<%$ Metadata:value(.Poker_Bonus) %>">
<% 
    List<BonusData> bonuses = this.Model;
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


    </table>
<%      }
    } %>


</ui:Fieldset>





</ui:Panel>
</div>

</asp:Content>

