<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.PrepareTurkeySMSViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Deposit" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="CM.Web.UI" %>

<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
<form method="post" id="formPrepareSMSTransaction" action="<%= Model.PostbackUrl %>">
    
	<fieldset>
		<legend class="Hidden">
			<%= this.GetMetadata(".TurkeySMS_Legend").SafeHtmlEncode() %>
		</legend>
		<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
		<ul class="FormList">
			<%------------------------------------------
				Sender's phone number
			-------------------------------------------%>
			<% 
			 if (Model.ShowSenderPhoneNumber)
			 { %>
			<li class="FormItem" id="fldSenderPhoneNumber">
				<label class="FormLabel" for="senderPhoneNumber">
				<%= this.GetMetadata(".SenderPhoneNumber_Label").SafeHtmlEncode()%>
				</label>
				<%: Html.TextBox("senderPhoneNumber", string.Empty, new Dictionary<string, object>()  
					{ 
						{ "class", "FormInput" },
						{ "maxlength", "20" },
						{ "autocomplete", "off" },
						{ "dir", "ltr" },
						{ "type", "text" },
						{ "required", "required" },
						{ "placeholder", this.GetMetadata(".SenderPhoneNumber_Label") },
						{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".SenderPhoneNumber_Empty"))
									.Custom("validateSenderPhoneNumber")  }
					}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>

				<script type="text/javascript">
				//<![CDATA[
					$(function () {
						$('#fldSenderPhoneNumber input[name="senderPhoneNumber"]').allowNumberOnly();
					});
					function validateSenderPhoneNumber() {
						var value = this;
						var ret = /^(\d{3,20})$/.exec(value);
						if (ret == null || ret.length == 0)
							return '<%= this.GetMetadata(".SenderPhoneNumber_Invalid").SafeJavascriptStringEncode() %>';
						return true;
					}
				//]]>
				</script>
			</li>
			<% } %>

			<%------------------------------------------
				Receiver's phone number
			-------------------------------------------%>
			<% if (Model.ShowReceiverPhoneNumber)
			 { %>
			<li class="FormItem" id="fldReceiverPhoneNumber">
				<label class="FormLabel" for="receiverPhoneNumber">
				<%= this.GetMetadata(".ReceiverPhoneNumber_Label").SafeHtmlEncode()%>
				</label>
				<%: Html.TextBox("receiverPhoneNumber", string.Empty, new Dictionary<string, object>()  
					{ 
						{ "class", "FormInput" },
						{ "maxlength", "20" },
						{ "autocomplete", "off" },
						{ "dir", "ltr" },
						{ "type", "text" },
						{ "required", "required" },
						{ "placeholder", this.GetMetadata(".ReceiverPhoneNumber_Label") },
						{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ReceiverPhoneNumber_Empty"))
									.Custom("validateReceiverPhoneNumber")  }
					}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>

				<script type="text/javascript">
				//<![CDATA[
					$(function () {
						$('#fldReceiverPhoneNumber input[name="receiverPhoneNumber"]').allowNumberOnly();
					});
					function validateReceiverPhoneNumber() {
						var value = this;
						var ret = /^(\d{3,20})$/.exec(value);
						if (ret == null || ret.length == 0)
							return '<%= this.GetMetadata(".ReceiverPhoneNumber_Invalid").SafeJavascriptStringEncode() %>';
						return true;
					}
				//]]>
				</script>
			</li>
			<% } %>

			<%------------------------------------------
				Receiver's Birth Date
			-------------------------------------------%>
			<% if (Model.ShowReceiverBirthDate)
				{ %>
			<li class="FormItem DOBFormItem" id="fldReceiverBirthDate" runat="server">
				<label class="FormLabel"><%= this.GetMetadata(".ReceiverBirthDate_Label").SafeHtmlEncode()%></label>
				<ol class="CompositeInput DateInput Cols-3">
					<li class="Col">
						<%: Html.DropDownList("rbday", this.Model.DateSelect.GetDayList(this.GetMetadata(".DOB_Day")), new Dictionary<string, object>() 
						{ 
							{ "class", "FormInput" },
							{ "id", "depositDay" },
							{ "required", "required" },
							{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ReceiverBirthDate_Empty")).Custom("validateRegistrationBirthDate") }
						})%>
					</li>
					<li class="Col">
						<%: Html.DropDownList("rbmonth", this.Model.DateSelect.GetMonthList(this.GetMetadata(".DOB_Month")), new Dictionary<string, object>() 
						{ 
							{ "class", "FormInput" },
							{ "id", "depositMonth" },
							{ "required", "required" },
							{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ReceiverBirthDate_Empty")).Custom("validateRegistrationBirthDate") }
						})%>
					</li>
					<li class="Col">
						<%: Html.DropDownList("rbyear", this.Model.DateSelect.GetYearList(this.GetMetadata(".DOB_Year")), new Dictionary<string, object>() 
						{ 
							{ "class", "FormInput" },
							{ "id", "depositYear" },
							{ "required", "required" },
							{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ReceiverBirthDate_Empty")).Custom("validateRegistrationBirthDate") }
						})%>
					</li>
				</ol>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<ui:MinifiedJavascriptControl ID="scriptDOB" runat="server" Enabled="true" AppendToPageEnd="true" EnableObfuscation="true">
			<script type="text/javascript">
			function validateRegistrationBirthDate() {
				var day = $('#depositDay').val();
				var month = $('#depositMonth').val();
				var year = $('#depositYear').val();
				if( day.length == 0 || month.length == 0 || year.length == 0 )
					return '<%= this.GetMetadata(".ReceiverBirthDate_Empty").SafeJavascriptStringEncode() %>';

				day = parseInt(day, 10);
				month = parseInt(month, 10);
				year = parseInt(year, 10);

				var maxDay = 31;
				switch (month) {
					case 4: maxDay = 30; break;
					case 6: maxDay = 30; break;
					case 9: maxDay = 30; break;
					case 11: maxDay = 30; break;

					case 2:
						{
							if (year % 400 == 0 || year % 4 == 0)
								maxDay = 29;
							else
								maxDay = 28;
							break;
						}
					default:
						break;
				}
				if (day > maxDay)
					return '<%= this.GetMetadata(".ReceiverBirthDate_Empty").SafeJavascriptStringEncode() %>';

				return true;
			}
			</script>
			</ui:MinifiedJavascriptControl>
			 <% } %>

			 <%------------------------------------------
				Password
			-------------------------------------------%>
			<% if (Model.ShowPassword)
				{ %>
			<li class="FormItem" id="fldPassword" runat="server">
				<label class="FormLabel" for="registerPassword"><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("password", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "20" },
					{ "placeholder", this.GetMetadata(".Password_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Password_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<% } %>

			<%------------------------------------------
				Reference number
			-------------------------------------------%>
			<% if (Model.ShowReferenceNumber)
				{ %>
			<li class="FormItem" id="fldReferenceNumber" runat="server">
				<label class="FormLabel" for="referenceNumber"><%= this.GetMetadata(".ReferenceNumber_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("referenceNumber", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "20" },
					{ "placeholder", this.GetMetadata(".ReferenceNumber_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ReferenceNumber_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<% } %>

			<%------------------------------------------
				Sender's TC number
			-------------------------------------------%>
			<% if (Model.ShowSenderTCNumber)
				{ %>
			<li class="FormItem" id="fldSenderTCNumber" runat="server">
				<label class="FormLabel" for="senderTCNumber"><%= this.GetMetadata(".SenderTCNumber_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("senderTCNumber", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "20" },
					{ "placeholder", this.GetMetadata(".SenderTCNumber_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".SenderTCNumber_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			 <% } %>
			 <%------------------------------------------
				Receiver's TC number
			 -------------------------------------------%>
			<% if (Model.ShowReceiverTCNumber)
				{ %>
			<li class="FormItem" id="fldReceiverTCNumber" runat="server">
				<label class="FormLabel" for="receiverTCNumber"><%= this.GetMetadata(".ReceiverTCNumber_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("receiverTCNumber", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "20" },
					{ "placeholder", this.GetMetadata(".ReceiverTCNumber_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".ReceiverTCNumber_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<% } %>
		</ul>
	</fieldset>
	<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
</form>