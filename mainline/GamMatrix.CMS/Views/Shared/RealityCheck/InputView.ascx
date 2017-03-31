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

<div class="wrapperRealityCheck">
<%
    using (Html.BeginRouteForm("RealityCheck", new { @action = "SetRealityCheck" }, FormMethod.Post, new { @id = "formRealityCheck" }))
   {  %>
        <div id="divRealityCheckOption">
            <p><%= this.GetMetadata(".Options_To_Choose_RealityCheck").HtmlEncodeSpecialCharactors()%></p><br />
            <table cellpadding="0" cellspacing="0" border="0" class="options-table" style="width:auto;">
                <% 
                    foreach (var realityCheckValue in GetRealityCheckValues())
                   { %>
                <tr>
                    <td>
                        <input type="radio" name="realityCheckOption" value="<%=realityCheckValue %>" id="optionRealityCheck<%=realityCheckValue %>"<%=string.Equals(UserRealityCheckValue, realityCheckValue, StringComparison.InvariantCultureIgnoreCase) ? " checked" : string.Empty %> />&nbsp;&nbsp;
                    </td>
                    <td>
                        <label for="optionRealityCheck<%=realityCheckValue %>"><strong><%=realityCheckValue %> <%= this.GetMetadata(".RealityCheckUnit").SafeHtmlEncode()%></strong>
                    </td>
                </tr>
                <% } %>
            </table>
        </div>

        <center>
            <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnRealityCheck" })%>
        </center>
<% } %>

<script type="text/javascript">
    $(function () {
        $(document).bind("_ON_RealityCheck_APPLIED", function (e, html) {
            $('.wrapperRealityCheck').html(html);
        });
        $('#formRealityCheck').initializeForm();

        $('#btnRealityCheck').click(function (e) {
            if (!$('#formRealityCheck').valid())
                return false;

            if ($('input[name="realityCheckOption"]:checked').val() == "<%=UserRealityCheckValue%>")
                return false;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnRealityCheck').toggleLoadingSpin(false);
                    $(document).trigger("_ON_RealityCheck_APPLIED", html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnRealityCheck').toggleLoadingSpin(false);
                }
            };
            $('#formRealityCheck').ajaxForm(options);
            $('#formRealityCheck').submit();
        });
    });
</script>
</div>