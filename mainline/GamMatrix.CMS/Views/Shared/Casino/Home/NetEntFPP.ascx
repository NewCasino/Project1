<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>


<div id="netent-casino-fpp">
    <div class="title"><%= this.GetMetadata(".Cash_Rewards").SafeHtmlEncode() %></div>
    <%: Html.TextboxEx("points", string.Empty, string.Empty, new { @id = "txtNetEntCasinoFPP", @value = "0", @readonly = "readonly"}, "number_box") %>
    <%: Html.LinkButton(this.GetMetadata(".Refresh"), new { @id = "btnRefreshNetEntFPP", @class = "btnRefreshNetEntFPP", @href = "javascript:void(0)" })%>
    <%: Html.LinkButton(this.GetMetadata(".Claim"), new { @id = "btnClaim", @class = "btnClaim", @disabled = "disabled", @href = "javascript:void(0)" })%>
    <%: Html.LinkButton(this.GetMetadata(".Learn_More"), new { @id = "btnLearnMoreNetEntRewards", @target = "_blank", @class = "btnLearnMoreNetEntRewards", @href = "/Casino/FPPLearnMore" })%>
</div>

<% if( Profile.IsAuthenticated )
   { %>
<script language="javascript" type="text/javascript">
    $(function () {

        $('#btnRefreshNetEntFPP').click(function (e) {
            e.preventDefault();

            $('#netent-casino-fpp #txtNetEntCasinoFPP').val('N / A');
            var url = '<%= this.Url.RouteUrl("Casino", new { @action = "GetNetEntFrequentPlayerPoints" }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                if (!json.success) {
                    //alert(json.error);
                    return;
                }
                $('#netent-casino-fpp #txtNetEntCasinoFPP').val(json.points);
                if (!json.claimable)
                    $('#netent-casino-fpp .btnClaim').attr('disabled', 'disabled');
                else
                    $('#netent-casino-fpp .btnClaim').removeAttr('disabled');
            });
        }).trigger('click');


        $('#netent-casino-fpp #btnClaim').click(function (e) {
            e.preventDefault();
            if ($(this).attr('disabled'))
                return;
            $(this).attr('disabled', 'disabled');

            var url = '<%= this.Url.RouteUrl("Casino", new { @action = "ClaimNetEntFrequentPlayerPoints" }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                if (!json.success) {
                    if (json.error.length > 0) alert(json.error);
                    return;
                }
                $('#btnRefreshNetEntFPP').trigger('click');
                alert('<%= this.GetMetadata(".Claimed_Success").SafeJavascriptStringEncode() %>');
            });
        });

    });
</script>

<% } else { %>
<script language="javascript" type="text/javascript">
    $(function () {
        $('#netent-casino-fpp .btnClaim').attr('disabled', true);
        $('#netent-casino-fpp .btnClaim').click(function (e) {
            e.preventDefault();
        });
    });
</script>
<% } %>