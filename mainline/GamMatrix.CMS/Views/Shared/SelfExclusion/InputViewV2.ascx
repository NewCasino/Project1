<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<style type="text/css">
#pnSelfExclusion form td{  vertical-align: top }
    #fldSelfExclusionUntilSelectedDate .inputfield_Label, #fldCoolOffUntilSelectedDate .inputfield_Label
    {
        display: none;
    }
</style>
<div id="wrapperSelfExclusionAndCoolOff">
<% Html.RenderPartial("CoolOff"); %>
<br />
<% Html.RenderPartial("SelfExclusion"); %>
<% Html.RenderPartial("/Components/DatePicker"); %>
</div>

<script type="text/javascript">
    $(function () {
        $(document).bind("_ON_SelfExclusionCoolOff_APPLIED", function (e,html) {
            $('#wrapperSelfExclusionAndCoolOff').html(html);
        });
    });
</script>