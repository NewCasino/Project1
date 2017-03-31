<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<% 
    if (Profile.IsAuthenticated && !this.GetMetadata("/Messages/_Index_aspx.IsEnableSendMsg").Equals("no", StringComparison.OrdinalIgnoreCase))
       { 
	   using (Html.BeginRouteForm("Messages", new { @action = "AddMessage" }, FormMethod.Post, new { @id = "formAddMessage" }))
   {   %>

<ui:Block ID="UserMessageSendNew" runat="server" CssClass="UserMessageSendNew">
  <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".Subject_Label").SafeHtmlEncode().SafeHtmlEncode() %>
      </labelpart>
      <controlpart>
        <%: Html.TextBox( "Subject", string.Empty, new 
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
          <%: Html.Button( this.GetMetadata(".Sumbit_Title") , new { @id = "btnSubmitMessage", @type = "submit" }) %>
        </div>
        <div class="right">
          <%: Html.Button(this.GetMetadata(".Cancel_Title") , new { @id = "btnCancelSubmitionMessage", @type = "button" })%>
        </div>
      </div>
</ui:Block>
<% } // form end %>
<script type="text/javascript">
    $(function () {		
		var UserMessagesIsError=false;	
		var ShowSuccess =	function (){
			if(UserMessagesIsError != true){
				$('#UserMessages_Form').fadeOut();
				$('#UserMessage_Success').fadeIn(function(e){
					$('#UserMessages_Inner').html('<img src="/images/icon/loading.gif" />').load("/Messages/MessagesList", function () {
						setTimeout(function(){
									$('#UserMessages_Inner').slideDown(function(){
										$('#UserMessage_Success').fadeOut();
									});
						},1000);
					});
				});
				UserMessagesIsError=false;
			}
		}
        $('#formAddMessage').initializeForm();
        $('#btnSubmitMessage').click(function (e) {
            e.preventDefault();
            if (!$('#formAddMessage').valid())
                return false;
            $('#btnSubmitMessage').toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnSubmitMessage').toggleLoadingSpin(false);
                    if (!json.success) {
						UserMessagesIsError = true;
						$("#UserMessage_Error").fadeIn(function () {
							setTimeout(function(){
								$("#UserMessage_Error").fadeOut();
								UserMessagesIsError=false;	
							},1000);
						}).find(".message_Text").text(json.error);
                        return;
					}
					ShowSuccess();			
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnSubmitMessage').toggleLoadingSpin(false);
                }
            };
            $('#formAddMessage').ajaxForm(options);
            $('#formAddMessage').submit(); 
        });

        $('#btnCancelSubmitionMessage').click(function (e) {
            e.preventDefault();
            $(document).trigger('SUBMIT_MESSAGE_CANCELLED');
        });
    });
</script>
<%}%>