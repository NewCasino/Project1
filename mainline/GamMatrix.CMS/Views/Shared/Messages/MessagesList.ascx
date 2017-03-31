<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PagedDataOfUserMessageInfoRec>" %>
<script type="text/C#" runat="server">
    private string GetMessageType(string MessageType)
    {
        return this.GetMetadata(string.Format(".MessageType_{0}", MessageType)).DefaultIfNullOrEmpty(MessageType);
    }
    private string GetMessageStatus(string MessageStatus)
    {
        return this.GetMessageStatus(string.Format(".MessageStatus_{0}", MessageStatus)).DefaultIfNullOrEmpty(MessageStatus);
    }
</script>
<%if (Profile.IsAuthenticated)
       { 
	   %>

<ui:Block ID="UserMessagesList" runat="server" CssClass="UserMessagesList">
  <div class="UserMessages_list_body_header">
    <div class="um_type"> <%=this.GetMetadata(".Type_Title").SafeHtmlEncode()%></div>
    <div class="um_subject"> <%=this.GetMetadata(".Subject_Title").SafeHtmlEncode()%></div>
    <div class="um_Time"> <%=this.GetMetadata(".SendTime_Title").SafeHtmlEncode()%></div>
    <div class="c"> </div>
  </div>
  <div class="UserMessages_list_body_list">
    <%
            List<GamMatrixAPI.UserMessageInfoRec> list = this.Model.Records;
			if(list!=null){
            for (int i = 0; i < list.Count; i++)
            { 
        %>
    <div class="entry <%=i%2==0? "Even":"Odd" %> " id="UserMessage_<%=list[i].ID%>">
      <div class="um_type"> <%=GetMessageType(list[i].Type.ToString())%></div>
      <div class="um_subject <%=list[i].Status.ToString()+" " +list[i].Type.ToString()%>"> <a href="javascript:void(0)" onclick="ViewDetail(<%=list[i].ID%>)"> <%=list[i].Subject%></a></div>
      <div class="um_Time"> <%=list[i].SendTime.ToString("dd/MM/yyyy HH:mm:ss")%></div>
      <div class="c"> </div>
    </div>
    <% 
            }
        %>
    <div class="c"> </div>
    <div class="pagination-wrapper">
      <% 
        long pageIndex = this.Model.PageNumber   ;
        long pageSize = this.Model.PageSize;
        long totalPages = this.Model.TotalRecords;
        for (long i = 0; i <= totalPages/pageSize; i++)
       { %>
      <a <%= (i == pageIndex) ? "class=\"current\"" : "" %> target="_self" href="#" <%= (i == pageIndex) ? "onclick=\"return false;\"" : string.Format("onclick=\"__searchWalletCreditDebit({0}); return false;\"", i) %> > <span><%= (i+1).ToString() %></span> </a>
      <% }  //long i = 0; i <= totalPages/pageSize; i++	%>
    </div>
    <%
	} //list!=null
	else{
		%><div class="UserMessage_Null"><%=this.GetMetadata(".NoMessage_Text").SafeHtmlEncode()%></div>
    <%
		}
	%>
  </div>
</ui:Block>
<script language="javascript" type="text/javascript">
    function ViewDetail(msgid) {
        var item = $("#UserMessage_" + msgid);
        var detailId = "UserMessage_Detail_" + msgid;
        if ($("#" + detailId).length > 0) {
            $("#" + detailId).fadeOut().remove();
            return;
        } else {
            $(".ajaxMessageDetail").fadeOut().remove(); 
            item.after("<div id=" + detailId + " class=\"ajaxMessageDetail\"></div>");
            $("#" + detailId).html('<img src="/images/icon/loading.gif" />').load("/Messages/messagedetail?MessageId=" + msgid);
            var _targetTop = jQuery("#" + detailId).offset().top - 40;
            jQuery("html,body").animate({scrollTop:_targetTop},1000);
        }
    }
     function __searchWalletCreditDebit(pageIndex) {
         //e.preventDefault(); 
        $(document).trigger('Refresh_GetUserMessages_List', pageIndex);
    } 
</script>
<%}%>
