<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
  <link href="//cdn.everymatrix.com/Generic/messages.css" rel="stylesheet" type="text/css" />
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div id="UserMessages" class="content_wrapper">
    <div class="UserMessages_title">
      <div class="UserMessages_PageTitle">
        <%: Html.H1(this.GetMetadata(".PageTitle"))%>
      </div>
            <% if (Profile.IsAuthenticated &&  !this.GetMetadata(".IsEnableSendMsg").Equals("no", StringComparison.OrdinalIgnoreCase) )
       {%>
      <div class="UserMessages_SendNew">
        <ui:Button runat="server" Text="<%$ Metadata:value(.SendNew_Title) %>" ID="UserMessages_SendNew_Button"     />
      </div>
      <% }%>
    </div>
    <div class="UserMessages_mainPanel">

    <% if (!Profile.IsAuthenticated)
       {%>
    <ui:Message runat="server" id="UserMessage_Dislogin" Text="<%$ Metadata:value(.Dislogin_Text) %>" Type="Error" />
    <% }else{%>
    <div class="c"></div>
    <div id="UserMessage_msgbox">
      <ui:Message runat="server" id="UserMessage_Success" Text="<%$ Metadata:value(.Success_Text) %>" Type="Success" />
      <ui:Message runat="server" id="UserMessage_Error" Text="<%$ Metadata:value(.Error_Text) %>" Type="Error" />
    </div>
    <div id="UserMessages_Inner"> </div>
    <div id="UserMessages_Form"> </div>
    <script language="javascript" type="text/javascript">
        var IsEnableSendMsg = '<%=this.GetMetadata(".IsEnableSendMsg") %>'.toLowerCase() == "no" ? false : true;
      $(document).ready(function () {
        $('#UserMessages_Inner').html('<img src="/images/icon/loading.gif" />').load("/Messages/MessagesList");
        if(IsEnableSendMsg){
          $("#UserMessages_SendNew_Button").click(function () {
            $('#UserMessages_Form').html('<img src="/images/icon/loading.gif" />').load("/Messages/MessageForm", function () {
        $('#UserMessages_Form').hide();
    $('#UserMessages_Inner').slideUp( function() { 
                $('#UserMessages_Form').fadeIn();  
              });    
       });           
          }); 
          $(document).bind( 'SUBMIT_MESSAGE_CANCELLED', function(e){
            $('#UserMessages_Inner').fadeIn();     
            $('#UserMessages_Form').fadeOut();
          });
        }    
        $(document).bind('Refresh_GetUserMessages_List', function ( e,pageIndex) {
            $('#UserMessages_Inner').html('<img src="/images/icon/loading.gif" />').load("/Messages/MessagesList?pageNumber=" + pageIndex);
        });
      });
  </script>
    <%}%></div>
  </div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        jQuery('body').addClass('MessagesPage');
        jQuery('.inner').addClass('MessagesContent');
    </script>
</ui:MinifiedJavascriptControl>

</asp:Content>
