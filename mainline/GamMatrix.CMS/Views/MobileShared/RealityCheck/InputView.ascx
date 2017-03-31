<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script type="text/C#" runat="server">
    private string UserRealityCheckValue { get; set; }
    
    private List<string> GetRealityCheckValues()
    {
        List<string> realityCheckList = new List<string>();
        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GetUserRealityCheckRequest realityCheck = client.SingleRequest<GetUserRealityCheckRequest>(new GetUserRealityCheckRequest()
            {
                UserID = Profile.UserID,
            });

            UserRealityCheckValue = realityCheck.UserRealityCheckValue;

            GetAvailableRealityCheckValuesRequest realityCheckRequest = client.SingleRequest<GetAvailableRealityCheckValuesRequest>(new GetAvailableRealityCheckValuesRequest()
            {
                UserID = Profile.UserID,
            });

            realityCheckList = realityCheckRequest.AvailableRealityCheckValues;
        }

        return realityCheckList;
    }
</script>

<form id="formRealityCheck" action="<%= Url.RouteUrl("RealityCheck", new { @action = "SetRealityCheck" }).SafeHtmlEncode() %>" method="post" class="FormList RealityCheckForm" >
<fieldset>
<legend class="hidden">
<%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode()%>
</legend>
<div class="Container">
	<p class="RealityCheckText"><%= this.GetMetadata(".Options_To_Choose_RealityCheck").HtmlEncodeSpecialCharactors()%>
</div>
<ul class="FormList RealityCheckList">
<% 
foreach (var realityCheckValue in GetRealityCheckValues())
{ %>
	<li class="FormItem RealityCheckItem">
		<input type="radio" name="realityCheckOption" value="<%=realityCheckValue %>" id="optionRealityCheck<%=realityCheckValue %>"<%=string.Equals(UserRealityCheckValue, realityCheckValue, StringComparison.InvariantCultureIgnoreCase) ? " checked" : string.Empty %> />&nbsp;&nbsp;
		<label class="FormBulletLabel" for="optionRealityCheck<%=realityCheckValue %>"><%=realityCheckValue %> <%= this.GetMetadata(".RealityCheckUnit").SafeHtmlEncode()%></label>
	</li>
<% } %>
</ul>
</fieldset>
<div class="AccountButtonContainer RealityCheckBTN">
<button class="Button AccountButton SubmitRealityCheck" type="submit" name="send" id="btnRealityCheck">
<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit")%></strong>
</button>
</div>
</form>

<script type="text/javascript">
    $(function () {
        $('#formRealityCheck').initializeForm();

        $('#btnRealityCheck').click(function (e) {
            e.preventDefault();

            if (!$('#formRealityCheck').valid())
                return false;

            if ($('#formRealityCheck input:radio[name=realityCheckOption]:checked').length == 0)
                return false;

            if ($('input:radio[name=realityCheckOption]:checked').val() == "<%=UserRealityCheckValue%>")
                return false;

            $('#formRealityCheck').submit();
        });
    });
</script>
