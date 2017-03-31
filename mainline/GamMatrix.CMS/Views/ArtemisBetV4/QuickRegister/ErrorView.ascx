<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<br />
<br />
<br />
<%: Html.ErrorMessage(this.ViewData["ErrorMessage"] as string) %>
<br />
<br />
<script type="text/javascript">
    $('#simplemodal-container', top.document.body).addClass("Step2");
    $("#register-wrapper").addClass("Step2");
</script>