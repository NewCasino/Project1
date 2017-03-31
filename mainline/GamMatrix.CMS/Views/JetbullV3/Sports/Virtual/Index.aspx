<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%if (this.GetMetadata("/Metadata/Settings.UKLicense_CountryIDs").Contains(Profile.IpCountryID.ToString()))
        { %>
            
        
<div class="TablesContainer">
        
       <% string msg = this.GetMetadataEx( ".No_Table_Available"
                  , Request.GetRealUserAddress()
                  , Profile.IpCountryID
                  , Profile.UserCountryID
                  );
               %>

            <%: Html.WarningMessage(msg) %></div>
        

</div>
<% } 
else {%>
<% Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = "OddsMatrix_VirtualSports"})); %>
<%}%>
</asp:Content>

