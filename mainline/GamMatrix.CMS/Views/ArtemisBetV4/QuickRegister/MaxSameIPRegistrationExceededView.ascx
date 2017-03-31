<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%: Html.ErrorMessage( this.GetMetadata(".Blocked_Message").Replace("[IP]", Request.GetRealUserAddress()).Replace("[COUNT]", Settings.Registration.SameIPLimitPerDay.ToString()) ) %>

<script type="text/javascript">
    $('#simplemodal-container', top.document.body).addClass("Step2");
    $("#register-wrapper").addClass("Step2");
</script>