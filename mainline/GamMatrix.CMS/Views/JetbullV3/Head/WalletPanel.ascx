<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%if (!Profile.IsAuthenticated)
  {%>
    <div class="help_panel">
        <div class="reason">
            <%=this.GetMetadata(".Reason_Content").HtmlEncodeSpecialCharactors()%>
        </div>
        <div class="tutorial">
            <%=this.GetMetadata(".Tutorial_Content").HtmlEncodeSpecialCharactors()%>
        </div>
    </div>
    
<%}
  else
  {%>
    <div class="balance-box">
        <%: Html.CachedPartial( "/Head/BalanceList2", this.ViewData.Merge(new {ColumnCount = "1"})) %>
        <%: Html.CachedPartial( "/Head/RefreshBalance", this.ViewData) %>
        <div class="deposit_panel">
            <div class="deposit_number"><%=this.GetMetadata("/Head/TopMenuItems/Promotions.Notification").SafeHtmlEncode()%></div><div class="deposit_description"><%=this.GetMetadata(".Deposit_Description").HtmlEncodeSpecialCharactors()%></div>
            <%: Html.Button(this.GetMetadata(".Deposit_Txt"), new { @type = "button", @class = "button_rightarrow button", @onclick="window.location.href='/Deposit';" })%>
        </div>
        

    </div>
    
<%} %>