<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrixAPI.UserMessageInfoRec>>" %>
<%
if (Profile.IsAuthenticated)
	{ 
		if (this.Model != null)
		{ %>
<ui:Block ID="UserMessageDetail" runat="server" CssClass="UserMessageDetail">
  <div class="UserMessage_Detail_Subject"> <%=this.Model[0].Subject.ToString()%></div>
  <div class="UserMessage_Detail_content"> <%=this.Model[0].Body.ToString()%> </div>
  <% if (this.Model[0].Type != GamMatrixAPI.UserMessageType.FromUser && !this.GetMetadata("/Messages/_Index_aspx.IsEnableSendMsg").Equals("no", StringComparison.OrdinalIgnoreCase) )  
     {  
         using (Html.BeginRouteForm("Messages", new { @action = "AddMessage" }, FormMethod.Post, new { @id = "formCommentMessage" }))
         {
             %>
    
  <ui:Block ID="UserMessageSendNew" runat="server" CssClass="UserMessageSendNew">
    <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
      <labelpart><%= this.GetMetadata(".Subject_Label").SafeHtmlEncode() %> </labelpart>
      <controlpart>
        <%: Html.TextBox("Subject", 
        this.Model[0].Subject.ToString().Substring(0,this.GetMetadata(".Re_Text").SafeHtmlEncode().Length).ToUpper()==this.GetMetadata(".Re_Text").SafeHtmlEncode().ToUpper()?this.Model[0].Subject.ToString(): this.GetMetadata(".Re_Text").SafeHtmlEncode() + this.Model[0].Subject.ToString()
          , new 
		{
		    @id = "txtSubject",
			@maxlength ="70",
		    @validator = ClientValidators.Create().Required(this.GetMetadata(".Subject_Empty").SafeHtmlEncode()) 
		}
			) %>
      </controlpart>
      <hintpart><%= this.GetMetadata(".Subject_Hint").SafeHtmlEncode() %></hintpart>
    </ui:InputField>
    <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
      <labelpart><%= this.GetMetadata(".Body_Label").SafeHtmlEncode() %></labelpart>
      <controlpart>
        <%: Html.TextArea( "Body", string.Empty, new 
		{
		    @id = "txtBody",
		    @validator = ClientValidators.Create().Required(this.GetMetadata(".Body_Empty").SafeHtmlEncode())
		}
			) %>
      </controlpart>
      <hintpart><%= this.GetMetadata(".Body_Hint").SafeHtmlEncode() %></hintpart>
    </ui:InputField>
    <div class="UserMessage_SendNew_sumbit">
      <div class="left">
        <%: Html.Button( this.GetMetadata(".Sumbit_Title").SafeHtmlEncode(), new { @id = "btnSubmitCommentMessage", @type = "submit" }) %>
      </div>
    </div>
  </ui:Block>
  <% } // form end %>
  <script type="text/javascript">
    $(function () {
		var UserMessagesCommentIsError=false;
		var ShowCommentSuccess =	function (){
			if( !UserMessagesCommentIsError ){
            	$('#UserMessage_Detail_<%=this.Model[0].ID.ToString() %>').fadeOut();
				$('#UserMessage_Success').fadeIn(function (e) {
					$('#UserMessages_Inner').html('<img src="/images/icon/loading.gif" />').load("/Messages/MessagesList", function () {
						setTimeout(function () {
							$('#UserMessages_Inner').slideDown(function () {
								$('#UserMessage_Success').fadeOut();
							});
						}, 1000);
					});
				});
				UserMessagesCommentIsError=false;
			}
		}	
        $('#formCommentMessage').initializeForm();
        $('#btnSubmitCommentMessage').click(function (e) {
            e.preventDefault();
            if (!$('#formCommentMessage').valid())
                return false;
            $('#btnSubmitCommentMessage').toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnSubmitCommentMessage').toggleLoadingSpin(false);
                    if (!json.success) { 
						UserMessagesCommentIsError = true;
						$("#UserMessage_Error").fadeIn(function () {
							setTimeout(function(){
								$("#UserMessage_Error").fadeOut();
								UserMessagesCommentIsError=false;	
							},1000);
						}).find(".message_Text").text(json.error);
                        return;
                    }
					ShowCommentSuccess();
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnSubmitCommentMessage').toggleLoadingSpin(false);
                }
            };
            $('#formCommentMessage').ajaxForm(options);
            $('#formCommentMessage').submit();
        }); 
    });
</script>
  <%
  		} // $(function ()
  %>
</ui:Block>
<%
    } // this.Model != null
} //Profile.IsAuthenticated
%>
